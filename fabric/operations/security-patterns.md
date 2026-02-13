# Security Patterns and Best Practices

## Overview

Security in Microsoft Fabric data warehouses involves multiple layers: authentication, authorization, row-level security (RLS), column-level security, and data encryption. This guide covers security patterns and best practices for the T0-T5 architecture pattern.

**Key Security Areas:**
- Authentication and identity
- Row-Level Security (RLS)
- Column-level security
- Data encryption
- Network security
- Audit logging

---

## Architecture Context

### Security Layers in T0-T5

**T0**: Control layer security (pipeline access, logging)
**T2**: Data security (RLS on historical data)
**T3**: Transformation security (data access during processing)
**T5**: Presentation security (RLS on views)
**Semantic Layer**: RLS and security filtering

---

## Pattern 1: Row-Level Security (RLS) in Warehouse

### When to Use

- Multi-tenant data
- Department-based access
- Regional data restrictions
- Compliance requirements

### Implementation Pattern

**Create Security Function:**

```sql
-- Create function to determine user access
CREATE FUNCTION t5.fn_security_filter_department()
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT dept_id
    FROM t0.user_department_access
    WHERE user_name = USER_NAME();
GO
```

**Create Security Policy:**

```sql
-- Create RLS policy on T5 view
CREATE SECURITY POLICY t5.policy_department_access
ADD FILTER PREDICATE t5.fn_security_filter_department()
ON t5.vw_payroll_detail
WITH (STATE = ON);
GO
```

**Alternative: Inline Security Function:**

```sql
CREATE SECURITY POLICY t5.policy_department_access
ADD FILTER PREDICATE (
    SELECT dept_id 
    FROM t0.user_department_access 
    WHERE user_name = USER_NAME()
)
ON t5.vw_payroll_detail
WITH (STATE = ON);
GO
```

### Best Practices

- ✅ Implement RLS at T5 layer (presentation)
- ✅ Use security functions for complex logic
- ✅ Store user access mappings in T0
- ✅ Test RLS policies thoroughly
- ✅ Document security requirements
- ❌ Don't implement RLS at T2/T3 (do at T5)
- ❌ Don't skip RLS testing

---

## Pattern 2: RLS in Semantic Model

### When to Use

- Power BI report security
- User-based data filtering
- Dynamic security based on user context

### Implementation Pattern

**Create Role:**

1. In semantic model → **Model** → **Manage roles**
2. Create role: `Department Managers`
3. Add table filter:

```dax
-- Filter for department managers
[Department ID] IN 
    VALUES('SecurityTable'[DepartmentID])
    && 'SecurityTable'[UserName] = USERNAME()
```

**Security Table:**

```sql
-- T0 security table
CREATE TABLE t0.user_department_access (
    user_name VARCHAR(100),
    department_id VARCHAR(10),
    access_level VARCHAR(20)  -- 'Read', 'Write', 'Admin'
);
```

**DAX Filter Expression:**

```dax
-- Filter fact table based on user's departments
FILTER(
    fact_payroll_FINAL,
    fact_payroll_FINAL[dept_key] IN 
        CALCULATETABLE(
            VALUES(t0_security[department_id]),
            t0_security[user_name] = USERNAME()
        )
)
```

### Best Practices

- ✅ Use security tables for user mappings
- ✅ Create roles for different access levels
- ✅ Test RLS with different users
- ✅ Document security requirements
- ✅ Use USERNAME() or USERPRINCIPALNAME()
- ❌ Don't hardcode user names in filters
- ❌ Don't skip RLS testing

---

## Pattern 3: Dynamic RLS Patterns

### When to Use

- Hierarchical access (manager sees team data)
- Time-based access
- Complex business rules

### Implementation Pattern

**Manager Hierarchy:**

```sql
-- T0 security function for manager hierarchy
CREATE FUNCTION t0.fn_user_department_hierarchy()
RETURNS TABLE
AS
RETURN
    -- User's own department
    SELECT dept_id FROM t0.user_department_access WHERE user_name = USER_NAME()
    UNION
    -- Departments managed by user
    SELECT dept_id FROM t2.dim_department d
    INNER JOIN t2.dim_employee e ON d.dept_id = e.department_id
    WHERE e.employee_id IN (
        SELECT manager_id FROM t2.dim_employee 
        WHERE employee_id = (SELECT employee_id FROM t0.user_employee_mapping WHERE user_name = USER_NAME())
    );
GO
```

**Time-Based Access:**

```sql
-- RLS function with time-based access
CREATE FUNCTION t5.fn_time_based_access()
RETURNS TABLE
AS
RETURN
    SELECT dept_id
    FROM t0.user_department_access
    WHERE user_name = USER_NAME()
    AND (
        -- Always allow access
        access_level = 'Full'
        OR
        -- Time-based access
        (access_level = 'BusinessHours' AND DATEPART(HOUR, GETDATE()) BETWEEN 8 AND 18)
    );
GO
```

