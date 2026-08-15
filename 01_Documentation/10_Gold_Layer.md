# Gold Layer Implementation

## Overview

The Gold layer is the final analytical layer in the **Logistics Azure Data Engineering Project**.

The Silver layer contains cleaned and standardized Sales and Appointment data.

The Gold layer transforms this trusted Silver data into **business-ready Dimension and Fact tables**.

The final Gold tables are:

```text
DIM_APPOINTMENT_DATA
FACT_SALES
```

These tables are stored as **Unity Catalog managed Delta tables**.

---

# Gold Layer Architecture

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

The complete flow is:

```text
Silver Managed Tables
        ↓
Azure Databricks
        ↓
Gold Transformations
        ↓
Dimension + Fact Tables
        ↓
Unity Catalog Gold Schema
        ↓
SC2 Managed Storage
```

---

# Purpose of the Gold Layer

The Gold layer is designed for:

* Business analytics
* Reporting
* Aggregation
* Dimensional modeling
* Downstream consumption
* Analytical queries

The Gold layer should contain data that is easy for analysts and reporting systems to use.

---

# Gold Layer Input

The Gold layer reads data from the Silver schema.

The main inputs are:

```text
Silver Sales Data
Silver Appointment Data
```

These datasets have already gone through:

* Data cleaning
* Data type conversion
* NULL handling
* Duplicate removal
* Standardization
* Data quality checks

---

# Why Gold Uses Silver Data

Gold does not directly use raw source CSV files.

Correct flow:

```text
Source CSV
    ↓
Bronze
    ↓
Silver
    ↓
Gold
```

This ensures Gold is created only from cleaned and validated data.

---

# Final Gold Tables

The project creates two main Gold tables:

1. `DIM_APPOINTMENT_DATA`
2. `FACT_SALES`

---

# DIM_APPOINTMENT_DATA

`DIM_APPOINTMENT_DATA` is the Dimension table created from cleaned Appointment data.

A Dimension table stores descriptive information.

Examples of descriptive attributes can include:

* Appointment information
* Title
* Status
* Date
* Other appointment-related attributes

The exact columns depend on the final standardized Appointment dataset.

---

# Dimension Table Purpose

The Dimension table provides descriptive context for analytical data.

Easy way to remember:

```text
Dimension
    ↓
Describes
```

For example:

```text
Appointment ID
Title
Status
Date
```

These values describe an appointment.

---

# Dimension Table Flow

```text
Silver Appointment
        ↓
Select Required Columns
        ↓
Remove Required Duplicates
        ↓
Create Surrogate Key
        ↓
DIM_APPOINTMENT_DATA
```

---

# Surrogate Key

A **surrogate key** is a system-generated key used as the unique identifier of a Dimension record.

It is different from a source business key.

Example:

```text
Source Appointment ID
        ↓
Business Key

APPOINTMENT_KEY
        ↓
Surrogate Key
```

A surrogate key is usually created specifically for the analytical model.

---

# Why Surrogate Keys Are Used

Surrogate keys help:

* Create stable Dimension identifiers
* Avoid depending completely on source-system keys
* Support joins between Fact and Dimension tables
* Support dimensional modeling
* Simplify analytical relationships

Easy way to remember:

```text
Business Key
   ↓
Comes from Source

Surrogate Key
   ↓
Created in Data Warehouse
```

---

# Example Dimension Structure

Conceptually:

```text
DIM_APPOINTMENT_DATA
│
├── APPOINTMENT_KEY
├── APPOINTMENT_ID
├── TITLE
├── STATUS
├── DATE
└── Other Attributes
```

The exact final columns should match the implemented Gold table.

---

# Creating a Surrogate Key in PySpark

A surrogate key can be generated using Spark functions.

Conceptually:

```python
from pyspark.sql.functions import monotonically_increasing_id

dim_appointment_df = (
    appointment_silver_df
    .withColumn(
        "APPOINTMENT_KEY",
        monotonically_increasing_id()
    )
)
```

