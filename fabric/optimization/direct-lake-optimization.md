# Direct Lake Optimization Patterns

## Overview

Direct Lake is Microsoft Fabric's high-performance analytics mode that enables semantic models to query data directly from **OneLake** (Parquet files) or **SQL Warehouse** (tables) without importing data into the model. This guide covers optimization patterns and best practices for maximizing Direct Lake performance.

**Key Characteristics:**
- In-memory caching for fast queries
- Automatic query optimization
- Dual-mode operation (Direct Lake + DirectQuery)
- No refresh required
- Direct access to OneLake Parquet files or Warehouse tables

**Important Note**: This project uses **OneLake** as the primary storage layer, with Direct Lake connecting to Parquet files in OneLake, and DirectQuery used for complex queries or views.

---

## Architecture Context

### Role in T0-T5 Pattern

**Semantic Layer**: Direct Lake connects to data in OneLake or Warehouse
- **OneLake Parquet files** → Direct Lake (in-memory cache)
- **T3._FINAL tables** (if in Warehouse) → Direct Lake (in-memory cache)
- **T5 views** → DirectQuery fallback (automatic)
- No manual configuration needed for dual-mode

**OneLake Integration:**
- T1 Lakehouse stores data in OneLake (Delta/Parquet format)
- T3._FINAL tables can be stored in OneLake as Parquet files
- Semantic model connects to OneLake for Direct Lake access
- DirectQuery automatically used for complex aggregations or views

---

## Pattern 1: Table Selection for Direct Lake

### When to Use Direct Lake

**Ideal Candidates:**
- T3._FINAL fact tables (large, frequently queried)
- T3._FINAL dimension tables (small to medium, frequently joined)
- Tables with predictable query patterns
- Tables that benefit from caching

**Use DirectQuery Instead:**
- T5 views (complex aggregations)
- Very large tables (> 1B rows) that don't fit in cache
- Frequently changing data
- Complex calculations requiring SQL pushdown

### Implementation Pattern

**Option 1: Direct Lake on OneLake (Parquet Files)**

1. Create semantic model
2. Select **Direct Lake** mode
3. Connect to **OneLake** (Lakehouse)
4. Select Parquet tables/files:
   - `t3/dim_employee_FINAL` (Parquet in OneLake)
   - `t3/dim_department_FINAL` (Parquet in OneLake)
   - `t3/fact_payroll_FINAL` (Parquet in OneLake)

**Option 2: Direct Lake via Warehouse Connection**

1. Create semantic model
2. Connect to Warehouse
3. Select T3._FINAL tables (stored as Delta/Parquet in OneLake):
   - `t3.dim_employee_FINAL`
   - `t3.dim_department_FINAL`
   - `t3.dim_time_FINAL`
   - `t3.fact_payroll_FINAL`

**Key Point**: Warehouse tables are stored as Delta/Parquet files in OneLake. Connecting via Warehouse still accesses OneLake Parquet files - Direct Lake reads the underlying OneLake storage.

**Storage Mode Configuration:**

- **OneLake Parquet files** → **Direct Lake** (in-memory cache)
- **Warehouse T3._FINAL tables** → **Direct Lake** (reads OneLake Parquet files)
- **T5 views** → **DirectQuery** (automatic fallback)

**Both options access OneLake storage** - Option 1 directly, Option 2 via Warehouse (which stores in OneLake).
- No manual configuration needed for dual-mode

### Best Practices

- ✅ Use Direct Lake for OneLake Parquet files (primary pattern)
- ✅ Use Direct Lake for T3._FINAL tables (if in Warehouse)
- ✅ Use DirectQuery for T5 views (automatic fallback)
- ✅ Use DirectQuery for complex aggregations requiring SQL pushdown
- ✅ Let Fabric choose storage mode automatically
- ✅ Monitor storage mode assignments
- ✅ Optimize Parquet files/tables for Direct Lake
- ❌ Don't force DirectQuery on OneLake Parquet files unnecessarily
- ❌ Don't use Direct Lake for very large, rarely queried tables

---

## Pattern 2: Aggregation Design

### When to Use Aggregations

- Common query patterns
- Performance optimization
- Reduced cache size
- Faster query response
- **Use DirectQuery for aggregations** when complex SQL pushdown is needed

### Implementation Pattern

