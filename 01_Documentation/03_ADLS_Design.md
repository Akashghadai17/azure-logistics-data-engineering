# ADLS Gen2 Design

## Overview

Azure Data Lake Storage Gen2 (ADLS Gen2) is used as the main storage layer for the **Logistics Azure Data Engineering Project**.

It stores source files and processed data across the complete data pipeline.

The storage design supports the Medallion Architecture:

```text
Landing
   ↓
Bronze
   ↓
Silver
   ↓
Gold
```

Additional directories are used for:

* Logs
* Archive

---

# Purpose of ADLS Gen2

ADLS Gen2 is used because it provides scalable cloud storage for large amounts of structured and semi-structured data.

In this project, ADLS Gen2 is responsible for:

* Storing incoming CSV files
* Storing Bronze data
* Storing Silver data
* Storing Gold data
* Storing pipeline log files where required
* Archiving processed source files
* Providing storage access to Azure Databricks
* Supporting the complete Medallion Architecture

---

# Storage Architecture

The project follows the following logical storage structure:

```text
ADLS Gen2
│
├── landing
│   ├── sales
│   └── appointment
│
├── bronze
│   ├── sales
│   └── appointment
│
├── silver
│   ├── sales
│   └── appointment
│
├── gold
│   ├── DIM_APPOINTMENT_DATA
│   └── FACT_SALES
│
├── logs
│
└── archive
    ├── sales
    └── appointment
```

Each directory has a specific purpose in the data pipeline.

---

# Hierarchical Namespace

The storage account is configured with **Hierarchical Namespace enabled**.

Hierarchical Namespace converts the storage account into ADLS Gen2 and allows files to be organized using directories and subdirectories.

Example:

```text
landing/
    sales/
    appointment/
```

Instead of storing all files in one location, the project organizes data based on:

* Processing layer
* Dataset
* Data purpose

This makes the storage easier to manage.

---

# Source Data

The project processes two main source datasets:

```text
Sales Data
Appointment Data
```

The source files are received in CSV format.

Example:

```text
Sales CSV
Appointment CSV
```

These files are initially stored in the Landing area.

---

# Landing Layer

## Purpose

The Landing layer is the first storage location for incoming source files.

It stores the source data before Databricks starts processing it.

### Directory Structure

```text
landing/
│
├── sales/
│
└── appointment/
```

---

## Sales Landing

Path:

```text
landing/sales/
```

Purpose:

Stores incoming Sales CSV files.

Example:

```text
landing/
└── sales/
    └── sales_data.csv
```

---

## Appointment Landing

Path:

```text
landing/appointment/
```

Purpose:

Stores incoming Appointment CSV files.

Example:

```text
landing/
└── appointment/
    └── appointment_data.csv
```

---

# Landing Layer Flow

```text
Source CSV Files
       ↓
Upload / Ingestion
       ↓
ADLS Landing
       ↓
Databricks Reads Data
```

Landing data is considered the original incoming data.

Major transformations should not be performed directly on these files.

---

# Bronze Layer

## Purpose

The Bronze layer stores source data in raw or near-raw form after the initial ingestion and validation process.

Bronze provides a preserved copy of the source data that can be used for:

* Reprocessing
* Debugging
* Auditing
* Further transformation

---

## Bronze Directory Structure

```text
bronze/
│
├── sales/
│
└── appointment/
```

---

## Bronze Processing

The Bronze layer performs only basic processing.

Typical activities include:

* Read source CSV
* Validate expected schema
* Check required columns
* Identify missing columns
* Identify extra columns
* Add technical columns
* Preserve source values
* Write data in Delta format

---

## Bronze Flow

```text
Landing CSV
     ↓
Read Using PySpark
     ↓
Schema Validation
     ↓
Column Validation
     ↓
Add Technical Columns
     ↓
Bronze Delta Data
```

---

# Silver Layer

## Purpose

The Silver layer stores cleaned, transformed, and standardized data.

This layer improves data quality before the data is used for analytical processing.

---

## Silver Directory Structure

```text
silver/
│
├── sales/
│
└── appointment/
```

---

## Silver Processing

The Silver layer performs transformations such as:

