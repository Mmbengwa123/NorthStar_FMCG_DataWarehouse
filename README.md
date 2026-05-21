NorthStar FMCG Supply Chain - End-to-End Data Warehouse PoC

Project summary
- Purpose: Demonstrate an end-to-end supply-chain ETL into a small data warehouse using the provided CSV datasets, perform data quality checks, and enable BI reporting.
- Scope: Ingestion (staging), dim/fact modeling (star schema), ETL stored procedures (MERGE/upsert), orchestration (SSIS + SQL Agent), data quality checks, and a Power BI-ready model.

Artifacts created
- SQL (create databases, staging, dims/facts, procs, checks): [sql/create_databases_and_schemas.sql](sql/create_databases_and_schemas.sql)
- Staging table DDL: [sql/create_staging_tables.sql](sql/create_staging_tables.sql)
- Dim & Fact DDL: [sql/create_dim_fact_tables.sql](sql/create_dim_fact_tables.sql)
- ETL Stored Procedures: [sql/stored_procedures.sql](sql/stored_procedures.sql)
- Data-quality checks: [sql/quality_checks.sql](sql/quality_checks.sql)
- Star-schema (ER): [diagrams/dim_schema.mmd](diagrams/dim_schema.mmd)
- Medallion architecture: [diagrams/medallion_architecture.mmd](diagrams/medallion_architecture.mmd)
- Orchestration plan (SSIS / SQL Agent): [docs/ssis_plan.md](docs/ssis_plan.md)
- Dashboard guide: [dashboard/README.md](dashboard/README.md)

End-to-end process (high level)
1. Landing: CSV files are placed into a secure landing folder (network share or Azure Blob).
2. Ingest -> Bronze (Staging): SSIS Flat File or BULK INSERT reads CSVs into `NorthStar_Staging.dbo.staging.*` tables; minimal parsing and type casting.
3. Clean / Normalize -> Silver (ODS): Run stored procedures to upsert into `dw.dim_*` and prepare normalized facts (MERGE patterns implemented in `dw.sp_upsert_*`).
4. Enrich / Aggregate -> Gold (BI): Load cleansed facts into `dw.fact_*` and create aggregated KPI tables or materialized views for reporting.
5. Orchestration & Scheduling: SSIS packages chained and scheduled by SQL Agent; run data-quality checks and alert on failures.

Star schema (summary)
- Fact table: `dw.fact_sku_demand_daily` (grain: sku x retailer x date)
- Dimensions:
	- `dw.dim_sku` — SKU attributes (sku, pack_type, brand, category, packaging, avg_price, shelf_life)
	- `dw.dim_retailer` — Retailer/customer attributes (retailer_id, customer_name, region, channel)

This star model supports time-series sales, revenue, and segmentation analysis.

Medallion architecture
- Raw (CSV landing) -> Bronze (Staging) -> Silver (ODS/dim normalized) -> Gold (aggregates/BI), represented in [diagrams/medallion_architecture.mmd](diagrams/medallion_architecture.mmd).

Tools used
- SQL Server / SSMS: database, DDL, stored procedures, SQL Agent scheduling
- SSIS: package-based ingestion and orchestration (Flat File -> Staging -> Execute SQL)
- Power BI (recommended): dashboard and visualizations
- Mermaid (for diagrams): `diagrams/*.mmd`
- Local workspace: CSV files in current project folder

Issues identified and addressed
- Duplicate SKU rows across `pack_type` variants — resolved by using a composite natural key (`sku`,`pack_type`) and a surrogate `sku_key` in `dw.dim_sku`.
- Inconsistent `pack_type` naming in source CSVs — recommended normalization in staging (mapping table or standardization step in SSIS).
- Price mismatches between dim `avg_price` and fact `avg_price` — surfaced by the `sql/quality_checks.sql` rule (>50% difference) for manual review.
- Missing dim lookups: facts referencing retailer or SKUs not found in dims — handled by filtering in `dw.sp_load_fact_sku_demand_daily` and flagged via the referential-integrity checks.

Data quality checks (how to run)
1. After running ETL, open and run: [sql/quality_checks.sql](sql/quality_checks.sql) in SSMS.
2. Key checks included:
	- Row counts for dims and facts
	- Null / missing natural keys
	- Duplicate natural keys
	- Orphan facts (missing dim FK references)
	- Negative or anomalous values (negative units, price mismatches)

How to run (quick start)
1. Create databases and schemas (in SSMS):
```
-- Run in SSMS as a user with DB create privileges
:r .\\sql\\create_databases_and_schemas.sql
```
2. Create staging and DW tables:
```
:r .\\sql\\create_staging_tables.sql
:r .\\sql\\create_dim_fact_tables.sql
```
3. Load CSVs into staging (example using BULK INSERT — adjust path and options):
```
USE NorthStar_Staging;
BULK INSERT staging.stg_dim_skus
FROM 'C:\\path\\to\\dim_skus.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\\n',
	CODEPAGE = '65001'
);
-- Repeat for other CSV files (dim_retailers, fact_sku_demand_daily, etc.)
```
4. Run ETL stored procedures in `NorthStar_DW`:
```
USE NorthStar_DW;
EXEC dw.sp_upsert_dim_sku;
EXEC dw.sp_upsert_dim_retailer;
EXEC dw.sp_load_fact_sku_demand_daily;
```
5. Run data-quality checks:
```
:r .\\sql\\quality_checks.sql
```
6. Connect Power BI to `NorthStar_DW` and model `dw.dim_*` + `dw.fact_*` for reporting.

Next steps (recommended)
- Build SSIS packages (or Azure Data Factory pipelines) to automate CSV ingestion into staging with type normalization and error handling.
- Create SQL Agent jobs that run SSIS packages and trigger data-quality checks, with alerting (email/webhook) on failures.
- Implement incremental loading logic (CDC or watermark column) to avoid full reloads.
- Build a Power BI report (PBIX) with the suggested visuals and publish to Power BI Service for scheduled refresh.
- Add monitoring dashboards for ETL health (rows processed, failures, runtime) and unit tests for ETL SQL logic.

Contact / Ownership
- Author: Junior Data Engineering_Mpho Mmbengwa

-- End of README
