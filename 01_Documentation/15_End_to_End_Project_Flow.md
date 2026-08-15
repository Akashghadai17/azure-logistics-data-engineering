# End-to-End Project Flow

## Overview

This document explains the complete execution flow of the **Logistics Azure Data Engineering Project** from source CSV files to the final Gold Dimension and Fact tables.

The complete architecture uses:

* Azure Data Lake Storage Gen2
* Azure Data Factory
* Azure Databricks
* Apache Spark
* PySpark
* Delta Lake
* Unity Catalog
* Azure SQL Database
* Azure Key Vault

---

# Complete Architecture

```text
Sales CSV + Appointment CSV
             ↓
        SC1 - Landing
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
        /         \
       ↓           ↓
DIM_APPOINTMENT  FACT_SALES
             ↓
       Unity Catalog
             ↓
       Managed Delta
             ↓
             SC2
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
Secure Credentials / Secrets
```

---

# Step 1 — Source Data

The project processes two source datasets:

```text
Sales Data
Appointment Data
```

The source files are provided in CSV format.

These files are placed in the Landing area of the first ADLS Gen2 storage account.

```text
Source CSV
    ↓
SC1
    ↓
Landing
```

---

# Step 2 — Storage Account 1

The first storage account, SC1, is used for file-based project storage.

```text
SC1
│
├── landing
├── logs
└── archive
```

## Landing

Stores incoming source CSV files.

## Logs

Stores file-based technical or processing logs where required.

## Archive

Stores source files after successful processing.

Easy way to remember:

```text
Landing = New Files
Logs    = Technical Logs
Archive = Processed Files
```

---

# Step 3 — Azure Data Factory

Azure Data Factory acts as the **orchestration layer**.

ADF controls:

* When the pipeline runs
* Which Databricks processing step runs
* Execution sequence
* Dependencies
* Failure handling
* Pipeline monitoring

```text
ADF
 ↓
Controls Workflow
```

Databricks performs the actual data transformations.

---

# Step 4 — Azure Key Vault

Azure Key Vault securely stores sensitive information.

Examples include:

* Azure SQL username
* Azure SQL password
* Service Principal Client ID
* Service Principal Client Secret
* Tenant ID
* Storage-related credentials

Flow:

```text
Azure Key Vault
      ↓
Secure Secrets
      ↓
Databricks / Azure Services
```

Sensitive values are not hard-coded directly inside notebooks.

---

# Step 5 — Azure SQL Metadata

Azure SQL Database stores ETL configuration.

Main metadata tables:

```sql
metadata.OBJECTS_CONFIGURATION
```

and:

```sql
metadata.OBJECTS_COLUMN_MAPPING
```

`OBJECTS_CONFIGURATION` stores object-level configuration.

`OBJECTS_COLUMN_MAPPING` stores source-to-target column mappings and target data types.

---

# Step 6 — Databricks Reads Metadata

Azure Databricks connects to Azure SQL Database through JDBC.

```text
Databricks
    ↓
JDBC
    ↓
Azure SQL
    ↓
Metadata
```

Databricks uses the metadata to determine:

* Which object is being processed
* How columns should be mapped
* What target data types should be used

---

# Step 7 — Bronze Layer

Databricks reads Sales and Appointment CSV files from SC1 Landing.

```text
SC1 Landing
     ↓
Databricks
     ↓
Bronze
```

Bronze processing performs:

* CSV reading
* Schema validation
* Expected-column validation
* Missing-column validation
* Extra-column validation
* Minimal transformation
* Source preservation

The source values are kept as close as possible to their original format.

---

# Step 8 — Bronze Managed Tables

After validation, Bronze data is stored as Unity Catalog managed Delta tables.

```text
Bronze Data
     ↓
Unity Catalog
     ↓
bronze schema
     ↓
Managed Delta Tables
```

The physical storage is maintained in SC2.

```text
Unity Catalog
     ↓
SC2 Managed Storage
```

---

# Step 9 — Silver Layer

Silver reads the Bronze managed tables.

```text
Bronze
   ↓
Silver Processing
```

Silver is responsible for cleaning and standardizing the data.

