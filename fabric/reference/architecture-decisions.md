# Architecture Decision Records

## Overview

This document records key architectural decisions for the T0-T5 data warehouse pattern in Microsoft Fabric, including rationale, trade-offs, and alternatives considered.

---

## ADR-001: Use Data Factory for T1 Ingestion

**Status**: Accepted  
**Date**: 2026-02-13  
**Context**: Need to copy raw data from external sources to T1 Lakehouse

**Decision**: Use Azure Data Factory exclusively for T1 ingestion (copying data from external sources to Lakehouse).

**Rationale**:
- Data Factory is optimized for data movement
- Supports wide variety of sources (ADLS, SQL, APIs, etc.)
- Handles various data formats (JSON, XML, CSV, Parquet)
- Provides robust error handling and retry logic
- Integrates well with Fabric services

**Alternatives Considered**:
- **Dataflows Gen2**: Not designed for data movement, better for transformations
- **Notebooks**: Too complex for simple copy operations, harder to maintain
- **Custom scripts**: Less maintainable, no built-in error handling

**Consequences**:
- Clear separation: Data Factory = ingestion, Dataflows Gen2 = transformations
- Easy to maintain and monitor
- Standardized approach across projects

**Related**: [Technology Distinctions](technology-distinctions.md), [Data Factory Patterns](../patterns/data-factory-patterns.md)

---

## ADR-002: Use Dataflows Gen2 for T3 Transformations

**Status**: Accepted  
**Date**: 2026-02-13  
**Context**: Need to transform data in T3 layer (business logic, joins, aggregations)

**Decision**: Use Dataflows Gen2 exclusively for ALL T3 transformations.

**Rationale**:
- Visual, no-code/low-code interface reduces errors
- Power Query M language is familiar to many data professionals
- Supports complex transformations (joins, aggregations, data quality)
- Integrates well with Warehouse
- Version control support

**Alternatives Considered**:
- **T-SQL**: Too low-level, harder to maintain, less visual
- **Notebooks**: Not recommended for T3, better for data science workloads
- **Data Factory**: Designed for data movement, not transformations

**Consequences**:
- All T3 transformations use same tool (consistency)
- Easier for business users to understand and modify
- Clear separation from T2 (T-SQL) and T1 (Data Factory)

**Related**: [Technology Distinctions](technology-distinctions.md), [Dataflows Gen2 Patterns](../patterns/dataflows-gen2-patterns.md)

---

## ADR-003: Use T-SQL for T2 Stored Procedures

**Status**: Accepted  
**Date**: 2026-02-13  
**Context**: Need to implement SCD2 MERGE operations in T2 layer

**Decision**: Use T-SQL stored procedures for all SCD2 MERGE operations in T2 layer.

**Rationale**:
- T-SQL MERGE statement is efficient for SCD2 operations
- Stored procedures provide transaction management
- Error handling is comprehensive in T-SQL
- Batch processing capabilities
- Performance optimization through indexes

**Alternatives Considered**:
- **Dataflows Gen2**: Not suitable for MERGE operations, append-only in T3
- **Notebooks**: Too complex, harder to maintain, less performant
- **Data Factory**: Not designed for complex SQL operations

**Consequences**:
- Efficient SCD2 operations
- Comprehensive error handling
- Batch processing support
- Clear separation: T-SQL for T2, Dataflows Gen2 for T3

**Related**: [T-SQL Patterns](../patterns/t-sql-patterns.md), [Warehouse Patterns](../patterns/warehouse-patterns.md)

---

## ADR-004: Use VARIANT Columns in T1

**Status**: Accepted  
**Date**: 2026-02-13  
**Context**: Need schema-agnostic raw data landing

**Decision**: Use VARIANT columns in T1 Lakehouse for raw data storage.

**Rationale**:
- Absorbs schema changes without table alterations
- Supports multiple data formats (JSON, XML, CSV)
- Rapid ingestion without schema definition
- Materialized views provide typed access

**Alternatives Considered**:
- **Typed Tables**: Require schema changes for every source change
- **String Storage**: Less efficient, harder to query
- **Separate Tables per Format**: More complex, harder to manage

**Consequences**:
- Flexible schema evolution
- Rapid ingestion
- Materialized views needed for performance
- Transient layer (truncated after T2)

