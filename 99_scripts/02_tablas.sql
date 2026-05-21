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
    FechaCarga          DATE            NOT NULL CONSTRAINT DF_Documento_FechaCarga DEFAULT (CAST(SYSUTCDATETIME() AS DATE)),
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
