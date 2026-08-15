# Azure SQL Metadata Design

## Overview

Azure SQL Database is used in this project to store **metadata configuration** required by the ETL pipeline.

Instead of hard-coding all source names, target names, column mappings, and processing rules inside Azure Databricks notebooks, the pipeline reads configuration from metadata tables stored in Azure SQL Database.

This makes the ETL solution more:

* Dynamic
* Reusable
* Maintainable
* Scalable
* Configuration-driven

---

# Purpose of Metadata

Metadata means **data about data**.

In this project, metadata tells the ETL pipeline:

* Which dataset should be processed
* Where the source data is located
* Where the target data should be written
* Which source columns should be used
* What the target column names should be
* What data types should be applied
* Which objects are active for processing
* How each dataset should move through the pipeline

Instead of writing separate transformation logic for every dataset, the same processing logic can use metadata configuration.

---

# Azure SQL Database Role

Azure SQL Database is used mainly for two purposes:

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

The `metadata` schema stores ETL configuration.

The `audit` schema stores ETL execution history.

This document focuses on the **metadata schema**.

---

# Metadata Schema

The metadata schema is created to keep pipeline configuration separate from ETL audit information.

Schema name:

```sql
metadata
```

The main metadata tables used in the project are:

```sql
metadata.OBJECTS_CONFIGURATION
```

and:

```sql
metadata.OBJECTS_COLUMN_MAPPING
```

---

# 1. metadata.OBJECTS_CONFIGURATION

`metadata.OBJECTS_CONFIGURATION` is the main object-level configuration table.

It stores information about the datasets processed by the ETL pipeline.

Examples of datasets include:

```text
SALES_DATA_PRIOR_DAY
APPOINTMENT_DATA
```

The table tells the ETL process which object should be processed and where its source and target locations are configured.

---

## Purpose

The purpose of `OBJECTS_CONFIGURATION` is to maintain configuration at the **dataset/object level**.

Instead of writing values directly inside Databricks notebooks, the notebook can retrieve them from Azure SQL.

Conceptually:

```text
Databricks Notebook
        ↓
Read OBJECTS_CONFIGURATION
        ↓
Identify Object
        ↓
Read Source Configuration
        ↓
Read Target Configuration
        ↓
Process Dataset
```

---

## Configuration Information

The table can maintain information related to:

* Object name
* Source name
* Source path
* Source file type
* Target name
* Target path
* Processing layer
* Load type
* Incremental configuration
* Active/inactive status
* Other ETL configuration

The exact configuration values depend on the dataset being processed.

---

# Object-Level Configuration Example

Conceptually, a metadata record may represent:

```text
Object:
SALES_DATA_PRIOR_DAY

Source:
Landing Sales Data

Target:
Bronze / Silver / Gold Processing

Status:
Active
```

Another configuration can represent:

```text
Object:
APPOINTMENT_DATA

Source:
Landing Appointment Data

Target:
Bronze / Silver / Gold Processing

Status:
Active
```

---

# Why Object Configuration Is Useful

Without metadata:

```python
source_path = "..."
target_path = "..."
object_name = "SALES_DATA_PRIOR_DAY"
```

Values are directly written inside the notebook.

If another dataset is added, more hard-coded code may be required.

With metadata:

```text
Notebook
   ↓
Read Configuration
   ↓
Process Selected Object
```

The same notebook logic can be reused for multiple datasets.

---

# 2. metadata.OBJECTS_COLUMN_MAPPING

`metadata.OBJECTS_COLUMN_MAPPING` stores **column-level transformation configuration**.

It is especially useful during Silver layer processing.

The table defines how source columns should be transformed into target columns.

---

# Purpose of Column Mapping

Source column names may not match the required target column names.

For example:

```text
Source Column
      ↓
APPOINTMENT_TITLE

Target Column
      ↓
TITLE
```

Another example:

```text
Source Column
      ↓
APPOINTMENT_STATUS

Target Column
      ↓
STATUS
```

Another example:

