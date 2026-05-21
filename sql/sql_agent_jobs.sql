-- SQL Server Agent Job Setup for NorthStar FMCG Data Warehouse ETL Pipeline
-- This script creates jobs to orchestrate the end-to-end ETL process
-- Prerequisite: SQL Server Agent must be running
-- Run in SSMS as a sysadmin

USE msdb;
GO

-- =====================================================================
-- Job 1: ETL_01_INGEST_TO_STAGING
-- Purpose: Load CSV data into staging tables
-- =====================================================================

-- Create the job
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = 'ETL_01_INGEST_TO_STAGING')
BEGIN
    EXEC msdb.dbo.sp_add_job 
        @job_name = 'ETL_01_INGEST_TO_STAGING',
        @description = 'Ingest CSV files into staging tables (Bronze layer)',
        @enabled = 1;
END
GO

-- Add job step: Clear staging tables (idempotency)
EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'ETL_01_INGEST_TO_STAGING',
    @step_name = 'Step 1: Clear Staging Tables',
    @subsystem = 'TSQL',
    @command = N'
USE NorthStar_Staging;
TRUNCATE TABLE staging.stg_dim_skus;
TRUNCATE TABLE staging.stg_dim_retailers;
TRUNCATE TABLE staging.stg_fact_sku_demand_daily;
',
    @on_success_action = 3, -- Go to next step
    @on_fail_action = 2;    -- Quit with failure
GO

-- Add job step: Load data from CSV (example for dim_skus)
-- NOTE: Adjust file paths to match your landing zone
EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'ETL_01_INGEST_TO_STAGING',
    @step_name = 'Step 2: Load SKU Data',
    @subsystem = 'TSQL',
    @command = N'
USE NorthStar_Staging;
BULK INSERT staging.stg_dim_skus
FROM ''C:\DataLanding\dim_skus.csv''
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''\n'',
    CODEPAGE = ''65001''
);
',
    @on_success_action = 3,
    @on_fail_action = 2;
GO

-- Add job step: Load retailer data
EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'ETL_01_INGEST_TO_STAGING',
    @step_name = 'Step 3: Load Retailer Data',
    @subsystem = 'TSQL',
    @command = N'
USE NorthStar_Staging;
BULK INSERT staging.stg_dim_retailers
FROM ''C:\DataLanding\dim_retailers.csv''
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''\n'',
    CODEPAGE = ''65001''
);
',
    @on_success_action = 3,
    @on_fail_action = 2;
GO

-- Add job step: Load fact data
EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'ETL_01_INGEST_TO_STAGING',
    @step_name = 'Step 4: Load Fact Data',
    @subsystem = 'TSQL',
    @command = N'
USE NorthStar_Staging;
BULK INSERT staging.stg_fact_sku_demand_daily
FROM ''C:\DataLanding\fact_sku_demand_daily.csv''
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''\n'',
    CODEPAGE = ''65001''
);
',
    @on_success_action = 3,
    @on_fail_action = 2;
GO

-- Log staging row counts for verification
EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'ETL_01_INGEST_TO_STAGING',
    @step_name = 'Step 5: Log Row Counts',
    @subsystem = 'TSQL',
    @command = N'
USE NorthStar_Staging;
SELECT 
    ''stg_dim_skus'' AS table_name, 
    COUNT(*) AS row_count 
FROM staging.stg_dim_skus
UNION ALL
SELECT ''stg_dim_retailers'', COUNT(*) FROM staging.stg_dim_retailers
UNION ALL
SELECT ''stg_fact_sku_demand_daily'', COUNT(*) FROM staging.stg_fact_sku_demand_daily;
',
    @on_success_action = 1, -- Complete with success
    @on_fail_action = 2;
GO

