# T0-T5 Data Warehouse Architecture Pattern for Microsoft Fabric

## Overview

The T0-T5 architecture pattern is a standardized, layered approach to building enterprise data warehouses in Microsoft Fabric. This pattern provides clear separation of concerns, enables incremental data processing, supports historical tracking, and optimizes for both operational and analytical workloads.

**Key Principles:**
- **Separation of Concerns**: Each layer has a distinct purpose and responsibility
- **Incremental Processing**: Support for incremental loads and change tracking
- **Historical Preservation**: Maintain full history through SCD2 (Slowly Changing Dimension Type 2)
- **Zero-Copy Efficiency**: Use shortcuts and clones to avoid data duplication
- **Semantic Layer Optimization**: Enable Direct Lake for high-performance analytics

---

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│ T0: Control Layer                                          │
│ - Pipeline orchestration metadata                          │
│ - Logging and error tracking                              │
│ - Configuration management                                 │
│ - Watermark management                                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ T1: Lakehouse (Raw Landing)                                │
│ - VARIANT-based raw data storage                           │
│ - Schema-agnostic data ingestion                          │
│ - Materialized views for flattening                       │
│ - Transient layer (truncated after T2)                    │
└─────────────────────────────────────────────────────────────┘
                            ↓ (shortcuts)
┌─────────────────────────────────────────────────────────────┐
│ T2: Warehouse (Historical Record)                          │
│ - SCD2 dimension management                                │
│ - Surrogate key generation                                 │
│ - Full historical tracking                                 │
│ - T-SQL stored procedures for MERGE operations            │
└─────────────────────────────────────────────────────────────┘
                            ↓ (Dataflows Gen2)
┌─────────────────────────────────────────────────────────────┐
│ T3: Warehouse (Transformations)                            │
│ - Business logic transformations                          │
│ - Data quality and enrichment                             │
│ - Star schema modeling                                     │
│ - Reference data management                               │
│ - Append-only transformations                             │
└─────────────────────────────────────────────────────────────┘
                            ↓ (zero-copy clone)
┌─────────────────────────────────────────────────────────────┐
│ T3._FINAL: Warehouse (Validated Snapshots)                 │
│ - Zero-copy clones of T3 tables                            │
│ - Isolated from T3 pipeline failures                      │
│ - Point-in-time consistency                               │
│ - Optimized for semantic layer consumption                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ T5: Warehouse (Presentation Layer)                         │
│ - Business-friendly views                                  │
│ - Denormalized structures for reporting                   │
│ - Light transformations only                              │
│ - Version-controlled view definitions                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Semantic Layer (Direct Lake + DirectQuery)                 │
│ - Direct Lake on OneLake Parquet files                    │
│ - Direct Lake on T3._FINAL tables (if in Warehouse)       │
│ - DirectQuery fallback on T5 views                        │
│ - DAX measures and business logic                         │
│ - Automatic dual-mode operation                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Power BI Reports                                           │
│ - End-user analytics                                       │
│ - Self-service BI                                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Layer Descriptions

### T0: Control Layer

**Purpose**: Orchestration, monitoring, and configuration management

**Responsibilities:**
- Track pipeline execution status and timing
- Manage watermarks for incremental loads
- Store configuration parameters and connection strings
- Log errors and data quality issues
- Support pipeline dependency management

**Key Characteristics:**
- Metadata-driven approach
- Supports both scheduled and event-driven pipelines
- Enables retry logic and error handling
- Provides audit trail for data lineage

**Technology**: Warehouse (SQL tables and stored procedures)

---

### T1: Lakehouse (Raw Landing)

**Purpose**: Schema-agnostic raw data ingestion

**Responsibilities:**
- Accept data in any format (JSON, XML, CSV, Parquet)
- Store raw payloads without schema enforcement
- Provide materialized views for initial flattening
- Support rapid schema evolution

**Key Characteristics:**
- **VARIANT columns**: Store semi-structured data without schema changes
- **Materialized views**: Flatten VARIANT data for downstream consumption
- **Transient**: Data truncated after successful T2 processing
- **Timestamped**: All records include ingestion timestamp

