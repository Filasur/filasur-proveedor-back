/*
  FILASUR - Script 07: Bitácoras por triggers
  Ejecutar después de crear tablas y procedimientos.
*/
USE FilasurProveedores;
GO

/* ===================== TABLAS DE BITÁCORA ===================== */

IF OBJECT_ID('dbo.bit_usuario', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.bit_usuario (
        IdBitUsuario        BIGINT          NOT NULL IDENTITY(1, 1),
        IdUsuario           INT             NULL,
        Accion              NVARCHAR(20)    NOT NULL,
        FechaHora           DATETIME2(0)    NOT NULL CONSTRAINT DF_bit_usuario_Fecha DEFAULT (SYSUTCDATETIME()),
        UsuarioSql          NVARCHAR(128)   NOT NULL CONSTRAINT DF_bit_usuario_UsuarioSql DEFAULT (ORIGINAL_LOGIN()),
        HostName            NVARCHAR(128)   NULL CONSTRAINT DF_bit_usuario_Host DEFAULT (HOST_NAME()),
        AppName             NVARCHAR(128)   NULL CONSTRAINT DF_bit_usuario_App DEFAULT (APP_NAME()),
        DatosAntes          NVARCHAR(MAX)   NULL,
        DatosDespues        NVARCHAR(MAX)   NULL,
        CONSTRAINT PK_bit_usuario PRIMARY KEY CLUSTERED (IdBitUsuario),
        CONSTRAINT CK_bit_usuario_Accion CHECK (Accion IN (N'INSERT', N'UPDATE', N'DELETE'))
    );
END;
GO

IF OBJECT_ID('dbo.bit_proveedor', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.bit_proveedor (
        IdBitProveedor      BIGINT          NOT NULL IDENTITY(1, 1),
        IdProveedor         INT             NULL,
        Accion              NVARCHAR(20)    NOT NULL,
        FechaHora           DATETIME2(0)    NOT NULL CONSTRAINT DF_bit_proveedor_Fecha DEFAULT (SYSUTCDATETIME()),
        UsuarioSql          NVARCHAR(128)   NOT NULL CONSTRAINT DF_bit_proveedor_UsuarioSql DEFAULT (ORIGINAL_LOGIN()),
        HostName            NVARCHAR(128)   NULL CONSTRAINT DF_bit_proveedor_Host DEFAULT (HOST_NAME()),
        AppName             NVARCHAR(128)   NULL CONSTRAINT DF_bit_proveedor_App DEFAULT (APP_NAME()),
        DatosAntes          NVARCHAR(MAX)   NULL,
        DatosDespues        NVARCHAR(MAX)   NULL,
        CONSTRAINT PK_bit_proveedor PRIMARY KEY CLUSTERED (IdBitProveedor),
        CONSTRAINT CK_bit_proveedor_Accion CHECK (Accion IN (N'INSERT', N'UPDATE', N'DELETE'))
    );
END;
GO

IF OBJECT_ID('dbo.bit_evaluacion', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.bit_evaluacion (
        IdBitEvaluacion     BIGINT          NOT NULL IDENTITY(1, 1),
        IdEvaluacion        INT             NULL,
        Accion              NVARCHAR(20)    NOT NULL,
        FechaHora           DATETIME2(0)    NOT NULL CONSTRAINT DF_bit_evaluacion_Fecha DEFAULT (SYSUTCDATETIME()),
        UsuarioSql          NVARCHAR(128)   NOT NULL CONSTRAINT DF_bit_evaluacion_UsuarioSql DEFAULT (ORIGINAL_LOGIN()),
        HostName            NVARCHAR(128)   NULL CONSTRAINT DF_bit_evaluacion_Host DEFAULT (HOST_NAME()),
        AppName             NVARCHAR(128)   NULL CONSTRAINT DF_bit_evaluacion_App DEFAULT (APP_NAME()),
        DatosAntes          NVARCHAR(MAX)   NULL,
        DatosDespues        NVARCHAR(MAX)   NULL,
        CONSTRAINT PK_bit_evaluacion PRIMARY KEY CLUSTERED (IdBitEvaluacion),
        CONSTRAINT CK_bit_evaluacion_Accion CHECK (Accion IN (N'INSERT', N'UPDATE', N'DELETE'))
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_bit_usuario_FechaHora' AND object_id = OBJECT_ID('dbo.bit_usuario'))
    CREATE NONCLUSTERED INDEX IX_bit_usuario_FechaHora ON dbo.bit_usuario (FechaHora DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_bit_proveedor_FechaHora' AND object_id = OBJECT_ID('dbo.bit_proveedor'))
    CREATE NONCLUSTERED INDEX IX_bit_proveedor_FechaHora ON dbo.bit_proveedor (FechaHora DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_bit_evaluacion_FechaHora' AND object_id = OBJECT_ID('dbo.bit_evaluacion'))
    CREATE NONCLUSTERED INDEX IX_bit_evaluacion_FechaHora ON dbo.bit_evaluacion (FechaHora DESC);
GO

/* ===================== TRIGGERS ===================== */

CREATE OR ALTER TRIGGER dbo.trg_bit_usuario_ins
ON dbo.Usuario
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.bit_usuario (IdUsuario, Accion, DatosDespues)
    SELECT
        i.IdUsuario,
        N'INSERT',
        (
            SELECT
                i.IdUsuario,
                i.IdRol,
                i.NombreCompleto,
                i.Email,
                i.Iniciales,
                i.IdEstadoUsuario,
                i.IntentosFallidos,
                i.BloqueadoHasta,
                i.DebeCambiarPassword,
                i.FechaCreacion,
                i.FechaModificacion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    FROM inserted i;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_usuario_upd
ON dbo.Usuario
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.bit_usuario (IdUsuario, Accion, DatosAntes, DatosDespues)
    SELECT
        i.IdUsuario,
        N'UPDATE',
        (
            SELECT
                d.IdUsuario,
                d.IdRol,
                d.NombreCompleto,
                d.Email,
                d.Iniciales,
                d.IdEstadoUsuario,
                d.IntentosFallidos,
                d.BloqueadoHasta,
                d.DebeCambiarPassword,
                d.FechaCreacion,
                d.FechaModificacion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ),
        (
            SELECT
                i.IdUsuario,
                i.IdRol,
                i.NombreCompleto,
                i.Email,
                i.Iniciales,
                i.IdEstadoUsuario,
                i.IntentosFallidos,
                i.BloqueadoHasta,
                i.DebeCambiarPassword,
                i.FechaCreacion,
                i.FechaModificacion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    FROM inserted i
    INNER JOIN deleted d ON d.IdUsuario = i.IdUsuario;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_usuario_del
ON dbo.Usuario
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.bit_usuario (IdUsuario, Accion, DatosAntes)
    SELECT
        d.IdUsuario,
        N'DELETE',
        (
            SELECT
                d.IdUsuario,
                d.IdRol,
                d.NombreCompleto,
                d.Email,
                d.Iniciales,
                d.IdEstadoUsuario,
                d.IntentosFallidos,
                d.BloqueadoHasta,
                d.DebeCambiarPassword,
                d.FechaCreacion,
                d.FechaModificacion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    FROM deleted d;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_proveedor_ins
ON dbo.Proveedor
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.bit_proveedor (IdProveedor, Accion, DatosDespues)
    SELECT i.IdProveedor, N'INSERT',
        (
            SELECT
                i.IdProveedor,
                i.Ruc,
                i.RazonSocial,
                i.IdTipoProveedor,
                i.Rubro,
                i.Contacto,
                i.Telefono,
                i.Correo,
                i.Direccion,
                i.IdEstadoProveedor,
                i.IdClasificacion,
                i.PuntajePromedio,
                i.TotalEvaluaciones,
                i.FechaCreacion,
                i.FechaModificacion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    FROM inserted i;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_proveedor_upd
ON dbo.Proveedor
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.bit_proveedor (IdProveedor, Accion, DatosAntes, DatosDespues)
    SELECT i.IdProveedor, N'UPDATE',
        (
            SELECT
                d.IdProveedor,
                d.Ruc,
                d.RazonSocial,
                d.IdTipoProveedor,
                d.Rubro,
                d.Contacto,
                d.Telefono,
                d.Correo,
                d.Direccion,
                d.IdEstadoProveedor,
                d.IdClasificacion,
                d.PuntajePromedio,
                d.TotalEvaluaciones,
                d.FechaCreacion,
                d.FechaModificacion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ),
        (
            SELECT
                i.IdProveedor,
                i.Ruc,
                i.RazonSocial,
                i.IdTipoProveedor,
                i.Rubro,
                i.Contacto,
                i.Telefono,
                i.Correo,
                i.Direccion,
                i.IdEstadoProveedor,
                i.IdClasificacion,
                i.PuntajePromedio,
                i.TotalEvaluaciones,
                i.FechaCreacion,
                i.FechaModificacion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    FROM inserted i
    INNER JOIN deleted d ON d.IdProveedor = i.IdProveedor;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_proveedor_del
ON dbo.Proveedor
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.bit_proveedor (IdProveedor, Accion, DatosAntes)
    SELECT d.IdProveedor, N'DELETE',
        (
            SELECT
                d.IdProveedor,
                d.Ruc,
                d.RazonSocial,
                d.IdTipoProveedor,
                d.Rubro,
                d.Contacto,
                d.Telefono,
                d.Correo,
                d.Direccion,
                d.IdEstadoProveedor,
                d.IdClasificacion,
                d.PuntajePromedio,
                d.TotalEvaluaciones,
                d.FechaCreacion,
                d.FechaModificacion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    FROM deleted d;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_evaluacion_ins
ON dbo.Evaluacion
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.bit_evaluacion (IdEvaluacion, Accion, DatosDespues)
    SELECT i.IdEvaluacion, N'INSERT',
        (
            SELECT
                i.IdEvaluacion,
                i.IdProveedor,
                i.IdProducto,
                i.Periodo,
                i.OrdenCompra,
                i.FechaLimite,
                i.FechaEvaluacion,
                i.PuntajeFinal,
                i.IdEstadoEvaluacion,
                i.NivelResultado,
                i.ResultadoTexto,
                i.Observaciones,
                i.IdUsuarioCreador,
                i.FechaCreacion,
                i.FechaModificacion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    FROM inserted i;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_evaluacion_upd
ON dbo.Evaluacion
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.bit_evaluacion (IdEvaluacion, Accion, DatosAntes, DatosDespues)
    SELECT i.IdEvaluacion, N'UPDATE',
        (
            SELECT
                d.IdEvaluacion,
                d.IdProveedor,
                d.IdProducto,
                d.Periodo,
                d.OrdenCompra,
                d.FechaLimite,
                d.FechaEvaluacion,
                d.PuntajeFinal,
                d.IdEstadoEvaluacion,
                d.NivelResultado,
                d.ResultadoTexto,
                d.Observaciones,
                d.IdUsuarioCreador,
                d.FechaCreacion,
                d.FechaModificacion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ),
        (
            SELECT
                i.IdEvaluacion,
                i.IdProveedor,
                i.IdProducto,
                i.Periodo,
                i.OrdenCompra,
                i.FechaLimite,
                i.FechaEvaluacion,
                i.PuntajeFinal,
                i.IdEstadoEvaluacion,
                i.NivelResultado,
                i.ResultadoTexto,
                i.Observaciones,
                i.IdUsuarioCreador,
                i.FechaCreacion,
                i.FechaModificacion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    FROM inserted i
    INNER JOIN deleted d ON d.IdEvaluacion = i.IdEvaluacion;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_evaluacion_del
ON dbo.Evaluacion
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.bit_evaluacion (IdEvaluacion, Accion, DatosAntes)
    SELECT d.IdEvaluacion, N'DELETE',
        (
            SELECT
                d.IdEvaluacion,
                d.IdProveedor,
                d.IdProducto,
                d.Periodo,
                d.OrdenCompra,
                d.FechaLimite,
                d.FechaEvaluacion,
                d.PuntajeFinal,
                d.IdEstadoEvaluacion,
                d.NivelResultado,
                d.ResultadoTexto,
                d.Observaciones,
                d.IdUsuarioCreador,
                d.FechaCreacion,
                d.FechaModificacion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    FROM deleted d;
END;
GO

PRINT N'Tablas de bitácora y triggers creados correctamente.';
GO