The exact implementation can differ depending on the project logic.

---

# FACT_SALES

`FACT_SALES` is the main Fact table of the project.

A Fact table stores measurable or transactional information.

Examples can include:

* Sales values
* Price
* Quantity
* Other measurable fields

The Fact table also contains the key required to connect with the related Dimension table.

---

# Fact Table Purpose

Easy way to remember:

```text
Fact
 ↓
Measures
```

For example:

```text
Price
Quantity
Sales Amount
```

These are measurable values.

---

# Fact Table Flow

```text
Silver Sales
      +
DIM_APPOINTMENT_DATA
      ↓
Join
      ↓
Select Required Columns
      ↓
FACT_SALES
```

---

# Dimension and Fact Relationship

The relationship is:

```text
DIM_APPOINTMENT_DATA
        │
        │ APPOINTMENT_KEY
        ↓
    FACT_SALES
```

The surrogate key from the Dimension table can be stored in the Fact table as a foreign key.

This creates the analytical relationship between Sales and Appointment information.

---

# Gold Join

The Gold process joins Silver Sales data with the Appointment Dimension.

Conceptually:

```python
fact_sales_df = (
    sales_silver_df.alias("s")
    .join(
        dim_appointment_df.alias("d"),
        "<business join condition>",
        "left"
    )
)
```

The actual join condition should use the business relationship implemented in the project.

---

# Why a Left Join Can Be Used

A left join can preserve all Sales records even if some records do not find a matching Appointment Dimension record.

Conceptually:

```text
Sales
  ↓
LEFT JOIN
  ↓
Appointment Dimension
```

Result:

```text
All Sales Records
+
Matching Appointment Information
```

The final join type should match the actual project implementation.

---

# Gold Dimensional Model

The analytical model can be viewed as:

```text
          DIM_APPOINTMENT_DATA
                  │
                  │
                  ↓
              FACT_SALES
```

This is a simple dimensional-modeling structure.

---

# Dimension vs Fact

| Dimension Table      | Fact Table            |
| -------------------- | --------------------- |
| Descriptive data     | Measurable data       |
| Contains attributes  | Contains metrics      |
| Uses surrogate key   | Stores dimension key  |
| Used for filtering   | Used for calculations |
| Example: Appointment | Example: Sales        |

Easy way to remember:

```text
DIM = Description
FACT = Measurement
```

---

# Reading Silver Data

Gold processing reads the Silver managed tables from Unity Catalog.

Conceptually:

```python
appointment_silver_df = spark.table(
    "<catalog>.silver.<appointment_table>"
)
```

Sales:

```python
sales_silver_df = spark.table(
    "<catalog>.silver.<sales_table>"
)
```

---

# Creating DIM_APPOINTMENT_DATA

High-level steps:

```text
Read Silver Appointment
        ↓
Select Dimension Columns
        ↓
Remove Duplicates
        ↓
Create Surrogate Key
        ↓
Validate Dimension
        ↓
Write Gold Table
```

Conceptually:

```python
dim_appointment_df = (
    appointment_silver_df
    .select(
        "<required_dimension_columns>"
    )
    .dropDuplicates()
)
```

Then the surrogate key can be added according to the project logic.

---

# Creating FACT_SALES

High-level steps:

```text
Read Silver Sales
        ↓
Read DIM_APPOINTMENT_DATA
        ↓
Join Using Business Key
        ↓
Retrieve Surrogate Key
        ↓
Select Fact Columns
        ↓
Write FACT_SALES
```

---

# Why the Fact Table Uses a Dimension Key

Instead of copying all Appointment attributes into the Fact table, the Fact table can store only the Dimension key.

Example:

```text
FACT_SALES
│
├── SALES information
├── PRICE
├── Other Measures
└── APPOINTMENT_KEY
```

The descriptive information remains in:

```text
DIM_APPOINTMENT_DATA
```