**Option 1: Aggregation Table in OneLake (Parquet)**

```python
# Create aggregation in OneLake as Parquet file
# Using Spark or Dataflow Gen2
df_aggregated = df_fact_payroll.groupBy(
    year("pay_date").alias("year"),
    month("pay_date").alias("month"),
    "department_id"
).agg(
    sum("gross_pay").alias("total_gross_pay"),
    sum(col("regular_hours") + col("overtime_hours")).alias("total_hours"),
    countDistinct("employee_id").alias("employee_count")
)

# Write to OneLake as Parquet
df_aggregated.write.format("delta").mode("overwrite").save(
    "abfss://workspace@onelake.dfs.fabric.microsoft.com/lakehouse/Tables/agg_payroll_monthly"
)
```

**Option 2: Aggregation Table in Warehouse**

```sql
-- Create aggregation table in T3
CREATE TABLE t3.agg_payroll_monthly (
    year INT,
    month INT,
    department_id VARCHAR(10),
    total_gross_pay DECIMAL(12,2),
    total_hours DECIMAL(10,2),
    employee_count INT,
    INDEX idx_agg_payroll_monthly (year, month, department_id)
);

-- Populate aggregation
INSERT INTO t3.agg_payroll_monthly
SELECT 
    YEAR(pay_date) AS year,
    MONTH(pay_date) AS month,
    department_id,
    SUM(gross_pay) AS total_gross_pay,
    SUM(regular_hours + overtime_hours) AS total_hours,
    COUNT(DISTINCT employee_id) AS employee_count
FROM t3.fact_payroll_FINAL
GROUP BY YEAR(pay_date), MONTH(pay_date), department_id;
```

**Option 3: Aggregation View (DirectQuery)**

```sql
-- Create aggregation view for DirectQuery
CREATE VIEW t5.vw_payroll_monthly_summary AS
SELECT
    YEAR(pay_date) AS year,
    MONTH(pay_date) AS month,
    department_id,
    SUM(gross_pay) AS total_gross_pay,
    SUM(regular_hours + overtime_hours) AS total_hours,
    COUNT(DISTINCT employee_id) AS employee_count
FROM t3.fact_payroll_FINAL
GROUP BY YEAR(pay_date), MONTH(pay_date), department_id;
```

**Use Aggregation in Semantic Model:**

1. Add aggregation table/view to semantic model
2. Create relationships to dimensions
3. Use aggregation for common queries
4. Keep detail table for drill-down
5. **Views automatically use DirectQuery** (SQL pushdown)

### Best Practices

- ✅ Create aggregations for common query patterns
- ✅ Maintain aggregations via T3 dataflows
- ✅ Use aggregations for summary reports
- ✅ Keep detail tables for drill-down
- ✅ Document aggregation refresh strategy
- ❌ Don't create too many aggregations
- ❌ Don't skip aggregation maintenance

---

## Pattern 3: Column Optimization

### Column Selection

**Select Only Needed Columns:**

```sql
-- Good: Select only needed columns
SELECT 
    employee_key,
    employee_id,
    first_name,
    last_name,
    job_title
FROM t3.dim_employee_FINAL;

-- Bad: Select all columns
SELECT * FROM t3.dim_employee_FINAL;
```

**Hide Unnecessary Columns:**

In semantic model:
1. Hide columns not used in reports
2. Hide technical columns (keys, timestamps)
3. Keep only business-relevant columns visible

### Best Practices

- ✅ Select only needed columns
- ✅ Hide technical columns in semantic model
- ✅ Use display folders for organization
- ✅ Optimize column data types
- ✅ Remove unused columns
- ❌ Don't expose all columns
- ❌ Don't include large text columns unnecessarily

---

## Pattern 4: Relationship Optimization

### Relationship Design

**Star Schema Relationships:**

```
fact_payroll_FINAL
├── emp_key → dim_employee_FINAL[employee_key] (Many-to-One)
├── dept_key → dim_department_FINAL[dept_key] (Many-to-One)
└── pay_date_key → dim_time_FINAL[time_key] (Many-to-One)
```

**Configure Relationships:**

1. Set correct cardinality (Many-to-One)
2. Set cross-filter direction (Single)
3. Mark as active
4. Verify referential integrity

### Best Practices

