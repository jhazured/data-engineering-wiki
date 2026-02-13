# Lakehouse Patterns and Best Practices

## Overview

Microsoft Fabric Lakehouse provides a unified data platform combining the flexibility of data lakes with the performance and reliability of data warehouses. This guide covers patterns and best practices for using Lakehouse in the T0-T5 architecture pattern, focusing on the T1 raw landing layer and beyond.

**Key Characteristics:**
- Delta Lake format (open standard)
- VARIANT support for semi-structured data
- Materialized views for performance
- Shortcuts for zero-copy access
- SQL and Spark APIs

---

## Architecture Context

### Role in T0-T5 Pattern

**T1 Layer**: Primary use of Lakehouse for raw data landing
- VARIANT-based raw data storage
- Schema-agnostic ingestion
- Materialized views for flattening
- Transient layer (truncated after T2)

**Additional Uses**:
- Long-term data archival
- Data science workloads
- Multi-format data storage

---

## Pattern 1: VARIANT-Based Raw Landing (T1)

### When to Use

- Schema-agnostic data ingestion
- Rapid schema evolution
- Multi-format data (JSON, XML, CSV)
- Unknown or changing schemas

### Implementation Pattern

**Create VARIANT Table:**

```sql
CREATE TABLE raw_department (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    source_file STRING,
    payload VARIANT
);
```

**Insert JSON Data:**

```sql
INSERT INTO raw_department (source_file, payload)
SELECT 
    'dim_department.json' AS source_file,
    PARSE_JSON($1) AS payload
FROM VALUES
    ('{"dept_id": "D001", "dept_name": "Engineering", "division_id": "DIV1"}'),
    ('{"dept_id": "D002", "dept_name": "Sales", "division_id": "DIV2"}');
```

**Query VARIANT Data:**

```sql
SELECT
    id,
    ingested_at,
    payload:dept_id::STRING AS dept_id,
    payload:dept_name::STRING AS dept_name,
    payload:division_id::STRING AS division_id
FROM raw_department;
```

### Best Practices

- ✅ Use VARIANT for T1 raw landing
- ✅ Include ingestion timestamp
- ✅ Store source file name for traceability
- ✅ Use materialized views for frequent queries
- ✅ Document VARIANT structure
- ❌ Don't query VARIANT directly in production (use materialized views)
- ❌ Don't store VARIANT data indefinitely (move to typed tables in T2)

---

## Pattern 2: Materialized Views for Flattening

### When to Use

- Frequent queries on VARIANT data
- Performance optimization
- Consistent schema access
- Downstream consumption

### Implementation Pattern

**Create Materialized View:**

```sql
CREATE MATERIALIZED VIEW mv_department AS
SELECT
    id,
    ingested_at,
    payload:dept_id::STRING AS dept_id,
    payload:dept_name::STRING AS dept_name,
    payload:division_id::STRING AS division_id,
    payload:division_name::STRING AS division_name,
    payload:cost_center::STRING AS cost_center,
    payload:location::STRING AS location
FROM raw_department;
```

**Refresh Materialized View:**

```sql
REFRESH MATERIALIZED VIEW mv_department;
```

**Query Materialized View:**

```sql
SELECT * FROM mv_department WHERE dept_id = 'D001';
```

### Best Practices

- ✅ Create materialized views for all VARIANT tables
- ✅ Refresh materialized views after data loads
- ✅ Use materialized views for downstream shortcuts
- ✅ Document materialized view schemas
- ✅ Monitor materialized view refresh performance
- ❌ Don't query VARIANT tables directly in production
- ❌ Don't skip materialized view refresh

---

## Pattern 3: Delta Lake Optimization

### Partitioning Strategy

**Partition by Date:**

```sql
CREATE TABLE raw_sales_partitioned (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    sale_date DATE,
    payload VARIANT
)
USING DELTA
PARTITIONED BY (sale_date);
```

**Partition by Multiple Columns:**

```sql
CREATE TABLE raw_transactions_partitioned (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    transaction_date DATE,
    region STRING,
    payload VARIANT
)
USING DELTA
PARTITIONED BY (transaction_date, region);
```

### Z-Ordering (Clustering)

**Z-Order by Frequently Queried Columns:**

```sql
CREATE TABLE raw_sales_optimized (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    sale_date DATE,
    customer_id STRING,
    product_id STRING,
    payload VARIANT
)
USING DELTA
PARTITIONED BY (sale_date)
CLUSTER BY (customer_id, product_id);
```

### Best Practices

