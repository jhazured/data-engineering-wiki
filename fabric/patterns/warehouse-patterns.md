# Warehouse Patterns and Best Practices

## Overview

Microsoft Fabric Warehouse provides a SQL analytics engine optimized for data warehousing workloads. This guide covers patterns and best practices for using Warehouse in the T0-T5 architecture pattern, focusing on T2 (SCD2 historical record) and T3/T5 (transformations and presentation).

**Key Characteristics:**
- T-SQL compatibility
- Stored procedures support
- Zero-copy shortcuts to Lakehouse
- Zero-copy clones for snapshots
- High-performance query engine

**T-SQL Usage in T2 Layer:**
- **Stored Procedures**: All SCD2 MERGE operations
- **Error Handling**: Comprehensive error handling and logging
- **Temp Tables**: Temporary tables for batch processing and intermediate results
- **Batch Processing**: Batch operations for large datasets

---

## Architecture Context

### Role in T0-T5 Pattern

**T0**: Control layer tables and logging (T-SQL)
**T2**: Historical record with SCD2 via T-SQL stored procedures
**T3**: Transformation tables (populated by Dataflows Gen2)
**T3._FINAL**: Zero-copy clones for semantic layer
**T5**: Presentation views (T-SQL)

**T-SQL Primary Use**: T2 layer for stored procedures, error handling, temp tables, and batch processing

---

## Pattern 1: SCD2 MERGE Operations (T2)

### When to Use

- Dimension tables requiring historical tracking
- Track changes over time
- Point-in-time queries
- Audit requirements

### Implementation Pattern

**Standard SCD2 MERGE:**

```sql
CREATE PROCEDURE t2.usp_merge_dim_department
AS
BEGIN
    SET NOCOUNT ON;
    
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
END;
GO
```

### Optimized SCD2 MERGE with Single Pass

**More Efficient Pattern:**

```sql
CREATE PROCEDURE t2.usp_merge_dim_department_optimized
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Use MERGE statement for single-pass operation
    MERGE t2.dim_department AS target
    USING (
        SELECT 
            dept_id,
            dept_name,
            division_id,
            division_name,
            cost_center,
            location
        FROM t1_department
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
    INNER JOIN t2.dim_department t ON s.dept_id = t.dept_id
    WHERE t.is_current = 0
    AND t.expiry_date = CAST(GETDATE() AS DATE)
    AND NOT EXISTS (
        SELECT 1 FROM t2.dim_department t2 
        WHERE t2.dept_id = s.dept_id AND t2.is_current = 1
    );
END;
GO
```

### Best Practices

- ✅ Use MERGE for SCD2 operations
- ✅ Expire old records before inserting new versions
- ✅ Always set is_current flag correctly
- ✅ Include effective_date and expiry_date
- ✅ Use transactions for atomicity
- ✅ Index on business key and is_current
- ❌ Don't delete records (expire instead)
- ❌ Don't skip version tracking

---

## Pattern 2: Incremental Fact Table Loading

