# Performance Optimization Patterns

## Overview

Performance optimization in Microsoft Fabric involves optimizing queries, data structures, indexes, and resource allocation across all layers of the T0-T5 architecture. This guide covers comprehensive performance optimization patterns and best practices.

**Key Optimization Areas:**
- Query performance
- Index optimization
- Partitioning strategies
- Data structure optimization
- Resource allocation
- Caching strategies

---

## Architecture Context

### Performance Optimization Across Layers

**T1**: Optimize VARIANT queries, materialized views
**T2**: Optimize SCD2 MERGE operations, indexes
**T3**: Optimize Dataflows Gen2, transformations
**T5**: Optimize views, aggregations
**Semantic Layer**: Optimize Direct Lake, DAX queries

---

## Pattern 1: Query Performance Optimization

### Index Usage

**Create Appropriate Indexes:**

```sql
-- Index on frequently filtered columns
CREATE INDEX idx_t2_dept_id ON t2.dim_department(dept_id);

-- Index on foreign keys for joins
CREATE INDEX idx_t2_payroll_emp ON t2.fact_payroll(emp_key);
CREATE INDEX idx_t2_payroll_date ON t2.fact_payroll(pay_date_key);

-- Composite index for common query patterns
CREATE INDEX idx_t2_payroll_emp_date ON t2.fact_payroll(emp_key, pay_date_key);
```

**Monitor Index Usage:**

```sql
-- Check index usage
SELECT 
    OBJECT_NAME(object_id) AS table_name,
    name AS index_name,
    user_seeks,
    user_scans,
    user_lookups,
    user_updates
FROM sys.dm_db_index_usage_stats
WHERE database_id = DB_ID()
ORDER BY user_seeks + user_scans + user_lookups DESC;
```

### Best Practices

- ✅ Index foreign keys
- ✅ Index frequently filtered columns
- ✅ Create composite indexes for common patterns
- ✅ Monitor index usage
- ✅ Remove unused indexes
- ❌ Don't over-index (slows writes)
- ❌ Don't index low-cardinality columns

---

## Pattern 2: Partitioning Strategies

### Table Partitioning

**Partition by Date:**

```sql
-- Partition fact table by date
CREATE TABLE t2.fact_payroll (
    payroll_key INT IDENTITY(1,1),
    pay_date DATE,
    ...
)
PARTITION BY (pay_date);
```

**Benefits:**
- Partition pruning in queries
- Efficient data maintenance
- Improved query performance

### Best Practices

- ✅ Partition large fact tables by date
- ✅ Use partition pruning in queries
- ✅ Balance partition count (not too many)
- ✅ Monitor partition sizes
- ✅ Consider partition maintenance
- ❌ Don't over-partition
- ❌ Don't partition small tables

---

## Pattern 3: Materialized View Optimization

### Refresh Strategy

**Incremental Refresh:**

```sql
-- Refresh only changed partitions
REFRESH MATERIALIZED VIEW mv_department
PARTITION (ingested_date = '2024-01-15');
```

**Full Refresh:**

```sql
-- Full refresh when needed
REFRESH MATERIALIZED VIEW mv_department;
```

### Best Practices

- ✅ Use incremental refresh when possible
- ✅ Refresh after data loads
- ✅ Monitor refresh performance
- ✅ Schedule refresh appropriately
- ✅ Document refresh strategy
- ❌ Don't skip materialized view refresh
- ❌ Don't refresh unnecessarily

---

## Pattern 4: SCD2 MERGE Optimization

### Optimized MERGE Pattern

**Single-Pass MERGE:**

```sql
CREATE PROCEDURE t2.usp_merge_dim_department_optimized
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Use MERGE for single-pass operation
    MERGE t2.dim_department AS target
    USING (
        SELECT dept_id, dept_name, division_id, cost_center, location
        FROM t1_department
    ) AS source
    ON target.dept_id = source.dept_id AND target.is_current = 1
    WHEN MATCHED AND (
        target.dept_name <> source.dept_name
        OR target.division_id <> source.division_id
    ) THEN
        UPDATE SET expiry_date = GETDATE(), is_current = 0
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (dept_id, dept_name, division_id, cost_center, location, effective_date, is_current)
        VALUES (source.dept_id, source.dept_name, source.division_id, source.cost_center, source.location, GETDATE(), 1);
    
    -- Insert new versions separately
    INSERT INTO t2.dim_department (...)
    SELECT ... FROM t1_department s
    INNER JOIN t2.dim_department t ON s.dept_id = t.dept_id
    WHERE t.is_current = 0 AND t.expiry_date = CAST(GETDATE() AS DATE);
END;
GO
```

