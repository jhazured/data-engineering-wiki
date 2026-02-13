# Quick Start Guide

## Welcome to the Fabric T0-T5 Architecture Knowledge Base

This guide helps you get started quickly based on your role and needs.

---

## I'm New - Where Do I Start?

### Step 1: Understand the Architecture (15 minutes)

1. Read **[T0-T5 Pattern Summary](../architecture/pattern-summary.md)** - High-level overview
2. Review the architecture diagram
3. Understand each layer's purpose

### Step 2: Choose Your Path

**I want to implement a new project:**
→ Follow **[T0-T5 Architecture Pattern](../architecture/architecture-pattern.md)** (detailed implementation guide)

**I want to understand a specific technology:**
→ See "Technology-Specific Guides" below

**I'm troubleshooting an issue:**
→ Go to **[Troubleshooting Guide](../operations/troubleshooting-guide.md)**

---

## Common Scenarios

### Scenario 1: Setting Up T1 Ingestion

**Goal**: Load raw data from external sources to Lakehouse

**Files to Read:**
1. [Data Factory Patterns](../patterns/data-factory-patterns.md) - Pattern 3 (T1 Ingestion)
2. [Lakehouse Patterns](../patterns/lakehouse-patterns.md) - Pattern 1 (VARIANT Landing)
3. [Technology Distinctions](technology-distinctions.md) - Understand Data Factory role

**Key Points:**
- Use Data Factory for copying data from external sources
- Store in T1 Lakehouse with VARIANT columns
- Create materialized views for flattening
- Initially may use daily full snapshots

**Time Estimate**: 1-2 hours

---

### Scenario 2: Implementing T2 SCD2 Historical Record

**Goal**: Create historical tracking with SCD2

**Files to Read:**
1. [Warehouse Patterns](../patterns/warehouse-patterns.md) - Pattern 1 (SCD2 MERGE)
2. [T-SQL Patterns](../patterns/t-sql-patterns.md) - Pattern 1 (Stored Procedures)
3. [T-SQL Patterns](../patterns/t-sql-patterns.md) - Pattern 2 (Error Handling)

**Key Points:**
- Use T-SQL stored procedures for SCD2 MERGE
- Implement comprehensive error handling
- Track effective_date, expiry_date, is_current
- Use watermarks for incremental loads

**Time Estimate**: 2-3 hours

---

### Scenario 3: Implementing T3 Transformations

**Goal**: Transform data using Dataflows Gen2

**Files to Read:**
1. [Dataflows Gen2 Patterns](../patterns/dataflows-gen2-patterns.md) - All patterns
2. [Technology Distinctions](technology-distinctions.md) - Understand Dataflows Gen2 role
3. [Performance Optimization](../optimization/performance-optimization.md) - Pattern 5 (Dataflow optimization)

**Key Points:**
- Use Dataflows Gen2 for ALL T3 transformations
- Use append mode (data already versioned in T2)
- Enable query folding for performance
- Create star schema structures

**Time Estimate**: 2-3 hours

---

### Scenario 4: Setting Up Direct Lake Semantic Model

**Goal**: Create high-performance semantic model

**Files to Read:**
1. **[Direct Lake Modes & T5 View Compatibility](direct-lake-modes-t5-compatibility.md)** - **START HERE** - Choose the right Direct Lake approach
2. [Direct Lake Optimization](../optimization/direct-lake-optimization.md) - Performance optimization patterns
3. [T0-T5 Architecture Pattern](../architecture/architecture-pattern.md) - Phase 7 (Semantic Model)
4. [Performance Optimization](../optimization/performance-optimization.md) - DAX optimization

**Key Points:**
- Choose between Direct Lake on SQL Endpoints (simplest) or Hybrid T5 (maximum flexibility)
- Use Direct Lake for OneLake Parquet files (primary)
- Use DirectQuery for T5 views (automatic fallback or separate connection)
- Create aggregations for common queries
- Optimize DAX measures

**Time Estimate**: 1-2 hours

---

### Scenario 5: Optimizing Performance

**Goal**: Improve query and pipeline performance

**Files to Read:**
1. [Performance Optimization](../optimization/performance-optimization.md) - Comprehensive guide
2. [Direct Lake Optimization](../optimization/direct-lake-optimization.md) - Semantic layer optimization
3. Technology-specific performance sections

