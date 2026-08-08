# Bronze Layer

## Objective
The Bronze layer stores source data with minimal business transformation while adding technical metadata required for traceability.

## Inputs
```text
Sales_Data_Prior_Day.csv
AppointmentDataTest.csv
```

## Output Tables
```text
bronze.logistic.sales_data_prior_day
bronze.logistic.appointment_data
```

## Bronze Transformations
### 1. Read CSV
```python
df = (
    spark.read
    .option("header", True)
    .option("inferSchema", False)
    .csv(source_path)
)
```

### 2. Normalize Column Names
Example:

```text
Yard Id          → YARD_ID
Material Name    → MATERIAL_NAME
Invoice Total    → INVOICE_TOTAL
```

Typical normalization:

```python
import re

def normalize_columns(df):
    for old_col in df.columns:
        new_col = re.sub(r"[^a-zA-Z0-9]+", "_", old_col).strip("_").upper()
        df = df.withColumnRenamed(old_col, new_col)
    return df
```

### 3. Add Audit Columns
```python
from pyspark.sql.functions import current_timestamp, lit

df = (
    df
    .withColumn("ADDED_BY", lit(pipeline_run_id))
    .withColumn("ADDED_ON", current_timestamp())
)
```

### 4. Write Delta Table
```python
(
    df.write
    .format("delta")
    .mode("append")
    .saveAsTable(target_table)
)
```

## Bronze Principle
Do not perform major business transformations in Bronze. Data cleansing and standardization belong in Silver.
