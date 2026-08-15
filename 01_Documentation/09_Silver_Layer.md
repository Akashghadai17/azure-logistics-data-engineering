# Logistics Azure Data Engineering Project

## Project Overview

This project is an end-to-end **Azure Data Engineering solution** designed to process logistics-related **Sales** and **Appointment** data.

The project uses Azure services for data storage, transformation, validation, security, monitoring, and orchestration.

The complete solution follows the **Medallion Architecture**:

**Bronze → Silver → Gold**

The final Gold layer contains **Dimension and Fact tables** that can be used for analytics and reporting.

---

## Project Objective

The main objective of this project is to build a complete Azure Data Engineering pipeline that can:

* Ingest logistics Sales and Appointment data
* Store source data in Azure Data Lake Storage Gen2
* Process data using Azure Databricks
* Transform data using Apache Spark and PySpark
* Implement Bronze, Silver, and Gold layers
* Perform schema validation
* Clean and standardize source data
* Handle NULL and invalid values
* Remove duplicate records
* Convert data into required data types
* Perform data quality checks
* Use metadata-driven ETL processing
* Implement incremental data loading
* Perform Delta Lake MERGE / UPSERT
* Create Dimension and Fact tables
* Maintain ETL execution logs
* Handle pipeline errors
* Secure credentials using Azure Key Vault
* Orchestrate the complete workflow using Azure Data Factory

---

## Source Data

The project processes two main datasets:

1. **Sales Data**
2. **Appointment Data**

The source data is available in **CSV format**.

These source files are stored in Azure Data Lake Storage Gen2 before being processed through the Medallion Architecture.

---

## High-Level Architecture

```text
CSV Source Files
        ↓
ADLS Gen2
        ↓
Azure Databricks
        ↓
Bronze Layer
        ↓
Silver Layer
        ↓
Gold Layer
        ↓
Dimension & Fact Tables
```

Azure Data Factory is used to orchestrate the complete workflow.

```text
Azure Data Factory
        ↓
Databricks Processing
        ↓
Bronze
        ↓
Silver
        ↓
Data Quality
        ↓
Gold
        ↓
Incremental Processing
        ↓
ETL Logging
```

Supporting services:

```text
Azure Key Vault
      ↓
Secure Secrets / Credentials
```

```text
Azure SQL Database
      ↓
Metadata Configuration
      +
ETL Audit Logging
```

---

## Technologies Used

The project uses the following technologies:

* Microsoft Azure
* Azure Data Lake Storage Gen2 (ADLS Gen2)
* Azure Data Factory (ADF)
* Azure Databricks
* Apache Spark
* PySpark
* Delta Lake
* Azure SQL Database
* SQL Server Management Studio (SSMS)
* Azure Key Vault
* Git
* GitHub

---

# Medallion Architecture

The project follows the **Medallion Architecture** to improve the quality of data step by step.

```text
Raw Source Data
      ↓
Bronze Layer
      ↓
Silver Layer
      ↓
Gold Layer
```

Each layer has a different responsibility.

---

## Bronze Layer

The Bronze layer stores data in **raw or near-raw form**.

The main purpose of Bronze is to preserve source information before applying major business transformations.

### Bronze Layer Activities

* Read source CSV files
* Validate source schema
* Validate expected columns
* Identify missing columns
* Identify extra columns
* Preserve source information
* Add technical/audit information where required
* Store data in Delta format

### Bronze Flow

```text
CSV Source
    ↓
Read Data
    ↓
Schema Validation
    ↓
Column Validation
    ↓
Bronze Delta Data
```

---

## Silver Layer

The Silver layer stores **cleaned, standardized, and transformed data**.

Data from Bronze is processed using PySpark before being stored in the Silver layer.

### Silver Layer Activities

* Read Bronze data
* Apply metadata-driven column mapping
* Rename columns
* Convert data types
* Handle malformed values
* Handle NULL values
* Remove duplicate records
* Standardize data
* Clean invalid values
* Apply transformation rules
* Prepare data for Gold processing

### Silver Flow

```text
Bronze Data
      ↓
Column Mapping
      ↓
Data Cleaning
      ↓
Data Type Conversion
      ↓
NULL Handling
      ↓
Duplicate Removal
      ↓
Silver Data
```

---

## Gold Layer

The Gold layer stores **business-ready analytical data**.

Cleaned Silver data is transformed into a dimensional model containing **Dimension and Fact tables**.

### Gold Flow

