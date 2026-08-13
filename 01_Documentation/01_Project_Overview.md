# Logistics Azure Data Engineering Project

## Project Objective

Build an end-to-end Azure Data Engineering pipeline
to process logistics sales and appointment data.

## Source Data

1. Sales Data
2. Appointment Data

## Architecture

CSV Source
→ ADLS Gen2
→ Azure Databricks
→ Bronze
→ Silver
→ Gold
→ Dimension and Fact Tables

## Technologies

- Microsoft Azure
- Azure Data Lake Storage Gen2
- Azure Data Factory
- Azure Databricks
- Apache Spark
- PySpark
- Delta Lake
- Azure SQL Database
- Azure Key Vault
- Git
- GitHub

## Medallion Architecture

### Bronze
Stores raw source data.

### Silver
Stores cleaned and standardized data.

### Gold
Stores business-ready analytical data.

## Final Gold Tables

- DIM_APPOINTMENT_DATA
- FACT_SALES

## Project Features

- Data ingestion
- Data cleaning
- Duplicate removal
- NULL handling
- Data type conversion
- Data validation
- Incremental loading
- Delta MERGE
- ETL logging
- Error handling
- ADF orchestration
