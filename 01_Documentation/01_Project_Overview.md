# Azure Logistics Data Engineering Project

## Project Overview
This project implements an end-to-end Azure data engineering pipeline for logistics sales and appointment data. The solution follows a Medallion Architecture with Bronze, Silver, and Gold layers and uses metadata-driven processing so that ingestion and transformation behavior can be controlled from configuration tables instead of hard-coding every rule.

## Business Objective
The objective is to ingest logistics data, standardize and validate it, support incremental loading, and publish business-ready dimension and fact tables for downstream analytics.

## Source Data
Two source datasets are used:

| Dataset | Example File | Rows | Columns |
|---|---|---:|---:|
| Sales | `Sales_Data_Prior_Day_19072026.csv` | 8,566 | 40 |
| Appointment | `AppointmentDataTest_19072026 (1).csv` | 2 | 40 |

## Technology Stack
- GitHub
- Azure Resource Group
- Azure Data Lake Storage Gen2
- Azure SQL Database
- Azure Key Vault
- Azure Databricks
- Apache Spark / PySpark
- Delta Lake
- Unity Catalog
- Azure Data Factory
- SQL

## High-Level Flow
```text
CSV source files
      ↓
ADLS Gen2 Landing
      ↓
Databricks Bronze
      ↓
Databricks Silver
      ↓
Gold Dimension + Fact
      ↓
Validation / Logging

ADF orchestrates the complete workflow after the notebooks are tested manually.
```

## Medallion Layers
### Bronze
Stores ingested source data with minimum transformation and technical audit columns.

### Silver
Performs column standardization, metadata-driven renaming, null handling, datatype casting, date parsing, duplicate removal, validation, and incremental Delta MERGE.

### Gold
Creates business-ready objects:
- `gold.edw.dim_appointment_data`
- `gold.edw.fact_sales`

## Key Engineering Features
- Metadata-driven ETL
- Bronze/Silver/Gold architecture
- Delta Lake tables
- Incremental UPSERT using MERGE
- Null-safe business-key matching
- Unity Catalog governance
- Key Vault-based secret management
- ETL validation and logging
- ADF orchestration