### Best Practices

- ✅ Use security functions for complex logic
- ✅ Support hierarchical access patterns
- ✅ Consider time-based access requirements
- ✅ Test with various user scenarios
- ✅ Document security logic
- ❌ Don't create overly complex RLS
- ❌ Don't skip performance testing

---

## Pattern 4: Column-Level Security

### When to Use

- Sensitive columns (SSN, salary)
- Compliance requirements
- Partial data access

### Implementation Pattern

**Grant Column Access:**

```sql
-- Grant access to specific columns
GRANT SELECT ON t5.vw_employee (
    employee_key,
    employee_id,
    first_name,
    last_name,
    email
    -- Exclude: annual_salary, date_of_birth
) TO ROLE analyst_role;
```

**Create View with Column Filtering:**

```sql
-- Create view with column-level security
CREATE VIEW t5.vw_employee_restricted AS
SELECT
    employee_key,
    employee_id,
    first_name,
    last_name,
    email,
    -- Hide sensitive columns based on user role
    CASE 
        WHEN IS_MEMBER('hr_role') THEN annual_salary
        ELSE NULL
    END AS annual_salary
FROM t3.dim_employee_FINAL;
```

### Best Practices

- ✅ Use views for column-level security
- ✅ Grant minimal required permissions
- ✅ Document column access requirements
- ✅ Test column-level security
- ✅ Use roles for permission management
- ❌ Don't grant excessive column access
- ❌ Don't skip column-level security for sensitive data

---

## Pattern 5: Authentication Patterns

### Service Principal Authentication

**For Data Factory Pipelines:**

```json
{
  "name": "LS_Warehouse",
  "type": "SqlServer",
  "typeProperties": {
    "connectionString": "Server=tcp:warehouse.database.windows.net;Database=HR_Warehouse;Authentication=Active Directory Service Principal;User ID=<service-principal-id>;Password=<service-principal-secret>"
  }
}
```

**Create Service Principal:**

1. Azure AD → App registrations → New registration
2. Create client secret
3. Grant permissions to Warehouse
4. Use in Data Factory linked services

### Managed Identity

**For Fabric Services:**

```json
{
  "name": "LS_Warehouse_ManagedIdentity",
  "type": "SqlServer",
  "typeProperties": {
    "connectionString": "Server=tcp:warehouse.database.windows.net;Database=HR_Warehouse;Authentication=Active Directory Managed Identity"
  }
}
```

### Best Practices

- ✅ Use Managed Identity when possible
- ✅ Use Service Principal for automation
- ✅ Rotate credentials regularly
- ✅ Grant minimal required permissions
- ✅ Store credentials in Key Vault
- ❌ Don't use user credentials for automation
- ❌ Don't hardcode credentials

---

## Pattern 6: Network Security

### Private Endpoints

**Configure Private Endpoint:**

1. Azure Portal → Warehouse → Networking
2. Enable private endpoint
3. Configure virtual network
4. Restrict public access

### Firewall Rules

**Configure Firewall:**

```sql
-- Allow specific IP ranges
EXEC sp_set_firewall_rule 
    @name = 'AllowOfficeIPs',
    @start_ip_address = '192.168.1.0',
    @end_ip_address = '192.168.1.255';
```

### Best Practices

- ✅ Use private endpoints for production
- ✅ Configure firewall rules
- ✅ Restrict public access
- ✅ Use VPN for remote access
- ✅ Monitor network access
- ❌ Don't allow unrestricted public access
- ❌ Don't skip network security

---

## Pattern 7: Data Encryption

### Encryption at Rest

**Transparent Data Encryption (TDE):**

```sql
-- Enable TDE (usually enabled by default)
ALTER DATABASE HR_Warehouse
SET ENCRYPTION ON;
```

### Encryption in Transit

**SSL/TLS:**

- Enabled by default for Fabric connections
- Ensure all connections use encrypted protocols
- Verify certificate validation

### Column-Level Encryption

**Encrypt Sensitive Columns:**

```sql
-- Create master key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword123!';

-- Create certificate
CREATE CERTIFICATE SalaryCert
WITH SUBJECT = 'Salary Encryption Certificate';

-- Create symmetric key
CREATE SYMMETRIC KEY SalaryKey
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE SalaryCert;

-- Encrypt column
OPEN SYMMETRIC KEY SalaryKey DECRYPTION BY CERTIFICATE SalaryCert;

UPDATE t2.dim_employee
SET annual_salary_encrypted = EncryptByKey(Key_GUID('SalaryKey'), CAST(annual_salary AS VARCHAR(20)));
```

### Best Practices

- ✅ Enable TDE for all databases
- ✅ Use SSL/TLS for all connections
- ✅ Encrypt sensitive columns when needed
- ✅ Manage encryption keys securely
- ✅ Document encryption strategy
- ❌ Don't skip encryption for sensitive data
- ❌ Don't store encryption keys in code

