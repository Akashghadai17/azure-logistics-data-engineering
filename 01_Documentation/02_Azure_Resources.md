# Azure Resources

## Resource Group
Planned resource group:

```text
rg-logistic-dev
```

Recommended region:

```text
Central India
```

## Resources
| Resource | Suggested Name | Purpose |
|---|---|---|
| Resource Group | `rg-logistic-dev` | Logical project container |
| Storage Account | `stlogisticdevXX` | ADLS Gen2 data lake |
| Azure SQL Server | `sql-logistic-dev-XX` | Hosts metadata database |
| Azure SQL Database | `LogisticDB` | Stores ETL metadata/configuration |
| Key Vault | `kv-logistic-dev-XX` | Stores SQL credentials and secrets |
| Databricks Workspace | `dbw-logistic-dev` | PySpark ETL processing |
| Access Connector | `ac-logistic-databricks` | Managed-identity access from Unity Catalog to ADLS |
| Data Factory | `adf-logistic-dev-XX` | Pipeline orchestration |

## Resource Design
```text
rg-logistic-dev
│
├── ADLS Gen2
├── Azure SQL Server
│   └── LogisticDB
├── Key Vault
├── Azure Databricks
├── Access Connector
└── Azure Data Factory
```

## Security Approach
- Do not hard-code passwords, client secrets, storage keys, or connection strings in notebooks.
- Use the Access Connector managed identity for Unity Catalog access to ADLS.
- Store SQL credentials in Azure Key Vault.
- Grant only required RBAC permissions.
- Use ADF managed identity where possible for orchestration-related access.
