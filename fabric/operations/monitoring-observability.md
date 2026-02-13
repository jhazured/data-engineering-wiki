# Monitoring and Observability Patterns

## Overview

Monitoring and observability in Microsoft Fabric data warehouses involves tracking pipeline execution, data quality, performance metrics, and system health across all layers of the T0-T5 architecture. This guide covers monitoring patterns and best practices.

**Key Monitoring Areas:**
- Pipeline execution monitoring
- Data quality monitoring
- Performance monitoring
- Error tracking and alerting
- Dashboard creation
- Log aggregation

---

## Architecture Context

### Monitoring Across Layers

**T0**: Control layer logging and metrics
**T1**: Ingestion monitoring, data quality
**T2**: SCD2 processing metrics, data quality
**T3**: Transformation monitoring, performance
**T5**: View performance, access monitoring
**Semantic Layer**: Query performance, cache metrics

---

## Pattern 1: Pipeline Execution Logging

### T0 Pipeline Log Table

**Log Table Structure:**

```sql
CREATE TABLE t0.pipeline_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    pipeline_name VARCHAR(200) NOT NULL,
    execution_id VARCHAR(100),
    start_time DATETIME2 NOT NULL,
    end_time DATETIME2,
    duration_seconds INT,
    status VARCHAR(20) NOT NULL,  -- Running, Success, Failed, Cancelled
    rows_processed INT,
    data_size_mb DECIMAL(10,2),
    error_message VARCHAR(MAX),
    created_at DATETIME2 DEFAULT GETDATE()
);

CREATE INDEX idx_pipeline_log_name_time ON t0.pipeline_log(pipeline_name, start_time);
CREATE INDEX idx_pipeline_log_status ON t0.pipeline_log(status, start_time);
```

### Log Pipeline Start

**Script Activity in Pipeline:**

```sql
INSERT INTO t0.pipeline_log (
    pipeline_name,
    execution_id,
    start_time,
    status
)
VALUES (
    '@{pipeline().Pipeline}',
    '@{pipeline().RunId}',
    '@{pipeline().TriggerTime}',
    'Running'
);
```

### Log Pipeline Completion

**Script Activity:**

```sql
UPDATE t0.pipeline_log
SET 
    end_time = GETDATE(),
    duration_seconds = DATEDIFF(SECOND, start_time, GETDATE()),
    status = 'Success',
    rows_processed = @{activity('CopyActivity').output.rowsCopied},
    data_size_mb = @{activity('CopyActivity').output.dataRead} / 1024.0 / 1024.0
WHERE pipeline_name = '@{pipeline().Pipeline}'
AND execution_id = '@{pipeline().RunId}'
AND status = 'Running';
```

### Log Pipeline Failure

**On Failure Activity:**

```sql
UPDATE t0.pipeline_log
SET 
    end_time = GETDATE(),
    duration_seconds = DATEDIFF(SECOND, start_time, GETDATE()),
    status = 'Failed',
    error_message = '@{activity('ErrorActivity').error.message}'
WHERE pipeline_name = '@{pipeline().Pipeline}'
AND execution_id = '@{pipeline().RunId}'
AND status = 'Running';
```

### Best Practices

- ✅ Log all pipeline executions
- ✅ Include execution ID for tracking
- ✅ Log start and end times
- ✅ Log rows processed and data size
- ✅ Log error messages for failures
- ✅ Index log table for performance
- ❌ Don't skip logging
- ❌ Don't log sensitive data

---

## Pattern 2: Data Quality Monitoring

### Data Quality Metrics Table

**Metrics Table:**

```sql
CREATE TABLE t0.data_quality_metrics (
    metric_id INT IDENTITY(1,1) PRIMARY KEY,
    table_name VARCHAR(200) NOT NULL,
    metric_date DATE NOT NULL,
    metric_type VARCHAR(50),  -- RowCount, NullCount, DuplicateCount, etc.
    metric_value DECIMAL(18,2),
    threshold_value DECIMAL(18,2),
    status VARCHAR(20),  -- Pass, Warning, Fail
    details VARCHAR(MAX),
    created_at DATETIME2 DEFAULT GETDATE()
);

CREATE INDEX idx_dq_metrics_table_date ON t0.data_quality_metrics(table_name, metric_date);
```

