/*
  ============================================================
  FILASUR - Despliegue de producción (script único)
  ============================================================
  Ejecutar una sola vez en SQL Server (SSMS / sqlcmd).

  Incluye: BD + tablas + funciones + procedimientos + semilla
  + bitácoras de auditoría (bit_*).

  Después (opcional): datos_simulados_julio2026.sql
  ============================================================
*/


/* ========== INICIO: 01_crear_base_datos.sql ========== */
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

/* ========== FIN: 01_crear_base_datos.sql ========== */

/* ========== INICIO: 02_tablas.sql ========== */
/*
  FILASUR - Script 02: Tablas, Primary Keys, Foreign Keys
*/
USE FilasurProveedores;
GO

/* ===================== CATÁLOGOS ===================== */

CREATE TABLE dbo.CatEstadoProveedor (
    IdEstadoProveedor   TINYINT         NOT NULL,
    Codigo              NVARCHAR(30)    NOT NULL,
    Nombre              NVARCHAR(80)    NOT NULL,
    Activo              BIT             NOT NULL CONSTRAINT DF_CatEstadoProveedor_Activo DEFAULT (1),
    CONSTRAINT PK_CatEstadoProveedor PRIMARY KEY CLUSTERED (IdEstadoProveedor),
    CONSTRAINT UQ_CatEstadoProveedor_Codigo UNIQUE (Codigo)
);
GO

CREATE TABLE dbo.CatEstadoEvaluacion (
    IdEstadoEvaluacion  TINYINT         NOT NULL,
    Codigo              NVARCHAR(30)    NOT NULL,
    Nombre              NVARCHAR(80)    NOT NULL,
    Activo              BIT             NOT NULL CONSTRAINT DF_CatEstadoEvaluacion_Activo DEFAULT (1),
    CONSTRAINT PK_CatEstadoEvaluacion PRIMARY KEY CLUSTERED (IdEstadoEvaluacion),
    CONSTRAINT UQ_CatEstadoEvaluacion_Codigo UNIQUE (Codigo)
);
GO

CREATE TABLE dbo.CatClasificacionProveedor (
    IdClasificacion     CHAR(1)         NOT NULL,
    Nombre              NVARCHAR(40)    NOT NULL,
    PuntajeMinimo       DECIMAL(4, 2)   NOT NULL,
    CONSTRAINT PK_CatClasificacionProveedor PRIMARY KEY CLUSTERED (IdClasificacion),
    CONSTRAINT CK_CatClasificacionProveedor_Id CHECK (IdClasificacion IN ('A', 'B', 'C'))
);
GO

CREATE TABLE dbo.CatTipoProveedor (
    IdTipoProveedor     TINYINT         NOT NULL IDENTITY(1, 1),
    Nombre              NVARCHAR(50)    NOT NULL,
    CONSTRAINT PK_CatTipoProveedor PRIMARY KEY CLUSTERED (IdTipoProveedor),
    CONSTRAINT UQ_CatTipoProveedor_Nombre UNIQUE (Nombre)
);
GO

/* ===================== SEGURIDAD ===================== */

CREATE TABLE dbo.Rol (
    IdRol               INT             NOT NULL IDENTITY(1, 1),
    Nombre              NVARCHAR(50)    NOT NULL,
    Descripcion         NVARCHAR(255)   NULL,
    Activo              BIT             NOT NULL CONSTRAINT DF_Rol_Activo DEFAULT (1),
    CONSTRAINT PK_Rol PRIMARY KEY CLUSTERED (IdRol),
    CONSTRAINT UQ_Rol_Nombre UNIQUE (Nombre)
);
GO

CREATE TABLE dbo.RolModulo (
    IdRolModulo         INT             NOT NULL IDENTITY(1, 1),
    IdRol               INT             NOT NULL,
    Modulo              NVARCHAR(80)    NOT NULL,
    CONSTRAINT PK_RolModulo PRIMARY KEY CLUSTERED (IdRolModulo),
    CONSTRAINT FK_RolModulo_Rol FOREIGN KEY (IdRol) REFERENCES dbo.Rol (IdRol),
    CONSTRAINT UQ_RolModulo_Rol_Modulo UNIQUE (IdRol, Modulo)
);
GO

CREATE TABLE dbo.Usuario (
    IdUsuario           INT             NOT NULL IDENTITY(1, 1),
    IdRol               INT             NOT NULL,
    NombreCompleto      NVARCHAR(120)   NOT NULL,
    Email               NVARCHAR(120)   NOT NULL,
    PasswordHash        NVARCHAR(256)   NOT NULL,
    Iniciales           NVARCHAR(5)     NULL,
    IdEstadoUsuario     TINYINT         NOT NULL CONSTRAINT DF_Usuario_Estado DEFAULT (1),
    IntentosFallidos    INT             NOT NULL CONSTRAINT DF_Usuario_IntentosFallidos DEFAULT (0),
    BloqueadoHasta      DATETIME2(0)    NULL,
    DebeCambiarPassword BIT             NOT NULL CONSTRAINT DF_Usuario_DebeCambiarPassword DEFAULT (0),
    FechaCreacion       DATETIME2(0)    NOT NULL CONSTRAINT DF_Usuario_FechaCreacion DEFAULT (SYSUTCDATETIME()),
    FechaModificacion   DATETIME2(0)    NULL,
    CONSTRAINT PK_Usuario PRIMARY KEY CLUSTERED (IdUsuario),
    CONSTRAINT FK_Usuario_Rol FOREIGN KEY (IdRol) REFERENCES dbo.Rol (IdRol),
    CONSTRAINT UQ_Usuario_Email UNIQUE (Email),
    CONSTRAINT CK_Usuario_Estado CHECK (IdEstadoUsuario IN (0, 1))
);
GO

/* ===================== PROVEEDORES Y CATÁLOGOS ===================== */

CREATE TABLE dbo.UnidadMedida (
    IdUnidad            INT             NOT NULL IDENTITY(1, 1),
    Codigo              NVARCHAR(20)    NOT NULL,
    Nombre              NVARCHAR(80)    NOT NULL,
    Descripcion         NVARCHAR(255)   NULL,
    Activo              BIT             NOT NULL CONSTRAINT DF_UnidadMedida_Activo DEFAULT (1),
    CONSTRAINT PK_UnidadMedida PRIMARY KEY CLUSTERED (IdUnidad),
    CONSTRAINT UQ_UnidadMedida_Codigo UNIQUE (Codigo)
);
GO

CREATE TABLE dbo.Producto (
    IdProducto          INT             NOT NULL IDENTITY(1, 1),
    Codigo              NVARCHAR(40)    NOT NULL,
    Nombre              NVARCHAR(150)   NOT NULL,
    Categoria           NVARCHAR(80)    NULL,
    IdUnidad            INT             NOT NULL,
    Activo              BIT             NOT NULL CONSTRAINT DF_Producto_Activo DEFAULT (1),
    CONSTRAINT PK_Producto PRIMARY KEY CLUSTERED (IdProducto),
    CONSTRAINT FK_Producto_UnidadMedida FOREIGN KEY (IdUnidad) REFERENCES dbo.UnidadMedida (IdUnidad),
    CONSTRAINT UQ_Producto_Codigo UNIQUE (Codigo)
);
GO

CREATE TABLE dbo.Proveedor (
    IdProveedor         INT             NOT NULL IDENTITY(1, 1),
    Ruc                 CHAR(11)        NOT NULL,
    RazonSocial         NVARCHAR(200)   NOT NULL,
    IdTipoProveedor     TINYINT         NOT NULL,
    Rubro               NVARCHAR(100)   NULL,
    Contacto            NVARCHAR(120)   NULL,
    Telefono            NVARCHAR(30)    NULL,
    Correo              NVARCHAR(120)   NULL,
    Direccion           NVARCHAR(255)   NULL,
    IdEstadoProveedor   TINYINT         NOT NULL,
    IdClasificacion     CHAR(1)         NULL,
    PuntajePromedio     DECIMAL(4, 2)   NULL,
    TotalEvaluaciones   INT             NOT NULL CONSTRAINT DF_Proveedor_TotalEval DEFAULT (0),
    FechaCreacion       DATETIME2(0)    NOT NULL CONSTRAINT DF_Proveedor_FechaCreacion DEFAULT (SYSUTCDATETIME()),
    FechaModificacion   DATETIME2(0)    NULL,
    CONSTRAINT PK_Proveedor PRIMARY KEY CLUSTERED (IdProveedor),
    CONSTRAINT FK_Proveedor_Tipo FOREIGN KEY (IdTipoProveedor) REFERENCES dbo.CatTipoProveedor (IdTipoProveedor),
    CONSTRAINT FK_Proveedor_Estado FOREIGN KEY (IdEstadoProveedor) REFERENCES dbo.CatEstadoProveedor (IdEstadoProveedor),
    CONSTRAINT FK_Proveedor_Clasificacion FOREIGN KEY (IdClasificacion) REFERENCES dbo.CatClasificacionProveedor (IdClasificacion),
    CONSTRAINT UQ_Proveedor_Ruc UNIQUE (Ruc),
    CONSTRAINT CK_Proveedor_Ruc CHECK (Ruc NOT LIKE '%[^0-9]%')
);
GO

CREATE TABLE dbo.CriterioEvaluacion (
    IdCriterio          INT             NOT NULL IDENTITY(1, 1),
    Nombre              NVARCHAR(120)   NOT NULL,
    Area                NVARCHAR(80)    NOT NULL,
    Peso                DECIMAL(5, 2)   NOT NULL,
    Activo              BIT             NOT NULL CONSTRAINT DF_Criterio_Activo DEFAULT (1),
    FechaModificacion   DATETIME2(0)    NULL,
    CONSTRAINT PK_CriterioEvaluacion PRIMARY KEY CLUSTERED (IdCriterio),
    CONSTRAINT CK_Criterio_Peso CHECK (Peso > 0 AND Peso <= 100)
);
GO

CREATE TABLE dbo.DocumentoProveedor (
    IdDocumento         INT             NOT NULL IDENTITY(1, 1),
    IdProveedor         INT             NOT NULL,
    NombreArchivo       NVARCHAR(255)   NOT NULL,
    TipoArchivo         NVARCHAR(20)    NOT NULL,
    TamanoBytes         BIGINT          NULL,
    RutaAlmacenamiento  NVARCHAR(500)   NULL,
    CategoriaDocumento  NVARCHAR(80)    NULL,
    FechaCarga          DATE            NOT NULL CONSTRAINT DF_Documento_FechaCarga DEFAULT (CAST(SYSUTCDATETIME() AS DATE)),
    FechaVencimiento    DATE            NULL,
    CONSTRAINT PK_DocumentoProveedor PRIMARY KEY CLUSTERED (IdDocumento),
    CONSTRAINT FK_DocumentoProveedor_Proveedor FOREIGN KEY (IdProveedor) REFERENCES dbo.Proveedor (IdProveedor)
);
GO

/* ===================== EVALUACIONES ===================== */