**Related**: [Lakehouse Patterns](../patterns/lakehouse-patterns.md#pattern-1-variant-based-raw-landing-t1)

---

## ADR-005: Use Zero-Copy Clones for T3._FINAL

**Status**: Accepted  
**Date**: 2026-02-13  
**Context**: Need stable snapshots for semantic layer without data duplication

**Decision**: Use zero-copy clones for T3._FINAL tables.

**Rationale**:
- No data duplication until changes occur (storage efficient)
- Fast clone creation (metadata operation)
- Isolates semantic layer from T3 pipeline failures
- Point-in-time consistency

**Alternatives Considered**:
- **Physical Copy**: Data duplication, slower, more storage
- **Views**: Not stable, affected by T3 changes
- **Materialized Views**: More complex, still affected by source changes

**Consequences**:
- Efficient storage utilization
- Stable snapshots for semantic layer
- Isolation from T3 failures
- Requires clone refresh procedure

**Related**: [Warehouse Patterns](../patterns/warehouse-patterns.md#pattern-3-zero-copy-clones-t3_final)

---

## ADR-006: Use Direct Lake on OneLake Parquet Files

**Status**: Accepted  
**Date**: 2026-02-13  
**Context**: Need high-performance semantic model

**Decision**: Use Direct Lake connecting to OneLake Parquet files as primary pattern.

**Rationale**:
- In-memory caching for fast queries
- No refresh required
- Automatic optimization
- OneLake provides unified storage
- Open format (no vendor lock-in)

**Alternatives Considered**:
- **Import Mode**: Requires refresh, slower, more storage
- **DirectQuery Only**: Slower queries, no caching
- **Warehouse Tables**: Also supported, but OneLake is primary

**Consequences**:
- Fast query performance
- No refresh needed
- Automatic cache management
- Optimize Parquet files for best performance

**Related**: [Direct Lake Optimization](../optimization/direct-lake-optimization.md), [OneLake Architecture](../architecture/t0-t5-pattern-summary.md#onelake-integration)

---

## ADR-007: Use DirectQuery for T5 Views

**Status**: Accepted  
**Date**: 2026-02-13  
**Context**: Need SQL pushdown for complex aggregations

**Decision**: Use DirectQuery automatically for T5 views (no manual configuration).

**Rationale**:
- Automatic fallback to DirectQuery for views
- SQL pushdown for complex queries
- Real-time data access
- No cache limitations

**Alternatives Considered**:
- **Force Direct Lake**: Views can't use Direct Lake, would require tables
- **Import Mode**: Requires refresh, not suitable for views

**Consequences**:
- Automatic dual-mode operation
- Complex aggregations use SQL pushdown
- Real-time data access
- No manual configuration needed

**Related**: [Direct Lake Optimization](../optimization/direct-lake-optimization.md#pattern-8-dual-mode-operation)

---

## ADR-008: Append-Only T3 Transformations

**Status**: Accepted  
**Date**: 2026-02-13  
**Context**: Data already versioned in T2, no need for MERGE in T3

**Decision**: Use append-only mode for all T3 Dataflows Gen2 transformations.

**Rationale**:
- Data already versioned in T2 (SCD2)
- Simpler transformations (no MERGE logic)
- Better performance (append is faster than MERGE)
- Clearer data flow

**Alternatives Considered**:
- **MERGE in T3**: Unnecessary complexity, data already versioned
- **Replace Mode**: Would lose history, not suitable

**Consequences**:
- Simpler T3 transformations
- Better performance
- Data already versioned in T2
- Clear separation of concerns

**Related**: [Dataflows Gen2 Patterns](../patterns/dataflows-gen2-patterns.md#pattern-10-destination-configuration)

---

## ADR-009: Initial Snapshot Loading Strategy

**Status**: Accepted  
**Date**: 2026-02-13  
**Context**: Initial data load may use daily full snapshots

**Decision**: Initially use daily full snapshot loading to T1, transition to incremental later.

**Rationale**:
- Simpler initial implementation
- No watermark logic needed initially
- Easier to validate and test
- Can transition to incremental after validation

**Alternatives Considered**:
- **Incremental from Start**: More complex, harder to validate
- **Hybrid**: More complex, not necessary initially

**Consequences**:
- Simpler initial load
- Full data replacement each day
- Transition to incremental after validation
- T2 handles SCD2 regardless of load strategy

**Related**: [Data Factory Patterns](../patterns/data-factory-patterns.md#pattern-3-t1-ingestion-pipelines-primary-use-case), [T-SQL Patterns](../patterns/t-sql-patterns.md#pattern-5-initial-snapshot-loading)

---

## ADR-010: T5 Views Only (No Base Tables)

**Status**: Accepted  
**Date**: 2026-02-13  
**Context**: Presentation layer should be lightweight

**Decision**: T5 layer contains only views, no base tables.

**Rationale**:
- No storage overhead (views don't store data)
- Always current (reflects latest T3._FINAL data)
- Easy to modify (no data migration)
- Supports RLS at view level

**Alternatives Considered**:
- **Base Tables**: Storage overhead, requires refresh
- **Materialized Views**: More complex, still requires refresh

**Consequences**:
- No storage overhead
- Always current data
- Easy to modify
- Automatic DirectQuery for views

**Related**: [Warehouse Patterns](../patterns/warehouse-patterns.md#pattern-5-presentation-layer-t5), [T0-T5 Pattern Summary](../architecture/t0-t5-pattern-summary.md#t5-warehouse-presentation-layer)

---

## ADR-011: Comprehensive Error Handling in T-SQL

**Status**: Accepted  
**Date**: 2026-02-13  
**Context**: Need robust error handling for stored procedures

**Decision**: Implement comprehensive error handling in all T-SQL stored procedures using TRY-CATCH blocks.

**Rationale**:
- T-SQL provides comprehensive error handling
- Log errors to T0 for monitoring
- Re-throw errors for upstream handling
- Capture all error details (number, severity, line, procedure)

**Alternatives Considered**:
- **Minimal Error Handling**: Insufficient for production
- **External Error Handling**: Less integrated, harder to maintain

**Consequences**:
- Robust error handling
- Complete error logging
- Better troubleshooting
- Production-ready code

**Related**: [T-SQL Patterns](../patterns/t-sql-patterns.md#pattern-2-error-handling)

---

## ADR-012: Use Temp Tables for Batch Processing

**Status**: Accepted  
**Date**: 2026-02-13  
**Context**: Need to process large datasets efficiently

**Decision**: Use temporary tables for batch processing in T-SQL stored procedures.

**Rationale**:
- Efficient staging for batch data
- Reduces memory usage
- Supports indexing for performance
- Easy to clean up

**Alternatives Considered**:
- **Table Variables**: Limited to small datasets
- **Physical Staging Tables**: More complex, requires cleanup
- **No Staging**: Less efficient for large batches

**Consequences**:
- Efficient batch processing
- Better performance for large datasets
- Requires temp table management
- Supports error recovery

**Related**: [T-SQL Patterns](../patterns/t-sql-patterns.md#pattern-3-temporary-tables), [Warehouse Patterns](../patterns/warehouse-patterns.md#pattern-9-batch-processing)

---

## Summary of Decisions

| Decision | Technology | Layer | Rationale |
|----------|-----------|-------|-----------|
| T1 Ingestion | Data Factory | T1 | Optimized for data movement |
| T3 Transformations | Dataflows Gen2 | T3 | Visual, no-code transformations |
| T2 SCD2 | T-SQL Stored Procedures | T2 | Efficient MERGE operations |
| Raw Storage | VARIANT Columns | T1 | Schema flexibility |
| Snapshots | Zero-Copy Clones | T3._FINAL | Storage efficiency |
| Semantic Layer | Direct Lake on OneLake | Semantic | High performance |
| Presentation | Views Only | T5 | No storage overhead |
| Error Handling | T-SQL TRY-CATCH | T2 | Comprehensive error management |
| Batch Processing | Temp Tables | T2 | Efficient large dataset processing |

---

## Related Topics

- [T0-T5 Pattern Summary](../architecture/t0-t5-pattern-summary.md) - Architecture overview
- [Technology Distinctions](technology-distinctions.md) - Technology roles
- [T0-T5 Architecture Pattern](../architecture/t0-t5-architecture-pattern.md) - Implementation guide
