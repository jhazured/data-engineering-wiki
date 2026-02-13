-- Monitoring and Observability Sample Queries
-- Use these queries to monitor your T0-T5 architecture implementation

-- ============================================================================
-- T0 - Control Layer Monitoring
-- ============================================================================

-- Check pipeline execution status
SELECT 
    pipeline_name,
    start_time,
    end_time,
    DATEDIFF(MINUTE, start_time, end_time) AS duration_minutes,
    status,
    rows_processed,
    error_message
FROM t0.pipeline_log
WHERE start_time >= DATEADD(DAY, -7, GETDATE())
ORDER BY start_time DESC;

-- Check watermark status
SELECT 
    table_name,
    last_processed_timestamp,
    updated_at,
    DATEDIFF(HOUR, last_processed_timestamp, GETDATE()) AS hours_since_last_load
FROM t0.watermark
ORDER BY last_processed_timestamp DESC;

-- Pipeline success rate (last 30 days)
SELECT 
    pipeline_name,
    COUNT(*) AS total_runs,
    SUM(CASE WHEN status = 'Success' THEN 1 ELSE 0 END) AS successful_runs,
    SUM(CASE WHEN status = 'Failed' THEN 1 ELSE 0 END) AS failed_runs,
    CAST(SUM(CASE WHEN status = 'Success' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS success_rate_pct
FROM t0.pipeline_log
WHERE start_time >= DATEADD(DAY, -30, GETDATE())
GROUP BY pipeline_name
ORDER BY success_rate_pct DESC;

-- ============================================================================
-- T1 - Lakehouse Monitoring
-- ============================================================================

-- Check T1 table row counts
SELECT 
    'raw_department' AS table_name,
    COUNT(*) AS row_count,
    MAX(ingested_at) AS last_ingested
FROM T1_DATA_LAKE.raw_department
UNION ALL
SELECT 
    'raw_employee',
    COUNT(*),
    MAX(ingested_at)
FROM T1_DATA_LAKE.raw_employee
UNION ALL
SELECT 
    'raw_payroll',
    COUNT(*),
    MAX(ingested_at)
FROM T1_DATA_LAKE.raw_payroll;

-- Check materialized view freshness
SELECT 
    'mv_department' AS view_name,
    COUNT(*) AS row_count
FROM T1_DATA_LAKE.mv_department
UNION ALL
SELECT 
    'mv_employee',
    COUNT(*)
FROM T1_DATA_LAKE.mv_employee
UNION ALL
SELECT 
    'mv_payroll',
    COUNT(*)
FROM T1_DATA_LAKE.mv_payroll;

-- ============================================================================
-- T2 - Warehouse SCD2 Monitoring
-- ============================================================================

-- Check SCD2 dimension current vs historical records
SELECT 
    'dim_department' AS dimension,
    COUNT(*) AS total_records,
    SUM(CASE WHEN is_current = 1 THEN 1 ELSE 0 END) AS current_records,
    SUM(CASE WHEN is_current = 0 THEN 1 ELSE 0 END) AS historical_records
FROM t2.dim_department
UNION ALL
SELECT 
    'dim_employee',
    COUNT(*),
    SUM(CASE WHEN is_current = 1 THEN 1 ELSE 0 END),
    SUM(CASE WHEN is_current = 0 THEN 1 ELSE 0 END)
FROM t2.dim_employee;

-- Check fact table growth
SELECT 
    'fact_payroll' AS fact_table,
    COUNT(*) AS total_rows,
    MIN(pay_date) AS earliest_date,
    MAX(pay_date) AS latest_date,
    COUNT(DISTINCT employee_id) AS unique_employees,
    SUM(gross_pay) AS total_gross_pay
FROM t2.fact_payroll;

-- Check surrogate key population
SELECT 
    COUNT(*) AS total_facts,
    SUM(CASE WHEN emp_key IS NULL THEN 1 ELSE 0 END) AS missing_emp_key,
    SUM(CASE WHEN dept_key IS NULL THEN 1 ELSE 0 END) AS missing_dept_key,
    SUM(CASE WHEN pay_date_key IS NULL THEN 1 ELSE 0 END) AS missing_date_key
FROM t2.fact_payroll;

-- ============================================================================
-- T3 - Transformations Monitoring
-- ============================================================================

-- Check T3 table row counts
SELECT 
    'employee_base' AS table_name,
    COUNT(*) AS row_count
FROM t3.employee_base
UNION ALL
SELECT 
    'employee_enriched',
    COUNT(*)
FROM t3.employee_enriched
UNION ALL
SELECT 
    'payroll_monthly_summary',
    COUNT(*)
FROM t3.payroll_monthly_summary
UNION ALL
SELECT 
    'dim_employee',
    COUNT(*)
FROM t3.dim_employee
UNION ALL
SELECT 
    'fact_payroll',
    COUNT(*)
FROM t3.fact_payroll;

-- Check T3._FINAL clone status
SELECT 
    'dim_employee_FINAL' AS clone_table,
    COUNT(*) AS row_count
FROM t3.dim_employee_FINAL
UNION ALL
SELECT 
    'dim_department_FINAL',
    COUNT(*)
FROM t3.dim_department_FINAL
UNION ALL
SELECT 
    'fact_payroll_FINAL',
    COUNT(*)
FROM t3.fact_payroll_FINAL;

-- Compare T3 vs T3._FINAL (should match)
SELECT 
    'dim_employee' AS table_name,
    (SELECT COUNT(*) FROM t3.dim_employee) AS t3_count,
    (SELECT COUNT(*) FROM t3.dim_employee_FINAL) AS final_count,
    (SELECT COUNT(*) FROM t3.dim_employee) - (SELECT COUNT(*) FROM t3.dim_employee_FINAL) AS difference
UNION ALL
SELECT 
    'fact_payroll',
    (SELECT COUNT(*) FROM t3.fact_payroll),
    (SELECT COUNT(*) FROM t3.fact_payroll_FINAL),
    (SELECT COUNT(*) FROM t3.fact_payroll) - (SELECT COUNT(*) FROM t3.fact_payroll_FINAL);

-- ============================================================================
-- T5 - Presentation Layer Monitoring
-- ============================================================================

-- Test T5 views
SELECT TOP 10 * FROM t5.vw_employee;
SELECT TOP 10 * FROM t5.vw_department;
SELECT TOP 10 * FROM t5.vw_payroll_detail;
SELECT TOP 10 * FROM t5.vw_payroll_monthly_summary;

-- Check view row counts
SELECT 
    'vw_employee' AS view_name,
    COUNT(*) AS row_count
FROM t5.vw_employee
UNION ALL
SELECT 
    'vw_department',
    COUNT(*)
FROM t5.vw_department
UNION ALL
SELECT 
    'vw_payroll_detail',
    COUNT(*)
FROM t5.vw_payroll_detail
UNION ALL
SELECT 
    'vw_payroll_monthly_summary',
    COUNT(*)
FROM t5.vw_payroll_monthly_summary;

-- ============================================================================
-- Data Quality Checks
-- ============================================================================

-- Check for NULLs in critical columns
SELECT 
    'fact_payroll.employee_id' AS column_name,
    COUNT(*) AS null_count
FROM t2.fact_payroll
WHERE employee_id IS NULL
UNION ALL
SELECT 
    'fact_payroll.pay_date',
    COUNT(*)
FROM t2.fact_payroll
WHERE pay_date IS NULL
UNION ALL
SELECT 
    'dim_employee.employee_id',
    COUNT(*)
FROM t2.dim_employee
WHERE employee_id IS NULL;

-- Check for duplicates
SELECT 
    payroll_id,
    COUNT(*) AS duplicate_count
FROM t2.fact_payroll
GROUP BY payroll_id
HAVING COUNT(*) > 1;

-- Check data freshness
SELECT 
    'T1' AS layer,
    MAX(ingested_at) AS last_update
FROM T1_DATA_LAKE.raw_payroll
UNION ALL
SELECT 
    'T2',
    MAX(created_at)
FROM t2.fact_payroll
UNION ALL
SELECT 
    'T3',
    MAX(created_at)
FROM t3.fact_payroll;

-- ============================================================================
-- Performance Monitoring
-- ============================================================================

-- Check table sizes (approximate)
SELECT 
    t.name AS table_name,
    s.name AS schema_name,
    p.rows AS row_count,
    SUM(a.total_pages) * 8 / 1024 AS size_mb
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE s.name IN ('t0', 't2', 't3', 't5')
GROUP BY t.name, s.name, p.rows
ORDER BY size_mb DESC;

-- Check index usage
SELECT 
    OBJECT_NAME(s.object_id) AS table_name,
    i.name AS index_name,
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    s.user_updates
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE OBJECT_NAME(s.object_id) LIKE 'dim_%' OR OBJECT_NAME(s.object_id) LIKE 'fact_%'
ORDER BY s.user_seeks + s.user_scans + s.user_lookups DESC;

-- ============================================================================
-- End-to-End Data Flow Validation
-- ============================================================================

-- Validate T1 → T2 → T3 flow
SELECT 
    'T1 Department' AS source,
    COUNT(*) AS count
FROM t1_department
UNION ALL
SELECT 
    'T2 Department (current)',
    COUNT(*)
FROM t2.dim_department
WHERE is_current = 1
UNION ALL
SELECT 
    'T3 Department',
    COUNT(*)
FROM t3.dim_department;

-- Validate fact table flow
SELECT 
    'T1 Payroll' AS source,
    COUNT(*) AS count
FROM t1_payroll
UNION ALL
SELECT 
    'T2 Payroll',
    COUNT(*)
FROM t2.fact_payroll
UNION ALL
SELECT 
    'T3 Payroll',
    COUNT(*)
FROM t3.fact_payroll
UNION ALL
SELECT 
    'T3._FINAL Payroll',
    COUNT(*)
FROM t3.fact_payroll_FINAL;