CREATE TABLE dbo.Evaluacion (
    IdEvaluacion            INT             NOT NULL IDENTITY(1, 1),
    IdProveedor             INT             NOT NULL,
    IdProducto              INT             NULL,
    Periodo                 NVARCHAR(20)    NOT NULL,
    OrdenCompra             NVARCHAR(30)    NULL,
    FechaLimite             DATE            NULL,
    FechaEvaluacion         DATE            NULL,
    PuntajeFinal            DECIMAL(4, 2)   NULL,
    IdEstadoEvaluacion      TINYINT         NOT NULL,
    NivelResultado          NVARCHAR(30)    NULL,
    ResultadoTexto          NVARCHAR(500)   NULL,
    Observaciones           NVARCHAR(MAX)   NULL,
    IdUsuarioCreador        INT             NOT NULL,
    FechaCreacion           DATETIME2(0)    NOT NULL CONSTRAINT DF_Evaluacion_FechaCreacion DEFAULT (SYSUTCDATETIME()),
    FechaModificacion       DATETIME2(0)    NULL,
    CONSTRAINT PK_Evaluacion PRIMARY KEY CLUSTERED (IdEvaluacion),
    CONSTRAINT FK_Evaluacion_Proveedor FOREIGN KEY (IdProveedor) REFERENCES dbo.Proveedor (IdProveedor),
    CONSTRAINT FK_Evaluacion_Producto FOREIGN KEY (IdProducto) REFERENCES dbo.Producto (IdProducto),
    CONSTRAINT FK_Evaluacion_Estado FOREIGN KEY (IdEstadoEvaluacion) REFERENCES dbo.CatEstadoEvaluacion (IdEstadoEvaluacion),
    CONSTRAINT FK_Evaluacion_Usuario FOREIGN KEY (IdUsuarioCreador) REFERENCES dbo.Usuario (IdUsuario),
    CONSTRAINT CK_Evaluacion_PuntajeFinal CHECK (PuntajeFinal IS NULL OR (PuntajeFinal >= 0 AND PuntajeFinal <= 5))
);
GO

CREATE TABLE dbo.EvaluacionCriterio (
    IdEvaluacionCriterio    INT             NOT NULL IDENTITY(1, 1),
    IdEvaluacion            INT             NOT NULL,
    IdCriterio              INT             NOT NULL,
    Puntaje                 DECIMAL(5, 2)   NOT NULL,
    PuntajePonderado        DECIMAL(6, 3)   NULL,
    CONSTRAINT PK_EvaluacionCriterio PRIMARY KEY CLUSTERED (IdEvaluacionCriterio),
    CONSTRAINT FK_EvaluacionCriterio_Evaluacion FOREIGN KEY (IdEvaluacion) REFERENCES dbo.Evaluacion (IdEvaluacion) ON DELETE CASCADE,
    CONSTRAINT FK_EvaluacionCriterio_Criterio FOREIGN KEY (IdCriterio) REFERENCES dbo.CriterioEvaluacion (IdCriterio),
    CONSTRAINT UQ_EvaluacionCriterio_Eval_Crit UNIQUE (IdEvaluacion, IdCriterio),
    CONSTRAINT CK_EvaluacionCriterio_Puntaje CHECK (Puntaje >= 0 AND Puntaje <= 100)
);
GO

CREATE TABLE dbo.EvaluacionArea (
    IdEvaluacionArea        INT             NOT NULL IDENTITY(1, 1),
    IdEvaluacion            INT             NOT NULL,
    Area                    NVARCHAR(80)    NOT NULL,
    IdUsuarioEvaluador      INT             NULL,
    Puntaje                 DECIMAL(4, 2)   NOT NULL,
    Peso                    DECIMAL(5, 2)   NOT NULL,
    PuntajePonderado        DECIMAL(6, 3)   NULL,
    Observaciones           NVARCHAR(500)   NULL,
    CONSTRAINT PK_EvaluacionArea PRIMARY KEY CLUSTERED (IdEvaluacionArea),
    CONSTRAINT FK_EvaluacionArea_Evaluacion FOREIGN KEY (IdEvaluacion) REFERENCES dbo.Evaluacion (IdEvaluacion) ON DELETE CASCADE,
    CONSTRAINT FK_EvaluacionArea_Usuario FOREIGN KEY (IdUsuarioEvaluador) REFERENCES dbo.Usuario (IdUsuario),
    CONSTRAINT CK_EvaluacionArea_Puntaje CHECK (Puntaje >= 0 AND Puntaje <= 5)
);
GO

/* ===================== SISTEMA ===================== */

CREATE TABLE dbo.ConfiguracionSistema (
    IdConfig                    INT             NOT NULL CONSTRAINT DF_Config_Id DEFAULT (1),
    UmbralAprobacion            DECIMAL(4, 2)   NOT NULL,
    UmbralObservado             DECIMAL(4, 2)   NOT NULL,
    DiasAlertaVencimiento       INT             NOT NULL,
    NotificacionesEmail         BIT             NOT NULL,
    IntegracionErp              NVARCHAR(80)    NULL,
    FechaModificacion           DATETIME2(0)    NULL,
    IdUsuarioModificador        INT             NULL,
    CONSTRAINT PK_ConfiguracionSistema PRIMARY KEY CLUSTERED (IdConfig),
    CONSTRAINT CK_ConfiguracionSistema_SingleRow CHECK (IdConfig = 1),
    CONSTRAINT FK_Configuracion_Usuario FOREIGN KEY (IdUsuarioModificador) REFERENCES dbo.Usuario (IdUsuario)
);
GO

CREATE TABLE dbo.Bitacora (
    IdBitacora          BIGINT          NOT NULL IDENTITY(1, 1),
    IdUsuario           INT             NULL,
    Modulo              NVARCHAR(60)    NOT NULL,
    Accion              NVARCHAR(120)   NOT NULL,
    Detalle             NVARCHAR(500)   NULL,
    FechaHora           DATETIME2(0)    NOT NULL CONSTRAINT DF_Bitacora_Fecha DEFAULT (SYSUTCDATETIME()),
    DireccionIp         NVARCHAR(45)    NULL,
    CONSTRAINT PK_Bitacora PRIMARY KEY CLUSTERED (IdBitacora),
    CONSTRAINT FK_Bitacora_Usuario FOREIGN KEY (IdUsuario) REFERENCES dbo.Usuario (IdUsuario)
);
GO

/* ===================== ÍNDICES ===================== */

CREATE NONCLUSTERED INDEX IX_Proveedor_RazonSocial ON dbo.Proveedor (RazonSocial);
CREATE NONCLUSTERED INDEX IX_Evaluacion_Proveedor ON dbo.Evaluacion (IdProveedor);
CREATE NONCLUSTERED INDEX IX_Evaluacion_Estado ON dbo.Evaluacion (IdEstadoEvaluacion);
CREATE NONCLUSTERED INDEX IX_Evaluacion_FechaLimite ON dbo.Evaluacion (FechaLimite) WHERE FechaLimite IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_Bitacora_FechaHora ON dbo.Bitacora (FechaHora DESC);
CREATE NONCLUSTERED INDEX IX_DocumentoProveedor_Proveedor ON dbo.DocumentoProveedor (IdProveedor);
GO

PRINT N'Tablas, PK y FK creadas correctamente.';
GO

/* ========== FIN: 02_tablas.sql ========== */

/* ========== INICIO: 03_funciones.sql ========== */
/*
  FILASUR - Script 03: Funciones
*/
USE FilasurProveedores;
GO

/* Convierte puntaje porcentual (0-100) a escala 0-5 */
CREATE OR ALTER FUNCTION dbo.fn_PorcentajeAEscala5 (@PuntajePorcentaje DECIMAL(5, 2))
RETURNS DECIMAL(4, 2)
AS
BEGIN
    IF @PuntajePorcentaje IS NULL RETURN NULL;
    RETURN ROUND(@PuntajePorcentaje / 20.0, 2);
END;
GO

/* Clasificación A/B/C según puntaje 0-5 y umbrales de configuración */
CREATE OR ALTER FUNCTION dbo.fn_ClasificacionPorPuntaje (@Puntaje DECIMAL(4, 2))
RETURNS CHAR(1)
AS
BEGIN
    DECLARE @UmbralA DECIMAL(4, 2) = 4.0;
    DECLARE @UmbralB DECIMAL(4, 2) = 3.5;

    SELECT TOP (1)
        @UmbralA = ISNULL(UmbralAprobacion, 3.5),
        @UmbralB = ISNULL(UmbralObservado, 3.0)
    FROM dbo.ConfiguracionSistema
    WHERE IdConfig = 1;

    IF @Puntaje IS NULL RETURN NULL;
    IF @Puntaje >= @UmbralA + 0.5 RETURN 'A';
    IF @Puntaje >= @UmbralA RETURN 'A';
    IF @Puntaje >= @UmbralB RETURN 'B';
    RETURN 'C';
END;
GO

/* Nivel de resultado: APROBADO, OBSERVADO, RECHAZADO */
CREATE OR ALTER FUNCTION dbo.fn_NivelResultadoEvaluacion (@PuntajeFinal DECIMAL(4, 2))
RETURNS NVARCHAR(30)
AS
BEGIN
    DECLARE @Aprob DECIMAL(4, 2);
    DECLARE @Obs DECIMAL(4, 2);

    SELECT TOP (1)
        @Aprob = UmbralAprobacion,
        @Obs = UmbralObservado
    FROM dbo.ConfiguracionSistema
    WHERE IdConfig = 1;

    IF @PuntajeFinal IS NULL RETURN NULL;
    IF @PuntajeFinal >= @Aprob RETURN N'APROBADO';
    IF @PuntajeFinal >= @Obs RETURN N'OBSERVADO';
    RETURN N'RECHAZADO';
END;
GO

/* Puntaje ponderado de una evaluación a partir de criterios (0-100 con pesos) */
CREATE OR ALTER FUNCTION dbo.fn_CalcularPuntajeEvaluacion (@IdEvaluacion INT)
RETURNS DECIMAL(4, 2)
AS
BEGIN
    DECLARE @SumaPonderada DECIMAL(10, 4);
    DECLARE @SumaPesos DECIMAL(10, 4);

    SELECT
        @SumaPonderada = SUM(ec.Puntaje * c.Peso / 100.0),
        @SumaPesos = SUM(c.Peso)
    FROM dbo.EvaluacionCriterio ec
    INNER JOIN dbo.CriterioEvaluacion c ON c.IdCriterio = ec.IdCriterio
    WHERE ec.IdEvaluacion = @IdEvaluacion
      AND c.Activo = 1;

    IF @SumaPesos IS NULL OR @SumaPesos = 0 RETURN NULL;

    RETURN dbo.fn_PorcentajeAEscala5(@SumaPonderada * 100.0 / @SumaPesos);
END;
GO

/* Áreas pendientes: áreas de criterios activos sin fila en EvaluacionArea.
   No usar PuntajeFinal como señal de cierre: se actualiza en cada guardado parcial. */
CREATE OR ALTER FUNCTION dbo.fn_ContarAreasPendientes (@IdEvaluacion INT)
RETURNS INT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM dbo.Evaluacion e
        INNER JOIN dbo.CatEstadoEvaluacion ce ON ce.IdEstadoEvaluacion = e.IdEstadoEvaluacion
        WHERE e.IdEvaluacion = @IdEvaluacion
          AND ce.Codigo NOT IN (N'EN_PROCESO', N'EN_EVALUACION')
    )
        RETURN 0;

    DECLARE @TotalAreas INT;
    DECLARE @AreasCompletadas INT;

    SELECT @TotalAreas = COUNT(DISTINCT c.Area)
    FROM dbo.CriterioEvaluacion c
    WHERE c.Activo = 1;

    SELECT @AreasCompletadas = COUNT(DISTINCT ea.Area)
    FROM dbo.EvaluacionArea ea
    WHERE ea.IdEvaluacion = @IdEvaluacion;

    RETURN CASE
        WHEN @TotalAreas IS NULL THEN 0
        ELSE CASE WHEN @TotalAreas - ISNULL(@AreasCompletadas, 0) < 0 THEN 0
             ELSE @TotalAreas - ISNULL(@AreasCompletadas, 0) END
    END;
