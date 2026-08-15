# Azure Data Factory Orchestration

## When ADF Is Added
ADF is implemented after the Bronze, Silver, Dimension, and Fact notebooks have been tested successfully in Databricks.

## Purpose
ADF orchestrates the pipeline. The transformation logic remains in Databricks/PySpark.

## Pipeline Flow
```text
Trigger
  ↓
Bronze Ingestion
  ↓
Bronze to Silver
  ↓
DIM Appointment
  ↓
FACT Sales
  ↓
Validation / Logging
```

## Suggested Pipeline Name
```text
PL_LOGISTIC_END_TO_END
```

## Parameters
ADF can pass parameters such as:

```text
ObjectName
PipelineRunID
LoadType
```

## Dependencies
Use success dependencies between normal activities.

Example:

```text
Bronze Success
     ↓
Silver Success
     ↓
DIM Success
     ↓
FACT
```

Use failure paths to call error logging.

```text
Activity Failure
      ↓
ETL Error Logging
```

## Scheduling
After successful manual testing, add a schedule trigger based on the project requirement, such as daily processing for prior-day sales data.
