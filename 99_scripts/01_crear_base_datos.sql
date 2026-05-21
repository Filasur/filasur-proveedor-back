/*
  FILASUR - Gestión de Proveedores
  Script 01: Creación de base de datos
  Motor: Microsoft SQL Server
*/
USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = N'FilasurProveedores')
BEGIN
    CREATE DATABASE FilasurProveedores
    COLLATE Latin1_General_CI_AI;
END
GO

USE FilasurProveedores;
GO

PRINT N'Base de datos FilasurProveedores lista.';
GO