END;
GO

/* Tabla: ranking de proveedores */
CREATE OR ALTER FUNCTION dbo.fn_RankingProveedores ()
RETURNS TABLE
AS
RETURN
(
    SELECT
        ROW_NUMBER() OVER (ORDER BY p.PuntajePromedio DESC, p.TotalEvaluaciones DESC) AS Posicion,
        p.IdProveedor,
        p.RazonSocial AS Proveedor,
        p.PuntajePromedio AS Puntaje,
        p.IdClasificacion AS Clasificacion,
        p.TotalEvaluaciones AS Evaluaciones
    FROM dbo.Proveedor p
    WHERE p.PuntajePromedio IS NOT NULL
      AND p.IdEstadoProveedor IN (
          SELECT IdEstadoProveedor FROM dbo.CatEstadoProveedor
          WHERE Codigo IN (N'APROBADO', N'ACTIVO')
      )
);
GO

PRINT N'Funciones creadas correctamente.';
GO

/* ========== FIN: 03_funciones.sql ========== */

/* ========== INICIO: 04_procedimientos_almacenados.sql ========== */
/*
  FILASUR - Script 04: Procedimientos almacenados
*/
USE FilasurProveedores;
GO

/* ---------- Bitácora interna ---------- */
CREATE OR ALTER PROCEDURE dbo.sp_Bitacora_Registrar
    @IdUsuario      INT = NULL,
    @Modulo         NVARCHAR(60),
    @Accion         NVARCHAR(120),
    @Detalle        NVARCHAR(500) = NULL,
    @DireccionIp    NVARCHAR(45) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Bitacora (IdUsuario, Modulo, Accion, Detalle, DireccionIp)
    VALUES (@IdUsuario, @Modulo, @Accion, @Detalle, @DireccionIp);
END;
GO

/* ---------- Proveedores ---------- */
CREATE OR ALTER PROCEDURE dbo.sp_Proveedor_Registrar
    @Ruc                CHAR(11),
    @RazonSocial        NVARCHAR(200),
    @IdTipoProveedor    TINYINT,
    @Rubro              NVARCHAR(100) = NULL,
    @Contacto           NVARCHAR(120) = NULL,
    @Telefono           NVARCHAR(30) = NULL,
    @Correo             NVARCHAR(120) = NULL,
    @Direccion          NVARCHAR(255) = NULL,
    @IdUsuario          INT,
    @IdProveedor        INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;

        DECLARE @IdEstado TINYINT;
        SELECT @IdEstado = IdEstadoProveedor FROM dbo.CatEstadoProveedor WHERE Codigo = N'ACTIVO';

        INSERT INTO dbo.Proveedor (
            Ruc, RazonSocial, IdTipoProveedor, Rubro, Contacto, Telefono, Correo, Direccion,
            IdEstadoProveedor, TotalEvaluaciones
        )
        VALUES (
            @Ruc, @RazonSocial, @IdTipoProveedor, @Rubro, @Contacto, @Telefono, @Correo, @Direccion,
            @IdEstado, 0
        );

        SET @IdProveedor = SCOPE_IDENTITY();

        EXEC dbo.sp_Bitacora_Registrar
            @IdUsuario = @IdUsuario,
            @Modulo = N'Proveedores',
            @Accion = N'Nuevo proveedor registrado',
            @Detalle = @RazonSocial;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Proveedor_Actualizar
    @IdProveedor        INT,
    @RazonSocial        NVARCHAR(200),
    @IdTipoProveedor    TINYINT,
    @Rubro              NVARCHAR(100) = NULL,
    @Contacto           NVARCHAR(120) = NULL,
    @Telefono           NVARCHAR(30) = NULL,
    @Correo             NVARCHAR(120) = NULL,
    @Direccion          NVARCHAR(255) = NULL,
    @IdEstadoProveedor  TINYINT = NULL,
    @IdUsuario          INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.Proveedor
    SET RazonSocial = @RazonSocial,
        IdTipoProveedor = @IdTipoProveedor,
        Rubro = @Rubro,
        Contacto = @Contacto,
        Telefono = @Telefono,
        Correo = @Correo,
        Direccion = @Direccion,
        IdEstadoProveedor = COALESCE(@IdEstadoProveedor, IdEstadoProveedor),
        FechaModificacion = SYSUTCDATETIME()
    WHERE IdProveedor = @IdProveedor;

    EXEC dbo.sp_Bitacora_Registrar
        @IdUsuario = @IdUsuario,
        @Modulo = N'Proveedores',
        @Accion = N'Proveedor actualizado',
        @Detalle = @RazonSocial;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Proveedor_Listar
    @Busqueda NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        p.IdProveedor AS id,
        p.Ruc AS ruc,
        p.RazonSocial AS razonSocial,
        tp.Nombre AS tipoProveedor,
        p.Rubro AS rubro,
        p.Contacto AS contacto,
        p.Telefono AS telefono,
        p.Correo AS correo,
        p.Direccion AS direccion,
        ep.Nombre AS estado,
        p.IdClasificacion AS clasificacion,
        p.PuntajePromedio AS puntajePromedio,
        p.TotalEvaluaciones AS evaluaciones
    FROM dbo.Proveedor p
    INNER JOIN dbo.CatTipoProveedor tp ON tp.IdTipoProveedor = p.IdTipoProveedor
    INNER JOIN dbo.CatEstadoProveedor ep ON ep.IdEstadoProveedor = p.IdEstadoProveedor
    WHERE @Busqueda IS NULL
       OR p.RazonSocial LIKE N'%' + @Busqueda + N'%'
       OR p.Ruc LIKE N'%' + @Busqueda + N'%'
    ORDER BY p.RazonSocial;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Proveedor_RecalcularPromedio
    @IdProveedor INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Promedio DECIMAL(4, 2);
    DECLARE @Total INT;

    SELECT
        @Promedio = AVG(e.PuntajeFinal),
        @Total = COUNT(*)
    FROM dbo.Evaluacion e
    INNER JOIN dbo.CatEstadoEvaluacion ce ON ce.IdEstadoEvaluacion = e.IdEstadoEvaluacion
    WHERE e.IdProveedor = @IdProveedor
      AND e.PuntajeFinal IS NOT NULL
      AND ce.Codigo IN (N'APROBADO', N'OBSERVADO', N'RECHAZADO', N'FINALIZADA');

    UPDATE dbo.Proveedor
    SET PuntajePromedio = @Promedio,
        TotalEvaluaciones = ISNULL(@Total, 0),
        IdClasificacion = dbo.fn_ClasificacionPorPuntaje(@Promedio),
        FechaModificacion = SYSUTCDATETIME()
    WHERE IdProveedor = @IdProveedor;
END;
GO

/* ---------- Criterios ---------- */
CREATE OR ALTER PROCEDURE dbo.sp_Criterio_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        IdCriterio AS id,
        Nombre AS nombre,
        Area AS area,
        Peso AS peso,
        Activo AS activo
    FROM dbo.CriterioEvaluacion
    ORDER BY Area, Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Criterio_Guardar
    @CriteriosJson NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE c
    SET Nombre = j.nombre,
        Area = j.area,
        Peso = j.peso,
        Activo = j.activo
    FROM dbo.CriterioEvaluacion c
    INNER JOIN OPENJSON(@CriteriosJson)
    WITH (
        id INT '$.id',
        nombre NVARCHAR(120) '$.nombre',
        area NVARCHAR(60) '$.area',
        peso DECIMAL(5, 2) '$.peso',
        activo BIT '$.activo'
    ) AS j ON c.IdCriterio = j.id;

    SELECT
        IdCriterio AS id,
        Nombre AS nombre,
        Area AS area,
        Peso AS peso,
        Activo AS activo
    FROM dbo.CriterioEvaluacion
    ORDER BY Area, Nombre;
END;
GO

/* ---------- Evaluaciones ---------- */
CREATE OR ALTER PROCEDURE dbo.sp_Evaluacion_GuardarBorrador
    @IdProveedor        INT,
    @Periodo            NVARCHAR(20),
    @IdProducto         INT = NULL,
    @OrdenCompra        NVARCHAR(30) = NULL,
    @FechaLimite        DATE = NULL,
    @Observaciones      NVARCHAR(MAX) = NULL,
    @IdUsuarioCreador   INT,
    @IdEvaluacion       INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdEstado TINYINT;

    SELECT @IdEstado = IdEstadoEvaluacion FROM dbo.CatEstadoEvaluacion WHERE Codigo = N'EN_PROCESO';

    INSERT INTO dbo.Evaluacion (
        IdProveedor, IdProducto, Periodo, OrdenCompra, FechaLimite,
        IdEstadoEvaluacion, Observaciones, IdUsuarioCreador
    )
    VALUES (
        @IdProveedor, @IdProducto, @Periodo, @OrdenCompra, @FechaLimite,
        @IdEstado, @Observaciones, @IdUsuarioCreador
    );

    SET @IdEvaluacion = SCOPE_IDENTITY();

    EXEC dbo.sp_Bitacora_Registrar
        @IdUsuario = @IdUsuarioCreador,
        @Modulo = N'Evaluaciones',
        @Accion = N'Evaluación en borrador',
        @Detalle = CONCAT(N'IdEvaluacion=', @IdEvaluacion);
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Evaluacion_GuardarCriterios
    @IdEvaluacion INT,
    @CriteriosJson NVARCHAR(MAX)  -- [{"idCriterio":1,"puntaje":90},...]
