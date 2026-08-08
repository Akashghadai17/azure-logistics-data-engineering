# Unity Catalog Design

## Purpose
Unity Catalog provides centralized governance for Databricks data objects and controlled access to ADLS storage.

## Storage Access Flow
```text
ADLS Gen2
    ↑
External Location
    ↑
Storage Credential
    ↑
Access Connector Managed Identity
```

## Catalog and Schema Structure
This project uses separate catalogs for each Medallion layer.

```text
Catalog: bronze
└── Schema: logistic
    ├── sales_data_prior_day
    └── appointment_data

Catalog: silver
└── Schema: logistic
    ├── sales_data_prior_day
    └── appointment_data

Catalog: gold
└── Schema: edw
    ├── dim_appointment_data
    └── fact_sales
```

## SQL Structure
```sql
CREATE CATALOG IF NOT EXISTS bronze;
CREATE CATALOG IF NOT EXISTS silver;
CREATE CATALOG IF NOT EXISTS gold;

CREATE SCHEMA IF NOT EXISTS bronze.logistic;
CREATE SCHEMA IF NOT EXISTS silver.logistic;
CREATE SCHEMA IF NOT EXISTS gold.edw;
```

## Recommended External Locations
```text
ext_logistic_bronze → abfss://bronze@<storage>.dfs.core.windows.net/
ext_logistic_silver → abfss://silver@<storage>.dfs.core.windows.net/
ext_logistic_gold   → abfss://gold@<storage>.dfs.core.windows.net/
```

## Final Table Names
```text
bronze.logistic.sales_data_prior_day
bronze.logistic.appointment_data
silver.logistic.sales_data_prior_day
silver.logistic.appointment_data
gold.edw.dim_appointment_data
gold.edw.fact_sales
```
