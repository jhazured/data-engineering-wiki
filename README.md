# Microsoft Fabric Data Warehouse Knowledge Base

[![Last commit](https://img.shields.io/github/last-commit/jhazured/data-engineering-wiki?color=green)](https://github.com/jhazured/data-engineering-wiki)
[![Microsoft Fabric](https://img.shields.io/badge/Microsoft-Fabric-0078D4.svg)](https://learn.microsoft.com/fabric/)
[![Power BI](https://img.shields.io/badge/Power_BI-Direct_Lake-F2C811.svg)](https://powerbi.microsoft.com/)
[![T-SQL](https://img.shields.io/badge/T--SQL-SQL_Server-CC2927.svg)](https://learn.microsoft.com/sql/t-sql/)

## Overview

This knowledge base provides comprehensive documentation for implementing enterprise data warehouses in Microsoft Fabric using the **T0-T5 architecture pattern**. It covers patterns, best practices, and implementation guides for all layers of the architecture.

**Key Technologies:**
- **OneLake**: Unified data lake storage
- **Data Factory**: T1 ingestion pipelines
- **Dataflows Gen2**: T3 transformations
- **Warehouse**: T-SQL stored procedures and views
- **Direct Lake**: High-performance semantic models
- **DirectQuery**: SQL pushdown for complex queries

---

## Prerequisites

### Required Licenses
- **Microsoft Fabric**: F7 (8 CU) or F8 (16 CU) capacity minimum
- **Power BI Pro**: For semantic model and report creation
- **Azure Subscription**: For ADLS Gen2 storage (if using external sources)

**Note**: F7/F8 capacities are suitable for development and small-to-medium workloads. For production, consider F64 or higher for better performance and scalability.

### Required Permissions
- **Workspace Admin** or **Contributor** role in Fabric workspace
- **SQL Database Contributor** (for Warehouse operations)
- **Storage Blob Data Contributor** (for ADLS Gen2 access)
- **Power BI Service Administrator** (for semantic model deployment)

### Required Skills
- **T-SQL**: For stored procedures and views
- **Power Query M**: For Dataflows Gen2 transformations
- **DAX**: For semantic model measures
- **Data Factory**: Basic pipeline creation
- **Git**: For version control

### Required Tools
- **Fabric Portal**: Web-based interface
- **Power BI Desktop**: For semantic model development
- **SQL Server Management Studio (SSMS)** or **Azure Data Studio**: For T-SQL development
- **Git**: For version control

---

## Quick Start

### New to This Pattern?

1. **Start Here**: Read [`fabric/architecture/pattern-summary.md`](fabric/architecture/pattern-summary.md) for architecture overview (~15 min)
2. **Implementation**: Follow [`fabric/architecture/architecture-pattern.md`](fabric/architecture/architecture-pattern.md) for detailed guide (~2 hours)
3. **Technology Distinctions**: Understand [`fabric/reference/technology-distinctions.md`](fabric/reference/technology-distinctions.md) for Data Factory vs Dataflows Gen2 (~10 min)

### Which Document Should I Read?

| Scenario | Primary Document | Reading Time | Additional Resources |
|----------|-----------------|--------------|---------------------|
| **New to T0-T5 pattern** | [`pattern-summary.md`](fabric/architecture/pattern-summary.md) | 15 min | [`quick-start-guide.md`](fabric/reference/quick-start-guide.md) |
| **Implementing new project** | [`architecture-pattern.md`](fabric/architecture/architecture-pattern.md) | 2 hours | [`project-setup-checklist.md`](fabric/templates/project-setup-checklist.md) |
| **Setting up T1 ingestion** | [`data-factory-patterns.md`](fabric/patterns/data-factory-patterns.md) | 45 min | [`lakehouse-patterns.md`](fabric/patterns/lakehouse-patterns.md) |
| **Implementing incremental loading** | [`incremental-loading-strategies.md`](fabric/patterns/incremental-loading-strategies.md) | 60 min | [`data-factory-patterns.md`](fabric/patterns/data-factory-patterns.md), [`warehouse-patterns.md`](fabric/patterns/warehouse-patterns.md) |
| **Implementing T2 SCD2** | [`warehouse-patterns.md`](fabric/patterns/warehouse-patterns.md) | 60 min | [`t-sql-patterns.md`](fabric/patterns/t-sql-patterns.md), [`incremental-loading-strategies.md`](fabric/patterns/incremental-loading-strategies.md) |
| **Implementing T3 transformations** | [`dataflows-gen2-patterns.md`](fabric/patterns/dataflows-gen2-patterns.md) | 60 min | [`technology-distinctions.md`](fabric/reference/technology-distinctions.md) |
| **Setting up Direct Lake** | [`direct-lake-optimization.md`](fabric/optimization/direct-lake-optimization.md) | 45 min | [`architecture-pattern.md`](fabric/architecture/architecture-pattern.md) Phase 7 |
| **Optimizing performance** | [`performance-optimization.md`](fabric/optimization/performance-optimization.md) | 60 min | Layer-specific optimization sections |
| **Setting up security** | [`security-patterns.md`](fabric/operations/security-patterns.md) | 45 min | [`architecture-pattern.md`](fabric/architecture/architecture-pattern.md) |
| **Setting up monitoring** | [`monitoring-observability.md`](fabric/operations/monitoring-observability.md) | 45 min | [`monitoring-queries.sql`](fabric/examples/monitoring-queries.sql) |
| **Troubleshooting issues** | [`troubleshooting-guide.md`](fabric/operations/troubleshooting-guide.md) | 30 min | [`incident-response-playbook.md`](fabric/templates/incident-response-playbook.md) |
| **Setting up deployment** | [`deployment-cicd.md`](fabric/operations/deployment-cicd.md) | 45 min | [`architecture-pattern.md`](fabric/architecture/architecture-pattern.md) Phase 11 |
| **Understanding decisions** | [`architecture-decisions.md`](fabric/reference/architecture-decisions.md) | 30 min | [`adr-template.md`](fabric/templates/adr-template.md) |
| **Looking up terms** | [`glossary.md`](fabric/reference/glossary.md) | 15 min | Reference as needed |

### Common Use Cases

**Setting Up a New Project:**
1. [`fabric/architecture/pattern-summary.md`](fabric/architecture/pattern-summary.md) - Understand architecture
2. [`fabric/architecture/architecture-pattern.md`](fabric/architecture/architecture-pattern.md) - Follow implementation guide
3. [`fabric/operations/deployment-cicd.md`](fabric/operations/deployment-cicd.md) - Set up deployment pipeline

**Implementing T1 Ingestion:**
1. [`fabric/patterns/data-factory-patterns.md`](fabric/patterns/data-factory-patterns.md) - Data Factory patterns
2. [`fabric/patterns/lakehouse-patterns.md`](fabric/patterns/lakehouse-patterns.md) - Lakehouse VARIANT patterns

**Implementing T2 Historical Record:**
1. [`fabric/patterns/warehouse-patterns.md`](fabric/patterns/warehouse-patterns.md) - Warehouse patterns
2. [`fabric/patterns/t-sql-patterns.md`](fabric/patterns/t-sql-patterns.md) - T-SQL stored procedures

**Implementing T3 Transformations:**
1. [`fabric/patterns/dataflows-gen2-patterns.md`](fabric/patterns/dataflows-gen2-patterns.md) - Dataflows Gen2 patterns
2. [`fabric/reference/technology-distinctions.md`](fabric/reference/technology-distinctions.md) - Understand when to use

**Optimizing Performance:**
1. [`fabric/optimization/performance-optimization.md`](fabric/optimization/performance-optimization.md) - Comprehensive performance guide
2. [`fabric/optimization/direct-lake-optimization.md`](fabric/optimization/direct-lake-optimization.md) - Direct Lake optimization (includes OneLake patterns)

**Security and Operations:**
1. [`fabric/operations/security-patterns.md`](fabric/operations/security-patterns.md) - Security implementation
2. [`fabric/operations/monitoring-observability.md`](fabric/operations/monitoring-observability.md) - Monitoring patterns
3. [`fabric/operations/troubleshooting-guide.md`](fabric/operations/troubleshooting-guide.md) - Common issues and solutions

**Reverse Engineering:**
1. [`fabric/reference/semantic-layer-analysis.md`](fabric/reference/semantic-layer-analysis.md) - Tabular Editor and DAX Studio

---

## Documentation Structure

### Architecture Guides

- **[`fabric/architecture/pattern-summary.md`](fabric/architecture/pattern-summary.md)** - High-level architecture pattern overview (~15 min)
- **[`fabric/architecture/architecture-pattern.md`](fabric/architecture/architecture-pattern.md)** - Detailed implementation guide with HR POC example (~2 hours)

### Pattern Guides

- **[`fabric/patterns/data-factory-patterns.md`](fabric/patterns/data-factory-patterns.md)** - Data Factory patterns for T1 ingestion (~45 min)
- **[`fabric/patterns/dataflows-gen2-patterns.md`](fabric/patterns/dataflows-gen2-patterns.md)** - Dataflows Gen2 patterns for T3 transformations (~60 min)
- **[`fabric/patterns/warehouse-patterns.md`](fabric/patterns/warehouse-patterns.md)** - Warehouse patterns for T2/T3/T5 (~60 min)
- **[`fabric/patterns/lakehouse-patterns.md`](fabric/patterns/lakehouse-patterns.md)** - Lakehouse patterns for T1 (~45 min)
- **[`fabric/patterns/t-sql-patterns.md`](fabric/patterns/t-sql-patterns.md)** - T-SQL patterns for stored procedures, error handling, batch processing (~60 min)

### Optimization Guides

- **[`fabric/optimization/performance-optimization.md`](fabric/optimization/performance-optimization.md)** - Comprehensive performance optimization (~60 min)
- **[`fabric/optimization/direct-lake-optimization.md`](fabric/optimization/direct-lake-optimization.md)** - Direct Lake optimization patterns (includes OneLake integration) (~45 min)

### Operations Guides

- **[`fabric/operations/deployment-cicd.md`](fabric/operations/deployment-cicd.md)** - Deployment and CI/CD patterns (~45 min)
- **[`fabric/operations/monitoring-observability.md`](fabric/operations/monitoring-observability.md)** - Monitoring and observability patterns (~45 min)
- **[`fabric/operations/security-patterns.md`](fabric/operations/security-patterns.md)** - Security implementation patterns (~45 min)
- **[`fabric/operations/troubleshooting-guide.md`](fabric/operations/troubleshooting-guide.md)** - Troubleshooting common issues (~30 min)

### Reference Guides

- **[`fabric/reference/technology-distinctions.md`](fabric/reference/technology-distinctions.md)** - Data Factory vs Dataflows Gen2 (~10 min)
- **[`fabric/reference/semantic-layer-analysis.md`](fabric/reference/semantic-layer-analysis.md)** - Reverse engineering Power BI models (~30 min)
- **[`fabric/reference/quick-start-guide.md`](fabric/reference/quick-start-guide.md)** - Quick start guide for new users (~20 min)
- **[`fabric/reference/glossary.md`](fabric/reference/glossary.md)** - Terms and acronyms glossary (~15 min)
- **[`fabric/reference/architecture-decisions.md`](fabric/reference/architecture-decisions.md)** - Architecture decision records (~30 min)

### Diagrams

- **[`fabric/diagrams/architecture-overview.md`](fabric/diagrams/architecture-overview.md)** - High-level architecture diagram (~5 min)
- **[`fabric/diagrams/data-flow.md`](fabric/diagrams/data-flow.md)** - Detailed data flow diagram (~10 min)
- **[`fabric/diagrams/technology-stack.md`](fabric/diagrams/technology-stack.md)** - Technology mapping diagram (~5 min)

### Examples

- **[`fabric/examples/monitoring-queries.sql`](fabric/examples/monitoring-queries.sql)** - Sample monitoring queries
- **[`fabric/examples/stored-procedure-templates.sql`](fabric/examples/stored-procedure-templates.sql)** - T-SQL stored procedure templates

### Templates

- **[`fabric/templates/project-setup-checklist.md`](fabric/templates/project-setup-checklist.md)** - Project setup checklist
- **[`fabric/templates/adr-template.md`](fabric/templates/adr-template.md)** - Architecture Decision Record template
- **[`fabric/templates/incident-response-playbook.md`](fabric/templates/incident-response-playbook.md)** - Incident response playbook

---

## Architecture Overview

```
T0: Control Layer (T-SQL)
  ↓
T1: Lakehouse (Data Factory → VARIANT tables)
  ↓ (shortcuts)
T2: Warehouse (T-SQL stored procedures → SCD2)
  ↓ (Dataflows Gen2)
T3: Warehouse (Dataflows Gen2 → Transformations)
  ↓ (zero-copy clone)
T3._FINAL: Warehouse (Validated snapshots)
  ↓
T5: Warehouse (T-SQL views → Presentation)
  ↓
Semantic Layer (Direct Lake on OneLake + DirectQuery)
  ↓
Power BI Reports
```

**Key Technologies:**
- **T1**: Data Factory (ingestion) + Lakehouse (VARIANT storage in OneLake)
- **T2**: Warehouse (T-SQL stored procedures for SCD2, stored in OneLake)
- **T3**: Warehouse (Dataflows Gen2 for transformations, stored in OneLake)
- **T3._FINAL**: Warehouse (zero-copy clones, Delta/Parquet in OneLake)
- **T5**: Warehouse (T-SQL views)
- **Semantic**: Direct Lake on OneLake (Parquet files) + DirectQuery fallback for views

**Key Architectural Point**: OneLake is the unified storage layer. Both Lakehouse and Warehouse store data in OneLake as Delta/Parquet files. Direct Lake accesses these OneLake Parquet files directly, whether accessed via Warehouse or Lakehouse.

---

## Key Concepts

### T0-T5 Layers

- **T0**: Control layer (logging, configuration, watermarks)
- **T1**: Raw landing (VARIANT columns, transient)
- **T2**: Historical record (SCD2, T-SQL stored procedures)
- **T3**: Transformations (Dataflows Gen2, append-only)
- **T3._FINAL**: Validated snapshots (zero-copy clones)
- **T5**: Presentation layer (T-SQL views)

### Technology Roles

- **Data Factory**: T1 ingestion + pipeline orchestration
- **Dataflows Gen2**: T3 transformations only
- **T-SQL**: T2 stored procedures, error handling, batch processing
- **Direct Lake on OneLake**: OneLake Parquet files → in-memory cache (_FINAL tables)
- **DirectQuery**: T5 views → SQL pushdown (automatic fallback)

---

## Best Practices Summary

### Architecture
- ✅ Use VARIANT columns in T1 for schema flexibility
- ✅ Use T-SQL stored procedures for T2 SCD2 operations
- ✅ Use Dataflows Gen2 for ALL T3 transformations
- ✅ Use zero-copy clones for T3._FINAL tables
- ✅ Use views only in T5 (no base tables)

### Performance
- ✅ Partition large tables by date
- ✅ Use Z-ordering for frequently filtered columns
- ✅ Enable query folding in Dataflows Gen2
- ✅ Create aggregations for common queries
- ✅ Optimize DAX measures

### Operations
- ✅ Log all pipeline executions to T0
- ✅ Implement comprehensive error handling
- ✅ Monitor data quality metrics
- ✅ Set up alerts for failures
- ✅ Use version control for T5 views

---

## New to This Knowledge Base?

**Start Here:**
1. **[Quick Start Guide](fabric/reference/quick-start-guide.md)** (~20 min) - Get started quickly based on your needs
2. **[T0-T5 Pattern Summary](fabric/architecture/pattern-summary.md)** (~15 min) - Understand the architecture
3. **[Glossary](fabric/reference/glossary.md)** (~15 min) - Key terms and concepts

## Supporting Documents

- **[Quick Start Guide](fabric/reference/quick-start-guide.md)** (~20 min) - Quick start for new users
- **[Glossary](fabric/reference/glossary.md)** (~15 min) - Terms and acronyms
- **[Architecture Decisions](fabric/reference/architecture-decisions.md)** (~30 min) - Key architectural decisions and rationale
- **[Technology Distinctions](fabric/reference/technology-distinctions.md)** (~10 min) - Data Factory vs Dataflows Gen2
- **[Architecture Diagrams](fabric/diagrams/)** - Visual architecture representations
- **[Examples](fabric/examples/)** - Sample code and queries
- **[Templates](fabric/templates/)** - Checklists and templates

## Related Documentation

- [Microsoft Fabric Documentation](https://learn.microsoft.com/fabric/)
- [Power Query M Language](https://learn.microsoft.com/power-query-m/)
- [T-SQL Reference](https://learn.microsoft.com/sql/t-sql/)

---

## Contributing

When adding or updating documentation:

1. Follow existing patterns and structure
2. Include code examples with language tags (sql, m, dax, json, python)
3. Add cross-references to related topics
4. Update this README if adding new files
5. Maintain consistency with naming conventions

---

## Last Updated

Documentation last reviewed and updated: February 2026  
**Status**: Comprehensive coverage with cross-references and supporting guides