AS
BEGIN
    SET NOCOUNT ON;
    /* MERGE: permite que cada rol guarde solo sus criterios sin borrar los demás */
    ;WITH Incoming AS (
        SELECT
            j.IdCriterio,
            j.Puntaje,
            CAST(j.Puntaje * c.Peso / 100.0 AS DECIMAL(8, 4)) AS PuntajePonderado
        FROM OPENJSON(@CriteriosJson)
        WITH (
            IdCriterio INT '$.idCriterio',
            Puntaje DECIMAL(5, 2) '$.puntaje'
        ) AS j
        INNER JOIN dbo.CriterioEvaluacion c ON c.IdCriterio = j.IdCriterio
    )
    MERGE dbo.EvaluacionCriterio AS target
    USING Incoming AS src
        ON target.IdEvaluacion = @IdEvaluacion
       AND target.IdCriterio = src.IdCriterio
    WHEN MATCHED THEN
        UPDATE SET
            Puntaje = src.Puntaje,
            PuntajePonderado = src.PuntajePonderado
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (IdEvaluacion, IdCriterio, Puntaje, PuntajePonderado)
        VALUES (@IdEvaluacion, src.IdCriterio, src.Puntaje, src.PuntajePonderado);

    UPDATE dbo.Evaluacion
    SET PuntajeFinal = dbo.fn_CalcularPuntajeEvaluacion(@IdEvaluacion),
        FechaModificacion = SYSUTCDATETIME()
    WHERE IdEvaluacion = @IdEvaluacion;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Evaluacion_Finalizar
    @IdEvaluacion   INT,
    @IdUsuario      INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Puntaje DECIMAL(4, 2);
    DECLARE @Nivel NVARCHAR(30);
    DECLARE @IdEstado TINYINT;

    SET @Puntaje = dbo.fn_CalcularPuntajeEvaluacion(@IdEvaluacion);
    SET @Nivel = dbo.fn_NivelResultadoEvaluacion(@Puntaje);

    SELECT @IdEstado = IdEstadoEvaluacion
    FROM dbo.CatEstadoEvaluacion
    WHERE Codigo = CASE @Nivel
        WHEN N'APROBADO' THEN N'APROBADO'
        WHEN N'OBSERVADO' THEN N'OBSERVADO'
        ELSE N'RECHAZADO'
    END;

    UPDATE dbo.Evaluacion
    SET PuntajeFinal = @Puntaje,
        NivelResultado = @Nivel,
        IdEstadoEvaluacion = @IdEstado,
        FechaEvaluacion = CAST(SYSUTCDATETIME() AS DATE),
        ResultadoTexto = CASE @Nivel
            WHEN N'APROBADO' THEN N'Proveedor apto'
            WHEN N'OBSERVADO' THEN N'Proveedor con observaciones; requiere seguimiento'
            ELSE N'Proveedor no cumple umbral mínimo'
        END,
        FechaModificacion = SYSUTCDATETIME()
    WHERE IdEvaluacion = @IdEvaluacion;

    /* Consolidar puntajes por área a partir de criterios (escala 0-100 → 0-5) */
    DELETE FROM dbo.EvaluacionArea WHERE IdEvaluacion = @IdEvaluacion;

    INSERT INTO dbo.EvaluacionArea (IdEvaluacion, Area, IdUsuarioEvaluador, Puntaje, Peso, PuntajePonderado, Observaciones)
    SELECT
        @IdEvaluacion,
        c.Area,
        @IdUsuario,
        CAST(ROUND(SUM(ec.Puntaje * c.Peso / 100.0) / NULLIF(SUM(c.Peso), 0) / 20.0, 2) AS DECIMAL(4, 2)),
        SUM(c.Peso),
        CAST(ROUND(SUM(ec.Puntaje * c.Peso) / 2000.0, 2) AS DECIMAL(6, 3)),
        NULL
    FROM dbo.EvaluacionCriterio ec
    INNER JOIN dbo.CriterioEvaluacion c ON c.IdCriterio = ec.IdCriterio
    WHERE ec.IdEvaluacion = @IdEvaluacion
    GROUP BY c.Area;

    DECLARE @IdProveedor INT;
    SELECT @IdProveedor = IdProveedor FROM dbo.Evaluacion WHERE IdEvaluacion = @IdEvaluacion;

    EXEC dbo.sp_Proveedor_RecalcularPromedio @IdProveedor;

    EXEC dbo.sp_Bitacora_Registrar
        @IdUsuario = @IdUsuario,
        @Modulo = N'Evaluaciones',
        @Accion = N'Evaluación finalizada',
        @Detalle = CONCAT(N'Id=', @IdEvaluacion, N' Nivel=', @Nivel);
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Evaluacion_Aprobar
    @IdEvaluacion INT,
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdEstado TINYINT;
    SELECT @IdEstado = IdEstadoEvaluacion FROM dbo.CatEstadoEvaluacion WHERE Codigo = N'APROBADO';

    UPDATE dbo.Evaluacion
    SET IdEstadoEvaluacion = @IdEstado,
        NivelResultado = N'APROBADO',
        FechaModificacion = SYSUTCDATETIME()
    WHERE IdEvaluacion = @IdEvaluacion;

    EXEC dbo.sp_Bitacora_Registrar @IdUsuario, N'Evaluaciones', N'Evaluación aprobada',
        CONCAT(N'IdEvaluacion=', @IdEvaluacion);
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Evaluacion_Rechazar
    @IdEvaluacion INT,
    @IdUsuario INT,
    @Motivo NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdEstado TINYINT;
    SELECT @IdEstado = IdEstadoEvaluacion FROM dbo.CatEstadoEvaluacion WHERE Codigo = N'RECHAZADO';

    UPDATE dbo.Evaluacion
    SET IdEstadoEvaluacion = @IdEstado,
        NivelResultado = N'RECHAZADO',
        Observaciones = COALESCE(@Motivo, Observaciones),
        FechaModificacion = SYSUTCDATETIME()
    WHERE IdEvaluacion = @IdEvaluacion;

    EXEC dbo.sp_Bitacora_Registrar @IdUsuario, N'Evaluaciones', N'Evaluación rechazada',
        CONCAT(N'IdEvaluacion=', @IdEvaluacion);
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Evaluacion_Listar
    @IdProveedor INT = NULL,
    @EstadoCodigo NVARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        e.IdEvaluacion AS id,
        e.IdProveedor AS proveedorId,
        p.RazonSocial AS proveedor,
        pr.Nombre AS producto,
        e.OrdenCompra AS ordenCompra,
        CONVERT(VARCHAR(10), e.FechaEvaluacion, 103) AS fechaEvaluacion,
        e.PuntajeFinal AS puntajeFinal,
        ce.Nombre AS estado,
        dbo.fn_ContarAreasPendientes(e.IdEvaluacion) AS areasPendientes
    FROM dbo.Evaluacion e
    INNER JOIN dbo.Proveedor p ON p.IdProveedor = e.IdProveedor
    INNER JOIN dbo.CatEstadoEvaluacion ce ON ce.IdEstadoEvaluacion = e.IdEstadoEvaluacion
    LEFT JOIN dbo.Producto pr ON pr.IdProducto = e.IdProducto
    WHERE (@IdProveedor IS NULL OR e.IdProveedor = @IdProveedor)
      AND (@EstadoCodigo IS NULL OR ce.Codigo = @EstadoCodigo)
    ORDER BY e.FechaCreacion DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Evaluacion_ObtenerConsolidacion
    @IdEvaluacion INT
AS
BEGIN
    SET NOCOUNT ON;
    /* Cabecera */
    SELECT
        e.IdEvaluacion AS id,
        p.RazonSocial AS proveedor,
        pr.Nombre AS producto,
        e.OrdenCompra AS ordenCompra,
        CONVERT(VARCHAR(10), e.FechaEvaluacion, 103) AS fechaEvaluacion,
        e.Periodo AS periodo,
        e.PuntajeFinal AS puntajeFinal,
        CAST(5 AS DECIMAL(4, 2)) AS puntajeMax,
        e.NivelResultado AS nivel,
        e.ResultadoTexto AS resultado,
        e.Observaciones AS observaciones
    FROM dbo.Evaluacion e
    INNER JOIN dbo.Proveedor p ON p.IdProveedor = e.IdProveedor
    LEFT JOIN dbo.Producto pr ON pr.IdProducto = e.IdProducto
    WHERE e.IdEvaluacion = @IdEvaluacion;

    /* Áreas (guardadas o calculadas desde criterios) */
    IF EXISTS (SELECT 1 FROM dbo.EvaluacionArea WHERE IdEvaluacion = @IdEvaluacion)
    BEGIN
        SELECT
            ea.Area AS area,
            ISNULL(u.NombreCompleto, N'Consolidado') AS evaluador,
            ea.Puntaje AS puntaje,
            ea.Peso AS peso,
            ea.PuntajePonderado AS ponderado,
            ea.Observaciones AS observaciones
        FROM dbo.EvaluacionArea ea
        LEFT JOIN dbo.Usuario u ON u.IdUsuario = ea.IdUsuarioEvaluador
        WHERE ea.IdEvaluacion = @IdEvaluacion
        ORDER BY ea.Area;
    END
    ELSE
    BEGIN
        SELECT
            c.Area AS area,
            N'Consolidado' AS evaluador,
            CAST(ROUND(SUM(ec.Puntaje * c.Peso / 100.0) / NULLIF(SUM(c.Peso), 0) / 20.0, 2) AS DECIMAL(4, 2)) AS puntaje,
            SUM(c.Peso) AS peso,
            CAST(ROUND(SUM(ec.Puntaje * c.Peso) / 2000.0, 2) AS DECIMAL(6, 3)) AS ponderado,
            CAST(NULL AS NVARCHAR(500)) AS observaciones
        FROM dbo.EvaluacionCriterio ec
        INNER JOIN dbo.CriterioEvaluacion c ON c.IdCriterio = ec.IdCriterio
        WHERE ec.IdEvaluacion = @IdEvaluacion
        GROUP BY c.Area
        ORDER BY c.Area;
    END

    /* Criterios */
    SELECT
        c.Nombre AS nombre,
        ec.Puntaje AS puntaje,
        c.Peso AS peso
    FROM dbo.EvaluacionCriterio ec
    INNER JOIN dbo.CriterioEvaluacion c ON c.IdCriterio = ec.IdCriterio
    WHERE ec.IdEvaluacion = @IdEvaluacion;
END;
GO

