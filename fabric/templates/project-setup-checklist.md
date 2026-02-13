# T0-T5 Project Setup Checklist

Use this checklist when setting up a new project using the T0-T5 architecture pattern.

## Pre-requisites

- [ ] Microsoft Fabric workspace access
- [ ] Required licenses (Fabric F64 or higher recommended)
- [ ] Permissions: Workspace Admin or Contributor
- [ ] Azure ADLS Gen2 storage account (for external sources)
- [ ] Git repository for version control

## Phase 1: Environment Setup

### Workspace Setup
- [ ] Create Fabric workspace
- [ ] Configure workspace settings
- [ ] Set up workspace permissions
- [ ] Create workspace folders (optional)

### T0 - Control Layer
- [ ] Create Warehouse
- [ ] Create t0 schema
- [ ] Create t0.watermark table
- [ ] Create t0.pipeline_log table
- [ ] Create t0.error_log table (optional)
- [ ] Test T0 tables

### T1 - Lakehouse
- [ ] Create Lakehouse
- [ ] Verify VARIANT support
- [ ] Test VARIANT table creation
- [ ] Test materialized view creation

### Warehouse (T2/T3/T5)
- [ ] Create Warehouse
- [ ] Verify SQL analytics endpoint
- [ ] Test shortcuts to Lakehouse
- [ ] Test zero-copy clone feature

## Phase 2: T1 Ingestion Setup

### Data Factory Setup
- [ ] Create Data Factory linked services
- [ ] Create source datasets
- [ ] Create sink datasets (Lakehouse)
- [ ] Create T1 load pipelines
- [ ] Create master T1 orchestration pipeline
- [ ] Test T1 ingestion

### T1 Tables
- [ ] Create VARIANT base tables
- [ ] Create materialized views
- [ ] Test VARIANT data loading
- [ ] Test materialized view refresh

## Phase 3: T2 Historical Record Setup

### Shortcuts
- [ ] Create shortcuts from Warehouse to Lakehouse
- [ ] Test shortcut access
- [ ] Verify shortcut performance

### T2 Tables
- [ ] Create t2 schema
- [ ] Create dimension tables (SCD2)
- [ ] Create fact tables
- [ ] Create indexes
- [ ] Test table creation

### Stored Procedures
- [ ] Create SCD2 MERGE stored procedures
- [ ] Create fact load stored procedures
- [ ] Create error handling
- [ ] Test stored procedures
- [ ] Test SCD2 MERGE operations

### T2 Pipeline
- [ ] Create T2 orchestration pipeline
- [ ] Configure stored procedure activities
- [ ] Configure T1 truncation (on success)
- [ ] Configure error handling
- [ ] Test T2 pipeline

## Phase 4: T3 Transformations Setup

### T3 Schema
- [ ] Create t3 schema
- [ ] Create t3.ref reference tables
- [ ] Test reference data loading

### Dataflows Gen2
- [ ] Create base transformation dataflows
- [ ] Create join/enrichment dataflows
- [ ] Create aggregation dataflows
- [ ] Create star schema dataflows
- [ ] Configure incremental refresh (if needed)
- [ ] Test dataflows

### T3 Pipeline
- [ ] Create T3 orchestration pipeline
- [ ] Configure dataflow activities
- [ ] Configure dependencies
- [ ] Test T3 pipeline

## Phase 5: T5 Presentation Setup

### T3._FINAL Clones
- [ ] Create clone refresh stored procedure
- [ ] Test clone creation
- [ ] Test clone refresh

### T5 Views
- [ ] Create t5 schema
- [ ] Create T5 view scripts
- [ ] Store views in Git
- [ ] Deploy views via CI/CD (or manual)
- [ ] Test T5 views

### T5 Pipeline
- [ ] Create T5 clone refresh pipeline
- [ ] Configure clone refresh activity
- [ ] Configure view deployment activity
- [ ] Test T5 pipeline

## Phase 6: Semantic Layer Setup

### Semantic Model
- [ ] Create semantic model (Direct Lake on OneLake)
- [ ] Connect to Warehouse SQL analytics endpoint
- [ ] Select _FINAL tables
- [ ] Select T5 views
- [ ] Verify Direct Lake mode (_FINAL tables)
- [ ] Verify DirectQuery mode (T5 views)
- [ ] Configure relationships
- [ ] Create DAX measures
- [ ] Test semantic model

### Power BI Reports
- [ ] Create Power BI reports
- [ ] Test Direct Lake queries
- [ ] Test DirectQuery queries
- [ ] Verify performance

## Phase 7: Master Orchestration

### Master Pipeline
- [ ] Create master orchestration pipeline
- [ ] Configure pipeline dependencies
- [ ] Configure error handling
- [ ] Configure notifications
- [ ] Test end-to-end pipeline
- [ ] Schedule pipeline

## Phase 8: Monitoring & Operations

### Monitoring
- [ ] Set up monitoring dashboards
- [ ] Configure alerts
- [ ] Test monitoring queries
- [ ] Document monitoring procedures

### Security
- [ ] Configure RLS (if needed)
- [ ] Configure workspace permissions
- [ ] Configure data source permissions
- [ ] Test security policies

### Documentation
- [ ] Document architecture
- [ ] Document data flows
- [ ] Document deployment process
- [ ] Create runbooks

## Phase 9: Deployment Setup

### Deployment Pipeline
- [ ] Create deployment pipeline
- [ ] Configure deployment stages (Dev/Test/Prod)
- [ ] Configure datasource rules
- [ ] Test deployment to Test
- [ ] Test deployment to Prod

### CI/CD
- [ ] Set up Git repository
- [ ] Configure CI/CD pipeline
- [ ] Test automated deployments
- [ ] Document deployment process

## Phase 10: Testing & Validation

### Data Quality
- [ ] Create data quality checks
- [ ] Test data quality queries
- [ ] Set up data quality alerts

### Performance
- [ ] Test pipeline performance
- [ ] Test query performance
- [ ] Optimize slow queries
- [ ] Document performance baselines

### End-to-End Testing
- [ ] Test complete data flow
- [ ] Test error scenarios
- [ ] Test recovery procedures
- [ ] Validate success criteria

## Sign-off

- [ ] Architecture review completed
- [ ] Code review completed
- [ ] Testing completed
- [ ] Documentation completed
- [ ] Ready for production

---

## Related Documentation

- [Architecture Pattern](../architecture/architecture-pattern.md) - Detailed implementation guide
- [Quick Start Guide](../reference/quick-start-guide.md) - Quick start guide