### Best Practices

- ✅ Use MERGE for single-pass operations
- ✅ Index join columns
- ✅ Batch large MERGE operations
- ✅ Monitor MERGE performance
- ✅ Optimize MERGE conditions
- ❌ Don't use multiple passes unnecessarily
- ❌ Don't skip indexing

---

## Pattern 5: Dataflow Gen2 Optimization

### Query Folding

**Enable Query Folding:**

```m
// Good: Query folds to SQL
let
    Source = Sql.Database("server", "database"),
    Filtered = Table.SelectRows(Source, each [year] = 2024)
in
    Filtered

// Bad: Query doesn't fold
let
    Source = Sql.Database("server", "database"),
    LoadAll = Source{[Schema="sales"]}[Data],
    Filtered = Table.SelectRows(LoadAll, each [year] = 2024)
in
    Filtered
```

### Column Selection

**Select Columns Early:**

```m
// Good: Select columns early
let
    Source = Sql.Database("server", "database"),
    SelectColumns = Table.SelectColumns(Source, {"id", "name", "date"})
in
    SelectColumns

// Bad: Select columns after transformations
let
    Source = Sql.Database("server", "database"),
    Transform = Table.TransformColumns(Source, ...),
    SelectColumns = Table.SelectColumns(Transform, {"id", "name"})
in
    SelectColumns
```

### Best Practices

- ✅ Enable query folding
- ✅ Select columns early
- ✅ Filter before joins
- ✅ Use incremental refresh
- ✅ Monitor dataflow performance
- ❌ Don't disable query folding unnecessarily
- ❌ Don't load unnecessary columns

---

## Pattern 6: Direct Lake Optimization

### Aggregation Design

**Create Aggregations:**

```sql
-- Create aggregation table
CREATE TABLE t3.agg_payroll_monthly (
    year INT,
    month INT,
    department_id VARCHAR(10),
    total_gross_pay DECIMAL(12,2),
    INDEX idx_agg_payroll (year, month, department_id)
);
```

**Use in Semantic Model:**

- Add aggregation table to semantic model
- Create relationships
- Use for summary queries
- Keep detail table for drill-down

### Best Practices

- ✅ Create aggregations for common queries
- ✅ Use aggregations in semantic model
- ✅ Monitor aggregation usage
- ✅ Maintain aggregations regularly
- ✅ Balance aggregation count
- ❌ Don't create too many aggregations
- ❌ Don't skip aggregation maintenance

---

## Pattern 7: DAX Query Optimization

### Efficient DAX Patterns

**Use Aggregations:**

```dax
// Good: Uses aggregation
Total Sales = SUM(agg_sales_monthly[total_sales])

// Bad: Calculates from detail
Total Sales = SUMX(fact_sales_FINAL, [quantity] * [unit_price])
```

**Optimize CALCULATE:**

```dax
// Good: Simple filter
Sales This Year = 
CALCULATE(
    [Total Sales],
    dim_time_FINAL[year] = YEAR(TODAY())
)

// Bad: Complex filter
Sales This Year = 
CALCULATE(
    [Total Sales],
    FILTER(
        ALL(dim_time_FINAL),
        dim_time_FINAL[year] = YEAR(TODAY())
    )
)
```

### Best Practices

- ✅ Use aggregations when possible
- ✅ Use simple CALCULATE filters
- ✅ Avoid unnecessary iterations
- ✅ Test DAX performance
- ✅ Monitor query performance
- ❌ Don't use complex FILTER expressions
- ❌ Don't iterate over large tables unnecessarily

---

## Pattern 8: Resource Allocation

### Compute Resources

**Dataflow Gen2:**

```json
{
  "compute": {
    "computeType": "General",
    "coreCount": 8  // Adjust based on workload
  }
}
```

**Warehouse:**

- Configure compute size based on workload
- Scale up for large operations
- Scale down for cost optimization
- Monitor resource usage

### Best Practices

- ✅ Right-size compute resources
- ✅ Scale up for large operations
- ✅ Scale down for cost optimization
- ✅ Monitor resource usage
- ✅ Use appropriate compute types
- ❌ Don't over-allocate resources
- ❌ Don't under-allocate for large workloads

---

## Pattern 9: Caching Strategies

### Direct Lake Cache

**Optimize for Cache:**

- Use aggregations to reduce cache size
- Select only needed columns
- Use appropriate data types
- Monitor cache performance

### Materialized View Cache

**Refresh Strategy:**

- Refresh after data loads
- Use incremental refresh when possible
- Schedule refresh appropriately
- Monitor refresh performance