- ✅ Partition by date for time-series data
- ✅ Use Z-ordering for frequently filtered columns
- ✅ Balance partition count (not too many, not too few)
- ✅ Monitor partition sizes
- ✅ Consider partition pruning in queries
- ❌ Don't over-partition (too many small partitions)
- ❌ Don't partition by high-cardinality columns

---

## Pattern 4: Schema Evolution

### Adding Columns

**Add New Column to VARIANT:**

```sql
-- No schema change needed for VARIANT
-- New fields in JSON automatically available
INSERT INTO raw_department (source_file, payload)
VALUES (
    'dim_department_v2.json',
    PARSE_JSON('{"dept_id": "D003", "dept_name": "Marketing", "new_field": "value"}')
);
```

**Update Materialized View:**

```sql
-- Drop and recreate materialized view
DROP MATERIALIZED VIEW IF EXISTS mv_department;

CREATE MATERIALIZED VIEW mv_department AS
SELECT
    id,
    ingested_at,
    payload:dept_id::STRING AS dept_id,
    payload:dept_name::STRING AS dept_name,
    payload:division_id::STRING AS division_id,
    payload:new_field::STRING AS new_field  -- New field added
FROM raw_department;
```

### Handling Schema Changes

**Pattern: Backward-Compatible Changes**

```sql
-- Handle optional fields
SELECT
    payload:dept_id::STRING AS dept_id,
    payload:dept_name::STRING AS dept_name,
    COALESCE(payload:new_field::STRING, 'default') AS new_field
FROM raw_department;
```

### Best Practices

- ✅ Use VARIANT for schema flexibility
- ✅ Update materialized views when schema changes
- ✅ Handle missing fields gracefully
- ✅ Document schema evolution
- ✅ Version control schema changes
- ❌ Don't break backward compatibility unnecessarily
- ❌ Don't ignore schema changes

---

## Pattern 5: Time Travel and Versioning

### Query Historical Versions

**Query Specific Version:**

```sql
SELECT * FROM raw_department VERSION AS OF 5;
```

**Query Timestamp:**

```sql
SELECT * FROM raw_department TIMESTAMP AS OF '2024-01-15 10:00:00';
```

**List Versions:**

```sql
DESCRIBE HISTORY raw_department;
```

### Restore Previous Version

```sql
RESTORE TABLE raw_department TO VERSION AS OF 5;
```

### Best Practices

- ✅ Use time travel for data recovery
- ✅ Document version retention policy
- ✅ Monitor version count
- ✅ Use versions for audit trails
- ✅ Clean up old versions periodically
- ❌ Don't rely on time travel for long-term backup
- ❌ Don't accumulate too many versions

---

## Pattern 6: Merge Operations

### Upsert Pattern

**Merge Based on Key:**

```sql
MERGE INTO raw_department AS target
USING (
    SELECT 
        'D001' AS dept_id,
        PARSE_JSON('{"dept_id": "D001", "dept_name": "Engineering Updated"}') AS payload
) AS source
ON target.payload:dept_id::STRING = source.dept_id
WHEN MATCHED THEN
    UPDATE SET payload = source.payload, ingested_at = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN
    INSERT (source_file, payload) VALUES ('update.json', source.payload);
```

### Best Practices

- ✅ Use MERGE for upsert operations
- ✅ Include timestamp updates on match
- ✅ Handle both INSERT and UPDATE cases
- ✅ Use appropriate match conditions
- ✅ Monitor MERGE performance
- ❌ Don't use MERGE in T1 (use in T2)
- ❌ Don't MERGE without proper keys

---

## Pattern 7: Streaming Data Ingestion

### Structured Streaming Pattern

**Create Streaming Table:**

```sql
CREATE TABLE raw_events_streaming (
    event_id STRING,
    event_timestamp TIMESTAMP,
    event_data VARIANT
)
USING DELTA;
```

**Stream from Event Hub:**

```python
# PySpark example
df = spark.readStream \
    .format("eventhubs") \
    .options(**event_hub_config) \
    .load()

df.writeStream \
    .format("delta") \
    .outputMode("append") \
    .option("checkpointLocation", "/checkpoints/events") \
    .table("raw_events_streaming")
```

### Best Practices

- ✅ Use streaming for real-time data
- ✅ Configure checkpoint locations
- ✅ Handle streaming failures gracefully
- ✅ Monitor streaming lag
- ✅ Use appropriate output modes
- ❌ Don't use streaming for batch workloads
- ❌ Don't skip checkpoint configuration

---

## Pattern 8: Shortcuts for Zero-Copy Access

### Create Shortcut from Warehouse

**In Warehouse SQL:**

```sql
CREATE SHORTCUT t1_department
IN SCHEMA dbo
FROM LAKEHOUSE 'T1_DATA_LAKE'
TABLE 'mv_department';
```

