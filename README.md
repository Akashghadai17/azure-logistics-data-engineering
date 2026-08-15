# Logistics Azure Data Engineering Project

## Overview

This project is an end-to-end **Azure Data Engineering solution** built to process logistics-related **Sales** and **Appointment** data.

The pipeline uses Azure cloud services to ingest, validate, clean, transform, model, monitor, and store data using the **Medallion Architecture**.

```text
Bronze → Silver → Gold
```

The project also implements:

* Metadata-driven ETL
* Data Quality Checks
* Delta Lake MERGE / UPSERT
* Dimension and Fact modeling
* ETL audit logging
* Error handling
* Azure Key Vault security
* Azure Data Factory orchestration
* Unity Catalog managed tables

---

# Project Architecture

```text
Sales CSV + Appointment CSV
             ↓
          SC1 ADLS
             ↓
           Landing
             ↓
     Azure Data Factory
             ↓
      Azure Databricks
             ↓
           Bronze
             ↓
           Silver
             ↓
     Data Quality Checks
             ↓
            Gold
        /           \
       ↓             ↓
DIM_APPOINTMENT   FACT_SALES
       \             /
        \           /
             ↓
        Unity Catalog
             ↓
     SC2 Managed Storage
```

Supporting services:

```text
Azure SQL Database
        │
        ├── metadata
        │     ├── OBJECTS_CONFIGURATION
        │     └── OBJECTS_COLUMN_MAPPING
        │
        └── audit
              └── ETL_LOG
```

```text
Azure Key Vault
      ↓
Secure Credentials / Secrets
```

---

# Source Data

The project processes two CSV datasets:

1. Sales Data
2. Appointment Data

The source files are stored in the Landing area of the first ADLS Gen2 storage account.

---

# Technologies Used

* Microsoft Azure
* Azure Data Factory
* Azure Data Lake Storage Gen2
* Azure Databricks
* Azure SQL Database
* Azure Key Vault
* Unity Catalog
* Apache Spark
* PySpark
* Delta Lake
* SQL
* Git
* GitHub

---

# Storage Architecture

The project uses two ADLS Gen2 storage accounts.

## SC1 — File Storage

SC1 is used for:

```text
SC1
│
├── landing
├── logs
└── archive
```

### Landing

Stores incoming Sales and Appointment CSV files.

### Logs

Stores file-based technical or processing logs where required.

### Archive

Stores source files after successful processing.

---

## SC2 — Unity Catalog Managed Storage

SC2 is used for Unity Catalog managed tables.

```text
SC2
   ↓
Unity Catalog Managed Storage
   ↓
Bronze
Silver
Gold
```

Bronze, Silver, and Gold are stored as **managed Delta tables**.

---

# Medallion Architecture

## Bronze Layer

The Bronze layer stores raw or near-raw source data.

Main activities:

* Read CSV files
* Preserve source values
* Validate schema
* Check expected columns
* Detect missing columns
* Detect extra columns
* Store data as managed Delta tables

Easy definition:

```text
Bronze = Preserve
```

---

## Silver Layer

The Silver layer cleans and standardizes the Bronze data.

Main transformations:

* Metadata-driven column mapping
* Column renaming
* Data type conversion
* Malformed-value handling
* NULL handling
* Duplicate removal
* Data cleaning
* Data standardization

Easy definition:

```text
Silver = Clean
```

---

## Gold Layer

The Gold layer creates business-ready analytical data.

Final tables:

```text
DIM_APPOINTMENT_DATA
FACT_SALES
```

Easy definition:

```text
Gold = Business Ready
```

---

# Metadata-Driven ETL

Azure SQL Database stores ETL configuration.

Main metadata tables:

```sql
metadata.OBJECTS_CONFIGURATION
```

and:

```sql
metadata.OBJECTS_COLUMN_MAPPING
```

## OBJECTS_CONFIGURATION