/* ---------- Dashboard y reportes ---------- */
CREATE OR ALTER PROCEDURE dbo.sp_Dashboard_Resumen
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Hoy DATE = CAST(
        (SYSUTCDATETIME() AT TIME ZONE N'UTC') AT TIME ZONE N'SA Pacific Standard Time'
        AS DATE);
    DECLARE @DiasAlerta INT = 5;
    SELECT @DiasAlerta = ISNULL(DiasAlertaVencimiento, 5) FROM dbo.ConfiguracionSistema WHERE IdConfig = 1;

    /* 1. KPIs */
    SELECT
        (SELECT COUNT(*) FROM dbo.Proveedor) AS proveedoresRegistrados,
        (SELECT COUNT(*) FROM dbo.Evaluacion e
         INNER JOIN dbo.CatEstadoEvaluacion ce ON ce.IdEstadoEvaluacion = e.IdEstadoEvaluacion
         WHERE ce.Codigo IN (N'EN_PROCESO', N'EN_EVALUACION')) AS evaluacionesEnProceso,
        (SELECT COUNT(*) FROM dbo.Evaluacion e
         INNER JOIN dbo.CatEstadoEvaluacion ce ON ce.IdEstadoEvaluacion = e.IdEstadoEvaluacion
         WHERE ce.Codigo IN (N'APROBADO', N'FINALIZADA', N'OBSERVADO', N'RECHAZADO')) AS evaluacionesFinalizadas,
        (SELECT COUNT(*) FROM dbo.Proveedor p
         INNER JOIN dbo.CatEstadoProveedor ep ON ep.IdEstadoProveedor = p.IdEstadoProveedor
         WHERE ep.Codigo = N'APROBADO') AS proveedoresAprobados,
        (SELECT AVG(PuntajePromedio) FROM dbo.Proveedor WHERE PuntajePromedio IS NOT NULL) AS puntajePromedio,
        (SELECT COUNT(*)
         FROM dbo.DocumentoProveedor d
         WHERE d.FechaVencimiento IS NOT NULL
           AND d.FechaVencimiento <= DATEADD(DAY, @DiasAlerta, @Hoy)
        ) AS documentosPorVencer;

    /* 2. Evaluaciones recientes (últimas 5) */
    SELECT TOP (5)
        e.IdEvaluacion AS id,
        p.RazonSocial AS proveedor,
        pr.Nombre AS producto,
        dbo.fn_ContarAreasPendientes(e.IdEvaluacion) AS areasPendientes,
        ce.Nombre AS estado,
        COALESCE(
            CONVERT(VARCHAR(10), e.FechaLimite, 103),
            CONVERT(VARCHAR(10), e.FechaEvaluacion, 103),
            CONVERT(VARCHAR(10), e.FechaCreacion, 103)
        ) AS fechaLimite
    FROM dbo.Evaluacion e
    INNER JOIN dbo.Proveedor p ON p.IdProveedor = e.IdProveedor
    INNER JOIN dbo.CatEstadoEvaluacion ce ON ce.IdEstadoEvaluacion = e.IdEstadoEvaluacion
    LEFT JOIN dbo.Producto pr ON pr.IdProducto = e.IdProducto
    ORDER BY e.FechaCreacion DESC;

    /* 3. Próximas por vencer (en curso con fecha límite cercana o vencida) */
    SELECT TOP (10)
        e.IdEvaluacion AS id,
        p.RazonSocial AS proveedor,
        pr.Nombre AS producto,
        dbo.fn_ContarAreasPendientes(e.IdEvaluacion) AS areasPendientes,
        ce.Nombre AS estado,
        CONVERT(VARCHAR(10), e.FechaLimite, 103) AS fechaLimite
    FROM dbo.Evaluacion e
    INNER JOIN dbo.Proveedor p ON p.IdProveedor = e.IdProveedor
    INNER JOIN dbo.CatEstadoEvaluacion ce ON ce.IdEstadoEvaluacion = e.IdEstadoEvaluacion
    LEFT JOIN dbo.Producto pr ON pr.IdProducto = e.IdProducto
    WHERE e.PuntajeFinal IS NULL
      AND ce.Codigo IN (N'EN_PROCESO', N'EN_EVALUACION')
      AND e.FechaLimite IS NOT NULL
      AND e.FechaLimite <= DATEADD(DAY, @DiasAlerta, @Hoy)
    ORDER BY e.FechaLimite ASC;

    /* 4. Evolución mensual (últimos 6 meses, puntaje % sobre escala 0-100) */
    ;WITH UltimosMeses AS (
        SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2
        UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
    ),
    Meses AS (
        SELECT DATEADD(MONTH, -n, DATEFROMPARTS(YEAR(@Hoy), MONTH(@Hoy), 1)) AS PrimerDiaMes
        FROM UltimosMeses
    )
    SELECT
        CASE MONTH(m.PrimerDiaMes)
            WHEN 1 THEN N'Ene' WHEN 2 THEN N'Feb' WHEN 3 THEN N'Mar'
            WHEN 4 THEN N'Abr' WHEN 5 THEN N'May' WHEN 6 THEN N'Jun'
            WHEN 7 THEN N'Jul' WHEN 8 THEN N'Ago' WHEN 9 THEN N'Sep'
            WHEN 10 THEN N'Oct' WHEN 11 THEN N'Nov' ELSE N'Dic'
        END AS mes,
        ISNULL(CAST(ROUND(AVG(e.PuntajeFinal) * 20.0, 0) AS INT), 0) AS puntaje
    FROM Meses m
    LEFT JOIN dbo.Evaluacion e
        ON e.PuntajeFinal IS NOT NULL
       AND DATEFROMPARTS(
               YEAR(COALESCE(e.FechaEvaluacion, CAST(e.FechaCreacion AS DATE))),
               MONTH(COALESCE(e.FechaEvaluacion, CAST(e.FechaCreacion AS DATE))),
               1) = m.PrimerDiaMes
    GROUP BY m.PrimerDiaMes
    ORDER BY m.PrimerDiaMes;

    /* 5. Documentos por vencer / vencidos */
    SELECT TOP (15)
        d.IdDocumento AS id,
        p.RazonSocial AS proveedor,
        d.NombreArchivo AS archivo,
        ISNULL(d.CategoriaDocumento, N'Sin categoría') AS categoria,
        CONVERT(VARCHAR(10), d.FechaVencimiento, 103) AS fechaVencimiento,
        CASE
            WHEN d.FechaVencimiento < @Hoy THEN N'Vencido'
            ELSE N'Por vencer'
        END AS estado
    FROM dbo.DocumentoProveedor d
    INNER JOIN dbo.Proveedor p ON p.IdProveedor = d.IdProveedor
    WHERE d.FechaVencimiento IS NOT NULL
      AND d.FechaVencimiento <= DATEADD(DAY, @DiasAlerta, @Hoy)
    ORDER BY d.FechaVencimiento ASC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Ranking_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Posicion AS posicion, Proveedor AS proveedor, Puntaje AS puntaje,
           Clasificacion AS clasificacion, Evaluaciones AS evaluaciones
    FROM dbo.fn_RankingProveedores();
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Bitacora_Listar
    @Top INT = 200
AS
BEGIN
    SET NOCOUNT ON;

    /* FechaHora se guarda en UTC (SYSUTCDATETIME); se muestra en hora de Perú (UTC-5). */
    SELECT TOP (@Top)
        CAST(b.IdBitacora AS NVARCHAR(40)) AS id,
        CONVERT(VARCHAR(16),
            CAST((b.FechaHora AT TIME ZONE N'UTC') AT TIME ZONE N'SA Pacific Standard Time' AS DATETIME2(0)),
            103) + N' ' + CONVERT(VARCHAR(5),
            CAST((b.FechaHora AT TIME ZONE N'UTC') AT TIME ZONE N'SA Pacific Standard Time' AS DATETIME2(0)),
            108) AS fecha,
        ISNULL(u.NombreCompleto, N'Sistema') AS usuario,
        b.Accion AS accion,
        b.Detalle AS detalle,
        b.Modulo AS modulo
    FROM dbo.Bitacora b
    LEFT JOIN dbo.Usuario u ON u.IdUsuario = b.IdUsuario
    ORDER BY b.FechaHora DESC;
END;
GO

/* ---------- Configuración ---------- */
CREATE OR ALTER PROCEDURE dbo.sp_Configuracion_Obtener
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        UmbralAprobacion AS umbralAprobacion,
        UmbralObservado AS umbralObservado,
        DiasAlertaVencimiento AS diasAlertaVencimiento,
        NotificacionesEmail AS notificacionesEmail,
        IntegracionErp AS integracionErp
    FROM dbo.ConfiguracionSistema
    WHERE IdConfig = 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Configuracion_Guardar
    @UmbralAprobacion DECIMAL(4, 2),
    @UmbralObservado DECIMAL(4, 2),
    @DiasAlertaVencimiento INT,
    @NotificacionesEmail TINYINT,
    @IntegracionErp NVARCHAR(80),
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.ConfiguracionSistema WHERE IdConfig = 1)
        INSERT INTO dbo.ConfiguracionSistema (IdConfig, UmbralAprobacion, UmbralObservado,
            DiasAlertaVencimiento, NotificacionesEmail, IntegracionErp, IdUsuarioModificador, FechaModificacion)
        VALUES (1, @UmbralAprobacion, @UmbralObservado, @DiasAlertaVencimiento,
            @NotificacionesEmail, @IntegracionErp, @IdUsuario, SYSUTCDATETIME());
    ELSE
        UPDATE dbo.ConfiguracionSistema
        SET UmbralAprobacion = @UmbralAprobacion,
            UmbralObservado = @UmbralObservado,
            DiasAlertaVencimiento = @DiasAlertaVencimiento,
            NotificacionesEmail = @NotificacionesEmail,
            IntegracionErp = @IntegracionErp,
            IdUsuarioModificador = @IdUsuario,
            FechaModificacion = SYSUTCDATETIME()
        WHERE IdConfig = 1;
END;
GO

/* ---------- Autenticación (simplificado) ---------- */
CREATE OR ALTER PROCEDURE dbo.sp_Usuario_Login
    @Email NVARCHAR(120),
    @PasswordHash NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        u.IdUsuario AS id,
        u.NombreCompleto AS nombre,
        u.Email AS email,
        r.Nombre AS rol,
        u.Iniciales AS iniciales
    FROM dbo.Usuario u
    INNER JOIN dbo.Rol r ON r.IdRol = u.IdRol
    WHERE u.Email = @Email
      AND u.PasswordHash = @PasswordHash
      AND u.IdEstadoUsuario = 1;
END;
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

CREATE OR ALTER PROCEDURE dbo.sp_Proveedor_Obtener
    @IdProveedor INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RazonSocial NVARCHAR(200);
    SELECT @RazonSocial = RazonSocial FROM dbo.Proveedor WHERE IdProveedor = @IdProveedor;

    IF @RazonSocial IS NULL
        RETURN;

    /* 1. Cabecera */
    SELECT
        p.IdProveedor AS id,
        p.Ruc AS ruc,
        p.RazonSocial AS razonSocial,
        tp.Nombre AS tipoProveedor,
        p.Rubro AS rubro,
        p.Contacto AS contacto,
        p.Telefono AS telefono,
        p.Correo AS correo,
        p.Direccion AS direccion,
        ep.Nombre AS estado,
        p.IdClasificacion AS clasificacion,
        p.PuntajePromedio AS puntajePromedio,
        p.TotalEvaluaciones AS evaluaciones
    FROM dbo.Proveedor p
    INNER JOIN dbo.CatTipoProveedor tp ON tp.IdTipoProveedor = p.IdTipoProveedor
    INNER JOIN dbo.CatEstadoProveedor ep ON ep.IdEstadoProveedor = p.IdEstadoProveedor
    WHERE p.IdProveedor = @IdProveedor;

    /* 2. Evaluaciones del proveedor */
    EXEC dbo.sp_Evaluacion_Listar @IdProveedor = @IdProveedor, @EstadoCodigo = NULL;

    /* 3. Documentos */
    EXEC dbo.sp_Documento_Listar @IdProveedor = @IdProveedor, @Busqueda = NULL;

    /* 4. Bitácora relacionada */
    SELECT TOP (30)
        CAST(b.IdBitacora AS NVARCHAR(40)) AS id,
        CONVERT(VARCHAR(16), b.FechaHora, 103) + N' ' + CONVERT(VARCHAR(5), b.FechaHora, 108) AS fecha,
        ISNULL(u.NombreCompleto, N'Sistema') AS usuario,
        b.Accion AS accion,
        b.Detalle AS detalle,
        b.Modulo AS modulo
    FROM dbo.Bitacora b
    LEFT JOIN dbo.Usuario u ON u.IdUsuario = b.IdUsuario
    WHERE b.Detalle LIKE N'%' + @RazonSocial + N'%'
       OR b.Detalle LIKE N'%proveedor Id=' + CAST(@IdProveedor AS NVARCHAR(12)) + N'%'
       OR b.Detalle LIKE N'%Id=' + CAST(@IdProveedor AS NVARCHAR(12)) + N'%'
    ORDER BY b.FechaHora DESC;
END;
GO

PRINT N'Procedimientos de documentos creados.';
GO

/* ---------- Unidades de medida ---------- */
CREATE OR ALTER PROCEDURE dbo.sp_UnidadMedida_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        IdUnidad AS id,
        Codigo AS codigo,
        Nombre AS nombre,
        Descripcion AS descripcion,
        Activo AS activo
    FROM dbo.UnidadMedida
    ORDER BY Codigo;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_UnidadMedida_Registrar
    @Codigo         NVARCHAR(20),
    @Nombre         NVARCHAR(80),
    @Descripcion    NVARCHAR(255) = NULL,
    @Activo         BIT = 1,
    @IdUnidad       INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.UnidadMedida (Codigo, Nombre, Descripcion, Activo)
    VALUES (@Codigo, @Nombre, @Descripcion, @Activo);
    SET @IdUnidad = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_UnidadMedida_Actualizar
    @IdUnidad       INT,
    @Codigo         NVARCHAR(20),
    @Nombre         NVARCHAR(80),
    @Descripcion    NVARCHAR(255) = NULL,
    @Activo         BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.UnidadMedida
    SET Codigo = @Codigo,
        Nombre = @Nombre,
        Descripcion = @Descripcion,
        Activo = @Activo
    WHERE IdUnidad = @IdUnidad;
