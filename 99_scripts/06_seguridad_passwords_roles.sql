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

CREATE OR ALTER PROCEDURE dbo.sp_Usuario_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        u.IdUsuario AS id,
        u.NombreCompleto AS nombre,
        u.Email AS email,
        r.Nombre AS rol,
        CASE WHEN u.IdEstadoUsuario = 1 THEN N'Activo' ELSE N'Inactivo' END AS estado,
        ISNULL(u.IntentosFallidos, 0) AS intentosFallidos,
        u.BloqueadoHasta AS bloqueadoHasta,
        CASE WHEN u.BloqueadoHasta IS NOT NULL AND u.BloqueadoHasta > SYSUTCDATETIME()
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
        END AS bloqueado
    FROM dbo.Usuario u
    INNER JOIN dbo.Rol r ON r.IdRol = u.IdRol
    ORDER BY u.NombreCompleto;
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
