# Logistics Azure Data Engineering Project — Final Summary

## Project Overview

The **Logistics Azure Data Engineering Project** is an end-to-end cloud Data Engineering solution built on Microsoft Azure.

The project processes two logistics datasets:

* Sales Data
* Appointment Data

The solution covers the complete data lifecycle from raw CSV files to business-ready analytical tables.

---

# Project Objective

The main objective was to build a scalable and maintainable Azure Data Engineering pipeline that performs:

* Data ingestion
* Data storage
* Data transformation
* Data cleaning
* Data validation
* Metadata-driven processing
* Dimensional modeling
* Incremental loading
* ETL monitoring
* Error handling
* Pipeline orchestration
* Secure credential management

---

# Complete Architecture

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

Supporting components:

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
Secure Credentials
```

---

# Azure Services Used

The project uses:

* Microsoft Azure
* Azure Data Lake Storage Gen2
* Azure Data Factory
* Azure Databricks
* Azure SQL Database
* Azure Key Vault
* Unity Catalog
* Apache Spark
* PySpark
* Delta Lake
* Git
* GitHub

---

# Storage Design

The project uses **two ADLS Gen2 storage accounts**.

## SC1 — File Storage

SC1 stores:

```text
SC1
│
├── landing
├── logs
└── archive
```

### Landing

Stores new Sales and Appointment CSV files.

### Logs

Stores file-based technical or processing logs where required.

### Archive

Stores source files after successful processing.

---

## SC2 — Managed Table Storage

SC2 is used as the managed storage location for Databricks Unity Catalog.

```text
SC2
   ↓
Unity Catalog Managed Storage
   ↓
Bronze
Silver
Gold
```

Bronze, Silver, and Gold are stored as **Unity Catalog managed Delta tables**.

---

# Azure Data Factory

Azure Data Factory is used for **pipeline orchestration**.

ADF controls:

* Pipeline execution
* Databricks notebook execution
* Activity dependencies
* Processing order
* Failure handling
* Pipeline monitoring

Easy way to remember:

```text
ADF = Orchestration
```

---

# Azure Databricks

Azure Databricks is used as the main **data processing engine**.

Databricks performs:

* CSV ingestion
* Schema validation
* Bronze processing
* Silver transformation
* Data quality checks
* Gold modeling
* Delta MERGE
* ETL logging
* Error handling

PySpark is used to implement most transformations.

---

# Medallion Architecture

The project follows:

```text
Bronze
   ↓
Silver
   ↓
Gold
```

---

## Bronze Layer

Bronze stores raw or near-raw data.

Main activities:

* Read CSV files
* Preserve source values
* Validate schema
* Check expected columns
* Check missing columns
* Check extra columns
* Store data as managed Delta tables

Easy definition:

```text
Bronze = Preserve
```

---

## Silver Layer

Silver stores cleaned and standardized data.

Main activities:

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

Gold contains business-ready analytical data.

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

Azure SQL Database stores metadata configuration.

Main tables:

```sql
metadata.OBJECTS_CONFIGURATION
```

and:

```sql
metadata.OBJECTS_COLUMN_MAPPING
```

---

## OBJECTS_CONFIGURATION

Stores object-level ETL configuration.

Easy definition:

```text
What should I process?
```

---

## OBJECTS_COLUMN_MAPPING

Stores source-to-target column mappings and data types.

Easy definition:

```text
How should I transform the columns?
```

---

# Metadata Architecture

```text
Azure SQL Metadata
        ↓
Azure Databricks
        ↓
Read Configuration
        ↓
Reusable PySpark Logic
        ↓
Process Data
```

This reduces hard-coded transformation logic.

---

# Data Quality

Data Quality Checks are performed before data is promoted to Gold.

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

Easy definition:

```text
Data Cleaning = Fix Data

Data Quality = Verify Data
```

---

# Gold Data Model

The project creates:

```text
DIM_APPOINTMENT_DATA
        ↓
     Relationship
        ↓
    FACT_SALES
```

---

# Dimension Table

`DIM_APPOINTMENT_DATA` stores descriptive Appointment information.

Easy definition:

```text
Dimension = Description
```

---

# Fact Table

`FACT_SALES` stores measurable Sales information.

Easy definition:

```text
Fact = Measurement
```

---

# Surrogate Key

A surrogate key is created for analytical modeling.

```text
Business Key
      ↓
Comes from Source

Surrogate Key
      ↓
Created in Data Warehouse
```

The surrogate key helps connect the Fact and Dimension tables.

---

# Unity Catalog

Unity Catalog manages:

* Catalogs
* Schemas
* Tables
* Permissions
* Data governance
* Managed storage

The project uses schemas such as:

```text
bronze
silver
gold
```

---

# Delta Lake

Delta Lake is used for processed tables.

It provides:

* ACID transactions
* Reliable writes
* Schema enforcement
* UPDATE
* DELETE
* MERGE
* Incremental loading

---

# Incremental Loading

The project implements incremental loading so that the entire dataset does not need to be reprocessed every time.

```text
New / Changed Data
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

Azure SQL Database stores ETL execution history.

Main audit table:

```sql
audit.ETL_LOG
```

The log records information such as:

* Process name
* Object name
* Layer
* Start time
* End time
* Record count
* Status
* Error details

Main statuses:

```text
STARTED
SUCCESS
FAILED
```

