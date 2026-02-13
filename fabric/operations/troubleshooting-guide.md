# Troubleshooting Guide

## Overview

This troubleshooting guide provides solutions for common issues encountered when implementing and operating Microsoft Fabric data warehouses following the T0-T5 architecture pattern. Each issue includes symptoms, root causes, and step-by-step resolution steps.

**Common Issue Categories:**
- Pipeline failures
- Data quality issues
- Performance problems
- Authentication errors
- Data synchronization issues
- Semantic model issues

---

## Pipeline Issues

### Issue 1: Pipeline Execution Failure

**Symptoms:**
- Pipeline status shows "Failed"
- Error message in pipeline log
- No data loaded to target

**Common Causes:**
- Connection failures
- Invalid credentials
- Data format issues
- Resource constraints
- Timeout errors

**Resolution Steps:**

1. **Check Pipeline Logs:**
   ```sql
   SELECT TOP 10
       pipeline_name,
       start_time,
       end_time,
       status,
       error_message
   FROM t0.pipeline_log
   WHERE status = 'Failed'
   ORDER BY start_time DESC;
   ```

2. **Check Connection Strings:**
   - Verify linked service configurations
   - Test connections manually
   - Check credential expiration

3. **Check Data Format:**
   - Validate source data format
   - Check for schema changes
   - Verify data types match

4. **Check Resource Constraints:**
   - Monitor compute usage
   - Check for throttling
   - Verify capacity limits

5. **Retry Pipeline:**
   - Use retry logic in pipeline
   - Check for transient failures
   - Verify source data availability

**Prevention:**
- Implement robust error handling
- Use retry logic for transient failures
- Monitor pipeline execution regularly
- Test pipelines in Dev before Prod

---

### Issue 2: Pipeline Timeout

**Symptoms:**
- Pipeline runs for extended time
- Pipeline fails with timeout error
- Partial data loaded

**Common Causes:**
- Large data volumes
- Slow source systems
- Inefficient queries
- Resource constraints

**Resolution Steps:**

1. **Increase Timeout:**
   ```json
   {
     "name": "Copy_Activity",
     "type": "Copy",
     "timeout": "02:00:00"  // Increase timeout
   }
   ```

2. **Optimize Source Query:**
   - Add filters to reduce data volume
   - Use incremental loading
   - Optimize source queries

3. **Batch Processing:**
   - Break into smaller batches
   - Process in parallel
   - Use watermark-based loading

4. **Monitor Performance:**
   ```sql
   SELECT 
       pipeline_name,
       AVG(duration_seconds) AS avg_duration,
       MAX(duration_seconds) AS max_duration
   FROM t0.pipeline_log
   WHERE pipeline_name = 'PL_T1_Load_Employee'
   GROUP BY pipeline_name;
   ```

**Prevention:**
- Use incremental loading
- Optimize source queries
- Monitor pipeline performance
- Set appropriate timeouts

---

## Data Quality Issues

### Issue 3: Missing Data

**Symptoms:**
- Row counts don't match expectations
- Data missing in target tables
- Incomplete data loads

**Common Causes:**
- Filter conditions too restrictive
- Data quality filters removing data
- Incremental load issues
- Watermark problems

**Resolution Steps:**

1. **Check Row Counts:**
   ```sql
   -- Compare source and target
   SELECT 
       'Source' AS source,
       COUNT(*) AS row_count
   FROM t1_department
   UNION ALL
   SELECT 
       'Target',
       COUNT(*)
   FROM t2.dim_department
   WHERE is_current = 1;
   ```

2. **Check Filters:**
   - Review filter conditions
   - Verify filter logic
   - Test filters on sample data

3. **Check Watermarks:**
   ```sql
   SELECT 
       table_name,
       last_processed_timestamp
   FROM t0.watermark
   WHERE table_name = 'fact_payroll';
   ```

4. **Check Data Quality Rules:**
   ```sql
   SELECT 
       table_name,
       metric_type,
       metric_value,
       status
   FROM t0.data_quality_metrics
   WHERE table_name = 'dim_employee'
   AND metric_date = CAST(GETDATE() AS DATE);
   ```

**Prevention:**
- Validate data quality rules
- Test filters thoroughly
- Monitor data quality metrics
- Review watermark logic

---

### Issue 4: Duplicate Data

**Symptoms:**
- Duplicate rows in target tables
- Primary key violations
- Data inconsistency

**Common Causes:**
- Missing deduplication logic
- Incremental load issues
- MERGE logic problems
- Concurrent execution

**Resolution Steps:**

1. **Identify Duplicates:**
   ```sql
   SELECT 
       dept_id,
       COUNT(*) AS duplicate_count
   FROM t2.dim_department
   WHERE is_current = 1
   GROUP BY dept_id
   HAVING COUNT(*) > 1;
   ```

