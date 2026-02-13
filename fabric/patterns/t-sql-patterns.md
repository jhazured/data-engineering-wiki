# T-SQL Patterns and Best Practices

## Overview

T-SQL is the primary language for stored procedures, error handling, temporary tables, and batch processing in the T0-T5 architecture pattern. This guide covers T-SQL patterns specifically used in the T2 layer (historical record) and T0 layer (control and logging).

**Key T-SQL Usage Areas:**
- Stored procedures for SCD2 MERGE operations
- Comprehensive error handling and logging
- Temporary table strategies for batch processing
- Batch processing for large datasets
- Control layer operations (T0)

---

## Architecture Context

### T-SQL in T0-T5 Pattern

**T0 Layer**: Control and logging (T-SQL)
- Pipeline execution logging
- Watermark management
- Error logging
- Configuration management

**T2 Layer**: Historical record (T-SQL)
- SCD2 MERGE stored procedures
- Error handling
- Temporary tables for batch processing
- Batch processing operations

**T5 Layer**: Presentation views (T-SQL)
- SQL views for presentation layer

**Note**: T3 transformations use **Dataflows Gen2** (Power Query M), not T-SQL.

---

## Pattern 1: Stored Procedures for SCD2

### Standard SCD2 MERGE Pattern

**Complete Pattern with Error Handling:**

```sql
CREATE PROCEDURE t2.usp_merge_dim_department
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @RowsAffected INT = 0;
    DECLARE @ErrorNumber INT;
    DECLARE @ErrorMessage NVARCHAR(4000);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
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
            WHERE s.dept_name <> t.dept_name
               OR s.division_id <> t.division_id
               OR s.cost_center <> t.cost_center
               OR s.location <> t.location
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
        WHERE EXISTS (
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
        WHERE NOT EXISTS (
            SELECT 1 FROM t2.dim_department t WHERE t.dept_id = s.dept_id
        );
        
        SET @RowsAffected = @RowsAffected + @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        -- Log success
        INSERT INTO t0.pipeline_log (
            pipeline_name,
            start_time,
            end_time,
            status,
            rows_processed
        )
        VALUES (
            't2.usp_merge_dim_department',
            @StartTime,
            GETDATE(),
            'Success',
            @RowsAffected
        );
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Capture error details
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorMessage = ERROR_MESSAGE();
        
        -- Log error
        INSERT INTO t0.pipeline_log (
            pipeline_name,
            start_time,
            end_time,
            status,
            error_message
        )
        VALUES (
            't2.usp_merge_dim_department',
            @StartTime,
            GETDATE(),
            'Failed',
            @ErrorMessage
        );
        
        -- Log detailed error
        INSERT INTO t0.error_log (
            component_type,
            component_name,
            error_severity,
            error_message,
            error_details
        )
        VALUES (
            'StoredProcedure',
            't2.usp_merge_dim_department',
            'High',
            @ErrorMessage,
            'Error Number: ' + CAST(@ErrorNumber AS VARCHAR(10)) +
            ', Line: ' + CAST(ERROR_LINE() AS VARCHAR(10))
        );
        
        -- Re-throw error
        THROW;
    END CATCH
END;
GO
```

---

## Pattern 2: Error Handling

### Comprehensive Error Handling Pattern

**Standard Error Handling Template:**

```sql
CREATE PROCEDURE t2.usp_example_with_error_handling
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @ErrorNumber INT;
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    DECLARE @ErrorProcedure NVARCHAR(128);
    DECLARE @ErrorLine INT;
    DECLARE @ErrorMessage NVARCHAR(4000);
    
    BEGIN TRY
        -- Main procedure logic here
        -- ...
        
        -- Log success
        INSERT INTO t0.pipeline_log (
            pipeline_name,
            start_time,
            end_time,
            status,
            rows_processed
        )
        VALUES (
            OBJECT_NAME(@@PROCID),
            @StartTime,
            GETDATE(),
            'Success',
            @@ROWCOUNT
        );
        
    END TRY
    BEGIN CATCH
        -- Capture error details
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorProcedure = ERROR_PROCEDURE();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        
        -- Log to pipeline log
        INSERT INTO t0.pipeline_log (
            pipeline_name,
            start_time,
            end_time,
            status,
            error_message
        )
        VALUES (
            OBJECT_NAME(@@PROCID),
            @StartTime,
            GETDATE(),
            'Failed',
            @ErrorMessage
        );
        
        -- Log to error log
        INSERT INTO t0.error_log (
            component_type,
            component_name,
            error_severity,
            error_message,
            error_details
        )
        VALUES (
            'StoredProcedure',
            OBJECT_NAME(@@PROCID),
            CASE 
                WHEN @ErrorSeverity >= 16 THEN 'Critical'
                WHEN @ErrorSeverity >= 14 THEN 'High'
                ELSE 'Medium'
            END,
            @ErrorMessage,
            'Error Number: ' + CAST(@ErrorNumber AS VARCHAR(10)) +
            ', Severity: ' + CAST(@ErrorSeverity AS VARCHAR(10)) +
            ', State: ' + CAST(@ErrorState AS VARCHAR(10)) +
            ', Line: ' + CAST(@ErrorLine AS VARCHAR(10)) +
            ', Procedure: ' + ISNULL(@ErrorProcedure, 'N/A')
        );
        
        -- Re-throw error for upstream handling
        THROW;
    END CATCH
END;
GO
```

