/*
  Mejoras de gestión documental (RF11):
  - Categoría documental de negocio
  - Fecha de vencimiento opcional
  - Procedimiento de eliminación
*/
USE FilasurProveedores;
GO

IF COL_LENGTH('dbo.DocumentoProveedor', 'CategoriaDocumento') IS NULL
BEGIN
    ALTER TABLE dbo.DocumentoProveedor
        ADD CategoriaDocumento NVARCHAR(80) NULL;
END
GO

IF COL_LENGTH('dbo.DocumentoProveedor', 'FechaVencimiento') IS NULL
BEGIN
    ALTER TABLE dbo.DocumentoProveedor
        ADD FechaVencimiento DATE NULL;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Documento_Registrar
    @IdProveedor         INT,
    @NombreArchivo       NVARCHAR(255),
    @TipoArchivo         NVARCHAR(20),
    @TamanoBytes         BIGINT = NULL,
    @RutaAlmacenamiento  NVARCHAR(500) = NULL,
    @CategoriaDocumento  NVARCHAR(80) = NULL,
    @FechaVencimiento    DATE = NULL,
    @IdDocumento         INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Proveedor WHERE IdProveedor = @IdProveedor)
    BEGIN
        RAISERROR(N'Proveedor no encontrado.', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.DocumentoProveedor (
        IdProveedor, NombreArchivo, TipoArchivo, TamanoBytes, RutaAlmacenamiento,
        CategoriaDocumento, FechaVencimiento
    )
    VALUES (
        @IdProveedor, @NombreArchivo, @TipoArchivo, @TamanoBytes, @RutaAlmacenamiento,
        NULLIF(LTRIM(RTRIM(@CategoriaDocumento)), N''), @FechaVencimiento
    );

    SET @IdDocumento = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Documento_Listar
    @IdProveedor INT = NULL,
    @Busqueda    NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        d.IdDocumento AS id,
        p.RazonSocial AS proveedor,
        d.IdProveedor AS idProveedor,
        d.NombreArchivo AS nombre,
        d.TipoArchivo AS tipo,
        d.CategoriaDocumento AS categoria,
        d.TamanoBytes AS tamanoBytes,
        d.RutaAlmacenamiento AS ruta,
        CONVERT(VARCHAR(10), d.FechaCarga, 103) AS fecha,
        CASE
            WHEN d.FechaVencimiento IS NULL THEN NULL
            ELSE CONVERT(VARCHAR(10), d.FechaVencimiento, 103)
        END AS fechaVencimiento
    FROM dbo.DocumentoProveedor d
    INNER JOIN dbo.Proveedor p ON p.IdProveedor = d.IdProveedor
    WHERE (@IdProveedor IS NULL OR d.IdProveedor = @IdProveedor)
      AND (
          @Busqueda IS NULL
          OR p.RazonSocial LIKE N'%' + @Busqueda + N'%'
          OR d.NombreArchivo LIKE N'%' + @Busqueda + N'%'
          OR ISNULL(d.CategoriaDocumento, N'') LIKE N'%' + @Busqueda + N'%'
      )
    ORDER BY d.FechaCarga DESC, d.IdDocumento DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Documento_Eliminar
    @IdDocumento INT,
    @RutaAlmacenamiento NVARCHAR(500) OUTPUT,
    @NombreArchivo NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        @RutaAlmacenamiento = RutaAlmacenamiento,
        @NombreArchivo = NombreArchivo
    FROM dbo.DocumentoProveedor
    WHERE IdDocumento = @IdDocumento;

    IF @NombreArchivo IS NULL
    BEGIN
        RAISERROR(N'Documento no encontrado.', 16, 1);
        RETURN;
    END

    DELETE FROM dbo.DocumentoProveedor
    WHERE IdDocumento = @IdDocumento;
END;
GO

PRINT N'Gestión documental actualizada (categoría, vencimiento, eliminar).';
GO

/* Asegura módulo Documentos para Compras (BD ya sembradas) */
IF NOT EXISTS (
    SELECT 1
    FROM dbo.RolModulo rm
    INNER JOIN dbo.Rol r ON r.IdRol = rm.IdRol
    WHERE r.Nombre = N'Compras' AND rm.Modulo = N'Documentos'
)
BEGIN
    INSERT INTO dbo.RolModulo (IdRol, Modulo)
    SELECT r.IdRol, N'Documentos'
    FROM dbo.Rol r
    WHERE r.Nombre = N'Compras';
END
GO
