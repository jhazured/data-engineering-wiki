# Deployment and CI/CD Patterns

## Overview

Deployment and CI/CD (Continuous Integration/Continuous Deployment) patterns for Microsoft Fabric involve automating the deployment of data warehouse components across environments (Dev, Test, Prod). This guide covers deployment patterns and best practices for the T0-T5 architecture.

**Key Deployment Areas:**
- Environment promotion
- Datasource rules
- Version control
- Automated testing
- Rollback procedures

---

## Architecture Context

### Deployment Across Environments

**Dev → Test → Prod**: Promote components through environments
**Components**: Lakehouse, Warehouse, Dataflows Gen2, Semantic Models, Reports
**Datasource Rules**: Automatically map datasources to target environment

---

## Pattern 1: Version Control Strategy

### Git Repository Structure

**Recommended Structure:**

```
fabric-hr-analytics/
├── sql/
│   ├── t0/
│   │   └── control-tables.sql
│   ├── t2/
│   │   ├── dim_department.sql
│   │   ├── dim_employee.sql
│   │   └── stored-procedures/
│   │       ├── usp_merge_dim_department.sql
│   │       └── usp_load_fact_payroll.sql
│   ├── t3/
│   │   └── stored-procedures/
│   │       └── usp_refresh_final_clones.sql
│   └── t5/
│       └── views/
│           ├── vw_employee.sql
│           └── vw_payroll_detail.sql
├── dataflows/
│   ├── DF_T3_Employee_Base.json
│   └── DF_T3_Employee_Enriched.json
├── pipelines/
│   ├── PL_T1_Master_Ingest.json
│   └── PL_T2_Process_SCD2.json
└── semantic-models/
    └── HR_Analytics_Semantic.bim
```

### Best Practices

- ✅ Store all SQL scripts in version control
- ✅ Store Dataflow Gen2 definitions (export as JSON)
- ✅ Store Data Factory pipeline definitions
- ✅ Store semantic model definitions (.bim files)
- ✅ Use meaningful commit messages
- ✅ Tag releases
- ❌ Don't store credentials in version control
- ❌ Don't skip version control

---

## Pattern 2: Environment Setup

### Environment Configuration

**Dev Environment:**

```sql
-- T0 configuration
INSERT INTO t0.environment_config (
    config_key,
    config_value,
    environment
)
VALUES
    ('warehouse_server', 'dev-warehouse.database.windows.net', 'Dev'),
    ('lakehouse_name', 'T1_DATA_LAKE_DEV', 'Dev'),
    ('schema_name', 't2', 'Dev');
```

**Test Environment:**

```sql
INSERT INTO t0.environment_config (
    config_key,
    config_value,
    environment
)
VALUES
    ('warehouse_server', 'test-warehouse.database.windows.net', 'Test'),
    ('lakehouse_name', 'T1_DATA_LAKE_TEST', 'Test'),
    ('schema_name', 't2', 'Test');
```

**Prod Environment:**

```sql
INSERT INTO t0.environment_config (
    config_key,
    config_value,
    environment
)
VALUES
    ('warehouse_server', 'prod-warehouse.database.windows.net', 'Prod'),
    ('lakehouse_name', 'T1_DATA_LAKE_PROD', 'Prod'),
    ('schema_name', 't2', 'Prod');
```

### Best Practices

- ✅ Store environment configuration in T0
- ✅ Use consistent naming conventions
- ✅ Document environment differences
- ✅ Use parameters for environment-specific values
- ✅ Test environment configuration
- ❌ Don't hardcode environment values
- ❌ Don't skip environment configuration

---

## Pattern 3: Deployment Pipeline

### Deployment Stages

**Stage 1: Dev Deployment**

```yaml
# Azure DevOps Pipeline
stages:
  - stage: DeployDev
    displayName: 'Deploy to Dev'
    jobs:
      - job: DeploySQL
        steps:
          - task: SqlAzureDacpacDeployment@1
            inputs:
              azureSubscription: 'Dev-Subscription'
              serverName: 'dev-warehouse.database.windows.net'
              databaseName: 'HR_Warehouse_Dev'
              sqlFile: '$(System.DefaultWorkingDirectory)/sql/**/*.sql'
```

**Stage 2: Test Deployment**