- ✅ Use star schema relationships
- ✅ Set correct cardinality
- ✅ Use single-direction cross-filtering
- ✅ Verify relationships are active
- ✅ Test relationship performance
- ❌ Don't create unnecessary relationships
- ❌ Don't use bidirectional filtering unnecessarily

---

## Pattern 5: DAX Measure Optimization

### Efficient DAX Patterns

**Use Aggregations:**

```dax
// Good: Uses aggregation table
Total Sales = SUM(agg_sales_monthly[total_sales])

// Bad: Calculates from detail
Total Sales = SUMX(fact_sales_FINAL, [quantity] * [unit_price])
```

**Use CALCULATE Efficiently:**

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

**Avoid Row Context Issues:**

```dax
// Good: Use SUMX for row context
Total Revenue = SUMX(
    fact_sales_FINAL,
    [quantity] * [unit_price]
)

// Bad: Incorrect context
Total Revenue = [quantity] * [unit_price]  // Wrong context
```

### Best Practices

- ✅ Use aggregations when possible
- ✅ Use CALCULATE efficiently
- ✅ Avoid unnecessary iterations
- ✅ Use simple filters
- ✅ Test measure performance
- ❌ Don't use complex FILTER expressions
- ❌ Don't iterate over large tables unnecessarily

---

## Pattern 6: Query Performance Optimization

### Query Folding

**Enable Query Folding:**

Direct Lake automatically folds queries to warehouse SQL. Ensure:
- Source tables are optimized
- Indexes are in place
- Queries use indexed columns

**Monitor Query Performance:**

1. Use DAX Studio to analyze queries
2. Check storage engine queries
3. Monitor query duration
4. Identify slow queries

### Best Practices

- ✅ Optimize source tables
- ✅ Use indexed columns in filters
- ✅ Monitor query performance
- ✅ Use aggregations for common queries
- ✅ Test query performance regularly
- ❌ Don't ignore slow queries
- ❌ Don't use unindexed columns in filters

---

## Pattern 7: Cache Management

### Cache Strategy

**Direct Lake Cache:**
- Automatically caches frequently accessed data
- Cache size managed by Fabric
- Cache eviction based on usage

**Optimize for Cache:**

1. Use aggregations to reduce cache size
2. Select only needed columns
3. Use appropriate data types
4. Compress data in warehouse

### Best Practices

- ✅ Use aggregations to reduce cache size
- ✅ Select only needed columns
- ✅ Optimize data types
- ✅ Monitor cache performance
- ✅ Let Fabric manage cache automatically
- ❌ Don't try to manually manage cache
- ❌ Don't load unnecessary data into cache

---

## Pattern 8: Dual-Mode Operation

### Automatic Fallback

**Direct Lake Sources:**
- **OneLake Parquet files** → Direct Lake (in-memory cache)
- **T3._FINAL tables** (if in Warehouse) → Direct Lake (in-memory cache)
- Cached in-memory for fast queries
- Automatic optimization

**DirectQuery Sources:**
- **T5 views** → DirectQuery (automatic)
- **Complex aggregations** → DirectQuery (automatic fallback)
- SQL pushdown for complex queries
- Automatic fallback when Direct Lake can't handle query

### Implementation Pattern

**Semantic Model Configuration:**

1. Add **OneLake Parquet files** → Direct Lake (primary)
2. Add **T3._FINAL tables** (if in Warehouse) → Direct Lake
3. Add **T5 views** → DirectQuery (automatic)
4. Add **complex aggregations** → DirectQuery (automatic fallback)
5. No manual configuration needed
6. Fabric handles dual-mode automatically

**OneLake Integration:**

- Semantic model connects to OneLake for Direct Lake
- Parquet files in OneLake automatically use Direct Lake
- Views and complex queries automatically use DirectQuery
- Seamless dual-mode operation

### Best Practices

- ✅ Use Direct Lake for T3._FINAL tables
- ✅ Use DirectQuery for T5 views
- ✅ Let Fabric choose storage mode
- ✅ Monitor storage mode usage
- ✅ Optimize both tables and views
- ❌ Don't force storage mode unnecessarily
- ❌ Don't mix modes in same query unnecessarily

---

## Pattern 9: Incremental Refresh Strategy

### When to Refresh

**OneLake Parquet Files:**
- Refresh after T3 transformations complete
- Write new Parquet files to OneLake
- No data import needed