### Data Quality Checks

**Row Count Check:**

```sql
CREATE PROCEDURE t0.usp_check_row_count
    @TableName VARCHAR(200),
    @ExpectedMinRows INT = 0
AS
BEGIN
    DECLARE @ActualRows INT;
    DECLARE @SQL NVARCHAR(MAX);
    
    SET @SQL = N'SELECT @Rows = COUNT(*) FROM ' + QUOTENAME(@TableName);
    EXEC sp_executesql @SQL, N'@Rows INT OUTPUT', @Rows = @ActualRows OUTPUT;
    
    INSERT INTO t0.data_quality_metrics (
        table_name,
        metric_date,
        metric_type,
        metric_value,
        threshold_value,
        status
    )
    VALUES (
        @TableName,
        CAST(GETDATE() AS DATE),
        'RowCount',
        @ActualRows,
        @ExpectedMinRows,
        CASE 
            WHEN @ActualRows >= @ExpectedMinRows THEN 'Pass'
            ELSE 'Fail'
        END
    );
END;
GO
```

**Null Check:**

```sql
CREATE PROCEDURE t0.usp_check_nulls
    @TableName VARCHAR(200),
    @ColumnName VARCHAR(200),
    @MaxNullPercent DECIMAL(5,2) = 10.0
AS
BEGIN
    DECLARE @NullCount INT;
    DECLARE @TotalCount INT;
    DECLARE @NullPercent DECIMAL(5,2);
    DECLARE @SQL NVARCHAR(MAX);
    
    SET @SQL = N'
        SELECT 
            @NullCount = SUM(CASE WHEN ' + QUOTENAME(@ColumnName) + ' IS NULL THEN 1 ELSE 0 END),
            @TotalCount = COUNT(*)
        FROM ' + QUOTENAME(@TableName);
    
    EXEC sp_executesql @SQL, 
        N'@NullCount INT OUTPUT, @TotalCount INT OUTPUT',
        @NullCount = @NullCount OUTPUT,
        @TotalCount = @TotalCount OUTPUT;
    
    SET @NullPercent = (@NullCount * 100.0 / NULLIF(@TotalCount, 0));
    
    INSERT INTO t0.data_quality_metrics (
        table_name,
        metric_date,
        metric_type,
        metric_value,
        threshold_value,
        status,
        details
    )
    VALUES (
        @TableName,
        CAST(GETDATE() AS DATE),
        'NullPercent',
        @NullPercent,
        @MaxNullPercent,
        CASE 
            WHEN @NullPercent <= @MaxNullPercent THEN 'Pass'
            WHEN @NullPercent <= @MaxNullPercent * 1.5 THEN 'Warning'
            ELSE 'Fail'
        END,
        'Column: ' + @ColumnName + ', Null Count: ' + CAST(@NullCount AS VARCHAR(10))
    );
END;
GO
```

### Best Practices

- ✅ Monitor data quality metrics
- ✅ Set appropriate thresholds
- ✅ Alert on data quality failures
- ✅ Track data quality trends
- ✅ Document data quality rules
- ❌ Don't ignore data quality issues
- ❌ Don't set thresholds too strict

---

## Pattern 3: Performance Monitoring

### Performance Metrics Table

**Metrics Table:**

```sql
CREATE TABLE t0.performance_metrics (
    metric_id INT IDENTITY(1,1) PRIMARY KEY,
    component_type VARCHAR(50),  -- Pipeline, Dataflow, StoredProcedure, Query
    component_name VARCHAR(200),
    execution_date DATETIME2,
    duration_seconds DECIMAL(10,2),
    rows_processed INT,
    data_size_mb DECIMAL(10,2),
    cpu_time_ms INT,
    memory_mb DECIMAL(10,2),
    created_at DATETIME2 DEFAULT GETDATE()
);

CREATE INDEX idx_perf_metrics_component_date ON t0.performance_metrics(component_name, execution_date);
```