END;
GO

/* ---------- Productos ---------- */
CREATE OR ALTER PROCEDURE dbo.sp_Producto_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        p.IdProducto AS id,
        p.Codigo AS codigo,
        p.Nombre AS nombre,
        p.Categoria AS categoria,
        u.Codigo AS unidad
    FROM dbo.Producto p
    INNER JOIN dbo.UnidadMedida u ON u.IdUnidad = p.IdUnidad
    ORDER BY p.Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Producto_Registrar
    @Codigo         NVARCHAR(40),
    @Nombre         NVARCHAR(150),
    @Categoria      NVARCHAR(80) = NULL,
    @UnidadCodigo   NVARCHAR(20),
    @IdProducto     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdUnidad INT;
    SELECT @IdUnidad = IdUnidad FROM dbo.UnidadMedida WHERE Codigo = @UnidadCodigo;

    IF @IdUnidad IS NULL
    BEGIN
        RAISERROR(N'Unidad de medida no encontrada.', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.Producto (Codigo, Nombre, Categoria, IdUnidad, Activo)
    VALUES (@Codigo, @Nombre, @Categoria, @IdUnidad, 1);

    SET @IdProducto = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Producto_Actualizar
    @IdProducto     INT,
    @Codigo         NVARCHAR(40),
    @Nombre         NVARCHAR(150),
    @Categoria      NVARCHAR(80) = NULL,
    @UnidadCodigo   NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdUnidad INT;
    SELECT @IdUnidad = IdUnidad FROM dbo.UnidadMedida WHERE Codigo = @UnidadCodigo;

    IF @IdUnidad IS NULL
    BEGIN
        RAISERROR(N'Unidad de medida no encontrada.', 16, 1);
        RETURN;
    END

    UPDATE dbo.Producto
    SET Codigo = @Codigo,
        Nombre = @Nombre,
        Categoria = @Categoria,
        IdUnidad = @IdUnidad
    WHERE IdProducto = @IdProducto;
END;
GO

/* ---------- Usuarios ---------- */
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

CREATE OR ALTER PROCEDURE dbo.sp_Usuario_Registrar
    @NombreCompleto   NVARCHAR(120),
    @Email            NVARCHAR(120),
    @RolNombre        NVARCHAR(50),
    @PasswordHash     NVARCHAR(256),
    @IdUsuario        INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdRol INT;
    SELECT @IdRol = IdRol FROM dbo.Rol WHERE Nombre = @RolNombre;

    IF @IdRol IS NULL
    BEGIN
        RAISERROR(N'Rol no encontrado.', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.Usuario (IdRol, NombreCompleto, Email, PasswordHash, Iniciales, IdEstadoUsuario, DebeCambiarPassword)
    VALUES (
        @IdRol,
        @NombreCompleto,
        @Email,
        @PasswordHash,
        UPPER(LEFT(@NombreCompleto, 1)) + ISNULL(UPPER(SUBSTRING(@NombreCompleto, CHARINDEX(N' ', @NombreCompleto) + 1, 1)), N''),
        1,
        1
    );

    SET @IdUsuario = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Usuario_Actualizar
    @IdUsuario        INT,
    @NombreCompleto   NVARCHAR(120),
    @Email            NVARCHAR(120),
    @RolNombre        NVARCHAR(50),
    @Estado           NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdRol INT;
    SELECT @IdRol = IdRol FROM dbo.Rol WHERE Nombre = @RolNombre;

    IF @IdRol IS NULL
    BEGIN
        RAISERROR(N'Rol no encontrado.', 16, 1);
        RETURN;
    END

    UPDATE dbo.Usuario
    SET IdRol = @IdRol,
        NombreCompleto = @NombreCompleto,
        Email = @Email,
        IdEstadoUsuario = CASE WHEN @Estado = N'Activo' THEN 1 ELSE 0 END,
        FechaModificacion = SYSUTCDATETIME()
    WHERE IdUsuario = @IdUsuario;
END;
GO

/* ---------- Roles ---------- */
CREATE OR ALTER PROCEDURE dbo.sp_Rol_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT IdRol AS id, Nombre AS nombre, Descripcion AS descripcion
    FROM dbo.Rol
    WHERE Activo = 1
    ORDER BY Nombre;

    SELECT rm.IdRol AS idRol, rm.Modulo AS modulo
    FROM dbo.RolModulo rm
    INNER JOIN dbo.Rol r ON r.IdRol = rm.IdRol
    WHERE r.Activo = 1
    ORDER BY rm.IdRol, rm.Modulo;
END;
GO

/* ---------- Reportes ---------- */
CREATE OR ALTER PROCEDURE dbo.sp_Reporte_Evaluaciones
    @Estado      NVARCHAR(50) = NULL,
    @FechaDesde  DATE = NULL,
    @FechaHasta  DATE = NULL,
    @Producto    NVARCHAR(150) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Estado = N'Todos'
        SET @Estado = NULL;
    IF @Producto = N'Todos' OR @Producto = N''
        SET @Producto = NULL;

    /* Tabla temporal: un CTE solo aplica al SELECT inmediatamente siguiente (SQL Server 2019). */
    CREATE TABLE #EvaluacionesFiltradas (
        IdEvaluacion     INT             NOT NULL,
        proveedor        NVARCHAR(200)   NOT NULL,
        producto         NVARCHAR(150)   NULL,
        fechaEvaluacion  VARCHAR(10)     NULL,
        puntajeFinal     DECIMAL(4, 2)   NULL,
        estado           NVARCHAR(50)    NOT NULL,
        fechaRef         DATE            NOT NULL
    );

    INSERT INTO #EvaluacionesFiltradas (
        IdEvaluacion, proveedor, producto, fechaEvaluacion, puntajeFinal, estado, fechaRef
    )
    SELECT
        e.IdEvaluacion,
        p.RazonSocial,
        pr.Nombre,
        CONVERT(VARCHAR(10), COALESCE(e.FechaEvaluacion, CAST(e.FechaCreacion AS DATE)), 103),
        e.PuntajeFinal,
        ce.Nombre,
        COALESCE(e.FechaEvaluacion, CAST(e.FechaCreacion AS DATE))
    FROM dbo.Evaluacion e
    INNER JOIN dbo.Proveedor p ON p.IdProveedor = e.IdProveedor
    INNER JOIN dbo.CatEstadoEvaluacion ce ON ce.IdEstadoEvaluacion = e.IdEstadoEvaluacion
    LEFT JOIN dbo.Producto pr ON pr.IdProducto = e.IdProducto
    WHERE e.PuntajeFinal IS NOT NULL
      AND (@Estado IS NULL OR ce.Nombre = @Estado)
      AND (@FechaDesde IS NULL OR COALESCE(e.FechaEvaluacion, CAST(e.FechaCreacion AS DATE)) >= @FechaDesde)
      AND (@FechaHasta IS NULL OR COALESCE(e.FechaEvaluacion, CAST(e.FechaCreacion AS DATE)) <= @FechaHasta)
      AND (@Producto IS NULL OR pr.Nombre = @Producto);

    /* Result set 1: filas del reporte */
    SELECT
        IdEvaluacion AS id,
        proveedor,
        producto,
        fechaEvaluacion,
        puntajeFinal,
        estado
    FROM #EvaluacionesFiltradas
    ORDER BY fechaRef DESC;

    /* Result set 2: totales KPI */
    SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN estado = N'Aprobado' THEN 1 ELSE 0 END) AS aprobados,
        SUM(CASE WHEN estado = N'Observado' THEN 1 ELSE 0 END) AS observados,
        SUM(CASE WHEN estado = N'Rechazado' THEN 1 ELSE 0 END) AS rechazados
    FROM #EvaluacionesFiltradas;
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

PRINT N'Procedimientos almacenados creados correctamente.';
GO

/* ========== FIN: 04_procedimientos_almacenados.sql ========== */

/* ========== INICIO: 05_datos_semilla.sql ========== */
/*
  FILASUR - Script 05: Datos iniciales (catálogos + configuración)
  Incluido en 00_despliegue_produccion.sql
*/
USE FilasurProveedores;
GO

/* Catálogos estado proveedor */
IF NOT EXISTS (SELECT 1 FROM dbo.CatEstadoProveedor)
INSERT INTO dbo.CatEstadoProveedor (IdEstadoProveedor, Codigo, Nombre) VALUES
(1, N'ACTIVO', N'Activo'),
(2, N'EN_EVALUACION', N'En evaluación'),
(3, N'APROBADO', N'Aprobado'),
(4, N'RECHAZADO', N'Rechazado');
GO

/* Catálogos estado evaluación */
IF NOT EXISTS (SELECT 1 FROM dbo.CatEstadoEvaluacion)
INSERT INTO dbo.CatEstadoEvaluacion (IdEstadoEvaluacion, Codigo, Nombre) VALUES
(1, N'EN_PROCESO', N'En proceso'),
(2, N'EN_EVALUACION', N'En evaluación'),
(3, N'FINALIZADA', N'Finalizada'),
(4, N'APROBADO', N'Aprobado'),
(5, N'OBSERVADO', N'Observado'),
(6, N'RECHAZADO', N'Rechazado');
GO

IF NOT EXISTS (SELECT 1 FROM dbo.CatClasificacionProveedor)
INSERT INTO dbo.CatClasificacionProveedor (IdClasificacion, Nombre, PuntajeMinimo) VALUES
('A', N'Excelente', 4.00),
('B', N'Aceptable', 3.50),
('C', N'En mejora', 0.00);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.CatTipoProveedor)
INSERT INTO dbo.CatTipoProveedor (Nombre) VALUES
(N'Materia prima'),
(N'Servicio'),
(N'Mixto');
GO

/* Roles y módulos */
IF NOT EXISTS (SELECT 1 FROM dbo.Rol)
INSERT INTO dbo.Rol (Nombre, Descripcion) VALUES
(N'Administrador', N'Acceso total al sistema'),
(N'Compras', N'Gestión de proveedores y evaluaciones'),
(N'Calidad', N'Evaluación por áreas y criterios'),
(N'Logística', N'Evaluación logística y documentos');
GO

IF NOT EXISTS (SELECT 1 FROM dbo.RolModulo)
INSERT INTO dbo.RolModulo (IdRol, Modulo)
SELECT r.IdRol, m.Modulo
FROM dbo.Rol r
CROSS APPLY (VALUES
    (N'Administrador', N'Todos'),
    (N'Compras', N'Proveedores'),
    (N'Compras', N'Evaluaciones'),
    (N'Compras', N'Reportes'),
    (N'Compras', N'Documentos'),
    (N'Compras', N'Criterios'),
    (N'Compras', N'Unidades'),
    (N'Compras', N'Productos'),
    (N'Compras', N'Configuración'),
    (N'Calidad', N'Evaluaciones'),
    (N'Calidad', N'Criterios'),
    (N'Logística', N'Proveedores'),
    (N'Logística', N'Evaluaciones'),
    (N'Logística', N'Reportes'),
    (N'Logística', N'Documentos')
) AS m(RolNombre, Modulo)
WHERE r.Nombre = m.RolNombre;
GO