```yaml
  - stage: DeployTest
    displayName: 'Deploy to Test'
    dependsOn: DeployDev
    condition: succeeded()
    jobs:
      - job: DeploySQL
        steps:
          - task: SqlAzureDacpacDeployment@1
            inputs:
              azureSubscription: 'Test-Subscription'
              serverName: 'test-warehouse.database.windows.net'
              databaseName: 'HR_Warehouse_Test'
              sqlFile: '$(System.DefaultWorkingDirectory)/sql/**/*.sql'
```

**Stage 3: Prod Deployment**

```yaml
  - stage: DeployProd
    displayName: 'Deploy to Prod'
    dependsOn: DeployTest
    condition: succeeded()
    jobs:
      - job: DeploySQL
        steps:
          - task: SqlAzureDacpacDeployment@1
            inputs:
              azureSubscription: 'Prod-Subscription'
              serverName: 'prod-warehouse.database.windows.net'
              databaseName: 'HR_Warehouse_Prod'
              sqlFile: '$(System.DefaultWorkingDirectory)/sql/**/*.sql'
```

### Best Practices

- ✅ Use deployment pipelines
- ✅ Deploy in sequence (Dev → Test → Prod)
- ✅ Require approval for Prod
- ✅ Test deployments in Dev/Test first
- ✅ Document deployment process
- ❌ Don't skip testing stages
- ❌ Don't deploy directly to Prod

---

## Pattern 4: Datasource Rules

### Semantic Model Datasource Rules

**Configure Datasource Rules:**

1. In Fabric → Deployment pipelines → Settings
2. Configure datasource rules for semantic model
3. Map datasources to target environments:

```
Dev:
  Warehouse → dev-warehouse.database.windows.net
  Lakehouse → T1_DATA_LAKE_DEV

Test:
  Warehouse → test-warehouse.database.windows.net
  Lakehouse → T1_DATA_LAKE_TEST

Prod:
  Warehouse → prod-warehouse.database.windows.net
  Lakehouse → T1_DATA_LAKE_PROD
```

### Best Practices

- ✅ Configure datasource rules for all environments
- ✅ Test datasource rules in Dev/Test
- ✅ Document datasource mappings
- ✅ Verify datasource rules after deployment
- ✅ Use consistent naming conventions
- ❌ Don't skip datasource rule configuration
- ❌ Don't hardcode datasources

---

## Pattern 5: Dataflow Gen2 Deployment

### Export Dataflow Definition

**Export as JSON:**

1. In Fabric → Dataflows Gen2 → Select dataflow
2. Export → Download JSON
3. Store in version control

### Deploy Dataflow

**Deployment Steps:**

1. Import dataflow JSON to target environment
2. Rebind to target warehouse
3. Update parameters
4. Test dataflow execution

### Best Practices

- ✅ Export dataflow definitions
- ✅ Store in version control
- ✅ Rebind to target warehouse
- ✅ Update parameters for environment
- ✅ Test dataflow execution
- ❌ Don't skip dataflow deployment
- ❌ Don't forget to rebind datasources

---

## Pattern 6: Automated Testing

### SQL Unit Tests

**Test Stored Procedures:**

```sql
-- Test SCD2 MERGE
EXEC t2.usp_merge_dim_department;

-- Verify results
SELECT 
    COUNT(*) AS total_records,
    SUM(CASE WHEN is_current = 1 THEN 1 ELSE 0 END) AS current_records,
    SUM(CASE WHEN is_current = 0 THEN 1 ELSE 0 END) AS historical_records
FROM t2.dim_department;

-- Assertions
IF (SELECT COUNT(*) FROM t2.dim_department WHERE is_current = 1) = 0
    THROW 50001, 'No current records found', 1;
```

### Integration Tests

**Test End-to-End Flow:**

```sql
-- Test T1 → T2 → T3 flow
EXEC PL_T1_Master_Ingest;
EXEC PL_T2_Process_SCD2;
EXEC PL_T3_Transform;

-- Verify data flow
SELECT 
    'T1' AS layer, COUNT(*) AS record_count FROM t1_department
UNION ALL
SELECT 'T2', COUNT(*) FROM t2.dim_department WHERE is_current = 1
UNION ALL
SELECT 'T3', COUNT(*) FROM t3.dim_employee_FINAL;
```

### Best Practices

- ✅ Create unit tests for stored procedures
- ✅ Create integration tests for pipelines
- ✅ Run tests in Dev/Test before Prod
- ✅ Automate test execution
- ✅ Document test cases
- ❌ Don't skip testing
- ❌ Don't deploy without tests

---

## Pattern 7: Rollback Procedures

### Rollback Strategy

**Version Control Rollback:**