### Monitor Stored Procedure Performance

**Add Performance Logging:**

```sql
CREATE PROCEDURE t2.usp_merge_dim_department_with_perf
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @EndTime DATETIME2;
    DECLARE @RowsProcessed INT;
    
    -- Main logic
    MERGE t2.dim_department AS target
    USING (SELECT * FROM t1_department) AS source
    ON target.dept_id = source.dept_id AND target.is_current = 1
    WHEN MATCHED THEN UPDATE SET ...
    WHEN NOT MATCHED THEN INSERT ...;
    
    SET @RowsProcessed = @@ROWCOUNT;
    SET @EndTime = GETDATE();
    
    -- Log performance
    INSERT INTO t0.performance_metrics (
        component_type,
        component_name,
        execution_date,
        duration_seconds,
        rows_processed
    )
    VALUES (
        'StoredProcedure',
        't2.usp_merge_dim_department',
        @StartTime,
        DATEDIFF(MILLISECOND, @StartTime, @EndTime) / 1000.0,
        @RowsProcessed
    );
END;
GO
```

### Best Practices

- ✅ Monitor performance metrics
- ✅ Track execution times
- ✅ Monitor resource usage
- ✅ Identify performance trends
- ✅ Alert on performance degradation
- ❌ Don't ignore performance issues
- ❌ Don't skip performance monitoring

---

## Pattern 4: Error Tracking and Alerting

### Error Log Table

**Error Table:**

```sql
CREATE TABLE t0.error_log (
    error_id INT IDENTITY(1,1) PRIMARY KEY,
    error_timestamp DATETIME2 DEFAULT GETDATE(),
    component_type VARCHAR(50),
    component_name VARCHAR(200),
    error_severity VARCHAR(20),  -- Critical, High, Medium, Low
    error_message VARCHAR(MAX),
    error_details VARCHAR(MAX),
    stack_trace VARCHAR(MAX),
    resolved BIT DEFAULT 0,
    resolved_at DATETIME2,
    resolved_by VARCHAR(100)
);

CREATE INDEX idx_error_log_timestamp ON t0.error_log(error_timestamp);
CREATE INDEX idx_error_log_resolved ON t0.error_log(resolved, error_severity);
```

### Error Logging Pattern

**Log Errors:**

```sql
CREATE PROCEDURE t0.usp_log_error
    @ComponentType VARCHAR(50),
    @ComponentName VARCHAR(200),
    @ErrorSeverity VARCHAR(20),
    @ErrorMessage VARCHAR(MAX),
    @ErrorDetails VARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO t0.error_log (
        component_type,
        component_name,
        error_severity,
        error_message,
        error_details
    )
    VALUES (
        @ComponentType,
        @ComponentName,
        @ErrorSeverity,
        @ErrorMessage,
        @ErrorDetails
    );
    
    -- Send alert for critical errors
    IF @ErrorSeverity IN ('Critical', 'High')
    BEGIN
        -- Trigger alert (e.g., send email, webhook)
        EXEC t0.usp_send_alert 
            @AlertType = 'Error',
            @ComponentName = @ComponentName,
            @Message = @ErrorMessage;
    END
END;
GO
```

### Alert Configuration

**Alert Table:**

```sql
CREATE TABLE t0.alert_config (
    alert_id INT IDENTITY(1,1) PRIMARY KEY,
    alert_name VARCHAR(200),
    alert_type VARCHAR(50),  -- Error, Performance, DataQuality
    threshold_value DECIMAL(18,2),
    alert_recipients VARCHAR(MAX),
    enabled BIT DEFAULT 1
);
```

### Best Practices

- ✅ Log all errors
- ✅ Categorize error severity
- ✅ Send alerts for critical errors
- ✅ Track error resolution
- ✅ Monitor error trends
- ❌ Don't ignore errors
- ❌ Don't skip error alerting