### Error Handling Best Practices

- ✅ Always use TRY-CATCH blocks
- ✅ Capture all error details (number, severity, line, procedure)
- ✅ Log to both pipeline_log and error_log
- ✅ Use appropriate error severity levels
- ✅ Re-throw errors for upstream handling
- ✅ Include execution context (start time, procedure name)
- ✅ Distinguish between transient and permanent errors
- ❌ Don't swallow errors silently
- ❌ Don't skip error logging
- ❌ Don't ignore error details

---

## Pattern 3: Temporary Tables

### Temporary Table Strategies

**Strategy 1: Local Temp Tables (#table)**

```sql
CREATE PROCEDURE t2.usp_use_temp_table
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Create local temp table
    CREATE TABLE #temp_results (
        id INT,
        value DECIMAL(10,2),
        INDEX idx_temp_id (id)  -- Index for performance
    );
    
    -- Populate temp table
    INSERT INTO #temp_results (id, value)
    SELECT id, value
    FROM source_table
    WHERE condition = 1;
    
    -- Use temp table
    SELECT * FROM #temp_results;
    
    -- Explicitly drop (good practice)
    DROP TABLE #temp_results;
END;
GO
```

**Strategy 2: Table Variables (@table)**

```sql
CREATE PROCEDURE t2.usp_use_table_variable
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Table variable (good for small datasets)
    DECLARE @temp_results TABLE (
        id INT,
        value DECIMAL(10,2)
    );
    
    -- Populate table variable
    INSERT INTO @temp_results (id, value)
    SELECT id, value
    FROM source_table
    WHERE condition = 1;
    
    -- Use table variable
    SELECT * FROM @temp_results;
END;
GO
```

**Strategy 3: Physical Staging Tables**

```sql
CREATE PROCEDURE t2.usp_use_staging_table
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Create staging table (if not exists)
    IF OBJECT_ID('t2.staging_payroll', 'U') IS NULL
    BEGIN
        CREATE TABLE t2.staging_payroll (
            payroll_id VARCHAR(10),
            employee_id VARCHAR(10),
            pay_date DATE,
            INDEX idx_staging_payroll_id (payroll_id)
        );
    END
    
    -- Truncate staging table
    TRUNCATE TABLE t2.staging_payroll;
    
    -- Load staging table
    INSERT INTO t2.staging_payroll (...)
    SELECT ... FROM source;
    
    -- Process from staging
    INSERT INTO t2.fact_payroll (...)
    SELECT ... FROM t2.staging_payroll;
    
    -- Clean up staging table
    TRUNCATE TABLE t2.staging_payroll;
END;
GO
```

### Temporary Table Best Practices

- ✅ Use local temp tables (#table) for medium datasets
- ✅ Use table variables (@table) for small datasets (< 100 rows)
- ✅ Use physical staging tables for very large batches
- ✅ Index temp tables if large (> 10K rows)
- ✅ Drop temp tables explicitly (good practice)
- ✅ Document temp table usage and purpose
- ❌ Don't use temp tables for simple operations
- ❌ Don't forget to clean up temp tables
- ❌ Don't use temp tables for cross-procedure operations

---

## Pattern 4: Batch Processing

### Batch Processing with Temp Tables

**Complete Batch Processing Pattern:**

```sql
CREATE PROCEDURE t2.usp_batch_process_large_dataset
    @BatchSize INT = 10000
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RowsProcessed INT = 1;
    DECLARE @TotalRows INT;
    DECLARE @BatchesProcessed INT = 0;
    DECLARE @StartTime DATETIME2 = GETDATE();
    
    BEGIN TRY
        -- Get total rows
        SELECT @TotalRows = COUNT(*) FROM t1_payroll WHERE processed = 0;
        
        -- Process in batches
        WHILE @RowsProcessed > 0
        BEGIN
            BEGIN TRANSACTION;
            
            -- Create temp table for current batch
            CREATE TABLE #current_batch (
                payroll_id VARCHAR(10),
                employee_id VARCHAR(10),
                pay_date DATE,
                gross_pay DECIMAL(12,2),
                INDEX idx_batch_payroll_id (payroll_id)
            );
            
            -- Load batch into temp table
            INSERT INTO #current_batch
            SELECT TOP (@BatchSize) 
                payroll_id, employee_id, pay_date, gross_pay
            FROM t1_payroll
            WHERE processed = 0
            ORDER BY payroll_id;
            
            SET @RowsProcessed = @@ROWCOUNT;
            
            -- Process batch
            INSERT INTO t2.fact_payroll (...)
            SELECT ... FROM #current_batch;
            
            -- Mark as processed
            UPDATE t1_payroll
            SET processed = 1
            WHERE payroll_id IN (SELECT payroll_id FROM #current_batch);
            
            SET @BatchesProcessed = @BatchesProcessed + 1;
            
            COMMIT TRANSACTION;
            
            -- Log progress
            PRINT 'Batch ' + CAST(@BatchesProcessed AS VARCHAR(10)) + 
                  ': Processed ' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows';
            
            -- Clean up temp table
            DROP TABLE #current_batch;
        END
        
        -- Log completion
        INSERT INTO t0.pipeline_log (
            pipeline_name,
            start_time,
            end_time,
            status,
            rows_processed
        )
        VALUES (
            't2.usp_batch_process_large_dataset',
            @StartTime,
            GETDATE(),
            'Success',
            @TotalRows
        );
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Log error
        INSERT INTO t0.error_log (
            component_type,
            component_name,
            error_severity,
            error_message
        )
        VALUES (
            'StoredProcedure',
            't2.usp_batch_process_large_dataset',
            'High',
            ERROR_MESSAGE()
        );
        
        THROW;
    END CATCH
END;
GO
```

### Batch Processing Best Practices

- ✅ Use batch processing for large datasets (> 1M rows)
- ✅ Use appropriate batch size (10K-50K rows typically)
- ✅ Commit after each batch
- ✅ Use temp tables for batch staging
- ✅ Log progress and metrics
- ✅ Handle batch failures gracefully
- ✅ Track batch progress in T0 tables
- ❌ Don't use batches for small datasets
- ❌ Don't skip transaction management
- ❌ Don't use too large batch sizes

---

## Pattern 5: Initial Snapshot Loading

### Daily Snapshot Load Pattern

**Initial Approach: Full Snapshot Daily**

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
        
        -- Process full snapshot (no incremental logic)
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
        INSERT INTO t0.pipeline_log (
            pipeline_name,
            start_time,
            end_time,
            status,
            rows_processed
        )
        VALUES (
            't2.usp_load_snapshot_daily',
            @StartTime,
            GETDATE(),
            'Success',
            @@ROWCOUNT
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

**Transition to Incremental:**

```sql
-- After initial snapshot period, transition to incremental
CREATE PROCEDURE t2.usp_load_incremental
AS
BEGIN
    -- Use watermark-based incremental loading
    -- See Pattern 2: Incremental Fact Table Loading
END;
GO
```

---

## Summary

T-SQL patterns in the T0-T5 architecture focus on:

1. **Stored Procedures**: SCD2 MERGE operations in T2
2. **Error Handling**: Comprehensive error handling and logging
3. **Temporary Tables**: Strategies for batch processing and intermediate results
4. **Batch Processing**: Large dataset processing with temp tables
5. **Initial Snapshots**: Daily full snapshot loading (transition to incremental later)

**Key Principles:**
- Use T-SQL for T2 stored procedures and T0 control operations
- Use Dataflows Gen2 for T3 transformations (not T-SQL)
- Implement comprehensive error handling
- Use appropriate temp table strategies
- Process large datasets in batches

## Related Topics

- [Warehouse Patterns](warehouse-patterns.md) - Warehouse-specific patterns (references T-SQL patterns)
- [Performance Optimization](../optimization/performance-optimization.md) - T-SQL query performance optimization
- [Monitoring & Observability](../operations/monitoring-observability.md) - Error logging and monitoring
- [Troubleshooting Guide](../operations/troubleshooting-guide.md) - T-SQL troubleshooting

---

Follow these patterns to build efficient, reliable T-SQL implementations in Fabric Warehouse.
