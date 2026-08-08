# End-to-End Implementation Guide

Follow this order during implementation.

## Phase 1 — GitHub
1. Create `azure-logistics-data-engineering` repository.
2. Create numbered folders.
3. Add README, documentation, SQL, Databricks, ADF, sample-data, architecture, and screenshot folders.
4. Add `.gitignore` and never commit secrets.

## Phase 2 — Azure Foundation
5. Create `rg-logistic-dev`.
6. Create ADLS Gen2 Storage Account with Hierarchical Namespace enabled.
7. Create `landing`, `bronze`, `silver`, `gold`, and `logs` containers.
8. Create landing folders for Sales and Appointment data.
9. Upload the source CSV files.

## Phase 3 — Metadata and Security
10. Create Azure SQL Server and `LogisticDB`.
11. Create `metadata` schema.
12. Create `OBJECTS_CONFIGURATION`.
13. Create `OBJECTS_COLUMN_MAPPING`.
14. Create `EDW_CONFIG`.
15. Create `ETL_LOG`.
16. Insert Sales and Appointment configuration records.
17. Insert corrected column mappings.
18. Create Azure Key Vault and store SQL secrets.

## Phase 4 — Databricks and Unity Catalog
19. Create Azure Databricks workspace.
20. Create Access Connector.
21. Assign required storage RBAC role to the Access Connector identity.
22. Create Unity Catalog storage credential.
23. Create external locations for Bronze, Silver, and Gold ADLS paths.
24. Create catalogs: `bronze`, `silver`, `gold`.
25. Create schemas: `bronze.logistic`, `silver.logistic`, `gold.edw`.
26. Test storage access.

## Phase 5 — Bronze
27. Read metadata from Azure SQL.
28. Read CSV from ADLS landing.
29. Normalize column names.
30. Add `ADDED_BY` and `ADDED_ON`.
31. Write Bronze Delta tables.

## Phase 6 — Silver
32. Read Bronze table.
33. Load column mapping metadata.
34. Rename columns.
35. Apply null defaults.
36. Cast datatypes.
37. Parse dates.
38. Remove duplicates using business keys.
39. Add audit columns.
40. Perform first full load.
41. Test Silver data.
42. Switch to incremental mode and implement Delta MERGE with null-safe key matching.

## Phase 7 — Gold
43. Build `DIM_APPOINTMENT_DATA`.
44. Keep latest Appointment row for each Yard.
45. Create `APPOINTMENT_DATA_KEY`.
46. Build `FACT_SALES`.
47. Left join Sales with Appointment Dimension using Yard.
48. Create `SALES_KEY`.
49. Validate matched and unmatched Appointment keys.

## Phase 8 — Validation and Logging
50. Add row-count checks.
51. Add duplicate checks.
52. Add NULL checks.
53. Add source-to-target reconciliation.
54. Write ETL run details to `ETL_LOG`.
55. Add exception/error logging.

## Phase 9 — ADF
56. Create Azure Data Factory.
57. Create Databricks linked service.
58. Create end-to-end pipeline.
59. Run Bronze notebook.
60. Run Silver notebook.
61. Run DIM notebook.
62. Run FACT notebook.
63. Add validation/logging activity.
64. Configure success and failure dependencies.
65. Add schedule trigger.
66. Monitor test execution.

## Phase 10 — GitHub Finalization
67. Export final notebooks/code to `04_Databricks`.
68. Save metadata SQL under `03_SQL`.
69. Export ADF pipeline JSON/documentation.
70. Add architecture diagrams.
71. Add screenshots with no secrets visible.
72. Update README with architecture, technologies, pipeline flow, validation, and results.

## Final Output
```text
Landing CSV
   ↓
Bronze Delta
   ↓
Silver Delta
   ↓
DIM_APPOINTMENT_DATA
   ↓
FACT_SALES
   ↓
Validation + Logging

ADF orchestrates the process.
Unity Catalog governs the Databricks data objects and ADLS access.
Azure SQL stores metadata.
Key Vault protects credentials.
GitHub stores code and documentation.
```