```text
Source Column
      ↓
APPOINTMENT_DATE

Target Column
      ↓
DATE
```

The mapping information can be stored in Azure SQL instead of being manually written inside every transformation notebook.

---

# Column Mapping Flow

```text
Source Data
     ↓
Read Column Mapping Metadata
     ↓
Source Column Name
     ↓
Target Column Name
     ↓
Target Data Type
     ↓
Silver Data
```

---

# Column Mapping Information

The metadata can maintain information such as:

* Object name
* Source column name
* Target column name
* Target data type
* Column sequence
* Mapping status
* Transformation configuration

This information allows Databricks to dynamically transform columns.

---

# Example Mapping

Conceptually:

| Object      | Source Column       | Target Column       | Target Data Type |
| ----------- | ------------------- | ------------------- | ---------------- |
| Appointment | APPOINTMENT_TITLE   | TITLE               | STRING           |
| Appointment | APPOINTMENT_STATUS  | STATUS              | STRING           |
| Appointment | APPOINTMENT_DATE    | DATE                | DATE             |
| Sales       | Source Sales Column | Target Sales Column | Required Type    |

The actual values stored in Azure SQL are based on the mapping created for the project.

---

# Metadata-Driven Silver Processing

The Silver layer uses metadata-driven column mapping.

High-level flow:

```text
Bronze Data
      ↓
Read OBJECTS_COLUMN_MAPPING
      ↓
Get Mapping for Selected Object
      ↓
Rename Columns
      ↓
Convert Data Types
      ↓
Clean Invalid Values
      ↓
Silver Data
```

This avoids manually writing a separate rename and cast statement for every column.

---

# PySpark Mapping Concept

The Silver notebook reads metadata and applies mappings dynamically.

Conceptually:

```python
sales_silver_df = apply_mapping(
    sales_bronze_df,
    "SALES_DATA_PRIOR_DAY"
)
```

For Appointment data:

```python
appointment_silver_df = apply_mapping(
    appointment_bronze_df,
    "APPOINTMENT_DATA"
)
```

The `apply_mapping()` logic uses the metadata configuration to:

1. Find the source column
2. Rename it to the target column
3. Apply the required data type

---

# Data Type Conversion

Column mapping is also used to standardize data types.

Examples may include:

```text
STRING
INTEGER
FLOAT
DATE
TIMESTAMP
```

Conceptually:

```text
Source Value
     ↓
Read Target Data Type
     ↓
Cast / Convert
     ↓
Target Column
```

---

# Handling Invalid Data During Mapping

Source data may sometimes contain malformed values.

For example, a column expected to contain a numeric value may contain:

```text
215.0000, 230.0000
```

Such a value cannot be directly converted to a single `FLOAT`.

Therefore, Silver processing must clean or safely handle malformed source values before or during type conversion.

The purpose of metadata is to define the required type, while PySpark transformation logic handles the actual conversion.

---

# OBJECTS_CONFIGURATION vs OBJECTS_COLUMN_MAPPING

The two metadata tables have different responsibilities.

| Metadata Table                    | Purpose                                                |
| --------------------------------- | ------------------------------------------------------ |
| `metadata.OBJECTS_CONFIGURATION`  | Stores dataset/object-level ETL configuration          |
| `metadata.OBJECTS_COLUMN_MAPPING` | Stores source-to-target column mappings and data types |

Easy way to remember:

```text
OBJECTS_CONFIGURATION
        ↓
"What object should I process?"

OBJECTS_COLUMN_MAPPING
        ↓
"How should its columns be transformed?"
```

---

# Metadata Processing Architecture

```text
                  Azure SQL Database
                          │
                    metadata schema
                          │
             ┌────────────┴────────────┐
             │                         │
             ↓                         ↓
OBJECTS_CONFIGURATION       OBJECTS_COLUMN_MAPPING
             │                         │
             │                         │
     Object Configuration        Column Configuration
             │                         │
             └────────────┬────────────┘
                          ↓
                  Azure Databricks
                          ↓
                  PySpark Processing
                          ↓
               Bronze → Silver → Gold
```

