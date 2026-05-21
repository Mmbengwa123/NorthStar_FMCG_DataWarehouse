# SQL Server Agent Job Orchestration Guide

## Overview

This guide explains the SQL Agent job setup for the NorthStar FMCG Data Warehouse ETL pipeline. The jobs automate the complete ETL process from ingestion through quality validation.

## Prerequisites

- SQL Server Agent service must be **running** (check Services → SQL Server Agent)
- You must have **sysadmin** role permissions to create jobs
- Specify correct file paths for BULK INSERT (landing zone location)
- Database Mail configured (optional, but required for email alerts)

## Job Architecture

The orchestration uses **5 jobs** with a master job that chains them in sequence:

```
ETL_MASTER_ORCHESTRATION (daily at 2 AM)
    ├── ETL_01_INGEST_TO_STAGING
    │   └── Clears staging tables
    │   └── Loads CSVs (dim_skus, dim_retailers, fact_sku_demand_daily)
    │   └── Logs row counts
    │
    ├── ETL_02_UPSERT_DIMENSIONS
    │   └── MERGE into dim_sku
    │   └── MERGE into dim_retailer
    │
    ├── ETL_03_LOAD_FACTS
    │   └── Loads fact_sku_demand_daily with FK validation
    │
    └── ETL_04_DATA_QUALITY_CHECKS
        └── Row count validation
        └── Referential integrity checks
        └── Anomaly detection (negative units, price mismatches)
```

## Setup Instructions

### 1. Review and Customize Job Configuration

Open `sql/sql_agent_jobs.sql` and update:

- **CSV file paths** (line ~80): Replace `C:\DataLanding\` with your actual landing zone path
- **Schedule time** (line ~180): Change from 2 AM to your preferred time
- **Server name** (line ~200): Confirm `(local)` is correct; use server name if remote

### 2. Create Jobs in SQL Server

In **SQL Server Management Studio (SSMS)**:

```sql
-- Connect to your SQL Server instance
-- Open and execute: sql/sql_agent_jobs.sql
:r sql/sql_agent_jobs.sql
```

Expected output:
```
=== SQL Agent Jobs Created Successfully ===

Jobs:
ETL_01_INGEST_TO_STAGING
ETL_02_UPSERT_DIMENSIONS
ETL_03_LOAD_FACTS
ETL_04_DATA_QUALITY_CHECKS
ETL_MASTER_ORCHESTRATION
```

### 3. Verify Job Creation

```sql
-- View all ETL jobs
SELECT name, description, enabled 
FROM msdb.dbo.sysjobs 
WHERE name LIKE 'ETL_%'
ORDER BY name;

-- View attached schedule
SELECT j.name, s.name as schedule_name, s.active_start_time
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobschedules js ON j.job_id = js.job_id
INNER JOIN msdb.dbo.sysschedules s ON js.schedule_id = s.schedule_id
WHERE j.name = 'ETL_MASTER_ORCHESTRATION';
```

### 4. (Optional) Configure Email Alerts

To receive email notifications on job failures:

```sql
-- Execute: sql/sql_agent_email_alerts.sql
:r sql/sql_agent_email_alerts.sql
```

Then uncomment and customize:
- SMTP server configuration (line ~15)
- Operator email address (line ~45)
- Database Mail profile setup

Test the email:
```sql
EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'NorthStar_DW_Profile',
    @recipients = 'your-email@company.com',
    @subject = 'Test Email',
    @body = 'This is a test.';
```

## Running Jobs

### Automatic Execution (Scheduled)

- Master job runs daily at **2 AM** (configurable)
- All child jobs execute in sequence
- Each job waits for the previous to complete

### Manual Execution

```sql
-- Trigger the master job immediately
EXEC msdb.dbo.sp_start_job @job_name = 'ETL_MASTER_ORCHESTRATION';

-- Or trigger individual jobs
EXEC msdb.dbo.sp_start_job @job_name = 'ETL_01_INGEST_TO_STAGING';
```

### Wait for Completion

```sql
-- Check if jobs are running
SELECT * FROM msdb.dbo.sysjobactivity 
WHERE job_name LIKE 'ETL_%' 
AND run_requested_date IS NOT NULL 
AND stop_execution_date IS NULL;