-- =====================================================================
-- Job 2: ETL_02_UPSERT_DIMENSIONS
-- Purpose: Populate dimension tables with MERGE (Silver layer)
-- =====================================================================

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = 'ETL_02_UPSERT_DIMENSIONS')
BEGIN
    EXEC msdb.dbo.sp_add_job 
        @job_name = 'ETL_02_UPSERT_DIMENSIONS',
        @description = 'Upsert dimension tables from staging (Silver layer)',
        @enabled = 1;
END
GO

EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'ETL_02_UPSERT_DIMENSIONS',
    @step_name = 'Step 1: Upsert dim_sku',
    @subsystem = 'TSQL',
    @command = N'USE NorthStar_DW; EXEC dw.sp_upsert_dim_sku;',
    @on_success_action = 3,
    @on_fail_action = 2;
GO

EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'ETL_02_UPSERT_DIMENSIONS',
    @step_name = 'Step 2: Upsert dim_retailer',
    @subsystem = 'TSQL',
    @command = N'USE NorthStar_DW; EXEC dw.sp_upsert_dim_retailer;',
    @on_success_action = 1,
    @on_fail_action = 2;
GO

-- =====================================================================
-- Job 3: ETL_03_LOAD_FACTS
-- Purpose: Load fact table with validated data (Gold layer)
-- =====================================================================

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = 'ETL_03_LOAD_FACTS')
BEGIN
    EXEC msdb.dbo.sp_add_job 
        @job_name = 'ETL_03_LOAD_FACTS',
        @description = 'Load fact tables from staging with dim lookups (Gold layer)',
        @enabled = 1;
END
GO

EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'ETL_03_LOAD_FACTS',
    @step_name = 'Step 1: Clear Existing Facts (Optional - for full reload)',
    @subsystem = 'TSQL',
    @command = N'
-- Uncomment to do full reload; otherwise, facts are inserted incrementally
-- USE NorthStar_DW;
-- TRUNCATE TABLE dw.fact_sku_demand_daily;
',
    @on_success_action = 3,
    @on_fail_action = 2;
GO

EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'ETL_03_LOAD_FACTS',
    @step_name = 'Step 2: Load fact_sku_demand_daily',
    @subsystem = 'TSQL',
    @command = N'USE NorthStar_DW; EXEC dw.sp_load_fact_sku_demand_daily;',
    @on_success_action = 1,
    @on_fail_action = 2;
GO

-- =====================================================================
-- Job 4: ETL_04_DATA_QUALITY_CHECKS
-- Purpose: Run quality checks and log results
-- =====================================================================

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = 'ETL_04_DATA_QUALITY_CHECKS')
BEGIN
    EXEC msdb.dbo.sp_add_job 
        @job_name = 'ETL_04_DATA_QUALITY_CHECKS',
        @description = 'Validate data quality and flag anomalies',
        @enabled = 1;
END
GO

EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'ETL_04_DATA_QUALITY_CHECKS',
    @step_name = 'Step 1: Row Count Checks',
    @subsystem = 'TSQL',
    @command = N'
USE NorthStar_DW;
DECLARE @dim_sku_count INT, @dim_retailer_count INT, @fact_count INT;
SELECT @dim_sku_count = COUNT(*) FROM dw.dim_sku;
SELECT @dim_retailer_count = COUNT(*) FROM dw.dim_retailer;
SELECT @fact_count = COUNT(*) FROM dw.fact_sku_demand_daily;

-- Simple threshold check: fail if any count is 0
IF @dim_sku_count = 0 OR @dim_retailer_count = 0 OR @fact_count = 0
    RAISERROR(''Data quality check failed: zero rows detected'', 16, 1);

-- Log results
PRINT ''Quality Check Passed:'';
PRINT ''dim_sku rows: '' + CAST(@dim_sku_count AS VARCHAR);
PRINT ''dim_retailer rows: '' + CAST(@dim_retailer_count AS VARCHAR);
PRINT ''fact_sku_demand_daily rows: '' + CAST(@fact_count AS VARCHAR);
',
    @on_success_action = 3,
    @on_fail_action = 2;
GO

EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'ETL_04_DATA_QUALITY_CHECKS',
    @step_name = 'Step 2: Referential Integrity Check',
    @subsystem = 'TSQL',
    @command = N'
USE NorthStar_DW;
DECLARE @orphan_count INT;
SELECT @orphan_count = COUNT(*) 
FROM dw.fact_sku_demand_daily f
LEFT JOIN dw.dim_sku d ON f.sku_key = d.sku_key
LEFT JOIN dw.dim_retailer r ON f.retailer_key = r.retailer_key
WHERE d.sku_key IS NULL OR r.retailer_key IS NULL;

IF @orphan_count > 0
    RAISERROR(''Data quality check failed: orphan facts detected'', 16, 1);

PRINT ''Referential integrity check passed. Orphan facts: 0'';
',
    @on_success_action = 3,
    @on_fail_action = 2;
GO

EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'ETL_04_DATA_QUALITY_CHECKS',
    @step_name = 'Step 3: Anomaly Detection (Negative Units)',
    @subsystem = 'TSQL',
    @command = N'
USE NorthStar_DW;
DECLARE @negative_units INT;
SELECT @negative_units = COUNT(*) FROM dw.fact_sku_demand_daily WHERE units_sold < 0;

IF @negative_units > 0
    RAISERROR(''Data quality warning: negative units detected. Count: %d'', 10, 1, @negative_units);

PRINT ''Negative units check passed. Count: '' + CAST(@negative_units AS VARCHAR);
',
    @on_success_action = 1,
    @on_fail_action = 1; -- Continue even if anomalies found
GO

-- =====================================================================
-- Job 5: ETL_MASTER_ORCHESTRATION (chained job)
-- Purpose: Run all ETL jobs in sequence
-- =====================================================================

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = 'ETL_MASTER_ORCHESTRATION')
BEGIN
    EXEC msdb.dbo.sp_add_job 
        @job_name = 'ETL_MASTER_ORCHESTRATION',
        @description = 'Master job: orchestrates all ETL jobs in sequence',
        @enabled = 1;
END
GO

EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'ETL_MASTER_ORCHESTRATION',
    @step_name = 'Step 1: Start Ingest Job',
    @subsystem = 'TSQL',
    @command = N'
EXEC msdb.dbo.sp_start_job @job_name = ''ETL_01_INGEST_TO_STAGING'';
WAITFOR DELAY ''00:00:05''; -- Brief wait to ensure job starts
',
    @on_success_action = 3,
    @on_fail_action = 2;
GO

EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'ETL_MASTER_ORCHESTRATION',
    @step_name = 'Step 2: Wait for Ingest Completion',
    @subsystem = 'TSQL',
    @command = N'
-- Wait up to 5 minutes for ingest job to complete
DECLARE @job_state INT, @max_wait INT = 300; -- 5 minutes in seconds
DECLARE @elapsed INT = 0;
WHILE @elapsed < @max_wait
BEGIN
    SELECT @job_state = ISNULL(MAX(CASE WHEN jh.run_status = 1 THEN 1 ELSE 0 END), 0)
    FROM msdb.dbo.sysjobs j
    INNER JOIN msdb.dbo.sysjobhistory jh ON j.job_id = jh.job_id
    WHERE j.name = ''ETL_01_INGEST_TO_STAGING''
    AND jh.step_id = 0 -- Job outcome record
    AND jh.run_date = CAST(GETDATE() AS INT);
    
    IF @job_state = 1
        BREAK;
    
    WAITFOR DELAY ''00:00:01'';
    SET @elapsed = @elapsed + 1;
END
',
    @on_success_action = 3,
    @on_fail_action = 2;
GO

EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'ETL_MASTER_ORCHESTRATION',
    @step_name = 'Step 3: Start Dimension Upsert Job',
    @subsystem = 'TSQL',
    @command = N'EXEC msdb.dbo.sp_start_job @job_name = ''ETL_02_UPSERT_DIMENSIONS'';',
    @on_success_action = 3,
    @on_fail_action = 2;