---

## Pattern 5: Dashboard Creation

### Pipeline Execution Dashboard

**Key Metrics:**

```sql
-- Pipeline execution summary
SELECT 
    pipeline_name,
    COUNT(*) AS execution_count,
    SUM(CASE WHEN status = 'Success' THEN 1 ELSE 0 END) AS success_count,
    SUM(CASE WHEN status = 'Failed' THEN 1 ELSE 0 END) AS failure_count,
    AVG(duration_seconds) AS avg_duration_seconds,
    SUM(rows_processed) AS total_rows_processed
FROM t0.pipeline_log
WHERE start_time >= DATEADD(DAY, -7, GETDATE())
GROUP BY pipeline_name;
```

**Recent Executions:**

```sql
SELECT TOP 20
    pipeline_name,
    start_time,
    end_time,
    duration_seconds,
    status,
    rows_processed,
    error_message
FROM t0.pipeline_log
ORDER BY start_time DESC;
```

### Data Quality Dashboard

**Data Quality Summary:**

```sql
SELECT 
    table_name,
    metric_date,
    SUM(CASE WHEN status = 'Pass' THEN 1 ELSE 0 END) AS pass_count,
    SUM(CASE WHEN status = 'Warning' THEN 1 ELSE 0 END) AS warning_count,
    SUM(CASE WHEN status = 'Fail' THEN 1 ELSE 0 END) AS fail_count
FROM t0.data_quality_metrics
WHERE metric_date >= DATEADD(DAY, -7, GETDATE())
GROUP BY table_name, metric_date
ORDER BY table_name, metric_date DESC;
```

### Performance Dashboard

**Performance Trends:**

```sql
SELECT 
    component_name,
    CAST(execution_date AS DATE) AS execution_date,
    AVG(duration_seconds) AS avg_duration,
    MAX(duration_seconds) AS max_duration,
    MIN(duration_seconds) AS min_duration,
    COUNT(*) AS execution_count
FROM t0.performance_metrics
WHERE execution_date >= DATEADD(DAY, -30, GETDATE())
GROUP BY component_name, CAST(execution_date AS DATE)
ORDER BY component_name, execution_date DESC;
```

### Best Practices

- ✅ Create dashboards for key metrics
- ✅ Update dashboards regularly
- ✅ Use visualizations for trends
- ✅ Include drill-down capabilities
- ✅ Share dashboards with stakeholders
- ❌ Don't create too many dashboards
- ❌ Don't skip dashboard updates

---

## Pattern 6: Log Aggregation

### Centralized Logging

**Aggregate Logs:**

```sql
-- Unified log view
SELECT 
    'Pipeline' AS log_type,
    pipeline_name AS component_name,
    start_time AS log_timestamp,
    status,
    error_message AS message
FROM t0.pipeline_log
WHERE start_time >= DATEADD(DAY, -1, GETDATE())

UNION ALL

SELECT 
    'Error' AS log_type,
    component_name,
    error_timestamp AS log_timestamp,
    error_severity AS status,
    error_message AS message
FROM t0.error_log
WHERE error_timestamp >= DATEADD(DAY, -1, GETDATE())

ORDER BY log_timestamp DESC;
```

### Best Practices

- ✅ Aggregate logs from all sources
- ✅ Use consistent log formats
- ✅ Include timestamps in all logs
- ✅ Store logs in T0 for querying
- ✅ Archive old logs periodically
- ❌ Don't store logs in multiple places
- ❌ Don't skip log aggregation

---

## Pattern 7: Alerting Strategies

### Alert Types

**Pipeline Failure Alerts:**

```sql
-- Check for recent failures
IF EXISTS (
    SELECT 1 FROM t0.pipeline_log
    WHERE status = 'Failed'
    AND start_time >= DATEADD(HOUR, -1, GETDATE())
)
BEGIN
    -- Send alert
    EXEC t0.usp_send_alert 
        @AlertType = 'PipelineFailure',
        @Message = 'Pipeline failures detected in last hour';
END
```

