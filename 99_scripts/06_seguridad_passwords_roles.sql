/* Ejecutar sobre una base existente antes de publicar la versión con seguridad reforzada. */

IF COL_LENGTH('dbo.Usuario', 'IntentosFallidos') IS NULL
BEGIN
    ALTER TABLE dbo.Usuario
    ADD IntentosFallidos INT NOT NULL CONSTRAINT DF_Usuario_IntentosFallidos DEFAULT (0);
END;
GO

IF COL_LENGTH('dbo.Usuario', 'BloqueadoHasta') IS NULL
BEGIN
    ALTER TABLE dbo.Usuario
    ADD BloqueadoHasta DATETIME2(0) NULL;
END;
GO

IF COL_LENGTH('dbo.Usuario', 'DebeCambiarPassword') IS NULL
BEGIN
    ALTER TABLE dbo.Usuario
    ADD DebeCambiarPassword BIT NOT NULL CONSTRAINT DF_Usuario_DebeCambiarPassword DEFAULT (0);
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rol_ActualizarModulos
    @IdRol INT,
    @ModulosJson NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.RolModulo WHERE IdRol = @IdRol;

    INSERT INTO dbo.RolModulo (IdRol, Modulo)
    SELECT @IdRol, LTRIM(RTRIM(value))
    FROM OPENJSON(@ModulosJson)
    WHERE LTRIM(RTRIM(value)) <> N'';
END;
GO