-- Check job history
EXEC msdb.dbo.sp_help_job_history @job_name = 'ETL_MASTER_ORCHESTRATION';
```

## Monitoring

### Use Monitoring Queries

Execute `sql/sql_agent_monitoring.sql` to get:

1. **Current Job Status** - Shows last run result and time elapsed
2. **Job History** - Last 20 runs with detailed step info
3. **Running Jobs** - Currently executing jobs
4. **Success Rate** - Success/failure counts and percentages
5. **Job Duration** - Average, min, max execution times
6. **Failed Runs** - Latest failures with error messages

### Query Examples

```sql
-- View last run status for all ETL jobs
SELECT 
    j.name AS job_name,
    jh.run_status,
    CONVERT(DATETIME, CAST(jh.run_date AS CHAR(8)) + ' ' + CAST(jh.run_time AS CHAR(6))) AS last_run_time
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobhistory jh ON j.job_id = jh.job_id 
    AND jh.step_id = 0
    AND jh.run_date = (SELECT MAX(run_date) FROM msdb.dbo.sysjobhistory WHERE job_id = j.job_id AND step_id = 0)
WHERE j.name LIKE 'ETL_%'
ORDER BY j.name;

-- Check if any job failed in the last 24 hours
SELECT TOP 10
    j.name AS job_name,
    jh.step_name,
    jh.message AS error_message,
    CONVERT(DATETIME, CAST(jh.run_date AS CHAR(8)) + ' ' + CAST(jh.run_time AS CHAR(6))) AS run_time
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobhistory jh ON j.job_id = jh.job_id
WHERE j.name LIKE 'ETL_%'
    AND jh.run_status = 0 -- Failed
    AND CAST(jh.run_date AS DATE) >= DATEADD(DAY, -1, CAST(GETDATE() AS DATE))
ORDER BY jh.run_date DESC, jh.run_time DESC;
```

## Troubleshooting

### Job Failed to Start

**Problem**: "Error: SQL Server Agent is not currently running"

**Solution**: Start SQL Server Agent service
```powershell
# In PowerShell as Administrator
Start-Service -Name SQLSERVERAGENT
```

### File Path Error

**Problem**: "Cannot bulk load. File not found: C:\DataLanding\dim_skus.csv"

**Solution**: 
- Verify CSV files exist in the specified path
- Use a UNC path for network shares: `\\server\share\file.csv`
- Ensure SQL Server service account has read permissions on the folder

### Jobs Running Slowly

**Problem**: Jobs taking longer than expected

**Solutions**:
- Check current SQL Server workload: `SELECT * FROM sys.dm_exec_requests`
- Verify staging data size: `SELECT SUM(rows) FROM sysindexes WHERE object_id = OBJECT_ID('staging.stg_fact_sku_demand_daily')`
- Review index fragmentation: `SELECT * FROM sys.dm_db_index_physical_stats(DB_ID('NorthStar_DW'), NULL, NULL, NULL, 'LIMITED')`

### Email Alerts Not Received

**Problem**: Job failures aren't sending emails

**Solutions**:
1. Verify Database Mail is enabled: `SELECT * FROM msdb.dbo.sysmail_account`
2. Check mail queue: `SELECT * FROM msdb.dbo.sysmail_mailitems WHERE sent_status = 1`
3. Verify operator email: `SELECT * FROM msdb.dbo.sysoperators`
4. Test manually: See section 4 above

## Maintenance

### Backup Job Configuration

```sql
-- Export job definitions
EXEC msdb.dbo.sp_help_job @job_name = 'ETL_MASTER_ORCHESTRATION';
```

### Modify Schedule

```sql
-- Change to 3 AM daily
EXEC msdb.dbo.sp_update_schedule
    @schedule_name = 'Daily_2AM',
    @active_start_time = 030000; -- HHMMSS format
```

### Disable/Enable Jobs

```sql
-- Temporarily disable a job
EXEC msdb.dbo.sp_update_job 
    @job_name = 'ETL_01_INGEST_TO_STAGING',
    @enabled = 0;

-- Re-enable
EXEC msdb.dbo.sp_update_job 
    @job_name = 'ETL_01_INGEST_TO_STAGING',
    @enabled = 1;
```

### Clean Up Old History

```sql
-- Delete job history older than 30 days
EXEC msdb.dbo.sp_purge_jobhistory 
    @oldest_date = '2026-04-21'; -- YYYY-MM-DD format
```

## Best Practices

1. **Always backup job definitions** before making changes
2. **Test jobs manually first** before relying on schedule
3. **Monitor email alerts** to catch failures early
4. **Review data quality checks output** after each run
5. **Keep CSV landing zone organized** with date-stamped files
6. **Document any customizations** in version control
7. **Implement incremental loading** to avoid full reloads (future enhancement)
8. **Archive old staging data** to prevent disk space issues

**Last Updated**: May 21, 2026
**Version**: 1.0
