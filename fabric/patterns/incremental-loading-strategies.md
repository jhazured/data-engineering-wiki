# Incremental Loading Strategies Guide

## Overview

This guide consolidates all incremental loading strategies for the T0-T5 architecture pattern in Microsoft Fabric. It covers watermark-based loading, CDC (Change Data Capture), snapshot loading, incremental SCD2, late-arriving data handling, and provides a comparison matrix to help you choose the right approach.

**Key Concepts:**
- **Incremental Loading**: Process only new or changed data since last load
- **Watermark-Based**: Track last processed timestamp/ID
- **CDC**: Capture changes from source systems
- **Snapshot Loading**: Full replacement of data
- **Late-Arriving Data**: Data arriving out of sequence

---

## Table of Contents

1. [Strategy Comparison Matrix](#strategy-comparison-matrix)
2. [Watermark-Based Incremental Loading](#watermark-based-incremental-loading)
3. [Change Data Capture (CDC)](#change-data-capture-cdc)
4. [Incremental SCD2 Loading](#incremental-scd2-loading)
5. [Snapshot Loading](#snapshot-loading)
6. [Late-Arriving Data Handling](#late-arriving-data-handling)
7. [Dataflows Gen2 Incremental Refresh](#dataflows-gen2-incremental-refresh)
8. [Best Practices](#best-practices)

---

## Strategy Comparison Matrix

### When to Use Which Approach

| Strategy | Use Case | Source Support Required | Complexity | Performance | Storage Impact | Late-Arriving Data Support |
|----------|----------|-------------------------|------------|-------------|----------------|---------------------------|
| **Watermark-Based** | Fact tables, append-only data | Timestamp/ID column | Low | High | Low | Manual handling needed |
| **CDC** | High-frequency changes, real-time needs | CDC-enabled source | Medium | Very High | Medium | Automatic handling |
| **Incremental SCD2** | Dimension tables with history | Timestamp column | Medium | Medium | High (history) | Manual handling needed |
| **Snapshot Loading** | Small tables, validation phase | None | Low | Low | High | Not applicable |
| **Dataflows Gen2 Incremental** | T3 transformations, large tables | Date/timestamp column | Low | High | Low | Manual handling needed |

### Decision Tree

```
Is source CDC-enabled?
├─ YES → Use CDC pattern
└─ NO → Does source have timestamp/ID column?
    ├─ YES → Is this a dimension table?
    │   ├─ YES → Use Incremental SCD2
    │   └─ NO → Use Watermark-Based
    └─ NO → Is table small (< 1M rows)?
        ├─ YES → Use Snapshot Loading
        └─ NO → Consider adding timestamp column or use CDC
```

### Performance Characteristics

| Strategy | Initial Load Time | Incremental Load Time | Query Performance | Maintenance Overhead |
|----------|------------------|----------------------|-------------------|---------------------|
| **Watermark-Based** | High (full load) | Low | High | Low |
| **CDC** | High (full load) | Very Low | High | Medium |
| **Incremental SCD2** | High (full load) | Medium | Medium | Medium |
| **Snapshot Loading** | Medium | Medium (full reload) | High | Low |
| **Dataflows Gen2 Incremental** | High (full load) | Low | High | Low |

---

## Watermark-Based Incremental Loading

### Overview

Watermark-based loading tracks the last processed timestamp or ID to identify new records. This is the most common pattern for fact tables and append-only data.

### Architecture Pattern

```
T0.watermark table
    ↓
Data Factory Lookup Activity
    ↓
Filter source data WHERE timestamp > watermark
    ↓
Load to T1
    ↓
Process to T2
    ↓
Update watermark
```

### Implementation: T1 Ingestion (Data Factory)

**Step 1: Create Watermark Table**

```sql
CREATE TABLE t0.watermark (
    table_name VARCHAR(100) PRIMARY KEY,
    last_processed_timestamp DATETIME2,
    last_processed_id BIGINT NULL,  -- Optional: for ID-based watermarks
    updated_at DATETIME2 DEFAULT GETDATE()
);
```

**Step 2: Lookup Watermark Activity**

```json
{
  "name": "Lookup_Watermark",
  "type": "Lookup",
  "typeProperties": {
    "source": {
      "type": "SqlSource",
      "sqlReaderQuery": "SELECT last_processed_timestamp FROM t0.watermark WHERE table_name = 'fact_payroll'"
    },
    "dataset": {
      "referenceName": "DS_Warehouse",
      "type": "DatasetReference"
    }
  }
}
```

**Step 3: Incremental Copy Activity**

```json
{
  "name": "Copy_Incremental_Data",
  "type": "Copy",
  "dependsOn": [
    {
      "activity": "Lookup_Watermark",
      "dependencyConditions": ["Succeeded"]
    }
  ],
  "typeProperties": {
    "source": {
      "type": "SqlSource",
      "sqlReaderQuery": "@concat('SELECT * FROM source.payroll WHERE modified_date > ''', activity('Lookup_Watermark').output.firstRow.last_processed_timestamp, '''')"
    },
    "sink": {
      "type": "LakehouseSink",
      "writeBehavior": "append"
    }
  }
}
```

**Step 4: Update Watermark**

```sql
MERGE INTO t0.watermark AS target
USING (
    SELECT 
        'fact_payroll' AS table_name,
        MAX(modified_date) AS last_processed_timestamp
    FROM T1_DATA_LAKE.raw_payroll
) AS source
ON target.table_name = source.table_name
WHEN MATCHED THEN 
    UPDATE SET 
        last_processed_timestamp = source.last_processed_timestamp,
        updated_at = GETDATE()
WHEN NOT MATCHED THEN 
    INSERT (table_name, last_processed_timestamp)
    VALUES (source.table_name, source.last_processed_timestamp);
```

### Implementation: T2 Fact Table Loading (T-SQL)

**Stored Procedure Pattern:**

```sql
CREATE PROCEDURE t2.usp_load_fact_payroll_incremental
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @LastLoad DATETIME2;
    DECLARE @RowsProcessed INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Get watermark (last loaded timestamp)
        SELECT @LastLoad = ISNULL(MAX(source_ingested_at), '1900-01-01')
        FROM t2.fact_payroll;
        
        -- Insert only new records
        INSERT INTO t2.fact_payroll (
            payroll_id, employee_id, pay_period_start, pay_period_end, pay_date,
            regular_hours, overtime_hours, hourly_rate, gross_pay,
            tax_deducted, superannuation, health_insurance, net_pay,
            payment_method, source_ingested_at
        )
        SELECT 
            s.payroll_id,
            s.employee_id,
            s.pay_period_start,
            s.pay_period_end,
            s.pay_date,
            s.regular_hours,
            s.overtime_hours,
            s.hourly_rate,
            s.gross_pay,
            s.tax_deducted,
            s.superannuation,
            s.health_insurance,
            s.net_pay,
            s.payment_method,
            s.ingested_at
        FROM t1_payroll s
        WHERE s.ingested_at > @LastLoad
        AND NOT EXISTS (
            SELECT 1 FROM t2.fact_payroll f 
            WHERE f.payroll_id = s.payroll_id
        );
        
        SET @RowsProcessed = @@ROWCOUNT;
        
        -- Update surrogate keys
        UPDATE f
        SET 
            f.emp_key = e.emp_key,
            f.dept_key = d.dept_key,
            f.pay_date_key = CAST(CONVERT(VARCHAR(8), f.pay_date, 112) AS INT)
        FROM t2.fact_payroll f
        LEFT JOIN t2.dim_employee e ON f.employee_id = e.employee_id AND e.is_current = 1
        LEFT JOIN t2.dim_department d ON e.department_id = d.dept_id AND d.is_current = 1
        WHERE f.emp_key IS NULL
        AND f.source_ingested_at > @LastLoad;
        
        COMMIT TRANSACTION;
        
        -- Log success
        INSERT INTO t0.pipeline_log (
            pipeline_name, start_time, end_time, status, rows_processed
        )
        VALUES (
            't2.usp_load_fact_payroll_incremental',
            @StartTime,
            GETDATE(),
            'Success',
            @RowsProcessed
        );
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Log error
        INSERT INTO t0.error_log (
            component_type, component_name, error_severity, error_message
        )
        VALUES (
            'StoredProcedure',
            't2.usp_load_fact_payroll_incremental',
            'High',
            ERROR_MESSAGE()
        );
        
        THROW;
    END CATCH
END;
GO
```

### ID-Based Watermark Pattern

For sources without timestamps, use ID-based watermarks:

```sql
CREATE PROCEDURE t2.usp_load_fact_incremental_by_id
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @LastProcessedID BIGINT;
    
    -- Get last processed ID
    SELECT @LastProcessedID = ISNULL(MAX(source_id), 0)
    FROM t2.fact_payroll;
    
    -- Insert new records
    INSERT INTO t2.fact_payroll (...)
    SELECT ...
    FROM t1_payroll
    WHERE source_id > @LastProcessedID
    ORDER BY source_id;
END;
GO
```

### Best Practices

- ✅ Use timestamp-based watermarks when available
- ✅ Index watermark columns in source and target
- ✅ Update watermark only after successful processing
- ✅ Handle NULL watermarks (first run)
- ✅ Use DATETIME2 for precise timestamps
- ✅ Store watermarks in T0 control layer
- ✅ Log watermark updates
- ❌ Don't update watermark before processing completes
- ❌ Don't use watermarks for full refresh scenarios
- ❌ Don't skip duplicate checking

---

## Change Data Capture (CDC)

### Overview

CDC captures changes (inserts, updates, deletes) from source systems automatically. This is ideal for high-frequency changes and real-time data integration.

### Architecture Pattern

```
Source System (CDC-enabled)
    ↓
CDC Change Tables
    ↓
Data Factory CDC Activity
    ↓
T1 Lakehouse (with change type)
    ↓
T2 Process Changes
    ↓
Update/Insert/Delete in T2
```

### Implementation: T1 CDC Ingestion

**Step 1: Enable CDC on Source (if SQL Server)**

```sql
-- On source database
EXEC sys.sp_cdc_enable_db;

EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'payroll',
    @role_name = N'cdc_admin',
    @supports_net_changes = 1;
```

**Step 2: Data Factory CDC Activity**

```json
{
  "name": "Copy_CDC_Changes",
  "type": "Copy",
  "typeProperties": {
    "source": {
      "type": "SqlSource",
      "sqlReaderQuery": "
        SELECT 
            __$start_lsn,
            __$operation,
            __$update_mask,
            payroll_id,
            employee_id,
            pay_date,
            gross_pay,
            -- Map __$operation: 1=delete, 2=insert, 3=update (before), 4=update (after)
            CASE __$operation
                WHEN 1 THEN 'DELETE'
                WHEN 2 THEN 'INSERT'
                WHEN 3 THEN 'UPDATE_BEFORE'
                WHEN 4 THEN 'UPDATE_AFTER'
            END AS change_type
        FROM cdc.dbo_payroll_CT
        WHERE __$start_lsn > @{activity('Lookup_CDC_LSN').output.firstRow.last_lsn}
        ORDER BY __$start_lsn
      "
    },
    "sink": {
      "type": "LakehouseSink",
      "writeBehavior": "append"
    }
  }
}
```

**Step 3: Track CDC LSN (Log Sequence Number)**

```sql
CREATE TABLE t0.cdc_watermark (
    table_name VARCHAR(100) PRIMARY KEY,
    last_processed_lsn BINARY(10),
    last_processed_timestamp DATETIME2,
    updated_at DATETIME2 DEFAULT GETDATE()
);
```

**Step 4: Update CDC Watermark**

```sql
MERGE INTO t0.cdc_watermark AS target
USING (
    SELECT 
        'payroll' AS table_name,
        MAX(__$start_lsn) AS last_processed_lsn,
        GETDATE() AS last_processed_timestamp
    FROM T1_DATA_LAKE.raw_payroll_cdc
) AS source
ON target.table_name = source.table_name
WHEN MATCHED THEN 
    UPDATE SET 
        last_processed_lsn = source.last_processed_lsn,
        last_processed_timestamp = source.last_processed_timestamp,
        updated_at = GETDATE()
WHEN NOT MATCHED THEN 
    INSERT (table_name, last_processed_lsn, last_processed_timestamp)
    VALUES (source.table_name, source.last_processed_lsn, source.last_processed_timestamp);
```

### Implementation: T2 Process CDC Changes

**Stored Procedure Pattern:**

```sql
CREATE PROCEDURE t2.usp_process_cdc_changes
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @RowsProcessed INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Process DELETES
        DELETE f
        FROM t2.fact_payroll f
        INNER JOIN t1_payroll_cdc c ON f.payroll_id = c.payroll_id
        WHERE c.change_type = 'DELETE';
        
        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;
        
        -- Process INSERTS
        INSERT INTO t2.fact_payroll (...)
        SELECT ...
        FROM t1_payroll_cdc
        WHERE change_type = 'INSERT'
        AND NOT EXISTS (
            SELECT 1 FROM t2.fact_payroll f 
            WHERE f.payroll_id = t1_payroll_cdc.payroll_id
        );
        
        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;
        
        -- Process UPDATES (UPDATE_AFTER only)
        UPDATE f
        SET 
            f.employee_id = c.employee_id,
            f.pay_date = c.pay_date,
            f.gross_pay = c.gross_pay,
            f.updated_at = GETDATE()
        FROM t2.fact_payroll f
        INNER JOIN t1_payroll_cdc c ON f.payroll_id = c.payroll_id
        WHERE c.change_type = 'UPDATE_AFTER';
        
        SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        -- Log success
        INSERT INTO t0.pipeline_log (
            pipeline_name, start_time, end_time, status, rows_processed
        )
        VALUES (
            't2.usp_process_cdc_changes',
            @StartTime,
            GETDATE(),
            'Success',
            @RowsProcessed
        );
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Log error
        INSERT INTO t0.error_log (...)
        VALUES (...);
        
        THROW;
    END CATCH
END;
GO
```

### CDC with Azure SQL Database

**Using Change Tracking (lighter than CDC):**

```sql
-- Enable Change Tracking on source
ALTER TABLE source.payroll
ENABLE CHANGE_TRACKING
WITH (TRACK_COLUMNS_UPDATED = ON);

-- Query changes
SELECT 
    ct.SYS_CHANGE_VERSION,
    ct.SYS_CHANGE_OPERATION,
    ct.SYS_CHANGE_COLUMNS,
    p.*
FROM CHANGETABLE(CHANGES source.payroll, @last_sync_version) AS ct
INNER JOIN source.payroll p ON ct.payroll_id = p.payroll_id;
```

### Best Practices

- ✅ Use CDC for high-frequency change sources
- ✅ Process changes in LSN order
- ✅ Handle all change types (INSERT, UPDATE, DELETE)
- ✅ Track LSN in T0 control layer
- ✅ Process UPDATE_BEFORE and UPDATE_AFTER correctly
- ✅ Clean up CDC change tables periodically
- ✅ Monitor CDC latency
- ❌ Don't skip DELETE operations
- ❌ Don't process changes out of order
- ❌ Don't ignore CDC retention period

---

## Incremental SCD2 Loading

### Overview

Incremental SCD2 loading processes only changed dimension records since the last load, creating new versions for changes while maintaining history.

### Architecture Pattern

```
T1 Dimension Data (with ingested_at timestamp)
    ↓
Compare with T2 Current Records
    ↓
Identify Changed Records
    ↓
Expire Old Versions
    ↓
Insert New Versions
    ↓
Insert New Records
```

### Implementation: Incremental SCD2 MERGE

**Stored Procedure Pattern:**

```sql
CREATE PROCEDURE t2.usp_merge_dim_department_incremental
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @LastLoad DATETIME2;
    DECLARE @RowsAffected INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Get watermark (last processed timestamp)
        SELECT @LastLoad = ISNULL(MAX(ingested_at), '1900-01-01')
        FROM t1_department
        WHERE EXISTS (
            SELECT 1 FROM t0.watermark 
            WHERE table_name = 'dim_department'
        );
        
        -- If watermark exists, use it; otherwise process all
        IF EXISTS (SELECT 1 FROM t0.watermark WHERE table_name = 'dim_department')
        BEGIN
            SELECT @LastLoad = last_processed_timestamp
            FROM t0.watermark
            WHERE table_name = 'dim_department';
        END
        
        -- Step 1: Expire old records that have changed
        UPDATE t2.dim_department
        SET 
            expiry_date = GETDATE(),
            is_current = 0,
            updated_at = GETDATE()
        WHERE is_current = 1
        AND dept_id IN (
            SELECT s.dept_id
            FROM t1_department s
            INNER JOIN t2.dim_department t ON s.dept_id = t.dept_id AND t.is_current = 1
            WHERE s.ingested_at > @LastLoad
            AND (
                s.dept_name <> t.dept_name
                OR s.division_id <> t.division_id
                OR s.cost_center <> t.cost_center
                OR s.location <> t.location
            )
        );
        
        SET @RowsAffected = @@ROWCOUNT;
        
        -- Step 2: Insert new versions for changed records
        INSERT INTO t2.dim_department (
            dept_id, dept_name, division_id, division_name,
            cost_center, location, effective_date, is_current
        )
        SELECT 
            s.dept_id,
            s.dept_name,
            s.division_id,
            s.division_name,
            s.cost_center,
            s.location,
            GETDATE(),
            1
        FROM t1_department s
        WHERE s.ingested_at > @LastLoad
        AND EXISTS (
            SELECT 1 
            FROM t2.dim_department t 
            WHERE t.dept_id = s.dept_id 
            AND t.is_current = 0
            AND t.expiry_date = CAST(GETDATE() AS DATE)
        );
        
        SET @RowsAffected = @RowsAffected + @@ROWCOUNT;
        
        -- Step 3: Insert completely new records
        INSERT INTO t2.dim_department (
            dept_id, dept_name, division_id, division_name,
            cost_center, location, effective_date, is_current
        )
        SELECT 
            s.dept_id,
            s.dept_name,
            s.division_id,
            s.division_name,
            s.cost_center,
            s.location,
            GETDATE(),
            1
        FROM t1_department s
        WHERE s.ingested_at > @LastLoad
        AND NOT EXISTS (
            SELECT 1 FROM t2.dim_department t WHERE t.dept_id = s.dept_id
        );
        
        SET @RowsAffected = @RowsAffected + @@ROWCOUNT;
        
        -- Update watermark
        MERGE INTO t0.watermark AS target
        USING (
            SELECT 
                'dim_department' AS table_name,
                MAX(ingested_at) AS last_processed_timestamp
            FROM t1_department
        ) AS source
        ON target.table_name = source.table_name
        WHEN MATCHED THEN 
            UPDATE SET 
                last_processed_timestamp = source.last_processed_timestamp,
                updated_at = GETDATE()
        WHEN NOT MATCHED THEN 
            INSERT (table_name, last_processed_timestamp)
            VALUES (source.table_name, source.last_processed_timestamp);
        
        COMMIT TRANSACTION;
        
        -- Log success
        INSERT INTO t0.pipeline_log (
            pipeline_name, start_time, end_time, status, rows_processed
        )
        VALUES (
            't2.usp_merge_dim_department_incremental',
            @StartTime,
            GETDATE(),
            'Success',
            @RowsAffected
        );
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Log error
        INSERT INTO t0.error_log (...)
        VALUES (...);
        
        THROW;
    END CATCH
END;
GO
```

### Optimized Incremental SCD2 with Single MERGE

**More Efficient Pattern:**

```sql
CREATE PROCEDURE t2.usp_merge_dim_department_incremental_optimized
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @LastLoad DATETIME2;
    
    -- Get watermark
    SELECT @LastLoad = ISNULL(last_processed_timestamp, '1900-01-01')
    FROM t0.watermark
    WHERE table_name = 'dim_department';
    
    -- Single MERGE statement for changed records
    MERGE t2.dim_department AS target
    USING (
        SELECT 
            dept_id, dept_name, division_id, division_name,
            cost_center, location
        FROM t1_department
        WHERE ingested_at > @LastLoad
    ) AS source
    ON target.dept_id = source.dept_id AND target.is_current = 1
    WHEN MATCHED AND (
        target.dept_name <> source.dept_name
        OR target.division_id <> source.division_id
        OR target.cost_center <> source.cost_center
        OR target.location <> source.location
    ) THEN
        UPDATE SET 
            expiry_date = GETDATE(),
            is_current = 0,
            updated_at = GETDATE()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (dept_id, dept_name, division_id, division_name,
                cost_center, location, effective_date, is_current)
        VALUES (source.dept_id, source.dept_name, source.division_id,
                source.division_name, source.cost_center, source.location,
                GETDATE(), 1);
    
    -- Insert new versions for expired records
    INSERT INTO t2.dim_department (...)
    SELECT ...
    FROM t1_department s
    INNER JOIN t2.dim_department t ON s.dept_id = t.dept_id
    WHERE t.is_current = 0
    AND t.expiry_date = CAST(GETDATE() AS DATE)
    AND s.ingested_at > @LastLoad
    AND NOT EXISTS (
        SELECT 1 FROM t2.dim_department t2 
        WHERE t2.dept_id = s.dept_id AND t2.is_current = 1
    );
    
    -- Update watermark
    MERGE INTO t0.watermark AS target
    USING (
        SELECT 
            'dim_department' AS table_name,
            MAX(ingested_at) AS last_processed_timestamp
        FROM t1_department
    ) AS source
    ON target.table_name = source.table_name
    WHEN MATCHED THEN UPDATE SET last_processed_timestamp = source.last_processed_timestamp
    WHEN NOT MATCHED THEN INSERT (table_name, last_processed_timestamp)
        VALUES (source.table_name, source.last_processed_timestamp);
END;
GO
```

### Best Practices

- ✅ Use incremental SCD2 for large dimension tables
- ✅ Compare only changed records (use watermark)
- ✅ Expire old versions before inserting new ones
- ✅ Update watermark after successful processing
- ✅ Handle first run (no watermark exists)
- ✅ Index on business key and is_current
- ✅ Log version creation metrics
- ❌ Don't process all records every time
- ❌ Don't skip version tracking
- ❌ Don't update watermark before processing completes

---

## Snapshot Loading

### Overview

Snapshot loading replaces all data with a full copy from the source. This is suitable for small tables, validation phases, or when incremental loading is not feasible.

### When to Use

- Small tables (< 1M rows)
- Initial validation phase
- Source doesn't support incremental queries
- Data changes are infrequent
- Simplicity is preferred over performance

### Implementation: T1 Snapshot Load

**Data Factory Copy Activity:**

```json
{
  "name": "Copy_Snapshot_Data",
  "type": "Copy",
  "typeProperties": {
    "source": {
      "type": "SqlSource",
      "sqlReaderQuery": "SELECT * FROM source.department"
    },
    "sink": {
      "type": "LakehouseSink",
      "writeBehavior": "replace"  // Full replacement
    }
  }
}
```

### Implementation: T2 Snapshot Processing

**Stored Procedure Pattern:**

```sql
CREATE PROCEDURE t2.usp_load_snapshot_daily
    @SnapshotDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SET @SnapshotDate = ISNULL(@SnapshotDate, CAST(GETDATE() AS DATE));
    DECLARE @StartTime DATETIME2 = GETDATE();
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Truncate T1 raw table (full snapshot replacement)
        TRUNCATE TABLE T1_DATA_LAKE.raw_department;
        
        -- Note: Data Factory pipeline loads full snapshot to T1
        -- This procedure processes the snapshot
        
        -- Process full snapshot with SCD2 logic
        MERGE t2.dim_department AS target
        USING t1_department AS source
        ON target.dept_id = source.dept_id AND target.is_current = 1
        WHEN MATCHED AND (
            target.dept_name <> source.dept_name
            OR target.division_id <> source.division_id
        ) THEN
            UPDATE SET 
                expiry_date = @SnapshotDate,
                is_current = 0,
                updated_at = GETDATE()
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (dept_id, dept_name, division_id, division_name,
                    cost_center, location, effective_date, is_current)
            VALUES (source.dept_id, source.dept_name, source.division_id,
                    source.division_name, source.cost_center, source.location,
                    @SnapshotDate, 1);
        
        -- Insert new versions for expired records
        INSERT INTO t2.dim_department (...)
        SELECT ... FROM t1_department s
        INNER JOIN t2.dim_department t ON s.dept_id = t.dept_id
        WHERE t.is_current = 0
        AND t.expiry_date = @SnapshotDate;
        
        COMMIT TRANSACTION;
        
        -- Log success
        INSERT INTO t0.pipeline_log (...)
        VALUES (...);
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Log error
        INSERT INTO t0.error_log (...)
        VALUES (...);
        
        THROW;
    END CATCH
END;
GO
```

### Transition from Snapshot to Incremental

**Migration Strategy:**

```sql
-- Step 1: Add watermark tracking
INSERT INTO t0.watermark (table_name, last_processed_timestamp)
SELECT 'dim_department', MAX(ingested_at)
FROM t1_department;

-- Step 2: Update stored procedure to use incremental logic
-- Replace snapshot MERGE with incremental MERGE (see Incremental SCD2 section)

-- Step 3: Test incremental load
EXEC t2.usp_merge_dim_department_incremental;

-- Step 4: Verify results match snapshot load
-- Compare row counts and data
```

### Best Practices

- ✅ Use snapshot loading for small tables initially
- ✅ Plan transition to incremental after validation
- ✅ Document snapshot schedule
- ✅ Monitor snapshot load times
- ✅ Consider partitioning for large snapshots
- ❌ Don't use snapshot loading for large tables (> 10M rows)
- ❌ Don't skip transition to incremental when appropriate

---

## Late-Arriving Data Handling

### Overview

Late-arriving data refers to records that arrive out of sequence (e.g., a record with timestamp T-2 arrives after records with timestamp T). This requires special handling to maintain data integrity.

### Common Scenarios

1. **Network Delays**: Data arrives late due to network issues
2. **Source System Delays**: Source system processes data out of order
3. **Backfill Operations**: Historical data loaded retroactively
4. **Time Zone Issues**: Records timestamped incorrectly

### Strategy 1: Lookback Window

**Process records within a lookback window:**

```sql
CREATE PROCEDURE t2.usp_load_fact_with_lookback
    @LookbackDays INT = 7  -- Process records up to 7 days old
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CutoffDate DATETIME2 = DATEADD(DAY, -@LookbackDays, GETDATE());
    DECLARE @LastLoad DATETIME2;
    
    -- Get watermark
    SELECT @LastLoad = ISNULL(last_processed_timestamp, '1900-01-01')
    FROM t0.watermark
    WHERE table_name = 'fact_payroll';
    
    -- Process records within lookback window
    INSERT INTO t2.fact_payroll (...)
    SELECT ...
    FROM t1_payroll
    WHERE ingested_at > @LastLoad
    AND ingested_at >= @CutoffDate  -- Lookback window
    AND NOT EXISTS (
        SELECT 1 FROM t2.fact_payroll f 
        WHERE f.payroll_id = t1_payroll.payroll_id
    );
    
    -- Update watermark to latest processed timestamp (not current time)
    MERGE INTO t0.watermark AS target
    USING (
        SELECT 
            'fact_payroll' AS table_name,
            MAX(ingested_at) AS last_processed_timestamp
        FROM t1_payroll
        WHERE ingested_at >= @CutoffDate
    ) AS source
    ON target.table_name = source.table_name
    WHEN MATCHED THEN UPDATE SET last_processed_timestamp = source.last_processed_timestamp
    WHEN NOT MATCHED THEN INSERT (table_name, last_processed_timestamp)
        VALUES (source.table_name, source.last_processed_timestamp);
END;
GO
```

### Strategy 2: Re-processing Window

**Re-process records within a re-processing window:**

```sql
CREATE PROCEDURE t2.usp_load_fact_with_reprocessing
    @ReprocessDays INT = 3  -- Re-process records up to 3 days old
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ReprocessDate DATETIME2 = DATEADD(DAY, -@ReprocessDays, GETDATE());
    DECLARE @LastLoad DATETIME2;
    
    -- Get watermark
    SELECT @LastLoad = ISNULL(last_processed_timestamp, '1900-01-01')
    FROM t0.watermark
    WHERE table_name = 'fact_payroll';
    
    -- Delete records within re-processing window
    DELETE FROM t2.fact_payroll
    WHERE source_ingested_at >= @ReprocessDate
    AND source_ingested_at > @LastLoad;
    
    -- Re-insert records (handles late-arriving data)
    INSERT INTO t2.fact_payroll (...)
    SELECT ...
    FROM t1_payroll
    WHERE ingested_at >= @ReprocessDate
    AND ingested_at > @LastLoad;
    
    -- Update watermark
    MERGE INTO t0.watermark AS target
    USING (
        SELECT 
            'fact_payroll' AS table_name,
            MAX(ingested_at) AS last_processed_timestamp
        FROM t1_payroll
        WHERE ingested_at >= @ReprocessDate
    ) AS source
    ON target.table_name = source.table_name
    WHEN MATCHED THEN UPDATE SET last_processed_timestamp = source.last_processed_timestamp
    WHEN NOT MATCHED THEN INSERT (table_name, last_processed_timestamp)
        VALUES (source.table_name, source.last_processed_timestamp);
END;
GO
```

### Strategy 3: Late-Arriving Data Detection

**Detect and flag late-arriving data:**

```sql
CREATE TABLE t0.late_arriving_data_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    table_name VARCHAR(100),
    record_id VARCHAR(100),
    record_timestamp DATETIME2,
    processed_at DATETIME2,
    delay_hours INT,
    severity VARCHAR(20),  -- Low, Medium, High
    created_at DATETIME2 DEFAULT GETDATE()
);

CREATE PROCEDURE t2.usp_load_fact_with_late_detection
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @LastLoad DATETIME2;
    DECLARE @DelayThresholdHours INT = 24;  -- Flag records > 24 hours late
    
    -- Get watermark
    SELECT @LastLoad = ISNULL(last_processed_timestamp, '1900-01-01')
    FROM t0.watermark
    WHERE table_name = 'fact_payroll';
    
    -- Insert new records
    INSERT INTO t2.fact_payroll (...)
    SELECT ...
    FROM t1_payroll
    WHERE ingested_at > @LastLoad
    AND NOT EXISTS (
        SELECT 1 FROM t2.fact_payroll f 
        WHERE f.payroll_id = t1_payroll.payroll_id
    );
    
    -- Detect late-arriving data
    INSERT INTO t0.late_arriving_data_log (
        table_name, record_id, record_timestamp, processed_at, delay_hours, severity
    )
    SELECT 
        'fact_payroll',
        payroll_id,
        pay_date,  -- Business timestamp
        ingested_at,  -- When it was ingested
        DATEDIFF(HOUR, pay_date, ingested_at) AS delay_hours,
        CASE 
            WHEN DATEDIFF(HOUR, pay_date, ingested_at) > 48 THEN 'High'
            WHEN DATEDIFF(HOUR, pay_date, ingested_at) > 24 THEN 'Medium'
            ELSE 'Low'
        END AS severity
    FROM t1_payroll
    WHERE ingested_at > @LastLoad
    AND DATEDIFF(HOUR, pay_date, ingested_at) > @DelayThresholdHours;
    
    -- Update watermark
    MERGE INTO t0.watermark AS target
    USING (
        SELECT 
            'fact_payroll' AS table_name,
            MAX(ingested_at) AS last_processed_timestamp
        FROM t1_payroll
    ) AS source
    ON target.table_name = source.table_name
    WHEN MATCHED THEN UPDATE SET last_processed_timestamp = source.last_processed_timestamp
    WHEN NOT MATCHED THEN INSERT (table_name, last_processed_timestamp)
        VALUES (source.table_name, source.last_processed_timestamp);
END;
GO
```

### Strategy 4: SCD2 Late-Arriving Dimensions

**Handle late-arriving dimension changes:**

```sql
CREATE PROCEDURE t2.usp_handle_late_arriving_dimension
    @LookbackDays INT = 30  -- Look back 30 days for dimension changes
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @LookbackDate DATETIME2 = DATEADD(DAY, -@LookbackDays, GETDATE());
    
    -- Find fact records with outdated dimension keys
    CREATE TABLE #outdated_facts (
        fact_key INT,
        old_dept_key INT,
        new_dept_key INT,
        effective_date DATETIME2
    );
    
    INSERT INTO #outdated_facts
    SELECT 
        f.payroll_key,
        f.dept_key AS old_dept_key,
        d_new.dept_key AS new_dept_key,
        d_new.effective_date
    FROM t2.fact_payroll f
    INNER JOIN t2.dim_department d_old ON f.dept_key = d_old.dept_key
    INNER JOIN t2.dim_department d_new ON d_old.dept_id = d_new.dept_id
    WHERE d_old.is_current = 0
    AND d_new.is_current = 1
    AND f.pay_date >= @LookbackDate
    AND f.pay_date >= d_new.effective_date;
    
    -- Update fact records with correct dimension keys
    UPDATE f
    SET f.dept_key = o.new_dept_key
    FROM t2.fact_payroll f
    INNER JOIN #outdated_facts o ON f.payroll_key = o.fact_key;
    
    -- Log corrections
    INSERT INTO t0.late_arriving_data_log (
        table_name, record_id, record_timestamp, processed_at, delay_hours, severity
    )
    SELECT 
        'fact_payroll',
        CAST(fact_key AS VARCHAR(100)),
        effective_date,
        GETDATE(),
        DATEDIFF(HOUR, effective_date, GETDATE()),
        'Medium'
    FROM #outdated_facts;
    
    DROP TABLE #outdated_facts;
END;
GO
```

### Best Practices

- ✅ Implement lookback window for late-arriving data
- ✅ Monitor late-arriving data patterns
- ✅ Set appropriate lookback/reprocessing windows
- ✅ Log late-arriving data for analysis
- ✅ Handle late-arriving dimensions in SCD2
- ✅ Alert on excessive delays
- ✅ Consider source system improvements
- ❌ Don't ignore late-arriving data
- ❌ Don't set lookback window too large (performance impact)
- ❌ Don't skip late-arriving dimension handling

---

## Dataflows Gen2 Incremental Refresh

### Overview

Dataflows Gen2 supports incremental refresh for T3 transformations, allowing you to process only new or changed data.

### Implementation Pattern

**Step 1: Configure Incremental Refresh**

1. Open Dataflow Gen2 in Fabric portal
2. Go to **Settings** → **Incremental refresh**
3. Enable incremental refresh
4. Configure:
   - **Incremental column**: Column to use for filtering (typically date/timestamp)
   - **Range start**: Start date for incremental window
   - **Range end**: End date for incremental window

**Step 2: Add Incremental Filter**

```m
// Power Query M code
let
    Source = Warehouse.Database("HR_Analytics_Warehouse", [Schema="t2"]),
    fact_payroll = Source{[Schema="t2", Item="fact_payroll"]}[Data],
    
    // Get last refresh date
    LastRefresh = DateTimeZone.UtcNow(),
    
    // Incremental filter
    IncrementalFilter = Table.SelectRows(
        fact_payroll,
        each [source_ingested_at] > Date.AddDays(LastRefresh, -1)  // Last 24 hours
    ),
    
    // Transformations
    Transformations = Table.TransformColumns(IncrementalFilter, {...})
in
    Transformations
```

**Step 3: Configure Refresh Policy**

- **Incremental refresh policy**: Set in dataflow settings
- **Refresh window**: Configure how far back to refresh
- **Full refresh schedule**: Schedule periodic full refresh

### Best Practices

- ✅ Use incremental refresh for large tables (> 1M rows)
- ✅ Use date/timestamp columns for incremental filtering
- ✅ Schedule periodic full refresh
- ✅ Monitor incremental refresh performance
- ✅ Use additive aggregations (SUM, COUNT) for incremental refresh
- ❌ Don't use incremental refresh for small tables (< 1M rows)
- ❌ Don't use incremental refresh if source doesn't support date filtering
- ❌ Don't skip periodic full refresh

---

## Best Practices Summary

### General Best Practices

1. **Choose the Right Strategy**
   - Use watermark-based for fact tables
   - Use incremental SCD2 for dimension tables
   - Use CDC for high-frequency changes
   - Use snapshot loading for small tables initially

2. **Watermark Management**
   - Store watermarks in T0 control layer
   - Update watermarks only after successful processing
   - Handle NULL watermarks (first run)
   - Use appropriate timestamp precision

3. **Error Handling**
   - Implement comprehensive error handling
   - Log all incremental load operations
   - Handle late-arriving data
   - Monitor load performance

4. **Performance Optimization**
   - Index watermark columns
   - Use batch processing for large datasets
   - Monitor load times
   - Optimize queries

5. **Data Quality**
   - Check for duplicates
   - Validate data before loading
   - Handle NULL values
   - Monitor data quality metrics

### Layer-Specific Best Practices

**T1 (Lakehouse):**
- Use append mode for incremental loads
- Store ingested_at timestamp
- Refresh materialized views after loads

**T2 (Warehouse):**
- Use stored procedures for incremental SCD2
- Update watermarks after successful processing
- Handle late-arriving data
- Log all operations

**T3 (Dataflows Gen2):**
- Use incremental refresh for large tables
- Configure refresh policies
- Use additive aggregations
- Schedule periodic full refresh

---

## Related Topics

- [Data Factory Patterns](data-factory-patterns.md) - T1 ingestion patterns
- [T-SQL Patterns](t-sql-patterns.md) - Stored procedure patterns
- [Warehouse Patterns](warehouse-patterns.md) - Warehouse-specific patterns
- [Dataflows Gen2 Patterns](dataflows-gen2-patterns.md) - T3 transformation patterns
- [Performance Optimization](../optimization/performance-optimization.md) - Performance optimization guide
- [Monitoring & Observability](../operations/monitoring-observability.md) - Monitoring incremental loads

---

Follow these strategies to implement efficient, reliable incremental loading in your Fabric data warehouse.