---

## Pattern 8: Audit Logging

### Audit Configuration

**Enable Audit:**

```sql
-- Create audit
CREATE SERVER AUDIT HR_Audit
TO FILE (
    FILEPATH = 'https://storageaccount.blob.core.windows.net/audit/',
    MAXSIZE = 1 GB,
    MAX_ROLLOVER_FILES = 10
)
WITH (
    QUEUE_DELAY = 1000,
    ON_FAILURE = CONTINUE
);

-- Enable audit
ALTER SERVER AUDIT HR_Audit WITH (STATE = ON);
```

**Create Audit Specification:**

```sql
-- Audit data access
CREATE SERVER AUDIT SPECIFICATION HR_Audit_Spec
FOR SERVER AUDIT HR_Audit
ADD (DATABASE_OBJECT_ACCESS_GROUP),
ADD (SCHEMA_OBJECT_ACCESS_GROUP);

ALTER SERVER AUDIT SPECIFICATION HR_Audit_Spec WITH (STATE = ON);
```

### Custom Audit Logging

**Log to T0:**

```sql
-- T0 audit table
CREATE TABLE t0.audit_log (
    audit_id INT IDENTITY(1,1) PRIMARY KEY,
    audit_timestamp DATETIME2 DEFAULT GETDATE(),
    user_name VARCHAR(100),
    action_type VARCHAR(50),
    object_name VARCHAR(200),
    ip_address VARCHAR(50),
    details VARCHAR(MAX)
);

-- Trigger for audit logging
CREATE TRIGGER trg_audit_employee_access
ON t5.vw_payroll_detail
AFTER SELECT
AS
BEGIN
    INSERT INTO t0.audit_log (user_name, action_type, object_name, ip_address)
    VALUES (
        USER_NAME(),
        'SELECT',
        't5.vw_payroll_detail',
        CONNECTIONPROPERTY('client_net_address')
    );
END;
```

### Best Practices

- ✅ Enable audit logging
- ✅ Log sensitive data access
- ✅ Store audit logs in T0
- ✅ Monitor audit logs regularly
- ✅ Retain audit logs per compliance requirements
- ❌ Don't skip audit logging
- ❌ Don't ignore audit log alerts

---

## Pattern 9: Security Testing

### Test RLS Policies

**Test with Different Users:**

```sql
-- Test as different user
EXECUTE AS USER = 'test_user@domain.com';

SELECT * FROM t5.vw_payroll_detail;
-- Verify only authorized data returned

REVERT;
```

**Test Security Functions:**

```sql
-- Test security function
SELECT * FROM t5.fn_security_filter_department();
-- Verify correct departments returned
```

### Best Practices

- ✅ Test RLS with various users
- ✅ Test security functions
- ✅ Verify column-level security
- ✅ Test edge cases
- ✅ Document test results
- ❌ Don't skip security testing
- ❌ Don't assume RLS works without testing

---

## Pattern 10: Security Best Practices Summary

### General Security Principles

1. **Least Privilege**: Grant minimal required permissions
2. **Defense in Depth**: Multiple security layers
3. **Audit Everything**: Log all security events
4. **Encrypt Sensitive Data**: Use encryption at rest and in transit
5. **Regular Reviews**: Review security policies regularly

### Implementation Checklist

- [ ] Implement RLS at T5 layer
- [ ] Create security roles in semantic model
- [ ] Configure column-level security
- [ ] Enable audit logging
- [ ] Use Managed Identity for automation
- [ ] Configure network security
- [ ] Encrypt sensitive columns
- [ ] Test security policies
- [ ] Document security requirements
- [ ] Review security regularly

### Best Practices

- ✅ Follow least privilege principle
- ✅ Implement defense in depth
- ✅ Audit all security events
- ✅ Encrypt sensitive data
- ✅ Test security thoroughly
- ✅ Document security policies
- ✅ Review security regularly
- ❌ Don't grant excessive permissions
- ❌ Don't skip security testing
- ❌ Don't ignore security alerts

---

## Summary

Security patterns in the T0-T5 architecture focus on:

1. **RLS Implementation**: Row-level security at T5 and semantic layer
2. **Column-Level Security**: Restrict access to sensitive columns
3. **Authentication**: Use Managed Identity and Service Principals
4. **Network Security**: Private endpoints and firewall rules
5. **Encryption**: Encrypt data at rest and in transit
6. **Audit Logging**: Log all security events
7. **Security Testing**: Test security policies thoroughly

## Related Topics

- [T0-T5 Architecture Pattern](../architecture/architecture-pattern.md) - Architecture overview
- [Warehouse Patterns](../patterns/warehouse-patterns.md) - Warehouse security patterns
- [Lakehouse Patterns](../patterns/lakehouse-patterns.md) - Lakehouse security patterns
- [Monitoring & Observability](monitoring-observability.md) - Audit logging

---

Follow these patterns to build secure, compliant data warehouses in Fabric.