* Column mapping
* Column renaming
* Data type conversion
* NULL handling
* Invalid value handling
* Duplicate removal
* Data standardization
* Data cleaning
* Transformation rules

---

## Silver Flow

```text
Bronze Data
     ↓
Read Metadata Mapping
     ↓
Rename Columns
     ↓
Convert Data Types
     ↓
Clean Invalid Values
     ↓
Handle NULLs
     ↓
Remove Duplicates
     ↓
Silver Data
```

---

# Gold Layer

## Purpose

The Gold layer contains final business-ready data.

Data stored in the Gold layer is optimized for:

* Analytics
* Reporting
* Business queries
* Downstream consumption

The project creates Dimension and Fact datasets.

---

# Gold Directory Structure

```text
gold/
│
├── DIM_APPOINTMENT_DATA/
│
└── FACT_SALES/
```

---

## DIM_APPOINTMENT_DATA

Path:

```text
gold/DIM_APPOINTMENT_DATA/
```

Purpose:

Stores the Appointment Dimension data.

The Dimension contains descriptive Appointment information used for analytical processing.

---

## FACT_SALES

Path:

```text
gold/FACT_SALES/
```

Purpose:

Stores the final Sales Fact data.

The Fact table contains measurable Sales information and connects to the required Dimension data.

---

# Gold Data Flow

```text
Silver Appointment
        ↓
DIM_APPOINTMENT_DATA
        ↓
        ├──── Join
        ↓
Silver Sales
        ↓
FACT_SALES
```

---

# Delta Lake Storage

Bronze, Silver, and Gold processed data are stored using **Delta Lake**.

Delta Lake provides additional capabilities on top of cloud storage.

These include:

* ACID transactions
* Schema enforcement
* Reliable updates
* Delta MERGE
* Incremental processing
* Data consistency

---

# Why Delta Instead of Only CSV

CSV is suitable for incoming source files.

However, processed data is better stored in Delta format because Delta supports:

```text
INSERT
UPDATE
MERGE
Schema Management
Transactional Processing
```

Therefore, the general project flow is:

```text
CSV
 ↓
Landing
 ↓
Bronze Delta
 ↓
Silver Delta
 ↓
Gold Delta
```

---

# Incremental Loading in ADLS

The project uses Delta Lake for incremental data loading.

Instead of rewriting all existing data, the pipeline compares incoming records with existing Delta data.

```text
New / Changed Data
        ↓
Existing Delta Data
        ↓
Delta MERGE
        ↓
 ┌──────────────┐
 │ Match        │ → UPDATE
 │ Not Matched  │ → INSERT
 └──────────────┘
```

This process is called **UPSERT**.

```text
UPSERT = UPDATE + INSERT
```

---

# Logs Directory

## Purpose

The Logs directory stores file-based pipeline or processing logs where required.

Path:

```text
logs/
```

Example:

```text
logs/
├── bronze/
├── silver/
├── gold/
└── errors/
```

The exact log structure can vary depending on the notebook or pipeline implementation.

---

# ADLS Logs vs Azure SQL Audit Logs

The project can contain two different types of logging.

## ADLS Logs

ADLS `logs/` is used for file-based technical information.

It may contain:

* Processing files
* Error files
* Diagnostic output
* Technical log files

Example:

```text
ADLS
└── logs/
```

---

## Azure SQL Audit Logs

Azure SQL stores structured ETL execution information.

Main table:

```sql
audit.ETL_LOG
```

It stores information such as:

* Job name
* Start time
* End time
* Status
* Record count
* Error message

---

## Difference

```text
ADLS logs/
     ↓
File-based technical logs

Azure SQL audit.ETL_LOG
     ↓
Structured ETL execution history
```

ADLS Logs and Azure SQL Audit Logs therefore serve different purposes.

---

# Archive Directory

## Purpose

The Archive directory is used to store source files after they have been successfully processed.

Instead of keeping completed files in the Landing directory, they can be moved to Archive.

---

## Archive Structure

```text
archive/
│
├── sales/
│
└── appointment/
```

---

## Archive Flow

```text
New File
   ↓
Landing
   ↓
Processing
   ↓
Processing Successful
   ↓
Archive
```