```sql
-- Rollback to previous version
-- 1. Identify previous version from git
-- 2. Deploy previous version SQL scripts
-- 3. Verify rollback success
```

**Data Rollback:**

```sql
-- Restore from backup if needed
RESTORE DATABASE HR_Warehouse
FROM BACKUP = 'https://storageaccount.blob.core.windows.net/backups/warehouse_backup.bak'
WITH REPLACE;
```

### Best Practices

- ✅ Document rollback procedures
- ✅ Test rollback procedures
- ✅ Keep backups before deployment
- ✅ Version control enables rollback
- ✅ Document rollback steps
- ❌ Don't skip rollback planning
- ❌ Don't deploy without backup

---

## Pattern 8: Deployment Checklist

### Pre-Deployment Checklist

- [ ] All code reviewed and approved
- [ ] Tests passing in Dev
- [ ] Version control updated
- [ ] Deployment plan documented
- [ ] Rollback plan documented
- [ ] Backup created
- [ ] Stakeholders notified

### Deployment Checklist

- [ ] Deploy to Dev
- [ ] Run tests in Dev
- [ ] Deploy to Test
- [ ] Run tests in Test
- [ ] Get approval for Prod
- [ ] Deploy to Prod
- [ ] Verify deployment
- [ ] Run smoke tests

### Post-Deployment Checklist

- [ ] Verify all components deployed
- [ ] Verify datasource rules applied
- [ ] Run integration tests
- [ ] Monitor for errors
- [ ] Document deployment results
- [ ] Update documentation

### Best Practices

- ✅ Use deployment checklists
- ✅ Follow checklist for every deployment
- ✅ Document deployment results
- ✅ Update checklists based on experience
- ✅ Don't skip checklist items
- ❌ Don't deploy without checklist

---

## Pattern 9: Blue-Green Deployment

### Implementation Pattern

**Blue Environment (Current):**

- Production environment running
- Users connected to Blue

**Green Environment (New):**

- Deploy new version to Green
- Test Green environment
- Switch traffic to Green
- Keep Blue as backup

### Best Practices

- ✅ Use blue-green for zero-downtime deployments
- ✅ Test green environment thoroughly
- ✅ Keep blue as backup
- ✅ Switch traffic gradually
- ✅ Monitor both environments
- ❌ Don't switch without testing
- ❌ Don't skip backup

---

## Pattern 10: Feature Flags

### Implementation Pattern

**Feature Flag Table:**

```sql
CREATE TABLE t0.feature_flags (
    feature_name VARCHAR(100) PRIMARY KEY,
    enabled BIT,
    environment VARCHAR(20),
    updated_at DATETIME2 DEFAULT GETDATE()
);
```

**Use Feature Flags:**

```sql
-- Check feature flag
IF EXISTS (
    SELECT 1 FROM t0.feature_flags 
    WHERE feature_name = 'new_aggregation' 
    AND enabled = 1 
    AND environment = 'Prod'
)
BEGIN
    -- Use new aggregation
    SELECT * FROM t3.agg_payroll_monthly_new;
END
ELSE
BEGIN
    -- Use old aggregation
    SELECT * FROM t3.agg_payroll_monthly;
END
```

### Best Practices

- ✅ Use feature flags for gradual rollout
- ✅ Store feature flags in T0
- ✅ Test feature flags in Dev/Test
- ✅ Monitor feature flag usage
- ✅ Document feature flags
- ❌ Don't use feature flags unnecessarily
- ❌ Don't skip feature flag testing

---

## Summary

Deployment and CI/CD patterns focus on:

1. **Version Control**: Store all code in git
2. **Environment Setup**: Configure Dev/Test/Prod
3. **Deployment Pipeline**: Automate deployments
4. **Datasource Rules**: Map datasources to environments
5. **Testing**: Automated unit and integration tests
6. **Rollback**: Plan for rollback procedures
7. **Checklists**: Use deployment checklists
8. **Feature Flags**: Gradual rollout capabilities

## Related Topics

- [T0-T5 Architecture Pattern](../architecture/t0-t5-architecture-pattern.md) - Implementation guide
- [Data Factory Patterns](../patterns/data-factory-patterns.md) - Pipeline patterns
- [Monitoring & Observability](monitoring-observability.md) - Deployment monitoring
- [Troubleshooting Guide](troubleshooting-guide.md) - Deployment issues

---

Follow these patterns to build reliable, automated deployment processes for Fabric data warehouses.