This reduces duplication and improves analytical modeling.

---

# Gold Data Quality

Before writing final Gold tables, the project should verify important conditions.

Examples include:

* Dimension key uniqueness
* Required columns
* NULL checks
* Duplicate checks
* Fact-to-Dimension relationships
* Row counts
* Invalid key checks

---

# Dimension Key Validation

The surrogate key should uniquely identify Dimension rows.

Conceptually:

```text
Total Dimension Rows
        ↓
Distinct Surrogate Keys
```

Expected:

```text
Total Rows = Distinct Keys
```

---

# Duplicate Validation

Dimension records should not contain unintended duplicate business records.

Conceptually:

```python
dim_appointment_df = dim_appointment_df.dropDuplicates(
    ["<business_key>"]
)
```

This ensures a business entity is represented correctly.

---

# Fact Foreign Key Validation

The Fact table should be checked to ensure Dimension references are valid.

Conceptually:

```text
FACT_SALES
    ↓
APPOINTMENT_KEY
    ↓
DIM_APPOINTMENT_DATA
```

If a key does not match, it should be investigated according to the project business rules.

---

# Gold Managed Tables

The final Dimension and Fact tables are stored in the Unity Catalog Gold schema.

Conceptually:

```text
Unity Catalog
      ↓
gold
      │
      ├── DIM_APPOINTMENT_DATA
      └── FACT_SALES
```

---

# Writing DIM_APPOINTMENT_DATA

Conceptually:

```python
dim_appointment_df.write \
    .format("delta") \
    .mode("overwrite") \
    .saveAsTable(
        "<catalog>.gold.DIM_APPOINTMENT_DATA"
    )
```

---

# Writing FACT_SALES

Conceptually:

```python
fact_sales_df.write \
    .format("delta") \
    .mode("overwrite") \
    .saveAsTable(
        "<catalog>.gold.FACT_SALES"
    )
```

The write mode depends on whether the notebook is performing a full load or incremental processing.

---

# Physical Gold Storage

Gold tables are Unity Catalog managed tables.

Their physical Delta data is stored in **SC2 managed storage**.

```text
Gold Table
    ↓
Unity Catalog
    ↓
Managed Delta Table
    ↓
SC2
```

Gold data is not manually stored in an SC1 Gold folder.

---

# SC1 vs SC2 in Gold

## SC1

Used for:

```text
Landing
Logs
Archive
```

## SC2

Used for:

```text
Unity Catalog Managed Storage
```

including:

```text
Bronze
Silver
Gold
```

---

# Delta Lake

Gold tables use Delta Lake.

Delta provides:

* Reliable transactions
* UPDATE support
* MERGE support
* Schema enforcement
* Incremental processing
* Consistent reads and writes

This is important when Gold tables are updated incrementally.

---

# Gold and Incremental Loading

After the initial Gold tables are created, later runs can use incremental processing.

Instead of rebuilding the complete table every time:

```text
Existing Gold Table
        +
New / Changed Data
        ↓
Delta MERGE
```

---

# Delta MERGE / UPSERT

The Gold incremental process can perform:

```text
Matched Record
      ↓
UPDATE

New Record
      ↓
INSERT
```

This process is:

```text
UPSERT = UPDATE + INSERT
```

---

# Gold and ETL Logging

Gold processing is tracked through:

```sql
audit.ETL_LOG
```

The audit log can contain:

* Gold process name
* Target table
* Start time
* End time
* Record count
* Status
* Error message

Example statuses:

```text
STARTED
SUCCESS
FAILED
```

---

# Successful Gold Flow

```text
Start Gold Job
      ↓
Write STARTED Log
      ↓
Read Silver
      ↓
Create Dimension
      ↓
Create Fact
      ↓
Validate Gold
      ↓
Write Gold Tables
      ↓
Write SUCCESS Log
```

---

# Failed Gold Flow

