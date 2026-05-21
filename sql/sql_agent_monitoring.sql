-- SQL Agent Job Monitoring & Management Queries
-- Use these queries to monitor, troubleshoot, and manage ETL jobs

USE msdb;
GO

-- =====================================================================
-- 1. VIEW ALL ETL JOBS AND THEIR STATUS
-- =====================================================================

SELECT 
    j.name AS job_name,
    j.description,
    j.enabled,
    CASE 
        WHEN jh.run_date IS NULL THEN 'Never Run'
        WHEN jh.run_status = 0 THEN 'Failed'
        WHEN jh.run_status = 1 THEN 'Succeeded'
        WHEN jh.run_status = 2 THEN 'Retry'
        WHEN jh.run_status = 3 THEN 'Cancelled'
        ELSE 'Unknown'
    END AS last_run_status,
    CONVERT(DATETIME, CAST(jh.run_date AS CHAR(8)) + ' ' + CAST(jh.run_time AS CHAR(6))) AS last_run_time,
    DATEDIFF(SECOND, 
        CONVERT(DATETIME, CAST(jh.run_date AS CHAR(8)) + ' ' + CAST(jh.run_time AS CHAR(6))),
        GETDATE()) AS seconds_since_last_run
FROM dbo.sysjobs j
LEFT JOIN dbo.sysjobhistory jh ON j.job_id = jh.job_id 
    AND jh.step_id = 0 
    AND jh.run_date = (
        SELECT MAX(run_date) 
        FROM dbo.sysjobhistory 
        WHERE job_id = j.job_id 
        AND step_id = 0
    )
WHERE j.name LIKE 'ETL_%'
ORDER BY j.name;

GO

-- =====================================================================
-- 2. VIEW DETAILED JOB HISTORY (Last 20 runs)
-- =====================================================================

SELECT TOP 20
    j.name AS job_name,
    jh.step_id,
    jh.step_name,
    CASE 
        WHEN jh.run_status = 0 THEN 'Failed'
        WHEN jh.run_status = 1 THEN 'Succeeded'
        WHEN jh.run_status = 2 THEN 'Retry'
        WHEN jh.run_status = 3 THEN 'Cancelled'
        ELSE 'Unknown'
    END AS run_status,
    CONVERT(DATETIME, CAST(jh.run_date AS CHAR(8)) + ' ' + CAST(jh.run_time AS CHAR(6))) AS run_date_time,
    jh.duration AS duration_seconds,
    jh.message
FROM dbo.sysjobs j
INNER JOIN dbo.sysjobhistory jh ON j.job_id = jh.job_id
WHERE j.name LIKE 'ETL_%'
ORDER BY jh.run_date DESC, jh.run_time DESC;

GO

-- =====================================================================
-- 3. CHECK IF JOBS ARE CURRENTLY RUNNING
-- =====================================================================

SELECT 
    j.name AS job_name,
    s.session_id,
    s.login_name,
    s.status,
    s.last_batch,
    DATEDIFF(SECOND, s.last_batch, GETDATE()) AS seconds_running
FROM dbo.sysjobs j
INNER JOIN dbo.sysjobactivity ja ON j.job_id = ja.job_id
INNER JOIN sys.dm_exec_sessions s ON ja.session_id = s.session_id
WHERE ja.run_requested_date IS NOT NULL 
    AND ja.stop_execution_date IS NULL
    AND j.name LIKE 'ETL_%';

GO

-- =====================================================================
-- 4. MANUALLY TRIGGER MASTER JOB
-- =====================================================================

-- Uncomment to run the master orchestration job immediately
-- EXEC msdb.dbo.sp_start_job @job_name = 'ETL_MASTER_ORCHESTRATION';
-- PRINT 'ETL_MASTER_ORCHESTRATION job started.';

GO

-- =====================================================================
-- 5. DISABLE/ENABLE JOBS
-- =====================================================================

-- Disable a specific job (example: ingest job)
-- EXEC msdb.dbo.sp_update_job 
--     @job_name = 'ETL_01_INGEST_TO_STAGING',
--     @enabled = 0;

-- Enable a specific job
-- EXEC msdb.dbo.sp_update_job 
--     @job_name = 'ETL_01_INGEST_TO_STAGING',
--     @enabled = 1;

GO

-- =====================================================================
-- 6. DELETE A JOB
-- =====================================================================

-- Delete a job (example: if you need to recreate it)
-- EXEC msdb.dbo.sp_delete_job 
--     @job_name = 'ETL_01_INGEST_TO_STAGING',
--     @delete_unused_schedule = 0;

GO

-- =====================================================================
-- 7. MODIFY JOB SCHEDULE
-- =====================================================================

-- Change schedule to run at 3 AM instead of 2 AM
-- EXEC msdb.dbo.sp_update_schedule
--     @schedule_name = 'Daily_2AM',
--     @active_start_time = 030000; -- 3:00 AM

GO

-- =====================================================================
-- 8. JOB SUCCESS RATE & SUMMARY
-- =====================================================================