Main transformations include:

* Metadata-driven column mapping
* Column renaming
* Data type conversion
* Malformed-value handling
* NULL handling
* Duplicate removal
* Data cleaning
* Data standardization

---

# Step 10 — Metadata-Driven Column Mapping

Silver reads:

```sql
metadata.OBJECTS_COLUMN_MAPPING
```

For example:

```text
APPOINTMENT_TITLE
        ↓
TITLE

APPOINTMENT_STATUS
        ↓
STATUS

APPOINTMENT_DATE
        ↓
DATE
```

This allows reusable PySpark transformation logic.

---

# Step 11 — Handling Malformed Data

During Sales processing, a malformed numeric value was identified.

Example:

```text
215.0000, 230.0000
```

The required target type was:

```text
FLOAT
```

A direct cast caused:

```text
CAST_INVALID_INPUT
```

The Silver transformation handled the malformed value before applying the final target data type.

This is an example of a real data-quality problem handled during the project.

---

# Step 12 — Silver Managed Tables

After cleaning, the datasets are stored as Silver managed Delta tables.

```text
Silver Data
     ↓
Unity Catalog
     ↓
silver schema
     ↓
Managed Delta Tables
     ↓
SC2
```

---

# Step 13 — Data Quality Checks

After Silver processing, Data Quality Checks verify the cleaned data.

Main checks include:

```text
Row Count
NULL Check
Duplicate Check
Primary Key Check
Foreign Key Check
Schema Check
Required Column Check
Data Type Check
Invalid Value Check
```

---

# Data Quality Flow

```text
Silver
   ↓
Run DQ Checks
   ↓
PASS?
 /    \
Yes    No
 ↓      ↓
Gold   Fail Pipeline
```

Only trusted data should continue to Gold.

---

# Step 14 — Gold Layer

Gold converts cleaned Silver data into business-ready analytical tables.

The final Gold tables are:

```text
DIM_APPOINTMENT_DATA
FACT_SALES
```

---

# Step 15 — Dimension Table

Appointment Silver data is used to create:

```text
DIM_APPOINTMENT_DATA
```

The Dimension table contains descriptive Appointment information.

Conceptually:

```text
Silver Appointment
        ↓
Select Required Columns
        ↓
Remove Duplicates
        ↓
Create Surrogate Key
        ↓
DIM_APPOINTMENT_DATA
```

---

# Step 16 — Surrogate Key

A surrogate key is created for the Dimension table.

Easy difference:

```text
Business Key
     ↓
Comes from Source

Surrogate Key
     ↓
Created by Data Warehouse
```

The surrogate key helps connect the Dimension table with the Fact table.

---

# Step 17 — Fact Table

Sales Silver data is used to create:

```text
FACT_SALES
```

The required Appointment Dimension information is joined with Sales.

```text
Silver Sales
      +
DIM_APPOINTMENT_DATA
      ↓
Join
      ↓
FACT_SALES
```

---

# Step 18 — Gold Managed Tables

The final Dimension and Fact tables are stored under the Unity Catalog Gold schema.

```text
Unity Catalog
      ↓
gold
      │
      ├── DIM_APPOINTMENT_DATA
      └── FACT_SALES
```

The physical Delta files are maintained in SC2.

---

# Step 19 — Incremental Loading

After the initial load, the project supports incremental processing.

Instead of replacing the complete target every time:

```text
New / Changed Data
        ↓
Existing Delta Table
        ↓
MERGE
```

---

# Step 20 — MERGE / UPSERT

Delta Lake MERGE performs:

```text
Matching Record
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

# Step 21 — ETL Logging

Azure SQL Database stores structured ETL execution history.

Main table:

```sql
audit.ETL_LOG
```

Typical statuses include:

```text
STARTED
SUCCESS
FAILED
```

The log can contain:

* Process name
* Object name
* Layer
* Start time
* End time
* Record count
* Status
* Error message

---

# Step 22 — Error Handling

Databricks uses exception handling to capture failures.

Conceptually:

```python
try:
    # ETL processing

except Exception as e:
    # capture error
    # write FAILED status
    raise