**Technology**: 
- **Lakehouse** (Delta tables with VARIANT support)
- **Data Factory** for ingestion pipelines (loads data from external sources to T1)

**Data Flow**: External sources → **Data Factory pipelines** → T1 (raw) → Materialized views → T2 (via shortcuts)

---

### T2: Warehouse (Historical Record)

**Purpose**: Maintain complete historical record with SCD2

**Responsibilities:**
- Implement SCD2 (Slowly Changing Dimension Type 2) for dimensions
- Generate surrogate keys
- Track effective dates and current status
- Support incremental fact table loads
- Maintain referential integrity

**Key Characteristics:**
- **SCD2 Dimensions**: Full history with effective_date, expiry_date, is_current
- **Surrogate Keys**: System-generated keys independent of source systems
- **T-SQL MERGE**: Stored procedures handle all SCD2 logic
- **T-SQL Error Handling**: Comprehensive error handling in stored procedures
- **T-SQL Temp Tables**: Temporary tables for batch processing and intermediate results
- **T-SQL Batch Processing**: Batch operations for large datasets
- **Watermark-based**: Incremental loads using timestamps (after initial snapshot)
- **Historical Preservation**: Never delete, only expire and insert new versions

**Technology**: Warehouse (T-SQL stored procedures, error handling, temp tables, batch processing)

**Data Flow**: T1 shortcuts → T2 MERGE procedures → Historical tables

**Initial Load Strategy**: 
- **Snapshot Loading**: Initially, daily full snapshots may be loaded to T1 raw layer
- **Incremental Loading**: After initial load, switch to incremental/watermark-based loading

---

### T3: Warehouse (Transformations)

**Purpose**: Business logic, data quality, and star schema modeling

**Responsibilities:**
- Apply business rules and transformations
- Enrich data with reference lookups
- Create star schema structures (facts and dimensions)
- Perform data quality checks
- Aggregate data for common patterns

**Key Characteristics:**
- **Dataflows Gen2**: All transformations via Power Query (M language) - **PRIMARY TOOL**
- **Append-only**: No MERGE operations (data already versioned in T2)
- **Reference Data**: T3.ref tables for lookups and mappings
- **Star Schema**: Properly modeled facts and dimensions
- **Read-and-Transform**: Reads from T2, transforms, writes to T3

**Technology**: 
- **Dataflows Gen2** for all transformations (Power Query M language)
- **Warehouse** for storing transformed data

**Data Flow**: T2 tables → **Dataflows Gen2** → T3 tables

**Sub-patterns:**
- **T3.ref**: Reference data (lookup tables, mappings)
- **T3.table_01**: Base transformations (filtering, renaming, data type conversion)
- **T3.table_02**: Joins and enrichment (combining multiple sources)
- **T3.agg_01**: Aggregations (pre-computed summaries)

---

### T3._FINAL: Warehouse (Validated Snapshots)

**Purpose**: Provide stable, validated snapshots for semantic layer consumption

**Responsibilities:**
- Create point-in-time consistent snapshots
- Isolate semantic layer from T3 pipeline failures
- Enable zero-copy efficiency through cloning
- Support semantic model refresh cycles

**Key Characteristics:**
- **Zero-Copy Clones**: Copy-on-write semantics, no data duplication
- **Isolation**: T3 pipeline failures don't affect _FINAL tables
- **Refresh Strategy**: Drop and recreate clones after successful T3 completion
- **Naming Convention**: All tables end with _FINAL suffix
- **Schema Location**: Clones exist in T3 schema (not separate schema)

**Technology**: Warehouse (Zero-copy clone feature)

**Data Flow**: T3 tables → Clone refresh procedure → T3._FINAL tables

---

### T5: Warehouse (Presentation Layer)

**Purpose**: Business-friendly views optimized for reporting