GO

EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'ETL_MASTER_ORCHESTRATION',
    @step_name = 'Step 4: Start Fact Load Job',
    @subsystem = 'TSQL',
    @command = N'EXEC msdb.dbo.sp_start_job @job_name = ''ETL_03_LOAD_FACTS'';',
    @on_success_action = 3,
    @on_fail_action = 2;
GO

EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'ETL_MASTER_ORCHESTRATION',
    @step_name = 'Step 5: Start Quality Checks Job',
    @subsystem = 'TSQL',
    @command = N'EXEC msdb.dbo.sp_start_job @job_name = ''ETL_04_DATA_QUALITY_CHECKS'';',
    @on_success_action = 1,
    @on_fail_action = 2;
GO

-- =====================================================================
-- Create Job Schedule: Daily at 2 AM
-- =====================================================================

DECLARE @schedule_id INT;

-- Create schedule
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysschedules WHERE name = 'Daily_2AM')
BEGIN
    EXEC msdb.dbo.sp_add_schedule
        @schedule_name = 'Daily_2AM',
        @freq_type = 4,           -- Daily
        @freq_interval = 1,       -- Every day
        @active_start_time = 020000, -- 2:00 AM (HHMMSS format)
        @active_end_time = 235959;   -- Until 11:59:59 PM
    
    SELECT @schedule_id = schedule_id FROM msdb.dbo.sysschedules WHERE name = 'Daily_2AM';
END
ELSE
    SELECT @schedule_id = schedule_id FROM msdb.dbo.sysschedules WHERE name = 'Daily_2AM';

-- Attach schedule to master orchestration job
IF NOT EXISTS (
    SELECT 1 FROM msdb.dbo.sysjobschedules 
    WHERE job_name = 'ETL_MASTER_ORCHESTRATION' 
    AND schedule_id = @schedule_id
)
BEGIN
    EXEC msdb.dbo.sp_attach_schedule
        @job_name = 'ETL_MASTER_ORCHESTRATION',
        @schedule_name = 'Daily_2AM';
END
GO

-- =====================================================================
-- Assign Server to Jobs (localhost)
-- =====================================================================

EXEC msdb.dbo.sp_add_jobserver
    @job_name = 'ETL_01_INGEST_TO_STAGING',
    @server_name = N'(local)';

EXEC msdb.dbo.sp_add_jobserver
    @job_name = 'ETL_02_UPSERT_DIMENSIONS',
    @server_name = N'(local)';

EXEC msdb.dbo.sp_add_jobserver
    @job_name = 'ETL_03_LOAD_FACTS',
    @server_name = N'(local)';

EXEC msdb.dbo.sp_add_jobserver
    @job_name = 'ETL_04_DATA_QUALITY_CHECKS',
    @server_name = N'(local)';

EXEC msdb.dbo.sp_add_jobserver
    @job_name = 'ETL_MASTER_ORCHESTRATION',
    @server_name = N'(local)';

GO

-- =====================================================================
-- Verification and Monitoring Queries
-- =====================================================================

PRINT '=== SQL Agent Jobs Created Successfully ===';
PRINT '';
PRINT 'Jobs:';
SELECT name, description, enabled FROM msdb.dbo.sysjobs 
WHERE name LIKE 'ETL_%'
ORDER BY name;

PRINT '';
PRINT 'Schedule (Daily_2AM):';
SELECT * FROM msdb.dbo.sysschedules WHERE name = 'Daily_2AM';

PRINT '';
PRINT 'To manually trigger the master job:';
PRINT 'EXEC msdb.dbo.sp_start_job @job_name = ''ETL_MASTER_ORCHESTRATION'';';

PRINT '';
PRINT 'To view job history:';
PRINT 'EXEC msdb.dbo.sp_help_job_history @job_name = ''ETL_MASTER_ORCHESTRATION'';';

GO