**Query Shortcut:**

```sql
SELECT * FROM t1_department;
```

### Best Practices

- ✅ Use shortcuts for zero-copy access
- ✅ Create shortcuts to materialized views (not VARIANT tables)
- ✅ Document shortcut dependencies
- ✅ Use consistent naming conventions
- ✅ Monitor shortcut performance
- ❌ Don't create shortcuts to VARIANT tables directly
- ❌ Don't create circular shortcuts

---

## Pattern 9: Data Retention and Cleanup

### Retention Policy

**Delete Old Data:**

```sql
DELETE FROM raw_department 
WHERE ingested_at < DATEADD(DAY, -90, CURRENT_TIMESTAMP());
```

**Vacuum Old Files:**

```sql
VACUUM raw_department RETAIN 168 HOURS;
```

**Optimize Table:**

```sql
OPTIMIZE raw_department;
```

### Best Practices

- ✅ Implement data retention policies
- ✅ Vacuum old files regularly
- ✅ Optimize tables after large writes
- ✅ Monitor storage usage
- ✅ Document retention policies
- ❌ Don't retain data indefinitely
- ❌ Don't skip optimization for large tables

---

## Pattern 10: Security and Access Control

### Row-Level Security

**Create RLS Policy:**

```sql
CREATE ROW LEVEL SECURITY POLICY rls_department
ON raw_department
USING (payload:division_id::STRING = CURRENT_USER());
```

### Column-Level Security

**Grant Column Access:**

```sql
GRANT SELECT (id, ingested_at, payload:dept_id::STRING) 
ON raw_department 
TO ROLE analyst_role;
```

### Best Practices

- ✅ Implement RLS for sensitive data
- ✅ Use column-level security when needed
- ✅ Grant minimal required permissions
- ✅ Document security policies
- ✅ Test security policies regularly
- ❌ Don't grant excessive permissions
- ❌ Don't skip security for sensitive data

---

## Pattern 11: Performance Optimization

**See [Performance Optimization](../optimization/performance-optimization.md) for comprehensive performance optimization guide.**

**Lakehouse-Specific Quick Tips:**
- Use partition pruning in queries (partition by date)
- Leverage Z-ordering for frequently filtered columns
- Use materialized views for frequent VARIANT queries
- Monitor query performance
- Optimize Delta tables regularly

**Key Strategies:**
1. **Partitioning**: Partition large tables by date (see Pattern 3)
2. **Z-Ordering**: Z-order by frequently queried columns (see Pattern 3)
3. **Materialized Views**: Use for VARIANT queries (see Pattern 2)
4. **Query Optimization**: Filter on partitioned columns, not VARIANT paths

---

## Pattern 12: Multi-Format Support

### Handling Different Formats

**JSON:**

```sql
CREATE TABLE raw_json_data (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    payload VARIANT
);
```

**Parquet:**

```sql
CREATE TABLE raw_parquet_data
USING DELTA
LOCATION '/path/to/parquet/files';
```

**CSV:**

```sql
CREATE TABLE raw_csv_data (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    col1 STRING,
    col2 INT,
    col3 DECIMAL(10,2)
)
USING DELTA;
```

### Best Practices

- ✅ Use VARIANT for JSON/XML
- ✅ Use typed tables for CSV/Parquet
- ✅ Choose format based on use case
- ✅ Document format choices
- ✅ Consider query patterns when choosing format
- ❌ Don't use VARIANT for structured data
- ❌ Don't mix formats unnecessarily

---

## Related Topics

- [Performance Optimization](../optimization/performance-optimization.md) - Comprehensive performance optimization guide
- [Data Factory Patterns](data-factory-patterns.md) - T1 ingestion patterns
- [Warehouse Patterns](warehouse-patterns.md) - Warehouse patterns (uses shortcuts to Lakehouse)
- [T0-T5 Architecture Pattern](../architecture/t0-t5-architecture-pattern.md) - Detailed implementation guide

---

## Summary

Lakehouse patterns in the T0-T5 architecture focus on:

1. **T1 VARIANT Landing**: Schema-agnostic raw data storage
2. **Materialized Views**: Performance optimization for VARIANT queries
3. **Delta Lake Optimization**: Partitioning and Z-ordering
4. **Schema Evolution**: Handling changing schemas gracefully
5. **Time Travel**: Versioning and recovery capabilities
6. **Shortcuts**: Zero-copy access from Warehouse
7. **Security**: RLS and access control
8. **Performance**: Query optimization strategies (see [Performance Optimization](../optimization/performance-optimization.md))

Follow these patterns to build efficient, scalable Lakehouse implementations in Fabric.
