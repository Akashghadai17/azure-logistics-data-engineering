# Data Validation and ETL Logging

## Validation Objectives
Validate data at each processing layer before considering a run successful.

## Core Checks
- Row count
- Duplicate count
- NULL checks
- Business-key validation
- Datatype validation
- Invalid date detection
- Source-to-target reconciliation
- Gold join match/unmatched analysis

## Row Count
```python
source_count = source_df.count()
target_count = target_df.count()
```

## Duplicate Validation
```python
(
    df.groupBy(key_columns)
      .count()
      .filter("count > 1")
      .show()
)
```

## NULL Validation
```python
null_count = df.filter(col("YARD_ID").isNull()).count()
```

## Join Validation
Check how many Sales rows matched the Appointment dimension and how many remained unmatched.

```python
matched = fact_df.filter(col("APPOINTMENT_DATA_KEY").isNotNull()).count()
unmatched = fact_df.filter(col("APPOINTMENT_DATA_KEY").isNull()).count()
```

# ETL Logging

## Suggested Log Columns
```text
PIPELINE_RUN_ID
OBJECT_NAME
LAYER
START_TIME
END_TIME
SOURCE_COUNT
TARGET_COUNT
STATUS
ERROR_MESSAGE
```

## Example
```text
RUN001 | SALES_DATA_PRIOR_DAY | SILVER | ... | 8566 | 8566 | SUCCESS | NULL
```

## Error Handling
```python
try:
    # ETL processing
    status = "SUCCESS"
except Exception as e:
    status = "FAILED"
    error_message = str(e)
    raise
```

The logging process should write both successful and failed runs so that pipeline execution can be audited and troubleshot.