```text
Start Gold Job
      ↓
Gold Transformation
      ↓
Processing Failure
      ↓
Capture Exception
      ↓
Write FAILED Log
```

---

# Error Handling

Gold processing uses exception handling so failures can be captured.

Conceptually:

```python
try:
    # Read Silver
    # Create Dimension
    # Create Fact
    # Write Gold

except Exception as e:
    # Record error
    # Write FAILED log
    raise
```

---

# Complete Gold Processing Flow

```text
                Silver Appointment
                        │
                        ↓
               Select Dimension Data
                        ↓
                 Remove Duplicates
                        ↓
               Create Surrogate Key
                        ↓
             DIM_APPOINTMENT_DATA
                        │
                        │
                        │ Join
                        ↓
                  Silver Sales
                        │
                        ↓
                Create FACT_SALES
                        │
                        ↓
                 Gold Validation
                        │
                        ↓
                  Unity Catalog
                        │
                     gold schema
                        │
              ┌─────────┴─────────┐
              ↓                   ↓
 DIM_APPOINTMENT_DATA         FACT_SALES
              │                   │
              └─────────┬─────────┘
                        ↓
                SC2 Managed Storage
```

---

# Gold Layer Business View

The technical pipeline:

```text
CSV
 ↓
Bronze
 ↓
Silver
 ↓
Gold
```

becomes a business model:

```text
Appointment Dimension
        +
Sales Fact
        ↓
Analytics
```

This is one of the main objectives of the Gold layer.

---

# Example Analytical Use

The Gold model can support questions such as:

* Sales by Appointment
* Sales by Appointment Status
* Sales by Date
* Number of Sales records
* Appointment-based Sales analysis
* Other logistics-related analytical queries

The exact analytical queries depend on the available columns.

---

# Gold Layer vs Silver Layer

## Silver

```text
Cleaned Data
Standardized Data
Detailed Records
```

## Gold

```text
Business Model
Dimension Tables
Fact Tables
Analytical Data
```

Easy way to remember:

```text
Silver
  ↓
Trusted Data

Gold
  ↓
Useful Business Data
```

---

# Bronze vs Silver vs Gold

| Layer  | Purpose                                    |
| ------ | ------------------------------------------ |
| Bronze | Preserve source data                       |
| Silver | Clean and standardize data                 |
| Gold   | Build analytical Dimension and Fact tables |

---

# Easy Gold Layer Explanation

Remember the Gold layer as:

```text
Read Silver
    ↓
Create Dimension
    ↓
Create Surrogate Key
    ↓
Join With Sales
    ↓
Create Fact
    ↓
Validate
    ↓
Save Gold
```

---

# Interview Explanation

> In my Logistics Azure Data Engineering project, the Gold layer creates the final analytical data model from cleaned Silver data. I created `DIM_APPOINTMENT_DATA` from the Appointment dataset and generated a surrogate key for the Dimension. Then I joined the required Appointment information with the Silver Sales dataset to create `FACT_SALES`. Both tables are stored as Unity Catalog managed Delta tables in the Gold schema, with the physical managed storage in the second ADLS account. The Gold layer provides business-ready Dimension and Fact data for analytics and reporting.

---

# Final Gold Architecture

```text
                  Silver Layer
                 /            \
                ↓              ↓
        Appointment Data     Sales Data
                │              │
                ↓              │
     DIM_APPOINTMENT_DATA      │
                │              │
                └──────┬───────┘
                       ↓
                     JOIN
                       ↓
                   FACT_SALES
                       ↓
               Unity Catalog Gold
                       ↓
                Managed Delta
                       ↓
                      SC2
```

---

# Summary

The Gold layer converts cleaned Silver data into a simple dimensional model.

```text
Silver Appointment
        ↓
DIM_APPOINTMENT_DATA
        ↓
        + 
Silver Sales
        ↓
FACT_SALES
```

The final Gold data is stored as Unity Catalog managed Delta tables and is ready for analytics, reporting, and downstream business use.
