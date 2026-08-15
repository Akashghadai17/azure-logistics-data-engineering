# Azure Key Vault

## Overview

Azure Key Vault is used in the **Logistics Azure Data Engineering Project** to securely store sensitive information such as:

* Azure SQL credentials
* Service Principal credentials
* Storage credentials
* Client ID
* Client Secret
* Tenant ID
* Other secrets required by the ETL pipeline

Instead of writing passwords and credentials directly inside Azure Databricks notebooks, the project stores them securely in Azure Key Vault.

---

# Why Azure Key Vault Is Used

Data Engineering projects often require connections between multiple Azure services.

For example:

```text
Azure Databricks
      ↓
Azure SQL Database
```

or:

```text
Azure Databricks
      ↓
Azure Storage
```

These connections may require sensitive information such as:

```text
Username
Password
Client ID
Client Secret
Tenant ID
Storage Key
```

Hard-coding this information directly inside notebooks is not secure.

For example, this should be avoided:

```python
username = "myusername"
password = "mypassword"
```

Instead, credentials are stored securely in Azure Key Vault.

---

# Key Vault Role in the Project

The high-level security flow is:

```text
Azure Key Vault
      ↓
Secure Secrets
      ↓
Azure Databricks
      ↓
ETL Processing
```

Azure Key Vault acts as the centralized location for sensitive configuration.

---

# Secrets Stored

The project uses Key Vault to store secrets required by different components.

Examples include:

```text
SQL Server Name
SQL Database Name
SQL Username
SQL Password
Service Principal Client ID
Service Principal Client Secret
Tenant ID
Storage Credential / Storage Key
```

The exact secret names in Azure can differ depending on the naming convention used during implementation.

---

# Azure SQL Secrets

Databricks connects to Azure SQL Database to read:

```sql
metadata.OBJECTS_CONFIGURATION
```

```sql
metadata.OBJECTS_COLUMN_MAPPING
```

and to write/read:

```sql
audit.ETL_LOG
```

Azure SQL connection information is therefore stored securely in Key Vault.

Typical SQL-related secrets include:

```text
sql-server-name
sql-database-name
sql-username
sql-password
```

---

# Service Principal Secrets

The project also uses a Service Principal for secure authentication where required.

Service Principal information can include:

```text
Client ID
Client Secret
Tenant ID
```

These values are sensitive and should not be stored directly in source code.

Conceptually:

```text
Azure Key Vault
      │
      ├── Client ID
      ├── Client Secret
      └── Tenant ID
```

---

# Storage Credentials

Storage-related credentials may also be stored securely in Key Vault where required.

The project uses two ADLS Gen2 storage accounts:

```text
SC1
│
├── landing
├── logs
└── archive
```

and:

```text
SC2
│
└── Unity Catalog Managed Storage
```

Storage access information should not be hard-coded inside Databricks notebooks.

---

# Two Storage Accounts and Key Vault

The project separates storage responsibilities.

## SC1

SC1 is used for file-based project storage.

```text
SC1
│
├── landing
├── logs
└── archive
```

SC1 contains:

* Incoming Sales files
* Incoming Appointment files
* Processing log files
* Archived source files

---

## SC2

SC2 is used for Unity Catalog managed storage.

```text
SC2
      ↓
Unity Catalog
      ↓
Bronze
Silver
Gold
```

Bronze, Silver, and Gold data are created as **Unity Catalog managed Delta tables**.

The physical storage for these managed tables is maintained in SC2.

---

# Secret Management Architecture

```text
                        Azure Key Vault
                              │
             ┌────────────────┼────────────────┐
             │                │                │
             ↓                ↓                ↓
       SQL Credentials   SP Credentials   Storage Secrets
             │                │                │
             └────────────────┼────────────────┘
                              ↓
                       Azure Databricks
                              ↓
                        ETL Processing
```

---

# Databricks Secret Scope

Azure Databricks can securely access Key Vault secrets through a secret scope.

Conceptually:

```text
Azure Key Vault
      ↓
Databricks Secret Scope
      ↓
Databricks Notebook
```

The Databricks notebook retrieves a secret using:

```python
dbutils.secrets.get(
    scope="<secret-scope-name>",
    key="<secret-name>"
)
```

Example:

```python
sql_username = dbutils.secrets.get(
    scope="<secret-scope-name>",
    key="sql-username"
)
```

Example:

```python
sql_password = dbutils.secrets.get(
    scope="<secret-scope-name>",
    key="sql-password"
)
```