**Key Points:**
- Monitor performance metrics
- Optimize indexes and partitions
- Use aggregations
- Enable query folding in Dataflows Gen2

**Time Estimate**: 2-3 hours

---

### Scenario 6: Setting Up Security

**Goal**: Implement row-level security and access control

**Files to Read:**
1. [Security Patterns](../operations/security-patterns.md) - All patterns
2. [T0-T5 Architecture Pattern](../architecture/architecture-pattern.md) - Security sections

**Key Points:**
- Implement RLS at T5 layer
- Create security roles in semantic model
- Use Managed Identity for automation
- Enable audit logging

**Time Estimate**: 2-3 hours

---

### Scenario 7: Setting Up Monitoring

**Goal**: Monitor pipelines and data quality

**Files to Read:**
1. [Monitoring & Observability](../operations/monitoring-observability.md) - All patterns
2. [T-SQL Patterns](../patterns/t-sql-patterns.md) - Error handling patterns

**Key Points:**
- Log all pipeline executions to T0
- Monitor data quality metrics
- Set up alerts for failures
- Create monitoring dashboards

**Time Estimate**: 2-3 hours

---

### Scenario 8: Troubleshooting Issues

**Goal**: Resolve common problems

**Files to Read:**
1. [Troubleshooting Guide](../operations/troubleshooting-guide.md) - Common issues
2. [Monitoring & Observability](../operations/monitoring-observability.md) - Diagnostic queries

**Key Points:**
- Check pipeline logs in T0
- Review error messages
- Verify configurations
- Test solutions

**Time Estimate**: 30 minutes - 2 hours (depends on issue)

---

## Technology-Specific Guides

### Data Factory
- **Primary Use**: T1 ingestion (copying data from external sources)
- **Guide**: [Data Factory Patterns](../patterns/data-factory-patterns.md)
- **Key Patterns**: T1 ingestion, pipeline orchestration, error handling

### Dataflows Gen2
- **Primary Use**: T3 transformations (business logic, joins, aggregations)
- **Guide**: [Dataflows Gen2 Patterns](../patterns/dataflows-gen2-patterns.md)
- **Key Patterns**: Incremental refresh, joins, aggregations, star schema

### T-SQL
- **Primary Use**: T2 stored procedures, error handling, batch processing
- **Guide**: [T-SQL Patterns](../patterns/t-sql-patterns.md)
- **Key Patterns**: SCD2 MERGE, error handling, temp tables, batch processing

### Warehouse
- **Primary Use**: T2/T3/T5 layers
- **Guide**: [Warehouse Patterns](../patterns/warehouse-patterns.md)
- **Key Patterns**: SCD2, zero-copy clones, indexing, views

### Lakehouse
- **Primary Use**: T1 raw landing
- **Guide**: [Lakehouse Patterns](../patterns/lakehouse-patterns.md)
- **Key Patterns**: VARIANT landing, materialized views, shortcuts

### Direct Lake
- **Primary Use**: Semantic layer optimization
- **Guide**: [Direct Lake Optimization](../optimization/direct-lake-optimization.md)
- **Key Patterns**: OneLake Parquet files, aggregations, DAX optimization

---

## File Reading Order

### For New Projects

1. **[T0-T5 Pattern Summary](../architecture/pattern-summary.md)** - Understand architecture
2. **[Technology Distinctions](technology-distinctions.md)** - Understand tool roles
3. **[T0-T5 Architecture Pattern](../architecture/architecture-pattern.md)** - Follow implementation guide
4. Technology-specific patterns as needed

### For Specific Tasks

**T1 Ingestion:**
1. [Data Factory Patterns](../patterns/data-factory-patterns.md)
2. [Lakehouse Patterns](../patterns/lakehouse-patterns.md)

**T2 Historical Record:**
1. [Warehouse Patterns](../patterns/warehouse-patterns.md)
2. [T-SQL Patterns](../patterns/t-sql-patterns.md)

**T3 Transformations:**
1. [Dataflows Gen2 Patterns](../patterns/dataflows-gen2-patterns.md)
2. [Technology Distinctions](technology-distinctions.md)

**Semantic Layer:**
1. [Direct Lake Optimization](../optimization/direct-lake-optimization.md)
2. [Performance Optimization](../optimization/performance-optimization.md)