**T3._FINAL Tables (if in Warehouse):**
- Refresh after T3 transformations complete
- Refresh clones (zero-copy operation)
- No data import needed

**Semantic Model:**
- No refresh needed (Direct Lake)
- Automatically uses latest OneLake Parquet files or Warehouse tables
- Cache updates automatically

### Implementation Pattern

**OneLake Refresh:**

```python
# Refresh Parquet files in OneLake
df_final.write.format("delta").mode("overwrite").save(
    "abfss://workspace@onelake.dfs.fabric.microsoft.com/lakehouse/Tables/fact_payroll_FINAL"
)
```

**Warehouse Clone Refresh:**

```sql
-- Refresh T3._FINAL clones (if using Warehouse)
EXEC t3.usp_refresh_final_clones;
```

**Semantic Model:**
- No action needed
- Automatically uses refreshed OneLake Parquet files or Warehouse tables
- Cache updates on next query

### Best Practices

- ✅ Refresh clones after T3 completion
- ✅ No semantic model refresh needed
- ✅ Monitor clone refresh performance
- ✅ Schedule clone refresh appropriately
- ✅ Let cache update automatically
- ❌ Don't refresh semantic model unnecessarily
- ❌ Don't skip clone refresh

---

## Pattern 10: Performance Monitoring

### Monitor Direct Lake Performance

**Key Metrics:**
- Query duration
- Cache hit rate
- Storage engine queries
- Formula engine time

**Use DAX Studio:**

1. Connect to semantic model
2. Execute queries
3. View server timings
4. Analyze storage engine queries
5. Identify performance bottlenecks

### Best Practices

- ✅ Monitor query performance regularly
- ✅ Use DAX Studio for analysis
- ✅ Track performance trends
- ✅ Identify slow queries
- ✅ Optimize based on metrics
- ❌ Don't ignore performance issues
- ❌ Don't optimize without metrics

---

## Pattern 11: Data Type Optimization

### Optimal Data Types

**Use Appropriate Types:**

```sql
-- Good: Use appropriate types
CREATE TABLE t3.fact_payroll_FINAL (
    payroll_key INT,
    payroll_id VARCHAR(10),
    pay_date DATE,
    gross_pay DECIMAL(12,2),
    hours DECIMAL(8,2)
);

-- Bad: Use generic types
CREATE TABLE t3.fact_payroll_FINAL (
    payroll_key VARCHAR(50),  -- Should be INT
    pay_date DATETIME,        -- Should be DATE
    gross_pay FLOAT          -- Should be DECIMAL
);
```

### Best Practices

- ✅ Use appropriate data types
- ✅ Use INT for keys
- ✅ Use DATE for dates (not DATETIME)
- ✅ Use DECIMAL for currency
- ✅ Use VARCHAR with appropriate length
- ❌ Don't use generic types
- ❌ Don't use FLOAT for currency

---

## Pattern 12: Partitioning Strategy

### Warehouse Partitioning

**Partition Large Tables:**

```sql
-- Partition fact table by date
CREATE TABLE t3.fact_payroll_FINAL (
    payroll_key INT,
    pay_date DATE,
    ...
)
PARTITION BY (pay_date);
```

**Benefits:**
- Query performance (partition pruning)
- Maintenance efficiency
- Cache efficiency

### Best Practices

- ✅ Partition large fact tables by date
- ✅ Use partition pruning in queries
- ✅ Monitor partition sizes
- ✅ Consider partition maintenance
- ✅ Balance partition count
- ❌ Don't over-partition
- ❌ Don't partition small tables

---

## Pattern 13: OneLake-Specific Optimization

### Optimize OneLake Parquet Files

**Partitioning:**

```python
# Partition Parquet files by date
df_final.write.format("delta").mode("overwrite") \
    .partitionBy("pay_date") \
    .save("abfss://workspace@onelake.dfs.fabric.microsoft.com/lakehouse/Tables/fact_payroll_FINAL")
```

**Z-Ordering:**

```python
# Z-order by frequently queried columns
df_final.write.format("delta").mode("overwrite") \
    .option("delta.optimizeWrite", "true") \
    .option("delta.autoOptimize", "true") \
    .save("abfss://workspace@onelake.dfs.fabric.microsoft.com/lakehouse/Tables/fact_payroll_FINAL")
```