```text
Silver Appointment Data
        ↓
DIM_APPOINTMENT_DATA
        ↓
        ├──── Join
        ↓
Silver Sales Data
        ↓
FACT_SALES
```

The Gold layer can be used for:

* Analytics
* Reporting
* Business queries
* Downstream consumption

---

# Final Gold Tables

## DIM_APPOINTMENT_DATA

`DIM_APPOINTMENT_DATA` is the Dimension table created using cleaned Appointment data.

It contains descriptive Appointment-related information.

The Dimension table provides descriptive context that can be used when analyzing Sales information.

---

## FACT_SALES

`FACT_SALES` is the Fact table created from cleaned Sales data.

It contains measurable Sales information and connects with the related dimension data where required.

The Fact table is designed for analytical and reporting workloads.

---

# Metadata-Driven ETL Processing

The project uses **Azure SQL Database** to store ETL configuration information.

The main metadata table is:

```sql
metadata.OBJECTS_CONFIGURATION
```

Instead of hard-coding all processing information directly inside Databricks notebooks, configuration can be maintained in the metadata table.

The ETL process can read configuration information dynamically during execution.

### Metadata Information

The configuration can contain information such as:

* Source object name
* Target object name
* Source location
* Target location
* Source columns
* Target columns
* Column mapping
* Target data types
* Processing layer
* Object configuration
* Active/inactive configuration

### Benefits of Metadata-Driven Processing

* Reduces hard-coded values
* Makes notebooks reusable
* Makes the pipeline easier to maintain
* Makes configuration changes easier
* Supports scalable ETL development

---

# Data Quality Checks

Data quality checks are implemented to verify that data is valid before it moves to the next processing stage.

The project includes checks such as:

* Schema validation
* Expected column validation
* Missing column validation
* Extra column validation
* Row count validation
* NULL validation
* Duplicate validation
* Data type validation
* Invalid value checks
* Business rule validation

### Data Quality Flow

```text
Processed Data
      ↓
Run Data Quality Checks
      ↓
Validate Records
      ↓
Valid Data
      ↓
Continue Processing
```

Data quality checks help prevent incorrect or poor-quality data from reaching the Gold layer.

---

# Incremental Data Loading

The project supports **incremental loading**.

Incremental loading means the complete historical dataset does not need to be reprocessed every time.

Only new or changed records need to be processed.

The project uses **Delta Lake MERGE** for incremental processing.

### MERGE Logic

```text
Incoming Data
      ↓
Compare With Existing Delta Data
      ↓
Record Exists?
      ↓
 ┌───────────────┬───────────────┐
 │      Yes      │       No      │
 ↓               ↓
UPDATE          INSERT
```

This process is also called:

**UPSERT = UPDATE + INSERT**

### Benefits of Incremental Loading

* Reduces unnecessary processing
* Improves ETL efficiency
* Supports new records
* Supports changed records
* Avoids reloading the complete dataset

---

# ETL Audit Logging

The project maintains ETL execution information in **Azure SQL Database**.

The main audit table is:

```sql
audit.ETL_LOG
```

The audit table is used to track ETL executions.

### ETL Log Information

ETL logs can contain information such as:

* ETL process name
* Source object
* Target object
* Start time
* End time
* Number of records processed
* Execution status
* Error message
* Execution details

### ETL Status

Example statuses include:

```text
STARTED
SUCCESS
FAILED
```

### Successful ETL Flow

```text
ETL Starts
    ↓
Write STARTED Log
    ↓
Process Data
    ↓
Processing Successful
    ↓
Write SUCCESS Log
```

### Failed ETL Flow

```text
ETL Starts
    ↓
Process Data
    ↓
Processing Failure
    ↓
Capture Error
    ↓
Write FAILED Log
```

ETL audit logging helps with:

* Pipeline monitoring
* Debugging
* Troubleshooting
* Execution tracking
* Operational auditing

---

# Error Handling

Error handling is implemented to make the ETL process more reliable.

When an error occurs during processing, the error is captured and recorded.

### Error Handling Flow

```text
Start ETL Process
      ↓
Try Processing
      ↓
Successful
      ↓
Write SUCCESS Status
```

If processing fails:

```text
Processing Failure
      ↓
Capture Exception
      ↓
Capture Error Message
      ↓
Write FAILED Status
      ↓
Store Error Details
```

Error handling helps identify:

* Which ETL process failed
* When the failure occurred
* What error occurred
* Which object was being processed

---

# Azure SQL Database

Azure SQL Database is used as a supporting component of the ETL solution.

The project uses two important SQL schemas:

```text
Azure SQL Database
        │
        ├── metadata
        │     └── OBJECTS_CONFIGURATION
        │
        └── audit
              └── ETL_LOG
```

## Metadata Schema

The `metadata` schema stores ETL configuration information.

Main table:

```sql
metadata.OBJECTS_CONFIGURATION
```

## Audit Schema

The `audit` schema stores ETL execution and monitoring information.

Main table:

```sql
audit.ETL_LOG
```

---

# Azure Key Vault

Azure Key Vault is used to securely manage sensitive credentials and secrets.

Examples include:

* Azure SQL username
* Azure SQL password
* Client ID
* Client Secret
* Tenant ID
* Storage credentials
* Other application secrets

Sensitive credentials should not be hard-coded directly inside notebooks or source code.

### Security Flow

```text
Azure Key Vault
      ↓
Secure Secrets
      ↓
Databricks / Azure Services
```

---

# Azure Data Factory Orchestration

Azure Data Factory is used as the **orchestration layer** of the project.

ADF controls the execution and sequence of the different ETL processes.

### ADF Pipeline Flow

```text
ADF Pipeline
      ↓
Start Processing
      ↓
Databricks ETL
      ↓
Bronze Layer
      ↓
Silver Layer
      ↓
Data Quality Checks
      ↓
Gold Layer
      ↓
Incremental Processing
      ↓
ETL Logging
      ↓
Pipeline Complete
```

ADF provides centralized orchestration for the end-to-end pipeline.

---

# Security

Security is an important part of the solution.

Sensitive information is managed through Azure Key Vault instead of storing credentials directly inside project code.

This provides:

* Better credential security
* Centralized secret management
* Easier maintenance
* Better access control

---

# Project Features

The project demonstrates the following Data Engineering concepts:

* End-to-end Azure Data Engineering pipeline
* CSV source data ingestion
* ADLS Gen2 storage
* Azure Databricks processing
* Apache Spark processing
* PySpark transformations
* Delta Lake
* Bronze, Silver, and Gold Medallion Architecture
* Schema validation
* Expected column validation
* Data cleaning
* Data standardization
* Duplicate removal
* NULL handling
* Invalid data handling
* Data type conversion
* Metadata-driven ETL
* Azure SQL metadata configuration
* Data quality checks
* Incremental data loading
* Delta Lake MERGE
* UPSERT operations
* Dimension table creation
* Fact table creation
* ETL audit logging
* Error handling
* Azure Key Vault security
* Azure Data Factory orchestration
* Git version control
* GitHub documentation

---

# Complete Project Architecture

```text
                 ┌─────────────────────────┐
                 │      Source Files       │
                 │                         │
                 │ Sales + Appointment CSV │
                 └────────────┬────────────┘
                              ↓
                 ┌─────────────────────────┐
                 │        ADLS Gen2        │
                 │       Data Storage      │
                 └────────────┬────────────┘
                              ↓
                 ┌─────────────────────────┐
                 │   Azure Data Factory    │
                 │      Orchestration      │
                 └────────────┬────────────┘
                              ↓
                 ┌─────────────────────────┐
                 │    Azure Databricks     │
                 │     Spark / PySpark     │
                 └────────────┬────────────┘
                              ↓
                        Bronze Layer
                              ↓
                        Silver Layer
                              ↓
                     Data Quality Checks
                              ↓
                         Gold Layer
                         /          \
                        ↓            ↓
          DIM_APPOINTMENT_DATA   FACT_SALES
```

Supporting components:

```text
Azure SQL Database
        │
        ├── metadata.OBJECTS_CONFIGURATION
        │
        └── audit.ETL_LOG
```

```text
Azure Key Vault
        │
        └── Secure Credentials / Secrets
```

---

# End-to-End Data Flow

```text
Sales CSV + Appointment CSV
             ↓
          ADLS Gen2
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
       ↓             ↓
       Business-Ready Data
```

Azure Data Factory orchestrates the overall pipeline, while Azure SQL Database maintains metadata and audit information and Azure Key Vault securely manages credentials.

---

# Project Outcome

The completed solution demonstrates a practical end-to-end Azure Data Engineering implementation covering:

* Data ingestion
* Cloud data storage
* Data transformation
* Medallion Architecture
* Metadata-driven ETL
* Data quality validation
* Incremental processing
* Delta MERGE / UPSERT
* Dimensional modeling
* ETL monitoring
* Error handling
* Security
* Pipeline orchestration

This project demonstrates how multiple Azure Data Engineering services can work together to build a **reliable, maintainable, and scalable data pipeline** for logistics data.