---

# Azure SQL Connection from Databricks

Azure Databricks connects to Azure SQL Database using JDBC.

Conceptually:

```text
Azure Databricks
      ↓
JDBC Connection
      ↓
Azure SQL Database
      ↓
metadata tables
```

The JDBC connection contains:

* SQL Server name
* Database name
* Username
* Password
* Encryption settings

Sensitive credentials should not be directly hard-coded inside notebooks.

---

# JDBC Connection Concept

Conceptually:

```python
jdbc_url = (
    f"jdbc:sqlserver://{server_name}:1433;"
    f"database={database_name};"
    "encrypt=true;"
    "trustServerCertificate=false;"
)
```

The username and password are supplied separately through secured credentials.

---

# Azure Key Vault Integration

Sensitive Azure SQL credentials are stored securely using Azure Key Vault.

The flow is:

```text
Azure Key Vault
      ↓
SQL Credentials
      ↓
Databricks Secret Scope
      ↓
Databricks Notebook
      ↓
JDBC Connection
      ↓
Azure SQL Database
```

This prevents SQL credentials from being written directly inside the project code.

---

# Reading Metadata

The Databricks notebook reads metadata from Azure SQL before processing data.

Conceptually:

```text
Start Notebook
      ↓
Connect to Azure SQL
      ↓
Read Metadata
      ↓
Filter Required Object
      ↓
Get Configuration
      ↓
Process Data
```

---

# Object Filtering

When processing Sales data, the notebook can request configuration for:

```text
SALES_DATA_PRIOR_DAY
```

When processing Appointment data, the notebook can request configuration for:

```text
APPOINTMENT_DATA
```

This allows the same reusable logic to work for different objects.

---

# Metadata-Driven ETL Example

Without metadata:

```text
Sales Notebook
Appointment Notebook
Different Hard-Coded Mappings
Different Paths
Different Configuration
```

With metadata:

```text
           Generic ETL Logic
                  ↓
           Read Object Name
                  ↓
          Read SQL Metadata
                  ↓
        Apply Configuration
                  ↓
             Process Data
```

This is one of the key concepts implemented in the project.

---

# Metadata and Bronze Layer

Bronze mainly preserves source data.

Metadata can help identify:

* Source object
* Expected dataset
* Source configuration
* Target Bronze location

High-level flow:

```text
Landing
   ↓
Read Object Configuration
   ↓
Bronze Processing
   ↓
Bronze Delta Data
```

---

# Metadata and Silver Layer

Metadata has a major role in the Silver layer.

The Silver layer uses column mappings to perform:

* Column renaming
* Data type conversion
* Data standardization

Flow:

```text
Bronze
   ↓
OBJECTS_COLUMN_MAPPING
   ↓
Apply Mapping
   ↓
Clean Data
   ↓
Silver
```

---

# Metadata and Gold Layer

Gold processing consumes cleaned Silver data.

Metadata-driven design can also support target configuration and reusable processing, while Gold-specific logic creates analytical Dimension and Fact structures.

Final tables include:

```text
DIM_APPOINTMENT_DATA
FACT_SALES
```

---

# Metadata and Incremental Loading

Object-level metadata can also maintain information required for incremental processing.

Conceptually:

```text
Object Configuration
       ↓
Determine Load Type
       ↓
Incremental Processing
       ↓
Delta MERGE
```

The Delta MERGE operation performs:

```text
Existing Record → UPDATE
New Record      → INSERT
```

This is known as UPSERT.

---

# Active and Inactive Configuration

Metadata-driven systems commonly use a configuration flag to control whether an object should be processed.

Conceptually:

```text
ACTIVE = 1
      ↓
Process Object

ACTIVE = 0
      ↓
Skip Object
```

This allows an object to be enabled or disabled through configuration rather than changing notebook code.

---

# Metadata vs Audit

Metadata and Audit have completely different purposes.

## Metadata