/*
  Usuario administrador inicial.
  Email:    fvelazco@filasur.com
  Password: fvelazco2026
*/
IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE Email = N'fvelazco@filasur.com')
INSERT INTO dbo.Usuario (IdRol, NombreCompleto, Email, PasswordHash, Iniciales, IdEstadoUsuario)
SELECT r.IdRol, N'Francisco Velazco', N'fvelazco@filasur.com',
       N'$2a$11$JAXCsnEU3qQLdiXLO8FX1OR8Xeo5rCGA0NfFj27RZUHlwhhIOE1fO', N'FV', 1
FROM dbo.Rol r WHERE r.Nombre = N'Administrador';
GO

/* Configuración: DiasAlerta 15 para que plazos de evaluación (≈15 días) aparezcan en dashboard */
IF NOT EXISTS (SELECT 1 FROM dbo.ConfiguracionSistema WHERE IdConfig = 1)
INSERT INTO dbo.ConfiguracionSistema (
    IdConfig, UmbralAprobacion, UmbralObservado, DiasAlertaVencimiento,
    NotificacionesEmail, IntegracionErp, FechaModificacion
) VALUES (1, 3.50, 3.00, 15, 1, N'Exactus', SYSUTCDATETIME());
GO

/* Unidades y productos */
IF NOT EXISTS (SELECT 1 FROM dbo.UnidadMedida)
INSERT INTO dbo.UnidadMedida (Codigo, Nombre, Descripcion, Activo) VALUES
(N'UND', N'Unidad', N'Pieza o unidad de venta', 1),
(N'KG', N'Kilogramo', N'Masa en kilogramos', 1),
(N'MT', N'Metro', N'Longitud en metros lineales', 1),
(N'ROLLO', N'Rollo', N'Rollo de material continuo', 1),
(N'LT', N'Litro', N'Volumen en litros', 1),
(N'M2', N'Metro cuadrado', N'Superficie en metros cuadrados', 0);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Producto)
INSERT INTO dbo.Producto (Codigo, Nombre, Categoria, IdUnidad) VALUES
(N'MAT-BOL-PP-50', N'Bolsa PP 50kg', N'Embalaje', (SELECT IdUnidad FROM dbo.UnidadMedida WHERE Codigo = N'UND')),
(N'MAT-HIL-ALG-30', N'Hilo Algodón 30/1', N'Textil', (SELECT IdUnidad FROM dbo.UnidadMedida WHERE Codigo = N'KG')),
(N'MAT-TEL-CRU-40', N'Tela cruda 40"', N'Textil', (SELECT IdUnidad FROM dbo.UnidadMedida WHERE Codigo = N'MT')),
(N'MAT-FILM-ST', N'Film stretch', N'Embalaje', (SELECT IdUnidad FROM dbo.UnidadMedida WHERE Codigo = N'ROLLO')),
(N'MAT-TINTE-IND', N'Tinte industrial azul', N'Químicos', (SELECT IdUnidad FROM dbo.UnidadMedida WHERE Codigo = N'LT')),
(N'MAT-ETIQ-TEJ', N'Etiqueta tejida', N'Accesorios', (SELECT IdUnidad FROM dbo.UnidadMedida WHERE Codigo = N'UND'));
GO

/* Criterios alineados a fases Calidad → Compras → Logística */
IF NOT EXISTS (SELECT 1 FROM dbo.CriterioEvaluacion)
INSERT INTO dbo.CriterioEvaluacion (Nombre, Area, Peso, Activo) VALUES
(N'Calidad del producto', N'Calidad', 25, 1),
(N'Documentación técnica', N'Calidad', 10, 1),
(N'Precio competitivo', N'Compras', 20, 1),
(N'Condiciones comerciales', N'Compras', 15, 1),
(N'Cumplimiento de plazos', N'Logística', 20, 1),
(N'Embalaje y despacho', N'Logística', 10, 1);
GO

PRINT N'Datos semilla (catálogos) cargados.';
GO

/* ========== FIN: 05_datos_semilla.sql ========== */

/* ========== INICIO: 10_bitacora_tablas_triggers.sql ========== */
/*
  FILASUR - Script 10: Bitácoras completas (BD existente)
  ========================================================
  Ejecutar UNA VEZ en la base FilasurProveedores ya desplegada.

  Crea / recrea tablas de auditoría alimentadas por triggers:
    bit_usuario    → dbo.Usuario
    bit_proveedor  → dbo.Proveedor
    bit_producto   → dbo.Producto
    bit_evaluacion → dbo.Evaluacion
    bit_rol        → dbo.Rol

  Convención PK: id_bit_<entidad>

  NOTA: si ya existían bit_usuario / bit_proveedor / bit_evaluacion
  con columnas PascalCase (IdBitUsuario, etc.), se eliminan y recrean
  con la convención nueva (se pierde historial previo de esas bit_*).
  La tabla dbo.Bitacora (acciones de aplicación) NO se toca.
*/
USE FilasurProveedores;
GO

SET NOCOUNT ON;
GO