This helps distinguish between:

```text
Landing
   ↓
Files waiting for processing

Archive
   ↓
Files already processed
```

---

# Why Archive Is Important

Archive helps with:

* Preventing accidental reprocessing
* Maintaining source file history
* Debugging
* Auditing
* Reprocessing if required
* Keeping Landing clean

---

# Data Lifecycle

The complete data lifecycle in ADLS is:

```text
Source CSV
    ↓
Landing
    ↓
Bronze
    ↓
Silver
    ↓
Gold
```

After successful source processing:

```text
Landing File
     ↓
Archive
```

Technical logs can be written to:

```text
logs/
```

---

# Complete ADLS Flow

```text
                     Source CSV Files
                    /                \
                   ↓                  ↓
               Sales             Appointment
                   \                  /
                    \                /
                     ↓              ↓
                         Landing
                            ↓
                         Bronze
                            ↓
                         Silver
                            ↓
                          Gold
                       /        \
                      ↓          ↓
          DIM_APPOINTMENT_DATA  FACT_SALES

Additional Storage
        │
        ├── logs
        │
        └── archive
```

---

# Databricks and ADLS Integration

Azure Databricks reads source data from ADLS Gen2 and writes processed data back to ADLS.

Conceptually:

```text
ADLS Landing
     ↓
Databricks
     ↓
Bronze
     ↓
Databricks
     ↓
Silver
     ↓
Databricks
     ↓
Gold
```

Databricks performs the transformations while ADLS provides persistent storage.

---

# Storage Responsibilities

| Storage Area | Purpose                                        |
| ------------ | ---------------------------------------------- |
| Landing      | Stores incoming source files                   |
| Bronze       | Stores raw or near-raw processed data          |
| Silver       | Stores cleaned and standardized data           |
| Gold         | Stores analytical Dimension and Fact data      |
| Logs         | Stores file-based processing or technical logs |
| Archive      | Stores successfully processed source files     |

---

# Folder Naming Strategy

Folder names are kept simple and meaningful.

Example:

```text
landing
bronze
silver
gold
logs
archive
```

Dataset-specific folders are used where required:

```text
sales
appointment
```

This helps developers quickly understand where each type of data is stored.

---

# Data Separation

The project separates data based on processing stage.

```text
Raw Incoming Data
       ↓
Landing

Raw / Near-Raw Processed Data
       ↓
Bronze

Cleaned Data
       ↓
Silver

Business-Ready Data
       ↓
Gold
```

This prevents raw and transformed data from being mixed together.

---

# Security Considerations

The storage account should not expose data publicly.

Access should be controlled using Azure identity and access-management mechanisms.

Sensitive credentials should not be written directly inside notebooks.

Azure Key Vault is used for secure credential management where required.

The overall security approach is:

```text
User / Application
        ↓
Authenticated Access
        ↓
ADLS Gen2
```

---

# Benefits of This ADLS Design

The ADLS design provides:

* Clear separation of processing layers
* Easy data organization
* Support for Medallion Architecture
* Scalable cloud storage
* Reliable Delta Lake storage
* Easier debugging
* Easier reprocessing
* Source-file history through Archive
* Separation of technical logs
* Support for incremental processing
* Better maintainability

---

# Final ADLS Architecture

```text
ADLS Gen2
│
├── landing
│   ├── sales
│   └── appointment
│
├── bronze
│   ├── sales
│   └── appointment
│
├── silver
│   ├── sales
│   └── appointment
│
├── gold
│   ├── DIM_APPOINTMENT_DATA
│   └── FACT_SALES
│
├── logs
│
└── archive
    ├── sales
    └── appointment
```

---

# Summary

Azure Data Lake Storage Gen2 acts as the central storage platform for the Logistics Azure Data Engineering Project.

The storage is divided into:

```text
Landing → Incoming source data
Bronze  → Raw / near-raw processed data
Silver  → Cleaned and standardized data
Gold    → Business-ready analytical data
Logs    → File-based technical logs
Archive → Successfully processed source files
```

This design provides a structured, scalable, and maintainable foundation for the complete Azure Data Engineering pipeline.