---

# Error Handling

Databricks uses `try-except` logic to capture processing errors.

Conceptually:

```python
try:
    # ETL processing

except Exception as e:
    # Capture error
    # Write FAILED log
    raise
```

The exception is raised again so Azure Data Factory can correctly identify the failed notebook activity.

---

# Error Flow

```text
Databricks Error
      ↓
Capture Exception
      ↓
Write FAILED
      ↓
audit.ETL_LOG
      ↓
raise
      ↓
ADF Activity = FAILED
```

---

# Azure Key Vault

Azure Key Vault securely stores credentials and secrets.

Examples include:

* SQL username
* SQL password
* Client ID
* Client Secret
* Tenant ID
* Storage-related credentials

This prevents sensitive information from being hard-coded in notebooks or GitHub.

---

# Important Problem Solved

During Silver processing, a malformed numeric Sales value was identified.

Example:

```text
215.0000, 230.0000
```

The target type was:

```text
FLOAT
```

Spark could not directly convert the value and raised:

```text
CAST_INVALID_INPUT
```

The Silver transformation logic was adjusted to clean or safely handle malformed numeric values before type conversion.

This demonstrated practical handling of real-world dirty data.

---

# Source File Lifecycle

```text
New Source File
      ↓
SC1 Landing
      ↓
Databricks Processing
      ↓
Successful Processing
      ↓
SC1 Archive
```

This helps separate new files from already processed files.

---

# Monitoring

The pipeline can be monitored through:

```text
ADF Monitor
+
Databricks Job Output
+
Azure SQL audit.ETL_LOG
```

Each provides a different level of monitoring.

---

# Service Responsibilities

| Component          | Responsibility                         |
| ------------------ | -------------------------------------- |
| SC1                | Landing, Logs and Archive              |
| ADF                | Pipeline orchestration                 |
| Databricks         | Data processing                        |
| Spark              | Distributed processing                 |
| PySpark            | Transformation logic                   |
| Azure SQL Metadata | ETL configuration                      |
| Azure SQL Audit    | ETL execution history                  |
| Key Vault          | Secure secret management               |
| Unity Catalog      | Data governance and table management   |
| SC2                | Managed Delta table storage            |
| Delta Lake         | Reliable storage and incremental MERGE |
| Git/GitHub         | Version control and documentation      |

---

# Key Project Features

The project demonstrates:

* End-to-end Azure Data Engineering
* Cloud data storage
* Medallion Architecture
* Two-storage-account architecture
* Azure Data Factory orchestration
* Databricks processing
* Apache Spark
* PySpark
* Delta Lake
* Unity Catalog
* Metadata-driven ETL
* Dynamic column mapping
* Schema validation
* Data cleaning
* NULL handling
* Duplicate removal
* Data type conversion
* Data Quality Checks
* Dimension and Fact modeling
* Surrogate keys
* Incremental loading
* MERGE / UPSERT
* ETL audit logging
* Error handling
* Azure Key Vault security
* Source file archiving
* Pipeline monitoring

---

# What I Learned

Through this project, I gained practical experience with:

* Designing Azure Data Engineering architecture
* Organizing cloud storage
* Creating reusable ETL pipelines
* Using metadata-driven processing
* Building PySpark transformations
* Handling dirty source data
* Designing Bronze, Silver and Gold layers
* Performing Data Quality Checks
* Creating Fact and Dimension tables
* Implementing incremental pipelines
* Using Delta MERGE
* Monitoring ETL jobs
* Capturing processing failures
* Managing secrets securely
* Orchestrating Databricks with ADF

---

# Final Project Flow

```text
                     SALES + APPOINTMENT
                              │
                              ↓
                           CSV Files
                              │
                              ↓
                           SC1 ADLS
                              │
                           Landing
                              │
                              ↓
                    Azure Data Factory
                              │
                              ↓
                    Azure Databricks
                              │
                              ↓
                           Bronze
                              │
                              ↓
                           Silver
                              │
                              ↓
                     Data Quality Checks
                              │
                              ↓
                            Gold
                    ┌─────────┴─────────┐
                    ↓                   ↓
         DIM_APPOINTMENT_DATA       FACT_SALES
                    │                   │
                    └─────────┬─────────┘
                              ↓
                        Unity Catalog
                              ↓
                     Managed Delta Tables
                              ↓
                           SC2 ADLS
```

Supporting:

```text
Azure SQL
│
├── metadata
│   ├── OBJECTS_CONFIGURATION
│   └── OBJECTS_COLUMN_MAPPING
│
└── audit
    └── ETL_LOG
```

```text
Azure Key Vault
      ↓
Secure Credentials
```

---

# One-Line Project Summary

> Built an end-to-end Azure Data Engineering pipeline using ADF, Databricks, PySpark, ADLS Gen2, Delta Lake, Unity Catalog, Azure SQL, and Key Vault with Medallion Architecture, metadata-driven transformations, Data Quality Checks, incremental MERGE, dimensional modeling, ETL logging, and error handling.

---

# Final Outcome

The project successfully demonstrates how multiple Azure Data Engineering services can work together to create a structured, secure, reusable, and maintainable ETL pipeline.

The final architecture processes raw Logistics Sales and Appointment CSV data and converts it into trusted analytical **Dimension and Fact tables** ready for downstream analytics and reporting.