This allows the notebook to use credentials without exposing the actual values.

---

# Secure SQL Connection

Azure Databricks uses JDBC to connect to Azure SQL Database.

The connection flow is:

```text
Azure Key Vault
      ↓
Retrieve SQL Credentials
      ↓
Azure Databricks
      ↓
JDBC Connection
      ↓
Azure SQL Database
```

Example JDBC configuration:

```python
jdbc_url = (
    f"jdbc:sqlserver://{server_name}:1433;"
    f"database={database_name};"
    "encrypt=true;"
    "trustServerCertificate=false;"
)
```

Username and password are retrieved securely from Key Vault instead of being hard-coded.

---

# JDBC Properties

Conceptually:

```python
connection_properties = {
    "user": sql_username,
    "password": sql_password,
    "driver": "com.microsoft.sqlserver.jdbc.SQLServerDriver"
}
```

Because `sql_username` and `sql_password` are retrieved from Key Vault, the actual credentials are not visible in the notebook.

---

# Reading Metadata Securely

Databricks uses the secured SQL connection to read metadata.

Flow:

```text
Key Vault
    ↓
SQL Credentials
    ↓
Databricks
    ↓
JDBC
    ↓
Azure SQL Database
    ↓
metadata.OBJECTS_CONFIGURATION
    +
metadata.OBJECTS_COLUMN_MAPPING
```

This metadata is then used for ETL processing.

---

# Writing Audit Logs Securely

The same secure Azure SQL connection can be used for ETL audit logging.

Flow:

```text
Databricks ETL
      ↓
ETL Status
      ↓
Secure JDBC Connection
      ↓
Azure SQL Database
      ↓
audit.ETL_LOG
```

The audit log records statuses such as:

```text
STARTED
SUCCESS
FAILED
```

---

# Service Principal Authentication

A Service Principal is an application identity used by Azure services and applications.

Instead of using a personal user account, the Service Principal can be assigned the required Azure permissions.

It uses information such as:

```text
Tenant ID
Client ID
Client Secret
```

Conceptual authentication flow:

```text
Service Principal
      ↓
Client ID
Client Secret
Tenant ID
      ↓
Azure Authentication
      ↓
Authorized Resource Access
```

---

# Why Service Principal Is Useful

Using a Service Principal provides:

* Application-based authentication
* Reduced dependency on personal user accounts
* Controlled Azure permissions
* Better automation
* Better security for pipelines

---

# Key Vault and Service Principal

Sensitive Service Principal information can be stored inside Key Vault.

```text
Azure Key Vault
      │
      ├── SP Client ID
      ├── SP Client Secret
      └── Tenant ID
              ↓
       Secure Authentication
```

This prevents the Service Principal secret from appearing directly inside notebooks.

---

# Unity Catalog Security

The project uses Azure Databricks **Unity Catalog** to manage Bronze, Silver, and Gold tables.

The storage design is:

```text
SC2
 ↓
Unity Catalog Managed Storage
 ↓
Bronze
Silver
Gold
```

Unity Catalog provides centralized governance and access management for the managed tables.

Key Vault is used for protecting secrets required by other ETL connections, while Unity Catalog manages access to the managed data objects.

---

# Key Vault vs Unity Catalog

These two services serve different purposes.

## Azure Key Vault

Used for:

```text
Secrets
Passwords
Credentials
Client Secrets
Connection Information
```

## Unity Catalog

Used for:

```text
Catalog Management
Schema Management
Table Management
Data Governance
Access Control
```

Easy way to remember:

```text
Key Vault
   ↓
Protects Secrets

Unity Catalog
   ↓
Governs Data
```

---

# Key Vault vs Azure SQL Metadata

Azure Key Vault and Azure SQL metadata also have different roles.

## Key Vault

Stores sensitive information.

Example:

```text
SQL Password
Client Secret
Storage Credential
```

## Azure SQL Metadata

Stores ETL configuration.

Example:

```sql
metadata.OBJECTS_CONFIGURATION
metadata.OBJECTS_COLUMN_MAPPING
```

Easy difference:

```text
Key Vault
    ↓
How do I connect securely?

Metadata
    ↓
What should I process?
```

---

# Key Vault vs Audit Table

Azure Key Vault protects credentials.

The audit table records ETL execution.

```text
Azure Key Vault
      ↓
Security

audit.ETL_LOG
      ↓
Monitoring
```

These are separate responsibilities.

---

# Security Flow for the Project

