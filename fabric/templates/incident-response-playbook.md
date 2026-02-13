# Incident Response Playbook

## Overview

This playbook provides step-by-step procedures for responding to incidents in the T0-T5 architecture.

## Incident Severity Levels

### Critical (P1)
- **Impact**: Complete system outage, data loss, security breach
- **Response Time**: Immediate (< 15 minutes)
- **Escalation**: On-call engineer + management

### High (P2)
- **Impact**: Major functionality degraded, significant performance issues
- **Response Time**: < 1 hour
- **Escalation**: On-call engineer

### Medium (P3)
- **Impact**: Minor functionality issues, performance degradation
- **Response Time**: < 4 hours
- **Escalation**: Team lead

### Low (P4)
- **Impact**: Cosmetic issues, minor bugs
- **Response Time**: < 24 hours
- **Escalation**: None

## Common Incident Scenarios

### Scenario 1: Pipeline Failure

**Symptoms:**
- Pipeline shows "Failed" status
- Error message in pipeline log
- Data not updated in downstream layers

**Diagnostic Steps:**
1. Check `t0.pipeline_log` for error details
2. Review pipeline execution history
3. Check source data availability
4. Verify connection strings and permissions

**Resolution Steps:**
1. Identify root cause from error log
2. Fix issue (data quality, connection, permissions)
3. Re-run failed pipeline
4. Verify data flow end-to-end
5. Update monitoring alerts if needed

**Prevention:**
- Implement comprehensive error handling
- Set up proactive monitoring
- Regular data quality checks

### Scenario 2: Data Quality Issue

**Symptoms:**
- Missing data in reports
- Incorrect calculations
- Duplicate records

**Diagnostic Steps:**
1. Run data quality queries (see [Monitoring Queries](../examples/monitoring-queries.sql))
2. Check T1 → T2 → T3 → T5 flow
3. Verify SCD2 MERGE operations
4. Check for NULLs and duplicates

**Resolution Steps:**
1. Identify affected layer
2. Fix data quality issue at source
3. Re-process affected data
4. Validate fixes
5. Update data quality rules

**Prevention:**
- Implement data quality checks in pipelines
- Set up data quality monitoring
- Regular data audits

### Scenario 3: Performance Degradation

**Symptoms:**
- Slow query performance
- Pipeline taking longer than usual
- Timeout errors

**Diagnostic Steps:**
1. Check query execution times
2. Review query plans
3. Check table sizes and growth
4. Review index usage
5. Check for blocking queries

**Resolution Steps:**
1. Identify performance bottleneck
2. Optimize queries (add indexes, rewrite queries)
3. Optimize pipelines (add filters, reduce data volume)
4. Scale resources if needed
5. Monitor performance improvements

**Prevention:**
- Regular performance monitoring
- Query optimization reviews
- Capacity planning

### Scenario 4: Semantic Model Issues

**Symptoms:**
- Reports not loading
- Direct Lake queries failing
- DirectQuery timeouts

**Diagnostic Steps:**
1. Check semantic model refresh status
2. Verify Warehouse connection
3. Check Direct Lake cache status
4. Review DAX query performance
5. Check for relationship issues

**Resolution Steps:**
1. Refresh semantic model if needed
2. Verify Warehouse SQL endpoint connectivity
3. Optimize DAX measures
4. Add aggregations if needed
5. Verify relationships

**Prevention:**
- Regular semantic model optimization
- Monitor query performance
- Review DAX measures regularly

## Incident Response Process

### 1. Detection
- Monitor alerts and dashboards
- Review pipeline logs regularly
- Check user reports

### 2. Triage
- Assess severity level
- Assign incident owner
- Create incident ticket

### 3. Investigation
- Gather diagnostic information
- Review logs and metrics
- Identify root cause

### 4. Resolution
- Implement fix
- Verify resolution
- Document solution

### 5. Post-Incident
- Conduct post-mortem
- Update documentation
- Improve monitoring/prevention

## Diagnostic Queries

See [Monitoring Queries](../examples/monitoring-queries.sql) for diagnostic queries.

## Escalation Contacts

- **On-Call Engineer**: [Contact info]
- **Team Lead**: [Contact info]
- **Management**: [Contact info]

## Related Documentation

- [Troubleshooting Guide](../operations/troubleshooting-guide.md) - Detailed troubleshooting steps
- [Monitoring & Observability](../operations/monitoring-observability.md) - Monitoring patterns