**See [Incremental Loading Strategies](incremental-loading-strategies.md#watermark-based-incremental-loading) for comprehensive incremental loading patterns, including watermark-based loading, CDC, late-arriving data handling, and comparison matrix.**

**Quick Reference:**

Incremental fact table loading uses watermark-based patterns to process only new records since the last load.

**Key Pattern:**
1. Get watermark (last processed timestamp)
2. Filter source data WHERE timestamp > watermark
3. Insert new records
4. Update surrogate keys
5. Update watermark after successful processing

**Best Practices:**
- ✅ Use watermarks for incremental loads
- ✅ Check for duplicates before insert
- ✅ Update surrogate keys after insert
- ✅ Index on watermark column
- ✅ Log incremental load metrics

---

## Pattern 3: Zero-Copy Clones (T3._FINAL)

### When to Use

- Create point-in-time snapshots
- Isolate semantic layer from T3 failures
- Efficient storage (copy-on-write)

### Implementation Pattern

**Create Clone Refresh Procedure:**

```sql
CREATE PROCEDURE t3.usp_refresh_final_clones
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Drop T5 views first (to avoid dependencies)
    IF OBJECT_ID('t5.vw_employee', 'V') IS NOT NULL
        DROP VIEW t5.vw_employee;
    
    IF OBJECT_ID('t5.vw_department', 'V') IS NOT NULL
        DROP VIEW t5.vw_department;
    
    -- Drop existing _FINAL clones
    IF OBJECT_ID('t3.dim_employee_FINAL', 'U') IS NOT NULL
        DROP TABLE t3.dim_employee_FINAL;
    
    IF OBJECT_ID('t3.dim_department_FINAL', 'U') IS NOT NULL
        DROP TABLE t3.dim_department_FINAL;
    
    IF OBJECT_ID('t3.fact_payroll_FINAL', 'U') IS NOT NULL
        DROP TABLE t3.fact_payroll_FINAL;
    
    -- Create new clones (zero-copy)
    CREATE TABLE t3.dim_employee_FINAL AS CLONE OF t3.dim_employee;
    CREATE TABLE t3.dim_department_FINAL AS CLONE OF t3.dim_department;
    CREATE TABLE t3.fact_payroll_FINAL AS CLONE OF t3.fact_payroll;
    
    -- Recreate T5 views (done via CI/CD deployment)
END;
GO
```

### Best Practices

- ✅ Drop views before dropping clones
- ✅ Drop clones before recreating
- ✅ Create clones in correct order
- ✅ Use _FINAL suffix consistently
- ✅ Execute after successful T3 completion
- ❌ Don't refresh clones during T3 execution
- ❌ Don't skip view recreation

---

## Pattern 4: Indexing Strategies

### When to Use

- Frequently queried columns
- Join columns
- Filter columns
- Sort columns

### Implementation Pattern

**Primary Key Index:**

```sql
CREATE TABLE t2.dim_department (
    dept_key INT IDENTITY(1,1) PRIMARY KEY,
    dept_id VARCHAR(10) NOT NULL,
    ...
);
```

**Non-Clustered Indexes:**

```sql
-- Index on business key
CREATE INDEX idx_t2_dept_id ON t2.dim_department(dept_id);

-- Index on current flag for filtering
CREATE INDEX idx_t2_dept_current ON t2.dim_department(is_current);

-- Composite index for common queries
CREATE INDEX idx_t2_dept_id_current ON t2.dim_department(dept_id, is_current);
```

**Index on Foreign Keys:**

```sql
-- Index on foreign key for joins
CREATE INDEX idx_t2_payroll_emp ON t2.fact_payroll(emp_key);
CREATE INDEX idx_t2_payroll_dept ON t2.fact_payroll(dept_key);
CREATE INDEX idx_t2_payroll_date ON t2.fact_payroll(pay_date_key);
```

### Best Practices

- ✅ Index primary keys
- ✅ Index foreign keys
- ✅ Index frequently filtered columns
- ✅ Use composite indexes for common query patterns
- ✅ Monitor index usage
- ✅ Balance index count (too many slows writes)
- ❌ Don't over-index (monitor usage)
- ❌ Don't index low-cardinality columns

---

## Pattern 5: Transaction Management

### When to Use

- Atomic operations
- Rollback on errors
- Data consistency

### Implementation Pattern

**Explicit Transaction:**

```sql
CREATE PROCEDURE t2.usp_merge_dim_department_transaction
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Expire old records
        UPDATE t2.dim_department
        SET expiry_date = GETDATE(), is_current = 0
        WHERE ...
        
        -- Insert new versions
        INSERT INTO t2.dim_department (...)
        SELECT ... FROM t1_department ...
        
        -- Commit transaction
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback on error
        ROLLBACK TRANSACTION;
        
        -- Log error
        INSERT INTO t0.pipeline_log (
            pipeline_name, start_time, end_time, status, error_message
        )
        VALUES (
            'PL_T2_Process_SCD2',
            GETDATE(),
            GETDATE(),
            'Failed',
            ERROR_MESSAGE()
        );
        
        -- Re-throw error
        THROW;
    END CATCH
END;
GO
```

### Best Practices

- ✅ Use transactions for atomic operations
- ✅ Handle errors with TRY-CATCH
- ✅ Rollback on errors
- ✅ Log errors to T0
- ✅ Keep transactions short
- ❌ Don't hold transactions too long
- ❌ Don't skip error handling

---

## Pattern 6: Error Handling in Stored Procedures

**See [T-SQL Patterns - Error Handling](t-sql-patterns.md#pattern-2-error-handling) for comprehensive error handling patterns.**

**Quick Reference:**
- Always use TRY-CATCH blocks
- Capture all error details (number, severity, line, procedure)
- Log to both t0.pipeline_log and t0.error_log
- Re-throw errors for upstream handling
- Include execution context (start time, procedure name)

**Key Pattern:**
```sql
BEGIN TRY
    -- Main logic
END TRY
BEGIN CATCH
    -- Capture error details
    -- Log to T0
    -- Re-throw error
END CATCH
```

---

## Pattern 7: Dynamic SQL Patterns

### When to Use

- Parameterized table names
- Dynamic column selection
- Flexible queries

### Implementation Pattern

**Dynamic Table Name:**

```sql
CREATE PROCEDURE t2.usp_refresh_table
    @TableName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    
    -- Validate table name (prevent SQL injection)
    IF @TableName NOT IN ('dim_department', 'dim_employee', 'fact_payroll')
    BEGIN
        RAISERROR('Invalid table name', 16, 1);
        RETURN;
    END
    
    -- Build dynamic SQL
    SET @SQL = N'
        TRUNCATE TABLE t2.' + QUOTENAME(@TableName) + ';
        
        INSERT INTO t2.' + QUOTENAME(@TableName) + ' (...)
        SELECT ... FROM t1_' + @TableName + ' ...';
    
    -- Execute dynamic SQL
    EXEC sp_executesql @SQL;
END;
GO
```

### Best Practices

- ✅ Validate input parameters
- ✅ Use QUOTENAME for identifiers
- ✅ Use parameterized queries when possible
- ✅ Document dynamic SQL usage
- ✅ Test thoroughly
- ❌ Don't use dynamic SQL unnecessarily
- ❌ Don't skip input validation (SQL injection risk)

---

## Pattern 8: Temporary Tables

**See [T-SQL Patterns - Temporary Tables](t-sql-patterns.md#pattern-3-temporary-tables) for comprehensive temporary table strategies.**

**Quick Reference:**
- Use local temp tables (#table) for single procedure operations
- Use table variables (@table) for small datasets (< 100 rows)
- Use physical staging tables for very large batches
- Index temp tables if large (> 10K rows)
- Always drop temp tables explicitly

**Common Use Cases:**
- Intermediate calculations in stored procedures
- Staging data for batch processing
- Data validation and quality checks
- Performance optimization (reduce table scans)

---

## Pattern 9: Batch Processing

### When to Use

- Large datasets (> 1M rows)
- Memory constraints
- Performance optimization
- Transaction log management
- Error recovery scenarios

### Implementation Pattern

**Batch Processing with Temp Tables:**

```sql
CREATE PROCEDURE t2.usp_batch_process
    @BatchSize INT = 10000,
    @SourceTable VARCHAR(200) = 't1_payroll'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RowsProcessed INT = 1;
    DECLARE @TotalRows INT;
    DECLARE @BatchesProcessed INT = 0;
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @SQL NVARCHAR(MAX);
    
    -- Create temporary table for batch tracking
    CREATE TABLE #batch_tracking (
        batch_id INT IDENTITY(1,1),
        rows_processed INT,
        batch_start_time DATETIME2,
        batch_end_time DATETIME2
    );
    
    -- Get total rows to process
    SET @SQL = N'SELECT @TotalRows = COUNT(*) FROM ' + QUOTENAME(@SourceTable) + ' WHERE processed = 0';
    EXEC sp_executesql @SQL, N'@TotalRows INT OUTPUT', @TotalRows = @TotalRows OUTPUT;
    
    -- Process in batches
    WHILE @RowsProcessed > 0
    BEGIN
        DECLARE @BatchStartTime DATETIME2 = GETDATE();
        
        BEGIN TRY
            BEGIN TRANSACTION;
            
            -- Process batch using temp table
            CREATE TABLE #current_batch (
                payroll_id VARCHAR(10),
                employee_id VARCHAR(10),
                pay_date DATE,
                gross_pay DECIMAL(12,2)
            );
            
            -- Load batch into temp table
            SET @SQL = N'
                INSERT INTO #current_batch
                SELECT TOP (@BatchSize) payroll_id, employee_id, pay_date, gross_pay
                FROM ' + QUOTENAME(@SourceTable) + '
                WHERE processed = 0
                ORDER BY payroll_id';
            
            EXEC sp_executesql @SQL, N'@BatchSize INT', @BatchSize = @BatchSize;
            
            SET @RowsProcessed = @@ROWCOUNT;
            
            -- Process batch
            INSERT INTO t2.fact_payroll (...)
            SELECT ... FROM #current_batch;
            
            -- Mark source records as processed
            SET @SQL = N'
                UPDATE ' + QUOTENAME(@SourceTable) + '
                SET processed = 1
                WHERE payroll_id IN (SELECT payroll_id FROM #current_batch)';
            
            EXEC sp_executesql @SQL;
            
            -- Track batch progress
            INSERT INTO #batch_tracking (rows_processed, batch_start_time, batch_end_time)
            VALUES (@RowsProcessed, @BatchStartTime, GETDATE());
            
            SET @BatchesProcessed = @BatchesProcessed + 1;
            
            COMMIT TRANSACTION;
            
            -- Log progress
            PRINT 'Batch ' + CAST(@BatchesProcessed AS VARCHAR(10)) + 
                  ': Processed ' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows';
            
            -- Clean up temp table
            DROP TABLE #current_batch;
            
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            
            -- Log batch failure
            INSERT INTO t0.error_log (
                component_type,
                component_name,
                error_severity,
                error_message,
                error_details
            )
            VALUES (
                'StoredProcedure',
                't2.usp_batch_process',
                'High',
                ERROR_MESSAGE(),
                'Batch ' + CAST(@BatchesProcessed + 1 AS VARCHAR(10)) + ' failed'
            );
            
            -- Re-throw error
            THROW;
        END CATCH
    END
    
    -- Log completion
    INSERT INTO t0.pipeline_log (
        pipeline_name,
        start_time,
        end_time,
        duration_seconds,
        status,
        rows_processed
    )
    VALUES (
        't2.usp_batch_process',
        @StartTime,
        GETDATE(),
        DATEDIFF(SECOND, @StartTime, GETDATE()),
        'Success',
        @TotalRows
    );
    
    -- Clean up
    DROP TABLE #batch_tracking;
END;
GO
```

**Batch Processing with Watermark:**

```sql
CREATE PROCEDURE t2.usp_batch_process_with_watermark
    @BatchSize INT = 10000
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @LastProcessedID INT;
    DECLARE @RowsProcessed INT = 1;
    
    -- Get watermark
    SELECT @LastProcessedID = ISNULL(MAX(payroll_key), 0)
    FROM t2.fact_payroll;
    
    -- Process in batches
    WHILE @RowsProcessed > 0
    BEGIN
        BEGIN TRANSACTION;
        
        -- Process batch
        INSERT INTO t2.fact_payroll (...)
        SELECT TOP (@BatchSize) ...
        FROM t1_payroll
        WHERE id > @LastProcessedID
        ORDER BY id;
        
        SET @RowsProcessed = @@ROWCOUNT;
        
        -- Update watermark
        SELECT @LastProcessedID = MAX(payroll_key)
        FROM t2.fact_payroll;
        
        COMMIT TRANSACTION;
        
        -- Log progress
        PRINT 'Processed batch: ' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows, Last ID: ' + CAST(@LastProcessedID AS VARCHAR(10));
    END
END;
GO
```

### Batch Processing Strategies

**Strategy 1: Fixed Batch Size**
- Process fixed number of rows per batch
- Good for: Consistent processing times
- Example: 10,000 rows per batch

**Strategy 2: Time-Based Batching**
- Process batches within time window
- Good for: Real-time processing
- Example: Process all rows from last 5 minutes

**Strategy 3: Watermark-Based Batching**
- Process batches using watermark column
- Good for: Incremental processing
- Example: Process rows where ID > last processed ID

**Strategy 4: Parallel Batching**
- Process multiple batches in parallel
- Good for: Very large datasets
- Requires: Careful transaction management

### Best Practices

- ✅ Use batch processing for large datasets (> 1M rows)
- ✅ Use appropriate batch size (balance between performance and transaction log)
- ✅ Commit after each batch (prevents long transactions)
- ✅ Log progress and metrics
- ✅ Handle batch failures gracefully
- ✅ Use temp tables for batch data staging
- ✅ Track batch progress in T0 tables
- ✅ Consider watermark-based batching for incremental loads
- ✅ Monitor batch performance and adjust batch size
- ❌ Don't use batches for small datasets (< 100K rows)
- ❌ Don't skip transaction management
- ❌ Don't process batches without error handling
- ❌ Don't use too large batch sizes (causes lock contention)

---

## Pattern 10: Performance Optimization

**See [Performance Optimization](../optimization/performance-optimization.md) for comprehensive performance optimization guide.**

**Quick Reference for Warehouse:**
- Use EXISTS instead of COUNT(*)
- Use appropriate JOIN types
- Filter early in queries
- Use indexed columns in WHERE clauses
- Avoid functions on indexed columns
- Monitor query performance with Query Store

**Warehouse-Specific:**
- Optimize SCD2 MERGE operations (see Pattern 1)
- Use appropriate indexes (see Pattern 4)
- Consider partitioning for large tables (see Pattern 2)
- Use batch processing for large datasets (see Pattern 9)

---

## Related Topics

- [Incremental Loading Strategies](incremental-loading-strategies.md) - Comprehensive incremental loading guide (watermarks, CDC, incremental SCD2, late-arriving data)
- [T-SQL Patterns](t-sql-patterns.md) - Comprehensive T-SQL patterns (error handling, temp tables, batch processing)
- [Performance Optimization](../optimization/performance-optimization.md) - Comprehensive performance optimization guide
- [Dataflows Gen2 Patterns](dataflows-gen2-patterns.md) - T3 transformation patterns
- [Data Factory Patterns](data-factory-patterns.md) - T1 ingestion patterns
- [T0-T5 Architecture Pattern](../architecture/architecture-pattern.md) - Detailed implementation guide

---

## Summary

Warehouse patterns in the T0-T5 architecture focus on:

1. **SCD2 MERGE**: Historical tracking with versioning
2. **Incremental Loading**: Watermark-based fact table loads
3. **Zero-Copy Clones**: Efficient snapshot creation
4. **Indexing**: Performance optimization strategies
5. **Transactions**: Atomic operations and consistency
6. **Error Handling**: Comprehensive error management (see [T-SQL Patterns](t-sql-patterns.md))
7. **Performance**: Query optimization techniques (see [Performance Optimization](../optimization/performance-optimization.md))
8. **Temporary Tables**: Strategies for batch processing (see [T-SQL Patterns](t-sql-patterns.md))
9. **Batch Processing**: Large dataset processing (see [T-SQL Patterns](t-sql-patterns.md))

Follow these patterns to build efficient, reliable Warehouse implementations in Fabric.