/* ---------- Quitar triggers previos ---------- */
IF OBJECT_ID('dbo.trg_bit_usuario_ins', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_bit_usuario_ins;
IF OBJECT_ID('dbo.trg_bit_usuario_upd', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_bit_usuario_upd;
IF OBJECT_ID('dbo.trg_bit_usuario_del', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_bit_usuario_del;
IF OBJECT_ID('dbo.trg_bit_proveedor_ins', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_bit_proveedor_ins;
IF OBJECT_ID('dbo.trg_bit_proveedor_upd', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_bit_proveedor_upd;
IF OBJECT_ID('dbo.trg_bit_proveedor_del', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_bit_proveedor_del;
IF OBJECT_ID('dbo.trg_bit_producto_ins', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_bit_producto_ins;
IF OBJECT_ID('dbo.trg_bit_producto_upd', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_bit_producto_upd;
IF OBJECT_ID('dbo.trg_bit_producto_del', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_bit_producto_del;
IF OBJECT_ID('dbo.trg_bit_evaluacion_ins', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_bit_evaluacion_ins;
IF OBJECT_ID('dbo.trg_bit_evaluacion_upd', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_bit_evaluacion_upd;
IF OBJECT_ID('dbo.trg_bit_evaluacion_del', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_bit_evaluacion_del;
IF OBJECT_ID('dbo.trg_bit_rol_ins', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_bit_rol_ins;
IF OBJECT_ID('dbo.trg_bit_rol_upd', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_bit_rol_upd;
IF OBJECT_ID('dbo.trg_bit_rol_del', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_bit_rol_del;
GO

/* ---------- Recrear tablas bit_* ---------- */
IF OBJECT_ID('dbo.bit_usuario', 'U') IS NOT NULL DROP TABLE dbo.bit_usuario;
IF OBJECT_ID('dbo.bit_proveedor', 'U') IS NOT NULL DROP TABLE dbo.bit_proveedor;
IF OBJECT_ID('dbo.bit_producto', 'U') IS NOT NULL DROP TABLE dbo.bit_producto;
IF OBJECT_ID('dbo.bit_evaluacion', 'U') IS NOT NULL DROP TABLE dbo.bit_evaluacion;
IF OBJECT_ID('dbo.bit_rol', 'U') IS NOT NULL DROP TABLE dbo.bit_rol;
GO

CREATE TABLE dbo.bit_usuario (
    id_bit_usuario      BIGINT          NOT NULL IDENTITY(1, 1),
    id_usuario          INT             NULL,
    accion              NVARCHAR(20)    NOT NULL,
    fecha_hora          DATETIME2(0)    NOT NULL CONSTRAINT DF_bit_usuario_fecha DEFAULT (SYSUTCDATETIME()),
    usuario_sql         NVARCHAR(128)   NOT NULL CONSTRAINT DF_bit_usuario_sql DEFAULT (ORIGINAL_LOGIN()),
    host_name           NVARCHAR(128)   NULL CONSTRAINT DF_bit_usuario_host DEFAULT (HOST_NAME()),
    app_name            NVARCHAR(128)   NULL CONSTRAINT DF_bit_usuario_app DEFAULT (APP_NAME()),
    datos_antes         NVARCHAR(MAX)   NULL,
    datos_despues       NVARCHAR(MAX)   NULL,
    CONSTRAINT PK_bit_usuario PRIMARY KEY CLUSTERED (id_bit_usuario),
    CONSTRAINT CK_bit_usuario_accion CHECK (accion IN (N'INSERT', N'UPDATE', N'DELETE'))
);
GO

CREATE TABLE dbo.bit_proveedor (
    id_bit_proveedor    BIGINT          NOT NULL IDENTITY(1, 1),
    id_proveedor        INT             NULL,
    accion              NVARCHAR(20)    NOT NULL,
    fecha_hora          DATETIME2(0)    NOT NULL CONSTRAINT DF_bit_proveedor_fecha DEFAULT (SYSUTCDATETIME()),
    usuario_sql         NVARCHAR(128)   NOT NULL CONSTRAINT DF_bit_proveedor_sql DEFAULT (ORIGINAL_LOGIN()),
    host_name           NVARCHAR(128)   NULL CONSTRAINT DF_bit_proveedor_host DEFAULT (HOST_NAME()),
    app_name            NVARCHAR(128)   NULL CONSTRAINT DF_bit_proveedor_app DEFAULT (APP_NAME()),
    datos_antes         NVARCHAR(MAX)   NULL,
    datos_despues       NVARCHAR(MAX)   NULL,
    CONSTRAINT PK_bit_proveedor PRIMARY KEY CLUSTERED (id_bit_proveedor),
    CONSTRAINT CK_bit_proveedor_accion CHECK (accion IN (N'INSERT', N'UPDATE', N'DELETE'))
);
GO

CREATE TABLE dbo.bit_producto (
    id_bit_producto     BIGINT          NOT NULL IDENTITY(1, 1),
    id_producto         INT             NULL,
    accion              NVARCHAR(20)    NOT NULL,
    fecha_hora          DATETIME2(0)    NOT NULL CONSTRAINT DF_bit_producto_fecha DEFAULT (SYSUTCDATETIME()),
    usuario_sql         NVARCHAR(128)   NOT NULL CONSTRAINT DF_bit_producto_sql DEFAULT (ORIGINAL_LOGIN()),
    host_name           NVARCHAR(128)   NULL CONSTRAINT DF_bit_producto_host DEFAULT (HOST_NAME()),
    app_name            NVARCHAR(128)   NULL CONSTRAINT DF_bit_producto_app DEFAULT (APP_NAME()),
    datos_antes         NVARCHAR(MAX)   NULL,
    datos_despues       NVARCHAR(MAX)   NULL,
    CONSTRAINT PK_bit_producto PRIMARY KEY CLUSTERED (id_bit_producto),
    CONSTRAINT CK_bit_producto_accion CHECK (accion IN (N'INSERT', N'UPDATE', N'DELETE'))
);
GO

CREATE TABLE dbo.bit_evaluacion (
    id_bit_evaluacion   BIGINT          NOT NULL IDENTITY(1, 1),
    id_evaluacion       INT             NULL,
    accion              NVARCHAR(20)    NOT NULL,
    fecha_hora          DATETIME2(0)    NOT NULL CONSTRAINT DF_bit_evaluacion_fecha DEFAULT (SYSUTCDATETIME()),
    usuario_sql         NVARCHAR(128)   NOT NULL CONSTRAINT DF_bit_evaluacion_sql DEFAULT (ORIGINAL_LOGIN()),
    host_name           NVARCHAR(128)   NULL CONSTRAINT DF_bit_evaluacion_host DEFAULT (HOST_NAME()),
    app_name            NVARCHAR(128)   NULL CONSTRAINT DF_bit_evaluacion_app DEFAULT (APP_NAME()),
    datos_antes         NVARCHAR(MAX)   NULL,
    datos_despues       NVARCHAR(MAX)   NULL,
    CONSTRAINT PK_bit_evaluacion PRIMARY KEY CLUSTERED (id_bit_evaluacion),
    CONSTRAINT CK_bit_evaluacion_accion CHECK (accion IN (N'INSERT', N'UPDATE', N'DELETE'))
);
GO

CREATE TABLE dbo.bit_rol (
    id_bit_rol          BIGINT          NOT NULL IDENTITY(1, 1),
    id_rol              INT             NULL,
    accion              NVARCHAR(20)    NOT NULL,
    fecha_hora          DATETIME2(0)    NOT NULL CONSTRAINT DF_bit_rol_fecha DEFAULT (SYSUTCDATETIME()),
    usuario_sql         NVARCHAR(128)   NOT NULL CONSTRAINT DF_bit_rol_sql DEFAULT (ORIGINAL_LOGIN()),
    host_name           NVARCHAR(128)   NULL CONSTRAINT DF_bit_rol_host DEFAULT (HOST_NAME()),
    app_name            NVARCHAR(128)   NULL CONSTRAINT DF_bit_rol_app DEFAULT (APP_NAME()),
    datos_antes         NVARCHAR(MAX)   NULL,
    datos_despues       NVARCHAR(MAX)   NULL,
    CONSTRAINT PK_bit_rol PRIMARY KEY CLUSTERED (id_bit_rol),
    CONSTRAINT CK_bit_rol_accion CHECK (accion IN (N'INSERT', N'UPDATE', N'DELETE'))
);
GO

CREATE NONCLUSTERED INDEX IX_bit_usuario_fecha_hora ON dbo.bit_usuario (fecha_hora DESC);
CREATE NONCLUSTERED INDEX IX_bit_proveedor_fecha_hora ON dbo.bit_proveedor (fecha_hora DESC);
CREATE NONCLUSTERED INDEX IX_bit_producto_fecha_hora ON dbo.bit_producto (fecha_hora DESC);
CREATE NONCLUSTERED INDEX IX_bit_evaluacion_fecha_hora ON dbo.bit_evaluacion (fecha_hora DESC);
CREATE NONCLUSTERED INDEX IX_bit_rol_fecha_hora ON dbo.bit_rol (fecha_hora DESC);
GO

/* ---------- Triggers Usuario (sin PasswordHash) ---------- */
CREATE OR ALTER TRIGGER dbo.trg_bit_usuario_ins ON dbo.Usuario AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_usuario (id_usuario, accion, datos_despues)
    SELECT i.IdUsuario, N'INSERT',
        (SELECT i.IdUsuario, i.IdRol, i.NombreCompleto, i.Email, i.Iniciales,
                i.IdEstadoUsuario, i.IntentosFallidos, i.BloqueadoHasta,
                i.DebeCambiarPassword, i.FechaCreacion, i.FechaModificacion
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_usuario_upd ON dbo.Usuario AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_usuario (id_usuario, accion, datos_antes, datos_despues)
    SELECT i.IdUsuario, N'UPDATE',
        (SELECT d.IdUsuario, d.IdRol, d.NombreCompleto, d.Email, d.Iniciales,
                d.IdEstadoUsuario, d.IntentosFallidos, d.BloqueadoHasta,
                d.DebeCambiarPassword, d.FechaCreacion, d.FechaModificacion
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT i.IdUsuario, i.IdRol, i.NombreCompleto, i.Email, i.Iniciales,
                i.IdEstadoUsuario, i.IntentosFallidos, i.BloqueadoHasta,
                i.DebeCambiarPassword, i.FechaCreacion, i.FechaModificacion
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i INNER JOIN deleted d ON d.IdUsuario = i.IdUsuario;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_usuario_del ON dbo.Usuario AFTER DELETE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_usuario (id_usuario, accion, datos_antes)
    SELECT d.IdUsuario, N'DELETE',
        (SELECT d.IdUsuario, d.IdRol, d.NombreCompleto, d.Email, d.Iniciales,
                d.IdEstadoUsuario, d.IntentosFallidos, d.BloqueadoHasta,
                d.DebeCambiarPassword, d.FechaCreacion, d.FechaModificacion
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted d;
END;
GO

/* ---------- Triggers Proveedor ---------- */
CREATE OR ALTER TRIGGER dbo.trg_bit_proveedor_ins ON dbo.Proveedor AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_proveedor (id_proveedor, accion, datos_despues)
    SELECT i.IdProveedor, N'INSERT',
        (SELECT i.IdProveedor, i.Ruc, i.RazonSocial, i.IdTipoProveedor, i.Rubro,
                i.Contacto, i.Telefono, i.Correo, i.Direccion, i.IdEstadoProveedor,
                i.IdClasificacion, i.PuntajePromedio, i.TotalEvaluaciones,
                i.FechaCreacion, i.FechaModificacion
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_proveedor_upd ON dbo.Proveedor AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_proveedor (id_proveedor, accion, datos_antes, datos_despues)
    SELECT i.IdProveedor, N'UPDATE',
        (SELECT d.IdProveedor, d.Ruc, d.RazonSocial, d.IdTipoProveedor, d.Rubro,
                d.Contacto, d.Telefono, d.Correo, d.Direccion, d.IdEstadoProveedor,
                d.IdClasificacion, d.PuntajePromedio, d.TotalEvaluaciones,
                d.FechaCreacion, d.FechaModificacion
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT i.IdProveedor, i.Ruc, i.RazonSocial, i.IdTipoProveedor, i.Rubro,
                i.Contacto, i.Telefono, i.Correo, i.Direccion, i.IdEstadoProveedor,
                i.IdClasificacion, i.PuntajePromedio, i.TotalEvaluaciones,
                i.FechaCreacion, i.FechaModificacion
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i INNER JOIN deleted d ON d.IdProveedor = i.IdProveedor;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_proveedor_del ON dbo.Proveedor AFTER DELETE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_proveedor (id_proveedor, accion, datos_antes)
    SELECT d.IdProveedor, N'DELETE',
        (SELECT d.IdProveedor, d.Ruc, d.RazonSocial, d.IdTipoProveedor, d.Rubro,
                d.Contacto, d.Telefono, d.Correo, d.Direccion, d.IdEstadoProveedor,
                d.IdClasificacion, d.PuntajePromedio, d.TotalEvaluaciones,
                d.FechaCreacion, d.FechaModificacion
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted d;
END;
GO

/* ---------- Triggers Producto ---------- */
CREATE OR ALTER TRIGGER dbo.trg_bit_producto_ins ON dbo.Producto AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_producto (id_producto, accion, datos_despues)
    SELECT i.IdProducto, N'INSERT',
        (SELECT i.IdProducto, i.Codigo, i.Nombre, i.Categoria, i.IdUnidad, i.Activo
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_producto_upd ON dbo.Producto AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_producto (id_producto, accion, datos_antes, datos_despues)
    SELECT i.IdProducto, N'UPDATE',
        (SELECT d.IdProducto, d.Codigo, d.Nombre, d.Categoria, d.IdUnidad, d.Activo
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT i.IdProducto, i.Codigo, i.Nombre, i.Categoria, i.IdUnidad, i.Activo
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i INNER JOIN deleted d ON d.IdProducto = i.IdProducto;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_producto_del ON dbo.Producto AFTER DELETE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_producto (id_producto, accion, datos_antes)
    SELECT d.IdProducto, N'DELETE',
        (SELECT d.IdProducto, d.Codigo, d.Nombre, d.Categoria, d.IdUnidad, d.Activo
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted d;
END;
GO

/* ---------- Triggers Evaluacion ---------- */
CREATE OR ALTER TRIGGER dbo.trg_bit_evaluacion_ins ON dbo.Evaluacion AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_evaluacion (id_evaluacion, accion, datos_despues)
    SELECT i.IdEvaluacion, N'INSERT',
        (SELECT i.IdEvaluacion, i.IdProveedor, i.IdProducto, i.Periodo, i.OrdenCompra,
                i.FechaLimite, i.FechaEvaluacion, i.PuntajeFinal, i.IdEstadoEvaluacion,
                i.NivelResultado, i.ResultadoTexto, i.Observaciones, i.IdUsuarioCreador,
                i.FechaCreacion, i.FechaModificacion
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_evaluacion_upd ON dbo.Evaluacion AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_evaluacion (id_evaluacion, accion, datos_antes, datos_despues)
    SELECT i.IdEvaluacion, N'UPDATE',
        (SELECT d.IdEvaluacion, d.IdProveedor, d.IdProducto, d.Periodo, d.OrdenCompra,
                d.FechaLimite, d.FechaEvaluacion, d.PuntajeFinal, d.IdEstadoEvaluacion,
                d.NivelResultado, d.ResultadoTexto, d.Observaciones, d.IdUsuarioCreador,
                d.FechaCreacion, d.FechaModificacion
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT i.IdEvaluacion, i.IdProveedor, i.IdProducto, i.Periodo, i.OrdenCompra,
                i.FechaLimite, i.FechaEvaluacion, i.PuntajeFinal, i.IdEstadoEvaluacion,
                i.NivelResultado, i.ResultadoTexto, i.Observaciones, i.IdUsuarioCreador,
                i.FechaCreacion, i.FechaModificacion
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i INNER JOIN deleted d ON d.IdEvaluacion = i.IdEvaluacion;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_evaluacion_del ON dbo.Evaluacion AFTER DELETE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_evaluacion (id_evaluacion, accion, datos_antes)
    SELECT d.IdEvaluacion, N'DELETE',
        (SELECT d.IdEvaluacion, d.IdProveedor, d.IdProducto, d.Periodo, d.OrdenCompra,
                d.FechaLimite, d.FechaEvaluacion, d.PuntajeFinal, d.IdEstadoEvaluacion,
                d.NivelResultado, d.ResultadoTexto, d.Observaciones, d.IdUsuarioCreador,
                d.FechaCreacion, d.FechaModificacion
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted d;
END;
GO

/* ---------- Triggers Rol ---------- */
CREATE OR ALTER TRIGGER dbo.trg_bit_rol_ins ON dbo.Rol AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_rol (id_rol, accion, datos_despues)
    SELECT i.IdRol, N'INSERT',
        (SELECT i.IdRol, i.Nombre, i.Descripcion, i.Activo
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_rol_upd ON dbo.Rol AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_rol (id_rol, accion, datos_antes, datos_despues)
    SELECT i.IdRol, N'UPDATE',
        (SELECT d.IdRol, d.Nombre, d.Descripcion, d.Activo
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT i.IdRol, i.Nombre, i.Descripcion, i.Activo
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i INNER JOIN deleted d ON d.IdRol = i.IdRol;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_rol_del ON dbo.Rol AFTER DELETE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_rol (id_rol, accion, datos_antes)
    SELECT d.IdRol, N'DELETE',
        (SELECT d.IdRol, d.Nombre, d.Descripcion, d.Activo
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted d;
END;
GO

PRINT N'Script 10 OK: bit_usuario, bit_proveedor, bit_producto, bit_evaluacion, bit_rol + triggers.';
GO

/* ========== FIN: 10_bitacora_tablas_triggers.sql ========== */