Stores object-level ETL configuration.

Easy way to remember:

```text
What should I process?
```

## OBJECTS_COLUMN_MAPPING

Stores source-to-target column mappings and target data types.

Easy way to remember:

```text
How should I transform the columns?
```

---

# Metadata Flow

```text
Azure SQL Metadata
        ↓
Azure Databricks
        ↓
Read Configuration
        ↓
Reusable PySpark Logic
        ↓
Data Processing
```

This reduces hard-coded ETL logic.

---

# Data Quality Checks

The project includes checks such as:

* Row count validation
* NULL validation
* Duplicate validation
* Primary key validation
* Foreign key validation
* Schema validation
* Required-column validation
* Data type validation
* Invalid-value validation

Flow:

```text
Silver
   ↓
Data Quality Checks
   ↓
PASS
   ↓
Gold
```

---

# Gold Data Model

The final Gold layer contains:

```text
DIM_APPOINTMENT_DATA
        ↓
    Relationship
        ↓
    FACT_SALES
```

## Dimension Table

`DIM_APPOINTMENT_DATA` stores descriptive Appointment information.

```text
Dimension = Description
```

## Fact Table

`FACT_SALES` stores measurable Sales information.

```text
Fact = Measurement
```

---

# Surrogate Key

A surrogate key is used in the analytical Dimension model.

```text
Business Key
      ↓
Comes from Source

Surrogate Key
      ↓
Created for Analytical Model
```

The surrogate key helps connect the Dimension and Fact tables.

---

# Delta Lake

Delta Lake is used for managed Bronze, Silver, and Gold tables.

It provides:

* ACID transactions
* Schema enforcement
* UPDATE support
* DELETE support
* MERGE support
* Reliable data processing
* Incremental loading

---

# Incremental Loading

The project supports incremental processing.

Instead of reloading all historical records:

```text
New / Changed Records
        ↓
Existing Delta Table
        ↓
MERGE
```

---

# MERGE / UPSERT

Delta MERGE performs:

```text
Existing Record
      ↓
UPDATE
```

and:

```text
New Record
      ↓
INSERT
```

Therefore:

```text
UPSERT = UPDATE + INSERT
```

---

# ETL Audit Logging

Azure SQL Database stores structured ETL execution history.

Main audit table:

```sql
audit.ETL_LOG
```

Typical status values:

```text
STARTED
SUCCESS
FAILED
```

The audit log can contain:

* Process name
* Object name
* Layer
* Start time
* End time
* Record count
* Status
* Error message

---

# Error Handling

Databricks uses Python exception handling.

Conceptually:

```python
try:
    # ETL processing

except Exception as e:
    # Capture error
    # Write FAILED audit log
    raise
```

The exception is raised again so Azure Data Factory correctly marks the Databricks activity as failed.

---

# Azure Data Factory

Azure Data Factory acts as the **orchestration layer**.

ADF controls:

* Pipeline execution
* Databricks notebook execution
* Activity sequence
* Dependencies
* Success and failure flow
* Pipeline monitoring

Easy way to remember:

```text
ADF = Controls the workflow

Databricks = Processes the data
```

---

# Azure Key Vault

Azure Key Vault securely stores sensitive information such as:

* Azure SQL credentials
* Service Principal Client ID
* Client Secret
* Tenant ID
* Storage-related secrets

Actual secrets are never committed to GitHub.

---

# Unity Catalog

Unity Catalog is used to centrally manage:

* Catalogs
* Schemas
* Tables
* Permissions
* Data governance
* Managed storage

The project uses:

```text
bronze
silver
gold
```

schemas.

The physical managed storage is located in SC2.

---

# Real Data Issue Handled

During Sales Silver processing, a malformed numeric value was found:

```text
215.0000, 230.0000
```

The required target type was:

```text
FLOAT
```

Spark raised:

```text
CAST_INVALID_INPUT
```