**Operations:**
1. [Monitoring & Observability](../operations/monitoring-observability.md)
2. [Security Patterns](../operations/security-patterns.md)
3. [Deployment & CI/CD](../operations/deployment-cicd.md)

---

## Key Concepts Quick Reference

### T0-T5 Layers
- **T0**: Control layer (logging, configuration)
- **T1**: Raw landing (VARIANT, transient)
- **T2**: Historical record (SCD2, T-SQL)
- **T3**: Transformations (Dataflows Gen2)
- **T3._FINAL**: Validated snapshots (zero-copy clones)
- **T5**: Presentation views (T-SQL)

### Technology Roles
- **Data Factory**: T1 ingestion + orchestration
- **Dataflows Gen2**: T3 transformations only
- **T-SQL**: T2 stored procedures, error handling, batch processing
- **Direct Lake**: OneLake Parquet files → in-memory cache
- **DirectQuery**: T5 views → SQL pushdown

### Key Patterns
- **VARIANT Landing**: Schema-agnostic raw data storage
- **SCD2**: Historical tracking with versioning
- **Zero-Copy Clones**: Efficient snapshot creation
- **Direct Lake**: High-performance semantic models
- **Append-Only T3**: Data already versioned in T2

---

## Getting Started Checklist

### Phase 1: Setup (Day 1)
- [ ] Read T0-T5 Pattern Summary
- [ ] Understand technology distinctions
- [ ] Set up Fabric workspace
- [ ] Create T0 control tables
- [ ] Create T1 Lakehouse
- [ ] Create Warehouse

### Phase 2: T1 Ingestion (Day 2)
- [ ] Create Data Factory pipelines
- [ ] Set up linked services
- [ ] Implement T1 VARIANT tables
- [ ] Create materialized views
- [ ] Test ingestion

### Phase 3: T2 Historical Record (Day 3-4)
- [ ] Create shortcuts from Warehouse to Lakehouse
- [ ] Create T2 dimension tables
- [ ] Create T2 fact tables
- [ ] Implement SCD2 stored procedures
- [ ] Test SCD2 MERGE operations

### Phase 4: T3 Transformations (Day 5-6)
- [ ] Create T3 schema
- [ ] Create Dataflows Gen2
- [ ] Implement base transformations
- [ ] Implement joins and enrichment
- [ ] Create star schema

### Phase 5: T5 and Semantic Layer (Day 7-8)
- [ ] Create T3._FINAL clones
- [ ] Create T5 views
- [ ] Create semantic model
- [ ] Configure Direct Lake
- [ ] Create DAX measures
- [ ] Test semantic model

### Phase 6: Operations (Day 9-10)
- [ ] Set up monitoring
- [ ] Implement security (RLS)
- [ ] Set up deployment pipeline
- [ ] Create dashboards
- [ ] Document architecture

---

## Common Questions

**Q: Should I use Data Factory or Dataflows Gen2 for transformations?**  
A: Use Dataflows Gen2 for ALL T3 transformations. Data Factory is only for T1 ingestion.

**Q: Can I use notebooks in T3?**  
A: No. Use Dataflows Gen2 for all T3 transformations.

**Q: Should I use Direct Lake or DirectQuery?**  
A: Use Direct Lake for OneLake Parquet files (automatic). DirectQuery is automatic for T5 views.

**Q: How do I handle errors?**  
A: Use comprehensive error handling in T-SQL stored procedures. See [T-SQL Patterns - Error Handling](../patterns/t-sql-patterns.md#pattern-2-error-handling).

**Q: How do I optimize performance?**  
A: See [Performance Optimization](../optimization/performance-optimization.md) for comprehensive guide.

**Q: How do I monitor my pipelines?**  
A: See [Monitoring & Observability](../operations/monitoring-observability.md) for monitoring patterns.

---

## Next Steps

1. Choose your scenario above
2. Read the recommended files
3. Follow the implementation guide
4. Reference troubleshooting guide if needed
5. Review best practices regularly

**Need Help?**
- Check [Troubleshooting Guide](../operations/troubleshooting-guide.md)
- Review [T0-T5 Architecture Pattern](../architecture/architecture-pattern.md)
- See [README](README.md) for complete file index
