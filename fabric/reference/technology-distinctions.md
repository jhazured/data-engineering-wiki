# Technology Distinctions: Data Factory vs Dataflows Gen2

## Overview

This document clarifies the distinct roles of **Data Factory** and **Dataflows Gen2** in the T0-T5 architecture pattern. Understanding these distinctions is critical for proper implementation.

---

## Key Distinctions

### Data Factory: T1 Ingestion

**Primary Role**: Copy data from external sources to T1 Lakehouse

**Responsibilities:**
- Copy data from external sources (ADLS, SQL Server, APIs, etc.)
- Load raw data into T1 Lakehouse VARIANT tables
- Handle various data formats (JSON, XML, CSV, Parquet)
- Manage ingestion orchestration
- Handle data format conversion (e.g., XML to JSON)

**When to Use:**
- Loading data from external systems
- Copying files from storage accounts
- Ingesting data from APIs
- Moving data from on-premises systems
- Initial data landing (T1 layer)

**What Data Factory Does NOT Do:**
- ❌ Business logic transformations
- ❌ Data quality transformations
- ❌ Joins and enrichment
- ❌ Aggregations
- ❌ Star schema modeling

---

### Dataflows Gen2: T3 Transformations

**Primary Role**: Transform data in T3 layer

**Responsibilities:**
- Apply business rules and transformations
- Perform data quality checks
- Join multiple tables
- Enrich data with reference lookups
- Create star schema structures
- Aggregate data for common patterns
- Standardize and clean data

**When to Use:**
- All T3 transformations
- Business logic implementation
- Data quality transformations
- Joins and enrichment
- Aggregations
- Star schema creation

**What Dataflows Gen2 Does NOT Do:**
- ❌ Copy data from external sources (use Data Factory)
- ❌ Execute T-SQL stored procedures (use Data Factory)
- ❌ MERGE operations (data already versioned in T2)

---

## Architecture Flow

### T1 Layer: Data Factory

```
External Sources
  ↓
Data Factory Pipelines
  ├── Copy Activity (JSON from ADLS)
  ├── Copy Activity (XML from ADLS)
  └── Copy Activity (CSV from SQL)
  ↓
T1 Lakehouse VARIANT Tables
  ├── raw_department (VARIANT)
  ├── raw_employee (VARIANT)
  └── raw_payroll (VARIANT)
```

**Data Factory Activities:**
- Copy Data activities
- ForEach activities (for multiple files)
- Script activities (for materialized view refresh)

---

### T3 Layer: Dataflows Gen2

```
T2 Tables (via shortcuts)
  ↓
Dataflows Gen2
  ├── DF_T3_Employee_Base
  │   └── Filter, rename, add derived columns
  ├── DF_T3_Employee_Enriched
  │   └── Join with reference tables
  └── DF_T3_Payroll_Summary
      └── Aggregate by month/department
  ↓
T3 Tables
  ├── t3.employee_base
  ├── t3.employee_enriched
  └── t3.payroll_monthly_summary
```

**Dataflows Gen2 Activities:**
- Power Query transformations
- Joins and merges
- Aggregations
- Data quality transformations
- Star schema creation

---

## Pipeline Orchestration

### Data Factory Master Pipeline

**Data Factory orchestrates the overall flow:**

```
PL_MASTER_HR_Analytics
├── PL_T1_Master_Ingest (Data Factory)
│   ├── Copy data from external sources
│   └── Load to T1 Lakehouse
├── PL_T2_Process_SCD2 (Data Factory)
│   └── Execute T-SQL stored procedures
├── PL_T3_Transform (Data Factory)
│   └── Execute Dataflows Gen2 (triggers transformations)
└── PL_T5_Clone_Refresh (Data Factory)
    └── Execute clone refresh procedures
```

**Key Point**: Data Factory triggers Dataflows Gen2 for T3 transformations, but Dataflows Gen2 performs the actual transformation work.

---

## Comparison Table

| Aspect | Data Factory | Dataflows Gen2 |
|--------|--------------|----------------|
| **Primary Use** | T1 Ingestion | T3 Transformations |
| **Layer** | T1 | T3 |
| **Language** | JSON (pipeline definitions) | M (Power Query) |
| **Activities** | Copy, Execute Pipeline, Script | Transform, Join, Aggregate |
| **Data Movement** | Copy from external to T1 | Transform within T3 |
| **Business Logic** | ❌ No | ✅ Yes |
| **Joins** | ❌ No | ✅ Yes |
| **Aggregations** | ❌ No | ✅ Yes |
| **Data Quality** | ❌ No | ✅ Yes |
| **Star Schema** | ❌ No | ✅ Yes |
| **Orchestration** | ✅ Yes (master pipeline) | ❌ No |

---

## Best Practices

### Data Factory Best Practices

- ✅ Use for copying data from external sources
- ✅ Use for T1 ingestion only
- ✅ Use for pipeline orchestration
- ✅ Handle data format conversion (XML to JSON, etc.)
- ✅ Use Copy activities for data movement
- ❌ Don't use for business logic transformations
- ❌ Don't use for joins or aggregations
- ❌ Don't use for data quality transformations

### Dataflows Gen2 Best Practices

- ✅ Use for ALL T3 transformations
- ✅ Use for business logic implementation
- ✅ Use for joins and enrichment
- ✅ Use for aggregations
- ✅ Use for star schema creation
- ✅ Use append mode (data already versioned in T2)
- ❌ Don't use for copying data from external sources
- ❌ Don't use for MERGE operations
- ❌ Don't use for T1 ingestion

---

## Common Mistakes to Avoid

### Mistake 1: Using Data Factory for Transformations

**Wrong:**
```
Data Factory Pipeline
├── Copy Activity (load data)
└── Data Flow Activity (transform data) ❌
```

**Correct:**
```
Data Factory Pipeline (T1)
├── Copy Activity (load to T1)

Dataflows Gen2 (T3)
└── Transform data from T2
```

### Mistake 2: Using Dataflows Gen2 for Ingestion

**Wrong:**
```
Dataflows Gen2
├── Connect to external SQL Server ❌
└── Load to T1
```

**Correct:**
```
Data Factory Pipeline
├── Copy Activity (external SQL → T1)

Dataflows Gen2
└── Transform from T2 → T3
```

### Mistake 3: Mixing Responsibilities

**Wrong:**
```
Data Factory Pipeline
├── Copy data
├── Transform data ❌
├── Join tables ❌
└── Aggregate data ❌
```

**Correct:**
```
Data Factory Pipeline (T1)
└── Copy data to T1

Dataflows Gen2 (T3)
├── Transform data
├── Join tables
└── Aggregate data
```

---

## Summary

**Clear Separation of Concerns:**

1. **Data Factory**: 
   - **T1 Ingestion** (primary role)
   - Pipeline orchestration (secondary role)
   - Copy data from external sources
   - Load to T1 Lakehouse

2. **Dataflows Gen2**:
   - **T3 Transformations** (only role)
   - Business logic
   - Joins and enrichment
   - Aggregations
   - Star schema creation

**Key Principle**: 
- **Data Factory** = Data movement and ingestion
- **Dataflows Gen2** = Data transformation and business logic

## Related Topics

- [Data Factory Patterns](../patterns/data-factory-patterns.md) - Data Factory implementation patterns
- [Dataflows Gen2 Patterns](../patterns/dataflows-gen2-patterns.md) - Dataflows Gen2 implementation patterns
- [T0-T5 Architecture Pattern](../architecture/architecture-pattern.md) - Architecture implementation guide

---

Follow these distinctions to build maintainable, scalable data pipelines in Fabric.