2. **Check MERGE Logic:**
   - Review SCD2 MERGE procedure
   - Verify is_current flag logic
   - Check for race conditions

3. **Check Incremental Load:**
   - Verify watermark logic
   - Check for duplicate source data
   - Review incremental load conditions

4. **Fix Duplicates:**
   ```sql
   -- Remove duplicates (keep most recent)
   WITH Duplicates AS (
       SELECT 
           dept_key,
           ROW_NUMBER() OVER (
               PARTITION BY dept_id 
               ORDER BY updated_at DESC
           ) AS rn
       FROM t2.dim_department
       WHERE is_current = 1
   )
   UPDATE t2.dim_department
   SET is_current = 0
   WHERE dept_key IN (
       SELECT dept_key FROM Duplicates WHERE rn > 1
   );
   ```

**Prevention:**
- Implement proper deduplication
- Use transactions for atomicity
- Test MERGE logic thoroughly
- Monitor for duplicates

---

## Performance Issues

### Issue 5: Slow Query Performance

**Symptoms:**
- Queries take long time to execute
- Timeout errors
- High resource usage

**Common Causes:**
- Missing indexes
- Inefficient queries
- Large data scans
- Resource constraints

**Resolution Steps:**

1. **Check Query Plan:**
   ```sql
   SET STATISTICS IO ON;
   SET STATISTICS TIME ON;
   
   -- Your query here
   SELECT * FROM t2.fact_payroll f
   INNER JOIN t2.dim_employee e ON f.emp_key = e.emp_key
   WHERE f.pay_date >= '2024-01-01';
   
   SET STATISTICS IO OFF;
   SET STATISTICS TIME OFF;
   ```

2. **Check Indexes:**
   ```sql
   -- Check index usage
   SELECT 
       OBJECT_NAME(object_id) AS table_name,
       name AS index_name,
       user_seeks,
       user_scans
   FROM sys.dm_db_index_usage_stats
   WHERE database_id = DB_ID()
   ORDER BY user_scans DESC;
   ```

3. **Create Missing Indexes:**
   ```sql
   -- Create index on frequently filtered column
   CREATE INDEX idx_t2_payroll_date ON t2.fact_payroll(pay_date);
   ```

4. **Optimize Query:**
   - Add filters early
   - Use appropriate JOIN types
   - Select only needed columns
   - Use aggregations when possible

**Prevention:**
- Create appropriate indexes
- Optimize queries
- Monitor query performance
- Use aggregations

---

### Issue 6: Slow Pipeline Execution

**Symptoms:**
- Pipelines take longer than expected
- Resource contention
- Timeout issues

**Common Causes:**
- Large data volumes
- Inefficient transformations
- Resource constraints
- Concurrent execution

**Resolution Steps:**

1. **Monitor Pipeline Performance:**
   ```sql
   SELECT 
       pipeline_name,
       AVG(duration_seconds) AS avg_duration,
       MAX(duration_seconds) AS max_duration,
       AVG(rows_processed) AS avg_rows
   FROM t0.pipeline_log
   WHERE start_time >= DATEADD(DAY, -7, GETDATE())
   GROUP BY pipeline_name
   ORDER BY avg_duration DESC;
   ```

2. **Optimize Dataflows:**
   - Enable query folding
   - Select columns early
   - Filter before joins
   - Use incremental refresh

3. **Optimize Stored Procedures:**
   - Use MERGE instead of multiple statements
   - Add indexes
   - Batch large operations
   - Optimize queries

4. **Scale Resources:**
   - Increase compute resources
   - Use parallel execution
   - Optimize resource allocation

**Prevention:**
- Optimize transformations
- Use incremental loading
- Monitor performance
- Scale resources appropriately

---

## Authentication Issues

### Issue 7: Authentication Failures

**Symptoms:**
- Connection failures
- Authentication errors
- Access denied errors

**Common Causes:**
- Invalid credentials
- Expired credentials
- Insufficient permissions
- Network issues

**Resolution Steps:**

1. **Verify Credentials:**
   - Check credential expiration
   - Verify credential format
   - Test credentials manually

2. **Check Permissions:**
   ```sql
   -- Check user permissions
   SELECT 
       pr.name AS principal_name,
       pr.type_desc AS principal_type,
       pe.permission_name,
       pe.state_desc
   FROM sys.database_permissions pe
   INNER JOIN sys.database_principals pr ON pe.grantee_principal_id = pr.principal_id
   WHERE pr.name = 'your_user';
   ```

3. **Check Service Principal:**
   - Verify service principal exists
   - Check service principal permissions
   - Verify secret hasn't expired