**Compression:**

```python
# Use appropriate compression
df_final.write.format("delta").mode("overwrite") \
    .option("compression", "zstd") \
    .save("abfss://workspace@onelake.dfs.fabric.microsoft.com/lakehouse/Tables/fact_payroll_FINAL")
```

### Best Practices

- ✅ Partition large tables by date
- ✅ Use Z-ordering for frequently filtered columns
- ✅ Use appropriate compression (zstd recommended)
- ✅ Optimize Parquet files regularly
- ✅ Monitor query performance
- ❌ Don't skip optimization
- ❌ Don't create too many small files

---

## Pattern 14: Monitoring Storage Modes

### Check Storage Mode in Semantic Model

1. Open semantic model in Power BI Desktop
2. Go to **Model** view
3. Select table/view
4. Check **Storage Mode** property:
   - **Direct Lake** for Parquet files
   - **DirectQuery** for views

### Monitor Query Performance with DAX Studio

**Use DAX Studio:**

1. Connect to semantic model
2. Execute queries
3. Check **Server Timings**:
   - **SE Queries**: Storage engine queries
   - **FE CPU**: Formula engine CPU time
   - **SE CPU**: Storage engine CPU time

**Direct Lake Queries:**
- Low SE query count
- Fast query performance
- In-memory cache hits

**DirectQuery Queries:**
- Higher SE query count
- SQL pushdown visible
- Real-time data access

---

## Pattern 15: Common OneLake Patterns

### Pattern 1: OneLake Parquet + DirectQuery Views

**Architecture:**
- Fact tables: OneLake Parquet → Direct Lake
- Dimension tables: OneLake Parquet → Direct Lake
- Aggregation views: Warehouse views → DirectQuery

**Benefits:**
- Fast queries on facts/dimensions (Direct Lake)
- Complex aggregations use SQL pushdown (DirectQuery)
- Automatic storage mode selection

### Pattern 2: Hybrid Approach

**Architecture:**
- Frequently queried tables: OneLake Parquet → Direct Lake
- Complex aggregations: Warehouse views → DirectQuery
- Reference data: OneLake Parquet → Direct Lake

**Benefits:**
- Optimize for common queries (Direct Lake)
- Support complex queries (DirectQuery)
- Flexible architecture

---

## Related Topics

- [Direct Lake Modes & T5 View Compatibility](../reference/direct-lake-modes-t5-compatibility.md) - Understanding Direct Lake modes and T5 view compatibility options
- [Performance Optimization](performance-optimization.md) - Comprehensive performance optimization guide
- [OneLake Architecture](../architecture/pattern-summary.md#onelake-integration) - OneLake in T0-T5 pattern
- [Semantic Layer Analysis](../reference/semantic-layer-analysis.md) - Reverse engineering semantic models
- [Troubleshooting Guide](../operations/troubleshooting-guide.md) - Common Direct Lake issues

---

## Summary

Direct Lake optimization focuses on:

1. **OneLake Integration**: Use Direct Lake for OneLake Parquet files (primary pattern)
2. **Table Selection**: Use Direct Lake for T3._FINAL tables (if in Warehouse)
3. **Aggregation Design**: Create aggregations for common queries (Parquet or views)
4. **DirectQuery Fallback**: Use DirectQuery for T5 views and complex aggregations
5. **Column Optimization**: Select only needed columns
6. **Relationship Optimization**: Use star schema relationships
7. **DAX Optimization**: Write efficient measures
8. **Query Performance**: Optimize queries and monitor performance (see [Performance Optimization](performance-optimization.md))
9. **Cache Management**: Use aggregations to reduce cache size
10. **Dual-Mode**: Leverage automatic DirectQuery fallback
11. **Performance Monitoring**: Monitor and optimize continuously
12. **OneLake Optimization**: Partition, Z-order, and compress Parquet files

**Key Points for OneLake Projects:**
- Direct Lake connects to **OneLake Parquet files** (primary)
- DirectQuery automatically used for **views and complex queries**
- No manual configuration needed for dual-mode
- Optimize Parquet files for Direct Lake performance
- Monitor storage mode assignments and query performance

Follow these patterns to maximize Direct Lake performance in Fabric semantic models using OneLake.