### Best Practices

- ✅ Use aggregations to reduce cache size
- ✅ Select only needed columns
- ✅ Refresh materialized views regularly
- ✅ Monitor cache performance
- ✅ Let Fabric manage cache automatically
- ❌ Don't try to manually manage cache
- ❌ Don't load unnecessary data into cache

---

## Pattern 10: Query Monitoring

### Monitor Query Performance

**Use Query Store:**

```sql
-- Enable Query Store
ALTER DATABASE HR_Warehouse SET QUERY_STORE = ON;

-- View top queries
SELECT TOP 10
    q.query_id,
    qt.query_sql_text,
    rs.avg_duration,
    rs.count_executions
FROM sys.query_store_query q
INNER JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
INNER JOIN sys.query_store_plan p ON q.query_id = p.query_id
INNER JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
ORDER BY rs.avg_duration DESC;
```

### Use DAX Studio

1. Connect to semantic model
2. Execute queries
3. View server timings
4. Analyze storage engine queries
5. Identify performance bottlenecks

### Best Practices

- ✅ Enable Query Store
- ✅ Monitor query performance regularly
- ✅ Use DAX Studio for semantic model
- ✅ Identify slow queries
- ✅ Optimize based on metrics
- ❌ Don't ignore performance issues
- ❌ Don't optimize without metrics

---

## Pattern 11: Batch Processing

### Large Dataset Processing

**Batch MERGE Operations:**

```sql
CREATE PROCEDURE t2.usp_batch_merge
    @BatchSize INT = 10000
AS
BEGIN
    DECLARE @RowsProcessed INT = 1;
    
    WHILE @RowsProcessed > 0
    BEGIN
        BEGIN TRANSACTION;
        
        -- Process batch
        MERGE t2.dim_department AS target
        USING (
            SELECT TOP (@BatchSize) * FROM t1_department WHERE processed = 0
        ) AS source
        ON target.dept_id = source.dept_id AND target.is_current = 1
        WHEN MATCHED THEN UPDATE SET ...
        WHEN NOT MATCHED THEN INSERT ...;
        
        SET @RowsProcessed = @@ROWCOUNT;
        
        -- Mark as processed
        UPDATE t1_department SET processed = 1
        WHERE dept_id IN (
            SELECT TOP (@BatchSize) dept_id FROM t1_department WHERE processed = 0
        );
        
        COMMIT TRANSACTION;
    END
END;
GO
```

### Best Practices

- ✅ Use batch processing for large datasets
- ✅ Use appropriate batch size
- ✅ Commit after each batch
- ✅ Log progress
- ✅ Handle batch failures
- ❌ Don't use batches for small datasets
- ❌ Don't skip transaction management

---

## Pattern 12: Performance Testing

### Benchmark Queries

**Create Test Queries:**

```sql
-- Test query performance
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT 
    d.dept_name,
    SUM(f.gross_pay) AS total_pay
FROM t2.fact_payroll f
INNER JOIN t2.dim_department d ON f.dept_key = d.dept_key
WHERE f.pay_date >= '2024-01-01'
GROUP BY d.dept_name;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
```

### Best Practices

- ✅ Create benchmark queries
- ✅ Test before and after optimization
- ✅ Monitor query execution plans
- ✅ Test with realistic data volumes
- ✅ Document performance improvements
- ❌ Don't optimize without testing
- ❌ Don't skip performance testing

---

## Summary

Performance optimization across the T0-T5 architecture focuses on:

1. **Query Optimization**: Indexes, partitioning, query tuning
2. **SCD2 Optimization**: Efficient MERGE operations
3. **Dataflow Optimization**: Query folding, column selection
4. **Direct Lake Optimization**: Aggregations, caching
5. **DAX Optimization**: Efficient measures and queries
6. **Resource Allocation**: Right-size compute resources
7. **Caching**: Optimize cache usage
8. **Monitoring**: Track performance metrics

## Related Topics

- [Direct Lake Optimization](direct-lake-optimization.md) - Direct Lake-specific optimization
- [Warehouse Patterns](../patterns/warehouse-patterns.md) - Warehouse performance patterns
- [Dataflows Gen2 Patterns](../patterns/dataflows-gen2-patterns.md) - Dataflow performance optimization
- [Lakehouse Patterns](../patterns/lakehouse-patterns.md) - Lakehouse performance optimization
- [T-SQL Patterns](../patterns/t-sql-patterns.md) - T-SQL query optimization

---

Follow these patterns to optimize performance across all layers of the Fabric data warehouse.