4. **Test Connection:**
   ```sql
   -- Test connection
   SELECT USER_NAME(), SUSER_NAME();
   ```

**Prevention:**
- Use Managed Identity when possible
- Rotate credentials regularly
- Grant minimal required permissions
- Monitor authentication failures

---

## Data Synchronization Issues

### Issue 8: Data Not Syncing

**Symptoms:**
- Data not appearing in target
- Stale data in target
- Inconsistent data

**Common Causes:**
- Pipeline not running
- Watermark issues
- Filter conditions
- Time zone issues

**Resolution Steps:**

1. **Check Pipeline Execution:**
   ```sql
   SELECT TOP 10
       pipeline_name,
       start_time,
       status,
       rows_processed
   FROM t0.pipeline_log
   WHERE pipeline_name = 'PL_T2_Process_SCD2'
   ORDER BY start_time DESC;
   ```

2. **Check Watermarks:**
   ```sql
   SELECT 
       table_name,
       last_processed_timestamp,
       updated_at
   FROM t0.watermark
   ORDER BY updated_at DESC;
   ```

3. **Check Source Data:**
   ```sql
   -- Check for new data in source
   SELECT 
       MAX(ingested_at) AS latest_ingestion
   FROM t1_department;
   ```

4. **Manual Sync:**
   ```sql
   -- Manually trigger sync
   EXEC t2.usp_merge_dim_department;
   ```

**Prevention:**
- Monitor pipeline execution
- Verify watermark logic
- Test synchronization regularly
- Set up alerts for sync failures

---

## Semantic Model Issues

### Issue 9: Direct Lake Not Working

**Symptoms:**
- Semantic model shows DirectQuery
- Slow query performance
- Cache not working

**Common Causes:**
- Incorrect table selection
- Storage mode configuration
- Table structure issues
- Cache issues

**Resolution Steps:**

1. **Check Storage Mode:**
   - Verify tables are T3._FINAL tables
   - Check storage mode in semantic model
   - Verify Direct Lake is enabled

2. **Check Table Structure:**
   ```sql
   -- Verify _FINAL tables exist
   SELECT 
       TABLE_SCHEMA,
       TABLE_NAME
   FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_NAME LIKE '%_FINAL'
   ORDER BY TABLE_NAME;
   ```

3. **Refresh Semantic Model:**
   - Refresh semantic model
   - Verify cache refresh
   - Check query performance

4. **Check Relationships:**
   - Verify relationships are configured
   - Check relationship cardinality
   - Verify active relationships

**Prevention:**
- Use T3._FINAL tables
- Verify storage mode
- Monitor Direct Lake performance
- Test semantic model regularly
- Review [Direct Lake Modes & T5 View Compatibility](../reference/direct-lake-modes-t5-compatibility.md) for best practices and troubleshooting

---

## General Troubleshooting Steps

### Diagnostic Queries

**System Health Check:**
```sql
-- Check system health
EXEC t0.usp_system_health_check;
```

**Recent Errors:**
```sql
-- Check recent errors
SELECT TOP 20
    error_timestamp,
    component_name,
    error_severity,
    error_message
FROM t0.error_log
WHERE resolved = 0
ORDER BY error_timestamp DESC;
```

**Performance Issues:**
```sql
-- Check performance issues
SELECT 
    component_name,
    AVG(duration_seconds) AS avg_duration,
    MAX(duration_seconds) AS max_duration
FROM t0.performance_metrics
WHERE execution_date >= DATEADD(DAY, -7, GETDATE())
GROUP BY component_name
HAVING AVG(duration_seconds) > 60  -- More than 1 minute
ORDER BY avg_duration DESC;
```

### Best Practices

- ✅ Check logs first
- ✅ Verify configurations
- ✅ Test in Dev before Prod
- ✅ Document solutions
- ✅ Monitor after resolution
- ❌ Don't skip diagnostic steps
- ❌ Don't ignore warning signs

---

## Summary

Common troubleshooting areas:

1. **Pipeline Issues**: Failures, timeouts, execution problems
2. **Data Quality**: Missing data, duplicates, quality issues
3. **Performance**: Slow queries, slow pipelines
4. **Authentication**: Connection failures, permission issues
5. **Synchronization**: Data not syncing, stale data
6. **Semantic Model**: Direct Lake issues, performance problems

## Related Topics

- [Monitoring & Observability](monitoring-observability.md) - Monitoring patterns for troubleshooting
- [Performance Optimization](../optimization/performance-optimization.md) - Performance troubleshooting
- [T-SQL Patterns](../patterns/t-sql-patterns.md) - Error handling patterns
- [Data Factory Patterns](../patterns/data-factory-patterns.md) - Pipeline troubleshooting

---

Follow diagnostic steps, check logs, verify configurations, and test solutions thoroughly.