**Performance Degradation Alerts:**

```sql
-- Check for performance degradation
IF EXISTS (
    SELECT 1 FROM t0.performance_metrics p1
    INNER JOIN (
        SELECT component_name, AVG(duration_seconds) AS avg_duration
        FROM t0.performance_metrics
        WHERE execution_date >= DATEADD(DAY, -7, GETDATE())
        GROUP BY component_name
    ) p2 ON p1.component_name = p2.component_name
    WHERE p1.duration_seconds > p2.avg_duration * 2
    AND p1.execution_date >= DATEADD(HOUR, -1, GETDATE())
)
BEGIN
    -- Send alert
    EXEC t0.usp_send_alert 
        @AlertType = 'PerformanceDegradation',
        @Message = 'Performance degradation detected';
END
```

### Best Practices

- ✅ Set up alerts for critical issues
- ✅ Use appropriate alert thresholds
- ✅ Include context in alerts
- ✅ Test alert mechanisms
- ✅ Review and tune alerts regularly
- ❌ Don't alert on every issue
- ❌ Don't ignore alert fatigue

---

## Pattern 8: Health Checks

### System Health Check

**Health Check Procedure:**

```sql
CREATE PROCEDURE t0.usp_system_health_check
AS
BEGIN
    DECLARE @HealthStatus VARCHAR(20) = 'Healthy';
    DECLARE @Issues VARCHAR(MAX) = '';
    
    -- Check for recent pipeline failures
    IF EXISTS (
        SELECT 1 FROM t0.pipeline_log
        WHERE status = 'Failed'
        AND start_time >= DATEADD(HOUR, -1, GETDATE())
    )
    BEGIN
        SET @HealthStatus = 'Unhealthy';
        SET @Issues = @Issues + 'Recent pipeline failures detected. ';
    END
    
    -- Check for data quality issues
    IF EXISTS (
        SELECT 1 FROM t0.data_quality_metrics
        WHERE status = 'Fail'
        AND metric_date = CAST(GETDATE() AS DATE)
    )
    BEGIN
        SET @HealthStatus = 'Unhealthy';
        SET @Issues = @Issues + 'Data quality issues detected. ';
    END
    
    -- Check for performance issues
    IF EXISTS (
        SELECT 1 FROM t0.performance_metrics
        WHERE duration_seconds > 300  -- 5 minutes
        AND execution_date >= DATEADD(HOUR, -1, GETDATE())
    )
    BEGIN
        SET @HealthStatus = 'Degraded';
        SET @Issues = @Issues + 'Performance issues detected. ';
    END
    
    -- Return health status
    SELECT 
        @HealthStatus AS health_status,
        @Issues AS issues,
        GETDATE() AS check_timestamp;
END;
GO
```

### Best Practices

- ✅ Create health check procedures
- ✅ Run health checks regularly
- ✅ Alert on unhealthy status
- ✅ Document health check criteria
- ✅ Review health check results
- ❌ Don't skip health checks
- ❌ Don't ignore health check results

---

## Summary

Monitoring and observability patterns focus on:

1. **Pipeline Logging**: Track all pipeline executions
2. **Data Quality Monitoring**: Monitor data quality metrics
3. **Performance Monitoring**: Track performance metrics
4. **Error Tracking**: Log and alert on errors
5. **Dashboard Creation**: Create monitoring dashboards
6. **Log Aggregation**: Centralize log collection
7. **Alerting**: Set up appropriate alerts
8. **Health Checks**: Monitor system health

## Related Topics

- [Troubleshooting Guide](troubleshooting-guide.md) - Use monitoring data for troubleshooting
- [Performance Optimization](../optimization/performance-optimization.md) - Performance monitoring
- [T-SQL Patterns](../patterns/t-sql-patterns.md) - Error handling and logging
- [Data Factory Patterns](../patterns/data-factory-patterns.md) - Pipeline logging

---

Follow these patterns to build comprehensive monitoring and observability for Fabric data warehouses.
