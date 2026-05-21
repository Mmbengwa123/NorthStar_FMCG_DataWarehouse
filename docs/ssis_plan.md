# SSIS Orchestration Plan

![Project](https://img.shields.io/badge/Project-End-to-End%20Data%20Warehouse-blue?style=for-the-badge)
![SSIS](https://img.shields.io/badge/SSIS-data%20integration-orange?style=for-the-badge&logo=microsoft-sql-server)
![SQL%20Server](https://img.shields.io/badge/SQL%20Server-SSMS-4479A1?style=for-the-badge&logo=microsoft-sql-server)
![CSV](https://img.shields.io/badge/Data-CSV-green?style=for-the-badge)

## Purpose

This plan defines the package chain for ingesting CSV data, loading staging tables, updating dimensions, loading facts, and validating data quality with alerts.

## Package architecture

### Package 1: Ingest → Staging
- Source: CSV files from a shared file share or ingestion landing zone
- Use `Flat File Source` for each CSV file
- Apply `Data Conversion` for dates, integers, decimals, and text normalization
- Load into `NorthStar_Staging.dbo.staging.*` using `OLE DB Destination`

### Package 2: Dimension Upsert
- Execute SQL Task: `EXEC dw.sp_upsert_dim_sku`
- Execute SQL Task: `EXEC dw.sp_upsert_dim_retailer`
- Ensure dimension keys and lookup values are refreshed before fact loads

### Package 3: Load Facts
- Execute SQL Task: `EXEC dw.sp_load_fact_sku_demand_daily`
- Load cleansed fact rows and preserve referential integrity with dimension lookups

### Package 4: Data Quality Checks & Alerts
- Execute SQL Task to run queries in `sql/quality_checks.sql`
- Send Mail Task or custom alert if checks fail
- Capture row counts, duplicates, missing FK references, and anomalous values

## Scheduling

Use SQL Agent to orchestrate the package sequence:

1. Run Package 1
2. Run Package 2
3. Run Package 3
4. Run Package 4

Use job steps or package execution order to enforce the workflow.

## Operational recommendations

- Enable package checkpointing for restartability
- Externalize connection strings, file paths, and configuration values
- Add error handling and logging for each package step
- Consider incremental loads using `last_load_date` or change detection logic
- Maintain a clear deployment and versioning strategy for SSIS packages