**Responsibilities:**
- Provide intuitive column names and structures
- Denormalize for common reporting patterns
- Support row-level security (RLS) requirements
- Enable DirectQuery fallback for complex queries

**Key Characteristics:**
- **Views Only**: No base tables in T5
- **Business Naming**: User-friendly column and table names
- **Light Transformations**: Minimal logic, primarily formatting
- **Version Controlled**: View definitions stored in git, deployed via CI/CD
- **RLS Ready**: Structured to support security filtering

**Technology**: Warehouse (SQL views)

**Data Flow**: T3._FINAL tables → T5 views → Semantic layer (DirectQuery)

---

### Semantic Layer (Direct Lake + DirectQuery)

**Purpose**: High-performance analytics layer for Power BI

**Responsibilities:**
- Expose data model to Power BI reports
- Implement business logic via DAX measures
- Support automatic dual-mode operation
- Enable Direct Lake caching for performance

**Key Characteristics:**
- **Direct Lake Mode**: OneLake Parquet files cached in-memory (primary)
- **Direct Lake Mode**: T3._FINAL tables (if in Warehouse) cached in-memory
- **DirectQuery Fallback**: T5 views automatically use DirectQuery
- **DirectQuery Fallback**: Complex aggregations automatically use DirectQuery
- **DAX Measures**: Business calculations stay in semantic layer
- **Automatic Optimization**: No manual configuration needed
- **Deployment Rules**: Support Dev/Test/Prod environment mapping

**Technology**: Fabric Semantic Model (Direct Lake on OneLake/SQL)

**⚠️ Important**: See [Direct Lake Modes & T5 View Compatibility](../reference/direct-lake-modes-t5-compatibility.md) for comprehensive guidance on choosing between Direct Lake on OneLake vs Direct Lake on SQL Endpoints, and the Hybrid T5 approach for maximum flexibility.

**Data Flow**: 
- **OneLake Parquet files** → Direct Lake (in-memory cache)
- **T3._FINAL tables** (if in Warehouse) → Direct Lake (in-memory cache)
- **T5 views** → DirectQuery (SQL pushdown)
- **Complex aggregations** → DirectQuery (automatic fallback)

---

## Data Flow Patterns

### Standard Flow

1. **Ingestion**: External sources → T1 (raw VARIANT storage)
2. **Flattening**: T1 raw tables → T1 materialized views
3. **Historical Load**: T1 shortcuts → T2 MERGE procedures → Historical tables
4. **Transformation**: T2 tables → T3 Dataflows Gen2 → Transformed tables
5. **Snapshot**: T3 tables → Clone refresh → T3._FINAL tables
6. **Presentation**: T3._FINAL tables → T5 views (if needed)
7. **Analytics**: T3._FINAL tables → Semantic model → Power BI reports

### Incremental Load Pattern

- **T1**: Always append (no deduplication)
- **T2**: MERGE operations handle updates (SCD2)
- **T3**: Append-only (data already versioned in T2)
- **T3._FINAL**: Full refresh via clone recreation
- **T5**: Views automatically reflect latest _FINAL data

### Error Handling Pattern

- **T1 Truncation**: Only after successful T2 completion
- **T2 Rollback**: Failed MERGE operations don't commit
- **T3 Isolation**: Failed transformations don't affect _FINAL
- **T3._FINAL Stability**: Clone refresh only on successful T3 completion

---

## Key Architectural Decisions

### Why VARIANT in T1?

- **Schema Flexibility**: Accept schema changes without table alterations
- **Rapid Ingestion**: No need to define schema upfront
- **Multi-Format Support**: Handle JSON, XML, CSV in same structure
- **Schema Evolution**: Adapt to source system changes automatically

### Why SCD2 in T2?

- **Historical Analysis**: Track changes over time
- **Audit Requirements**: Maintain complete change history
- **Point-in-Time Queries**: Answer "what was the state at time X?"
- **Compliance**: Meet regulatory requirements for data retention

### Why Dataflows Gen2 in T3?

