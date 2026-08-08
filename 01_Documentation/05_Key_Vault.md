# Azure Key Vault and Security

## Key Vault
Suggested name:

```text
kv-logistic-dev-XX
```

## Secrets
Store values such as:

```text
sql-server
sql-database
sql-username
sql-password
```

Additional secrets may be stored only if required by the final authentication design.

## Rules
Never commit the following to GitHub:
- SQL passwords
- Service principal client secrets
- Storage account keys
- Databricks tokens
- Connection strings
- Key Vault secret values

## Databricks Usage
Databricks should retrieve secrets securely rather than hard-code them.

Conceptual flow:

```text
Databricks Notebook
       ↓
Secret Scope / Key Vault
       ↓
Azure SQL credentials
       ↓
JDBC connection
```

## Unity Catalog Storage Access
For ADLS access through Unity Catalog, use:

```text
Access Connector Managed Identity
        ↓
Azure RBAC on Storage
        ↓
Storage Credential
        ↓
External Location
```

This keeps storage credentials out of notebook code.
