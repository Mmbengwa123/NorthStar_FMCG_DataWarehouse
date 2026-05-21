-- Creates the databases and base schemas for Staging and DataWarehouse
IF DB_ID('NorthStar_Staging') IS NULL
BEGIN
    CREATE DATABASE NorthStar_Staging;
END
GO
IF DB_ID('NorthStar_DW') IS NULL
BEGIN
    CREATE DATABASE NorthStar_DW;
END
GO
-- Create schemas inside DW
USE NorthStar_DW;
IF SCHEMA_ID('staging') IS NULL
    EXEC('CREATE SCHEMA staging');
IF SCHEMA_ID('ods') IS NULL
    EXEC('CREATE SCHEMA ods');
IF SCHEMA_ID('dw') IS NULL
    EXEC('CREATE SCHEMA dw');
GO
-- Notes: run these in SSMS as a user with CREATE DATABASE privileges.