```

The `raise` statement sends the failure back to Azure Data Factory.

---

# Failure Flow

```text
Databricks
     ↓
Error
     ↓
Capture Exception
     ↓
Write FAILED to ETL_LOG
     ↓
raise
     ↓
ADF Activity FAILED
```

This prevents silent failures.

---

# Step 23 — Source File Archive

After successful source processing, files can move from:

```text
SC1 / landing
```

to:

```text
SC1 / archive
```

Flow:

```text
Landing File
     ↓
Successful Processing
     ↓
Archive
```

This keeps new and processed files separate.

---

# Two Storage Account Design

The project uses two ADLS Gen2 storage accounts.

## SC1

```text
SC1
│
├── landing
├── logs
└── archive
```

Used for file-based source and operational storage.

## SC2

```text
SC2
      ↓
Unity Catalog Managed Storage
      ↓
Bronze
Silver
Gold
```

Used for managed Delta table storage.

Easy way to remember:

```text
SC1 = Files

SC2 = Managed Tables
```

---

# Complete End-to-End Data Flow

```text
                     Source CSV Files
                  Sales + Appointment
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
                   /             \
                  ↓               ↓
      DIM_APPOINTMENT_DATA    FACT_SALES
                  \               /
                   \             /
                          ↓
                     Delta MERGE
                          ↓
                    Unity Catalog
                          ↓
                  SC2 Managed Storage
```

Supporting flow:

```text
Azure Key Vault
      ↓
Secure Credentials
```

```text
Azure SQL Database
      │
      ├── Metadata Configuration
      └── ETL Audit Logging
```

---

# Role of Every Service

| Service            | Main Role                         |
| ------------------ | --------------------------------- |
| SC1 ADLS Gen2      | Landing, Logs and Archive         |
| Azure Data Factory | Pipeline orchestration            |
| Azure Databricks   | ETL processing                    |
| Apache Spark       | Distributed processing engine     |
| PySpark            | Data transformation               |
| Delta Lake         | Reliable table storage and MERGE  |
| Unity Catalog      | Table management and governance   |
| SC2 ADLS Gen2      | Unity Catalog managed storage     |
| Azure SQL Database | Metadata and ETL audit            |
| Azure Key Vault    | Secure secret management          |
| Git/GitHub         | Version control and documentation |

---

# Easy Project Flow to Remember

For interviews, remember the project in this order:

```text
1. CSV Files
      ↓
2. SC1 Landing
      ↓
3. ADF Orchestration
      ↓
4. Databricks
      ↓
5. Bronze
      ↓
6. Silver
      ↓
7. Data Quality
      ↓
8. Gold
      ↓
9. DIM + FACT
      ↓
10. Delta MERGE
      ↓
11. Unity Catalog
      ↓
12. SC2 Managed Storage
```

Supporting services:

```text
Azure SQL
→ Metadata + Audit

Key Vault
→ Security
```

---

# Short Interview Explanation

> I built an end-to-end Logistics Data Engineering pipeline on Azure using Sales and Appointment CSV data. Source files land in the first ADLS Gen2 storage account. Azure Data Factory orchestrates Databricks processing. In Databricks, I implemented Bronze ingestion and schema validation, Silver metadata-driven transformations and data cleaning, Data Quality Checks, and Gold Dimension and Fact modeling. I created `DIM_APPOINTMENT_DATA` and `FACT_SALES` as Unity Catalog managed Delta tables whose managed storage is configured in the second ADLS account. I also implemented incremental loading with Delta MERGE, Azure SQL metadata and ETL audit logging, error handling, and Azure Key Vault-based secret management.

---

# Project Outcome

The project demonstrates an end-to-end Azure Data Engineering architecture covering:

* Data ingestion
* Cloud storage
* Medallion Architecture
* Metadata-driven ETL
* PySpark transformations
* Delta Lake
* Unity Catalog
* Data quality
* Dimension and Fact modeling
* Incremental loading
* MERGE / UPSERT
* ETL audit logging
* Error handling
* Secret management
* ADF orchestration
* GitHub documentation

The final solution provides a structured and maintainable pipeline from raw logistics source files to business-ready analytical data.