SELECT 
    j.name AS job_name,
    COUNT(CASE WHEN jh.run_status = 1 THEN 1 END) AS successful_runs,
    COUNT(CASE WHEN jh.run_status = 0 THEN 1 END) AS failed_runs,
    COUNT(*) AS total_runs,
    ROUND(
        CAST(COUNT(CASE WHEN jh.run_status = 1 THEN 1 END) AS FLOAT) / 
        CAST(COUNT(*) AS FLOAT) * 100, 
        2
    ) AS success_rate_percent
FROM dbo.sysjobs j
LEFT JOIN dbo.sysjobhistory jh ON j.job_id = jh.job_id AND jh.step_id = 0
WHERE j.name LIKE 'ETL_%'
GROUP BY j.name
ORDER BY j.name;

GO

-- =====================================================================
-- 9. VIEW JOB STEP DETAILS
-- =====================================================================

SELECT 
    j.name AS job_name,
    s.step_id,
    s.step_name,
    s.subsystem,
    SUBSTRING(s.command, 1, 100) AS command_snippet,
    s.on_success_action,
    s.on_fail_action
FROM dbo.sysjobs j
INNER JOIN dbo.sysjobsteps s ON j.job_id = s.job_id
WHERE j.name LIKE 'ETL_%'
ORDER BY j.name, s.step_id;

GO

-- =====================================================================
-- 10. VIEW ATTACHED SCHEDULES
-- =====================================================================

SELECT 
    j.name AS job_name,
    s.name AS schedule_name,
    CASE s.freq_type
        WHEN 1 THEN 'Once'
        WHEN 4 THEN 'Daily'
        WHEN 8 THEN 'Weekly'
        WHEN 16 THEN 'Monthly'
        WHEN 32 THEN 'Monthly (relative)'
        WHEN 64 THEN 'At startup'
        WHEN 128 THEN 'On idle'
        ELSE 'Unknown'
    END AS frequency,
    CONVERT(TIME, CAST(s.active_start_time AS VARCHAR(6))) AS start_time,
    s.enabled AS schedule_enabled
FROM dbo.sysjobs j
INNER JOIN dbo.sysjobschedules js ON j.job_id = js.job_id
INNER JOIN dbo.sysschedules s ON js.schedule_id = s.schedule_id
WHERE j.name LIKE 'ETL_%'
ORDER BY j.name, s.name;

GO

-- =====================================================================
-- 11. TROUBLESHOOTING: Last Failed Job Runs
-- =====================================================================

SELECT TOP 10
    j.name AS job_name,
    jh.step_name,
    CONVERT(DATETIME, CAST(jh.run_date AS CHAR(8)) + ' ' + CAST(jh.run_time AS CHAR(6))) AS run_date_time,
    jh.message AS error_message
FROM dbo.sysjobs j
INNER JOIN dbo.sysjobhistory jh ON j.job_id = jh.job_id
WHERE j.name LIKE 'ETL_%'
    AND jh.run_status = 0 -- Failed runs only
ORDER BY jh.run_date DESC, jh.run_time DESC;

GO

-- =====================================================================
-- 12. AVERAGE DURATION OF JOB STEPS
-- =====================================================================

SELECT 
    j.name AS job_name,
    jh.step_name,
    COUNT(*) AS run_count,
    AVG(jh.duration) AS avg_duration_seconds,
    MIN(jh.duration) AS min_duration_seconds,
    MAX(jh.duration) AS max_duration_seconds
FROM dbo.sysjobs j
INNER JOIN dbo.sysjobhistory jh ON j.job_id = jh.job_id
WHERE j.name LIKE 'ETL_%'
    AND jh.step_id > 0  -- Exclude overall job record
GROUP BY j.name, jh.step_name
ORDER BY j.name, jh.step_name;

GO

-- =====================================================================
-- 13. CREATE TABLE TO LOG ETL EXECUTION METADATA (Optional)
-- =====================================================================

-- Run in NorthStar_DW to create a logging table
/*
USE NorthStar_DW;

IF OBJECT_ID('dw.etl_execution_log', 'U') IS NOT NULL
    DROP TABLE dw.etl_execution_log;

CREATE TABLE dw.etl_execution_log (
    execution_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    job_name NVARCHAR(128),
    step_name NVARCHAR(128),
    execution_start_time DATETIME,
    execution_end_time DATETIME,
    duration_seconds INT,
    row_count INT,
    status NVARCHAR(20), -- 'Success', 'Failed', 'Warning'
    error_message NVARCHAR(MAX),
    created_date DATETIME DEFAULT GETDATE()
);

CREATE INDEX idx_job_name ON dw.etl_execution_log(job_name);
CREATE INDEX idx_execution_date ON dw.etl_execution_log(execution_start_time);
*/

GO

-- =====================================================================
-- 14. SAMPLE: INSERT INTO ETL LOGGING TABLE
-- =====================================================================

/*
-- Example: Insert into logging table from a job step
INSERT INTO NorthStar_DW.dw.etl_execution_log (job_name, step_name, execution_start_time, row_count, status)
VALUES ('ETL_01_INGEST_TO_STAGING', 'Load SKU Data', GETDATE(), @@ROWCOUNT, 'Success');
*/

GO

PRINT '=== SQL Agent Job Monitoring Setup Complete ===';
PRINT 'Use the queries above to monitor ETL jobs and troubleshoot issues.';
