# Azure Databricks Setup

## Workspace
Suggested workspace:

```text
dbw-logistic-dev
```

## Notebook Structure
```text
01_Bronze_Ingestion
02_Bronze_To_Silver
03_DIM_Appointment
04_FACT_Sales
05_ETL_Logging
```

## Processing Responsibilities
### 01_Bronze_Ingestion
- Read metadata from Azure SQL
- Read source CSV from ADLS landing
- Normalize source column names
- Add audit fields
- Write Bronze Delta tables

### 02_Bronze_To_Silver
- Read Bronze table
- Read column mapping metadata
- Rename columns
- Handle null/default values
- Cast datatypes
- Parse date values
- Remove duplicates
- Perform full load or Delta MERGE

### 03_DIM_Appointment
- Read Silver Appointment data
- Select latest appointment record per Yard
- Create `APPOINTMENT_DATA_KEY`
- Write `gold.edw.dim_appointment_data`

### 04_FACT_Sales
- Read Silver Sales data
- Read Gold Appointment dimension
- Left join by `Sales.YARD = Dimension.YARD_NAME`
- Create `SALES_KEY`
- Write `gold.edw.fact_sales`

### 05_ETL_Logging
- Store run status
- Record source/target counts
- Record run timestamps
- Capture error message when a step fails

## Parameters
The notebooks should accept values such as:

```text
ObjectName
PipelineRunID
LoadType
```

These parameters can later be supplied by ADF.
