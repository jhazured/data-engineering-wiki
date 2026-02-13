# Glossary

## Architecture Terms

### T0-T5 Layers

**T0 (Control Layer)**
- Orchestration, logging, and configuration management layer
- Contains pipeline execution logs, watermarks, error logs
- Technology: Warehouse (T-SQL tables and stored procedures)

**T1 (Lakehouse - Raw Landing)**
- Schema-agnostic raw data landing layer
- Uses VARIANT columns for flexible data storage
- Transient layer (truncated after T2 processing)
- Technology: Lakehouse (Delta tables with VARIANT support)

**T2 (Warehouse - Historical Record)**
- Historical record layer with SCD2 (Slowly Changing Dimension Type 2)
- Maintains full history with effective_date, expiry_date, is_current
- Technology: Warehouse (T-SQL stored procedures)

**T3 (Warehouse - Transformations)**
- Business logic and transformation layer
- Creates star schema structures (facts and dimensions)
- Technology: Dataflows Gen2 (Power Query M language)

**T3._FINAL (Warehouse - Validated Snapshots)**
- Zero-copy clones of T3 tables
- Provides stable snapshots for semantic layer
- Isolated from T3 pipeline failures
- Technology: Warehouse (zero-copy clone feature)

**T5 (Warehouse - Presentation Layer)**
- Business-friendly views for reporting
- Light transformations only
- Technology: Warehouse (SQL views)

---

## Technology Terms

### Data Factory
- Azure Data Factory in Microsoft Fabric
- Used for T1 ingestion (copying data from external sources)
- Also orchestrates overall pipeline flow (T1 → T2 → T3 → T5)

### Dataflows Gen2
- Microsoft Fabric's cloud-based data transformation service
- Uses Power Query (M language)
- Used for ALL T3 transformations
- Runs in Fabric compute

### OneLake
- Microsoft Fabric's unified data lake storage layer
- Single storage location for all Fabric workloads
- Supports Delta/Parquet format
- Open data format (no vendor lock-in)

### Direct Lake
- High-performance analytics mode for semantic models
- Connects to OneLake Parquet files or Warehouse tables
- In-memory caching for fast queries
- No refresh required

### DirectQuery
- SQL pushdown mode for semantic models
- Automatically used for T5 views and complex queries
- Real-time data access
- Automatic fallback when Direct Lake can't handle query

### VARIANT
- Data type for storing semi-structured data
- Used in T1 Lakehouse for schema-agnostic ingestion
- Stores JSON, XML, and other formats without schema changes

### Materialized View
- Pre-computed view stored as a table
- Used in T1 Lakehouse to flatten VARIANT data
- Improves query performance

### Zero-Copy Clone
- Copy-on-write table clone
- No data duplication until changes occur
- Used for T3._FINAL tables
- Provides point-in-time snapshots

### Shortcut
- Reference to data in another location
- Zero-copy access (no data duplication)
- Used from Warehouse to access Lakehouse data

---

## Data Modeling Terms

### SCD2 (Slowly Changing Dimension Type 2)
- Historical tracking pattern for dimensions
- Maintains full history with effective_date, expiry_date, is_current
- Never deletes records, only expires and inserts new versions

### Star Schema
- Data warehouse modeling pattern
- Central fact table with surrounding dimension tables
- Optimized for analytical queries

### Surrogate Key
- System-generated key independent of source systems
- Used in T2 dimensions (e.g., dept_key, emp_key)
- Enables SCD2 historical tracking

### Business Key
- Natural key from source system
- Used to identify records (e.g., dept_id, employee_id)
- Used for SCD2 MERGE operations

### Fact Table
- Central table in star schema
- Contains measures/metrics (e.g., gross_pay, hours)
- Links to dimension tables via foreign keys

### Dimension Table
- Descriptive table in star schema
- Contains attributes (e.g., department name, employee name)
- Links to fact tables via foreign keys

---

## Process Terms

### Incremental Load
- Loading only new or changed data
- Uses watermarks to track last processed timestamp
- More efficient than full load

### Snapshot Load
- Loading complete dataset each time
- Full replacement of data
- May be used initially before transitioning to incremental

### Watermark
- Timestamp or ID tracking last processed record
- Used for incremental loads
- Stored in T0 control layer

### MERGE Operation
- SQL operation combining INSERT, UPDATE, DELETE
- Used for SCD2 in T2 layer
- Single-pass operation for efficiency

### Query Folding
- Pushing query operations to source system
- Optimizes Dataflows Gen2 performance
- Reduces data movement

---

## Security Terms

### RLS (Row-Level Security)
- Security feature restricting data access by row
- Implemented at T5 layer and semantic model
- Uses filter expressions to control access

### Managed Identity
- Azure authentication method
- No credentials to manage
- Recommended for automation

### Service Principal
- Azure AD application identity
- Used for programmatic access
- Requires credentials management

---

## Performance Terms

### Partitioning
- Dividing large tables into smaller parts
- Improves query performance through partition pruning
- Common strategy: partition by date

### Z-Ordering
- Clustering data by multiple columns
- Improves query performance for common filter patterns
- Used in Delta Lake optimization

### Aggregation
- Pre-computed summary data
- Reduces query time for common patterns
- Used in Direct Lake optimization

### Cache
- In-memory storage for frequently accessed data
- Direct Lake uses cache for fast queries
- Automatically managed by Fabric

---

## Operations Terms

### Pipeline
- Data Factory workflow
- Orchestrates data movement and processing
- Contains activities and dependencies

### Dataflow
- Dataflows Gen2 transformation workflow
- Contains Power Query transformations
- Executes in Fabric compute

### Stored Procedure
- T-SQL code stored in database
- Used for SCD2 MERGE operations in T2
- Can be called from Data Factory pipelines

### View
- Virtual table defined by SQL query
- Used in T5 presentation layer
- No data storage, always current

---

## Common Acronyms

- **ADF**: Azure Data Factory
- **ADLS**: Azure Data Lake Storage
- **DAX**: Data Analysis Expressions (Power BI query language)
- **ETL**: Extract, Transform, Load
- **ELT**: Extract, Load, Transform
- **M**: Power Query M language
- **PBI**: Power BI
- **RLS**: Row-Level Security
- **SCD2**: Slowly Changing Dimension Type 2
- **SQL**: Structured Query Language
- **T-SQL**: Transact-SQL (Microsoft SQL Server dialect)

---

## Pattern Terms

### Append Mode
- Adding new records without replacing existing
- Used in T3 Dataflows Gen2 (data already versioned in T2)
- Used in T1 ingestion (no deduplication)

### Replace Mode
- Complete replacement of data
- Used for T3.ref reference tables
- Used for initial snapshot loads

### Upsert Mode
- Insert new records or update existing
- Used when source doesn't support incremental
- More complex than append

---

## Related Topics

- [T0-T5 Pattern Summary](../architecture/pattern-summary.md) - Architecture overview
- [Technology Distinctions](technology-distinctions.md) - Technology roles
- [T0-T5 Architecture Pattern](../architecture/architecture-pattern.md) - Implementation guide
