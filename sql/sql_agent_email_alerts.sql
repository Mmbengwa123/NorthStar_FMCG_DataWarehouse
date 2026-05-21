-- SQL Agent Job Email Notifications Setup
-- Configure email alerts for job failures and completion

USE msdb;
GO

-- =====================================================================
-- STEP 1: Create Database Mail Account (if not already done)
-- =====================================================================

/*
EXECUTE msdb.dbo.sysmail_add_account_sp
    @account_name = 'NorthStar_DW_Alerts',
    @description = 'Email account for NorthStar DW alerts',
    @email_address = 'noreply-northstar-dw@yourdomain.com',
    @display_name = 'NorthStar DW Alerts',
    @mailserver_name = 'smtp.yourdomain.com', -- Replace with your SMTP server
    @port = 587,
    @enable_ssl = 1,
    @username = 'your_smtp_username',
    @password = 'your_smtp_password';

-- Verify account was created
SELECT * FROM msdb.dbo.sysmail_account;
*/

GO

-- =====================================================================
-- STEP 2: Create Database Mail Profile (if not already done)
-- =====================================================================

/*
EXECUTE msdb.dbo.sysmail_add_profile_sp
    @profile_name = 'NorthStar_DW_Profile',
    @description = 'Profile for NorthStar DW notifications';

-- Add the account to the profile
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = 'NorthStar_DW_Profile',
    @account_name = 'NorthStar_DW_Alerts',
    @sequence_number = 1;

-- Grant profile permission to MSDB user
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
    @principal_name = 'public',
    @profile_name = 'NorthStar_DW_Profile',
    @is_default = 1;

-- Verify profile was created
SELECT * FROM msdb.dbo.sysmail_profile;
*/

GO

-- =====================================================================
-- STEP 3: Create Operator for Job Notifications
-- =====================================================================

-- Create an operator to receive email alerts
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysoperators WHERE name = 'DataWarehouse_Team')
BEGIN
    EXEC msdb.dbo.sp_add_operator
        @name = 'DataWarehouse_Team',
        @enabled = 1,
        @email_address = 'your-team@yourdomain.com'; -- Replace with actual email
END

GO

-- =====================================================================
-- STEP 4: Add Notifications to Jobs
-- =====================================================================

-- Add notification to ETL_01_INGEST_TO_STAGING (on failure)
EXEC msdb.dbo.sp_update_job
    @job_name = 'ETL_01_INGEST_TO_STAGING',
    @notify_level_eventlog = 2,           -- Log to event log on failure
    @notify_level_email = 2,              -- Email on failure
    @notify_email_operator_name = 'DataWarehouse_Team';

-- Add notification to ETL_02_UPSERT_DIMENSIONS (on failure)
EXEC msdb.dbo.sp_update_job
    @job_name = 'ETL_02_UPSERT_DIMENSIONS',
    @notify_level_email = 2,
    @notify_email_operator_name = 'DataWarehouse_Team';

-- Add notification to ETL_03_LOAD_FACTS (on failure)
EXEC msdb.dbo.sp_update_job
    @job_name = 'ETL_03_LOAD_FACTS',
    @notify_level_email = 2,
    @notify_email_operator_name = 'DataWarehouse_Team';

-- Add notification to ETL_04_DATA_QUALITY_CHECKS (on failure)
EXEC msdb.dbo.sp_update_job
    @job_name = 'ETL_04_DATA_QUALITY_CHECKS',
    @notify_level_email = 2,
    @notify_email_operator_name = 'DataWarehouse_Team';

-- Add notification to ETL_MASTER_ORCHESTRATION (on success and failure)
EXEC msdb.dbo.sp_update_job
    @job_name = 'ETL_MASTER_ORCHESTRATION',
    @notify_level_eventlog = 0,           -- Log to event log (all outcomes)
    @notify_level_email = 3,              -- Email on completion (success or failure)
    @notify_email_operator_name = 'DataWarehouse_Team';

GO

-- =====================================================================
-- STEP 5: Verify Notifications Are Configured
-- =====================================================================

SELECT 
    name AS job_name,
    notify_level_eventlog,
    notify_level_email,
    notify_email_operator_name
FROM msdb.dbo.sysjobs
WHERE name LIKE 'ETL_%'
ORDER BY name;

GO

-- =====================================================================
-- STEP 6: TEST EMAIL NOTIFICATION
-- =====================================================================

/*
-- Send a test email to verify Database Mail is working
EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'NorthStar_DW_Profile',
    @recipients = 'your-team@yourdomain.com',
    @subject = 'Test Email - NorthStar DW Alerts',
    @body = 'This is a test email. If you receive this, email notifications are working correctly.',
    @body_format = 'TEXT';

-- Check mail queue
SELECT * FROM msdb.dbo.sysmail_mailitems WHERE sent_status = 1 ORDER BY sent_date DESC;
*/

GO

-- =====================================================================
-- STEP 7: OPTIONAL - Create a Custom Alert Procedure
-- =====================================================================

/*
-- Stored procedure to send custom alerts on data quality issues
CREATE OR ALTER PROCEDURE dw.sp_send_dq_alert
    @issue_description NVARCHAR(MAX),
    @severity NVARCHAR(20) -- 'Warning', 'Critical'
AS
BEGIN
    DECLARE @subject NVARCHAR(255) = 'NorthStar DW Alert: ' + @severity;
    DECLARE @body NVARCHAR(MAX) = 
        'Data Quality Alert' + CHAR(13) + CHAR(10) +
        'Time: ' + CAST(GETDATE() AS NVARCHAR) + CHAR(13) + CHAR(10) +
        'Severity: ' + @severity + CHAR(13) + CHAR(10) +
        'Issue: ' + @issue_description + CHAR(13) + CHAR(10);
    
    EXEC msdb.dbo.sp_send_dbmail
        @profile_name = 'NorthStar_DW_Profile',
        @recipients = 'your-team@yourdomain.com',
        @subject = @subject,
        @body = @body;
END
*/

GO

-- =====================================================================
-- STEP 8: Configure Notification Levels Explanation
-- =====================================================================

/*
notify_level_eventlog:
  0 = Never
  1 = On success
  2 = On failure
  3 = Always (success or failure)

notify_level_email:
  0 = Never
  1 = On success
  2 = On failure
  3 = Always (success or failure)

notify_level_netsend:
  0 = Never
  1 = On success
  2 = On failure
  3 = Always

notify_level_page:
  0 = Never
  1 = On success
  2 = On failure
  3 = Always
*/

GO

PRINT '=== Email Notification Setup Guide ===';
PRINT '';
PRINT 'Steps completed:';
PRINT '1. Configure Database Mail (see commented section in STEP 1-2)';
PRINT '2. Create operator (STEP 3) - DONE';
PRINT '3. Add notifications to jobs (STEP 4) - DONE';
PRINT '';
PRINT 'Next steps:';
PRINT '1. Replace ''your-team@yourdomain.com'' with your actual email address';
PRINT '2. Configure SMTP settings in STEP 1 with your mail server details';
PRINT '3. Run the test email query in STEP 6 to verify';
PRINT '';
PRINT 'For production:';
PRINT '- Use a service account for SMTP authentication';
PRINT '- Store credentials securely (preferably in a vault)';
PRINT '- Test email delivery before relying on alerts';