because the value could not be directly converted into a single FLOAT.

The Silver transformation logic was adjusted to safely clean or handle the value before applying the target data type.

This demonstrates practical handling of dirty source data.

---

# Project Flow

```text
CSV Files
    ↓
SC1 Landing
    ↓
ADF
    ↓
Databricks
    ↓
Bronze
    ↓
Silver
    ↓
Data Quality
    ↓
Gold
    ↓
DIM + FACT
    ↓
Delta MERGE
    ↓
Unity Catalog
    ↓
SC2
```

Supporting services:

```text
Azure SQL
→ Metadata + Audit

Azure Key Vault
→ Security
```

---

# Repository Structure

```text
Logistics-Azure-Data-Engineering/
│
├── README.md
│
├── .gitignore
│
├── 01_Documentation/
│   ├── 01_Project_Overview.md
│   ├── 02_Azure_Resources.md
│   ├── 03_ADLS_Design.md
│   ├── 04_Azure_SQL_Metadata_Configuration.md
│   ├── 05_Key_Vault.md
│   ├── 06_Azure_Databricks.md
│   ├── 07_Unity_Catalog.md
│   ├── 08_Bronze_Layer.md
│   ├── 09_Silver_Layer.md
│   ├── 10_Gold_Layer.md
│   ├── 11_Data_Quality_Checks.md
│   ├── 12_Incremental_Load_Merge_Upsert.md
│   ├── 13_ETL_Logging_Error_Handling.md
│   ├── 14_ADF_Orchestration.md
│   ├── 15_End_to_End_Project_Flow.md
│   ├── 16_Interview_Explanation.md
│   ├── 17_Project_Summary.md
│   └── 18_Repository_Structure.md
│
├── 02_SQL/
│
├── 03_Databricks_Notebooks/
│
├── 04_ADF/
│
├── 05_Sample_Data/
│
└── 06_Architecture/
```

---

# Key Project Features

* End-to-end Azure Data Engineering pipeline
* Two ADLS Gen2 storage accounts
* Medallion Architecture
* Azure Data Factory orchestration
* Azure Databricks processing
* Apache Spark
* PySpark
* Delta Lake
* Unity Catalog
* Managed Delta tables
* Metadata-driven ETL
* Dynamic column mapping
* Schema validation
* Data cleaning
* NULL handling
* Duplicate removal
* Data type conversion
* Data Quality Checks
* Dimension and Fact modeling
* Surrogate key
* Incremental loading
* Delta MERGE / UPSERT
* ETL audit logging
* Error handling
* Azure Key Vault security
* Source file archiving
* Git/GitHub version control

---

# Skills Demonstrated

This project demonstrates practical knowledge of:

```text
Azure Data Engineering
ETL / ELT
Azure Data Factory
Azure Databricks
ADLS Gen2
PySpark
Apache Spark
Delta Lake
Unity Catalog
Azure SQL Database
Metadata-Driven ETL
Data Quality
Dimensional Modeling
Incremental Loading
ETL Monitoring
Error Handling
Azure Key Vault
Git / GitHub
```

---

# Project Outcome

The completed pipeline converts raw Logistics Sales and Appointment CSV files into trusted and business-ready analytical data.

The final Gold model contains:

```text
DIM_APPOINTMENT_DATA
FACT_SALES
```

The project demonstrates how Azure services can be combined to build a secure, maintainable, metadata-driven, and scalable Data Engineering solution.

---

# Short Project Explanation

> Built an end-to-end Logistics Data Engineering pipeline on Microsoft Azure using ADF, Databricks, PySpark, ADLS Gen2, Delta Lake, Unity Catalog, Azure SQL, and Key Vault. Implemented Bronze, Silver, and Gold Medallion Architecture, metadata-driven transformations, Data Quality Checks, Dimension and Fact modeling, incremental Delta MERGE / UPSERT, ETL audit logging, error handling, and secure secret management.