- **No Code Approach**: Visual transformations reduce errors
- **Power Query Familiarity**: Leverage existing M language skills
- **Version Control**: Dataflow definitions can be exported and versioned
- **Reusability**: Dataflows can be shared across projects

### Why Zero-Copy Clones for _FINAL?

- **Storage Efficiency**: No data duplication until changes occur
- **Performance**: Fast clone creation (metadata operation)
- **Isolation**: T3 failures don't corrupt semantic layer
- **Consistency**: Point-in-time snapshots ensure consistent queries

### Why Views in T5?

- **No Storage Overhead**: Views don't store data
- **Always Current**: Automatically reflect latest _FINAL data
- **Flexibility**: Easy to modify without data migration
- **Security**: Can apply RLS at view level

### Why Direct Lake on OneLake?

- **Performance**: In-memory caching of OneLake Parquet files for fast queries
- **OneLake Integration**: Direct access to Parquet files in unified storage layer
- **Automatic Optimization**: Query engine optimizes automatically
- **Dual-Mode**: Seamless fallback to DirectQuery for views/complex queries
- **No Import**: Direct access to OneLake data without refresh
- **Zero-Copy**: Leverages OneLake as single source of truth

**Note**: DirectQuery is used automatically for T5 views and when Direct Lake cannot handle specific query patterns. Both Direct Lake and DirectQuery access the same OneLake storage layer - Direct Lake reads Parquet files directly, while DirectQuery accesses via Warehouse SQL endpoint.

---

## Naming Conventions

### Schemas
- `t0`: Control layer tables
- `t2`: Historical record tables
- `t3`: Transformation tables
- `t5`: Presentation views

### Tables
- `t2.dim_*`: Dimension tables (SCD2)
- `t2.fact_*`: Fact tables
- `t3.ref_*`: Reference/lookup tables
- `t3.*_base`: Base transformation tables
- `t3.*_enriched`: Enriched/joined tables
- `t3.*_FINAL`: Validated snapshot clones
- `t5.vw_*`: Presentation views

### Procedures
- `t2.usp_merge_dim_*`: SCD2 MERGE procedures
- `t2.usp_load_fact_*`: Fact table load procedures
- `t3.usp_refresh_final_clones`: Clone refresh procedure

### Pipelines
- `PL_T1_*`: T1 ingestion pipelines
- `PL_T2_*`: T2 historical load pipelines
- `PL_T3_*`: T3 transformation pipelines
- `PL_T5_*`: T5 clone refresh pipelines
- `PL_MASTER_*`: End-to-end orchestration

---

## Technology Stack

| Layer | Primary Technology | Secondary Technology |
|-------|-------------------|---------------------|
| T0 | Warehouse (SQL) | Data Factory (orchestration) |
| T1 | Lakehouse (Delta) | Materialized Views |
| T2 | Warehouse (T-SQL) | Stored Procedures |
| T3 | Dataflows Gen2 (M) | Warehouse (SQL) |
| T3._FINAL | Warehouse (Clones) | - |
| T5 | Warehouse (Views) | SQL |
| Semantic | Direct Lake | DAX |

---

## Benefits of This Pattern

### Scalability
- **Horizontal Scaling**: Each layer can scale independently
- **Incremental Processing**: Only process changed data
- **Parallel Execution**: T3 transformations can run in parallel

### Maintainability
- **Clear Boundaries**: Each layer has distinct responsibilities
- **Version Control**: View definitions and dataflows in git
- **Documentation**: Pattern provides self-documenting structure

### Performance
- **Direct Lake**: In-memory caching for fast queries
- **Zero-Copy**: Efficient storage utilization
- **Optimized Queries**: Star schema enables query optimization

### Reliability
- **Error Isolation**: Failures in one layer don't cascade
- **Historical Preservation**: Never lose data through SCD2
- **Audit Trail**: Complete lineage from T0 logging

### Flexibility
- **Schema Evolution**: VARIANT absorbs source changes
- **Multi-Source**: Support diverse data formats
- **Deployment**: Support Dev/Test/Prod environments

---

## When to Use This Pattern