```text
                         Azure Key Vault
                               │
                               ↓
                       Secure Credentials
                               │
                               ↓
                       Azure Databricks
                               │
               ┌───────────────┼───────────────┐
               │               │               │
               ↓               ↓               ↓
          Azure SQL           SC1          Unity Catalog
               │               │               │
        Metadata + Audit   Landing/Logs        │
                            /Archive            ↓
                                             SC2
                                         Managed Storage
```

---

# Secrets Should Never Be Printed

Even when using Key Vault, retrieved secrets should not be displayed in notebook output.

Avoid:

```python
print(sql_password)
```

Avoid:

```python
display(client_secret)
```

Secrets should only be passed to the connection or authentication logic that requires them.

---

# Secrets Should Not Be Stored in GitHub

Sensitive values should never be committed to GitHub.

Do not store values such as:

```text
SQL Password
Client Secret
Storage Account Key
Access Token
Connection String with Password
```

inside:

```text
.py files
.ipynb files
.md files
.sql files
configuration files
```

Only secret **names or placeholders** should appear in documentation.

Example:

```text
<sql-password>
<client-secret>
<storage-key>
```

---

# Safe Documentation Example

Correct:

```python
sql_password = dbutils.secrets.get(
    scope="<secret-scope-name>",
    key="sql-password"
)
```

Incorrect:

```python
sql_password = "ActualPassword123"
```

The first approach is safe for GitHub documentation because it does not expose the actual secret.

---

# Benefits of Azure Key Vault

Azure Key Vault provides several benefits for the project.

## Security

Sensitive information is not stored directly inside notebooks.

## Centralized Management

Credentials can be managed from one Azure service.

## Maintainability

If a credential changes, the secret can be updated in Key Vault without rewriting notebook code.

## Reduced Hard-Coding

Passwords and secrets are separated from application logic.

## Better Integration

Azure services can retrieve credentials securely when required.

---

# Complete Key Vault Flow

```text
                    Azure Key Vault
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ↓               ↓               ↓
   SQL Secrets      SP Secrets      Storage Secrets
         │               │               │
         └───────────────┼───────────────┘
                         ↓
                Databricks Secret Scope
                         ↓
                  Databricks Notebook
                         ↓
              Secure ETL Connections
                         │
          ┌──────────────┼──────────────┐
          ↓              ↓              ↓
     Azure SQL          SC1        Other Required
     Database          ADLS         Azure Access
```

---

# Project Security Architecture

```text
Source Files
     ↓
SC1 Landing
     ↓
Azure Databricks
     │
     ├── Retrieve Secrets from Key Vault
     │
     ├── Connect to Azure SQL
     │       │
     │       ├── Metadata
     │       └── Audit
     │
     ├── Process Bronze
     │
     ├── Process Silver
     │
     └── Process Gold
             ↓
        Unity Catalog
             ↓
       SC2 Managed Storage
```

---

# Best Practices Followed

The project follows important security practices:

* Do not hard-code passwords
* Do not commit secrets to GitHub
* Store sensitive credentials in Azure Key Vault
* Retrieve secrets only when required
* Use secure JDBC connections
* Use encrypted SQL connections
* Use application identities where appropriate
* Keep storage access controlled
* Separate security configuration from ETL logic
* Never print secret values in notebook output

---

# Easy Explanation

Azure Key Vault can be understood as a **secure password locker for Azure**.

Instead of:

```text
Databricks Notebook
      ↓
Password Written Directly in Code
```

the project uses:

```text
Azure Key Vault
      ↓
Secure Password
      ↓
Databricks Retrieves Password
      ↓
Secure Connection
```

---

# Interview Explanation

A simple interview explanation is:

> In my Logistics Azure Data Engineering project, I used Azure Key Vault to securely store sensitive information such as Azure SQL credentials, Service Principal credentials, and storage-related secrets. Databricks retrieves the required secrets securely instead of hard-coding passwords inside notebooks. This helps keep credentials out of source code and GitHub and improves the overall security of the ETL pipeline.

---

# Summary

Azure Key Vault is the main **secret-management service** used in the project.

It securely manages:

```text
Azure SQL Credentials
Service Principal Credentials
Storage Credentials
Client ID
Client Secret
Tenant ID
```

The overall security flow is:

```text
Azure Key Vault
      ↓
Secure Secrets
      ↓
Azure Databricks
      ↓
Secure Connections
      ↓
Azure SQL / Azure Storage / Required Azure Services
```

This ensures that sensitive credentials remain separate from the ETL code and GitHub repository.
This keeps storage credentials out of notebook code.