Metadata tells the pipeline **what and how to process**.

Examples:

```sql
metadata.OBJECTS_CONFIGURATION
metadata.OBJECTS_COLUMN_MAPPING
```

---

## Audit

Audit tells us **what happened during processing**.

Example:

```sql
audit.ETL_LOG
```

---

## Easy Difference

```text
Metadata
   ↓
Instructions for the pipeline

Audit
   ↓
History of the pipeline
```

Example:

```text
Metadata:
Process SALES_DATA_PRIOR_DAY using this mapping.

Audit:
SALES_DATA_PRIOR_DAY completed successfully at this time.
```

---

# Metadata vs Hard-Coded ETL

## Hard-Coded ETL

```text
Source Path → Written in Code
Target Path → Written in Code
Column Name → Written in Code
Data Type   → Written in Code
```

A change usually requires modifying the notebook.

---

## Metadata-Driven ETL

```text
Configuration
      ↓
Azure SQL Metadata
      ↓
Databricks Reads Configuration
      ↓
Generic Processing Logic
```

A configuration change can often be handled by updating metadata instead of rewriting transformation logic.

---

# Benefits of Metadata-Driven ETL

The metadata design provides several advantages:

### Reusability

The same PySpark functions can process multiple datasets.

### Maintainability

Configuration is separated from transformation code.

### Scalability

New objects can be added more easily.

### Flexibility

Mappings and processing configuration can be changed without rewriting large sections of ETL logic.

### Standardization

Different datasets follow the same processing pattern.

### Reduced Hard-Coding

Paths, mappings, and configuration do not need to be repeatedly written in notebooks.

---

# Complete Metadata Flow

```text
                     Azure SQL Database
                            │
                      metadata schema
                            │
           ┌────────────────┴────────────────┐
           │                                 │
           ↓                                 ↓
OBJECTS_CONFIGURATION              OBJECTS_COLUMN_MAPPING
           │                                 │
           ↓                                 ↓
 Object-Level Settings              Column-Level Settings
           │                                 │
           └────────────────┬────────────────┘
                            ↓
                    Azure Databricks
                            ↓
                     Read Metadata
                            ↓
                  Apply Configuration
                            ↓
                    PySpark Processing
                            ↓
              Bronze → Silver → Gold
```

---

# Project Metadata Summary

The project uses Azure SQL metadata to make ETL processing configuration-driven.

The main metadata objects are:

```sql
metadata.OBJECTS_CONFIGURATION
```

Used for:

* Dataset-level configuration
* Source configuration
* Target configuration
* Processing configuration
* Load configuration

And:

```sql
metadata.OBJECTS_COLUMN_MAPPING
```

Used for:

* Source column mapping
* Target column mapping
* Target data types
* Silver transformation configuration

Together, these tables allow Azure Databricks to dynamically determine **what data to process and how to transform it**.

---

# Interview Explanation

A simple way to explain this implementation in an interview is:

> In my logistics Azure Data Engineering project, I implemented a metadata-driven ETL approach using Azure SQL Database. I stored object-level configuration in `metadata.OBJECTS_CONFIGURATION` and source-to-target column mappings in `metadata.OBJECTS_COLUMN_MAPPING`. Databricks reads this metadata through JDBC and uses reusable PySpark logic to process Sales and Appointment datasets. This reduces hard-coded logic and makes the ETL pipeline easier to maintain and extend.

---

# Final Architecture

```text
Azure Key Vault
      │
      │ Secure SQL Credentials
      ↓
Azure Databricks
      │
      │ JDBC
      ↓
Azure SQL Database
      │
      └── metadata
            │
            ├── OBJECTS_CONFIGURATION
            │
            └── OBJECTS_COLUMN_MAPPING
                         │
                         ↓
                 Metadata Configuration
                         ↓
                 PySpark ETL Processing
                         ↓
                  Bronze → Silver → Gold
```

The metadata layer is therefore a key part of making the Logistics Azure Data Engineering pipeline **dynamic, reusable, and maintainable**.