### Ideal Scenarios
- Enterprise data warehouse requiring historical tracking
- Multiple source systems with varying schemas
- Need for both operational and analytical workloads
- Compliance requirements for data retention
- Complex transformation logic requiring visual tools

### Alternative Patterns
- **Simple ETL**: For straightforward, single-source scenarios
- **Data Mart**: For department-specific analytics
- **Real-Time**: For streaming/event-driven requirements (consider T0 event triggers)

---

## Common Variations

### T4 Layer (Optional)
Some implementations include a T4 layer for:
- Pre-aggregated summaries
- Data marts for specific business units
- Specialized reporting structures

**Note**: In this pattern, T4 functionality is handled by T5 views or T3 aggregations.

### T0 Event-Driven Triggers
T0 can be extended to support:
- Event-driven pipeline execution
- Real-time data ingestion triggers
- Change data capture (CDC) integration

### Hybrid Storage Modes
- Some tables may use DirectQuery instead of Direct Lake
- T5 views automatically use DirectQuery
- Semantic model handles dual-mode automatically

---

## Migration Considerations

### From Traditional Data Warehouse
- Map existing ETL to T3 Dataflows Gen2
- Convert stored procedures to T2 MERGE logic
- Migrate views to T5 layer
- Recreate semantic model with Direct Lake

### From Power BI Import Models
- Extract metadata using Tabular Editor
- Map calculated columns to T3 transformations
- Migrate measures to semantic layer
- Convert Import mode to Direct Lake

### From Azure Synapse
- Leverage existing T-SQL in T2 layer
- Migrate notebooks to Dataflows Gen2
- Use existing lakehouse as T1 source
- Adapt semantic models to Direct Lake

---

## Best Practices

### Do's
- ✅ Use VARIANT in T1 for schema flexibility
- ✅ Implement SCD2 in T2 for historical tracking
- ✅ Use Dataflows Gen2 for all T3 transformations
- ✅ Create _FINAL clones after successful T3 completion
- ✅ Store T5 view definitions in version control
- ✅ Use Direct Lake for semantic model performance
- ✅ Implement T0 logging for observability

### Don'ts
- ❌ Don't use notebooks in T3 (use Dataflows Gen2)
- ❌ Don't perform MERGE operations in T3 (data already versioned)
- ❌ Don't store base tables in T5 (views only)
- ❌ Don't skip T3._FINAL layer (provides isolation)
- ❌ Don't mix storage modes unnecessarily
- ❌ Don't truncate T1 before T2 success confirmation

---

## Summary

The T0-T5 architecture pattern provides a comprehensive, scalable approach to building enterprise data warehouses in Microsoft Fabric. By clearly defining the purpose and responsibilities of each layer, this pattern enables:

- **Reliable Data Processing**: With error isolation and historical preservation
- **Performance Optimization**: Through Direct Lake and zero-copy clones
- **Maintainable Code**: With clear boundaries and version control
- **Scalable Architecture**: Supporting growth from POC to production

This pattern serves as a reference architecture that can be adapted to specific business requirements while maintaining core principles of separation of concerns, incremental processing, and historical tracking.

## Related Topics

- [T0-T5 Architecture Pattern](architecture-pattern.md) - Detailed implementation guide
- [Technology Distinctions](../reference/technology-distinctions.md) - Data Factory vs Dataflows Gen2
- [Data Factory Patterns](../patterns/data-factory-patterns.md) - T1 ingestion patterns
- [Dataflows Gen2 Patterns](../patterns/dataflows-gen2-patterns.md) - T3 transformation patterns
- [Warehouse Patterns](../patterns/warehouse-patterns.md) - T2/T3/T5 Warehouse patterns
- [Lakehouse Patterns](../patterns/lakehouse-patterns.md) - T1 Lakehouse patterns
- [T-SQL Patterns](../patterns/t-sql-patterns.md) - T-SQL patterns for T2
- [Direct Lake Optimization](../optimization/direct-lake-optimization.md) - Semantic layer optimization
