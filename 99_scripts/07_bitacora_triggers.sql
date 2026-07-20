/*
  FILASUR - Script 07: Bitácoras por triggers
  Tablas auditadas: Usuario, Proveedor, Producto, Evaluacion, Rol
  Convención PK: id_bit_<entidad> (IDENTITY)

  Ejecutar después de crear tablas base (02_tablas.sql).
*/
USE FilasurProveedores;
GO

/* ===================== TABLAS DE BITÁCORA ===================== */

IF OBJECT_ID('dbo.bit_usuario', 'U') IS NULL
BEGIN
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
END;
GO

IF OBJECT_ID('dbo.bit_proveedor', 'U') IS NULL
BEGIN
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
END;
GO

IF OBJECT_ID('dbo.bit_producto', 'U') IS NULL
BEGIN
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
END;
GO

IF OBJECT_ID('dbo.bit_evaluacion', 'U') IS NULL
BEGIN
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
END;
GO

IF OBJECT_ID('dbo.bit_rol', 'U') IS NULL
BEGIN
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
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_bit_usuario_fecha_hora' AND object_id = OBJECT_ID('dbo.bit_usuario'))
    CREATE NONCLUSTERED INDEX IX_bit_usuario_fecha_hora ON dbo.bit_usuario (fecha_hora DESC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_bit_proveedor_fecha_hora' AND object_id = OBJECT_ID('dbo.bit_proveedor'))
    CREATE NONCLUSTERED INDEX IX_bit_proveedor_fecha_hora ON dbo.bit_proveedor (fecha_hora DESC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_bit_producto_fecha_hora' AND object_id = OBJECT_ID('dbo.bit_producto'))
    CREATE NONCLUSTERED INDEX IX_bit_producto_fecha_hora ON dbo.bit_producto (fecha_hora DESC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_bit_evaluacion_fecha_hora' AND object_id = OBJECT_ID('dbo.bit_evaluacion'))
    CREATE NONCLUSTERED INDEX IX_bit_evaluacion_fecha_hora ON dbo.bit_evaluacion (fecha_hora DESC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_bit_rol_fecha_hora' AND object_id = OBJECT_ID('dbo.bit_rol'))
    CREATE NONCLUSTERED INDEX IX_bit_rol_fecha_hora ON dbo.bit_rol (fecha_hora DESC);
GO

/* ===================== TRIGGERS USUARIO ===================== */
/* No se audita PasswordHash por seguridad */

CREATE OR ALTER TRIGGER dbo.trg_bit_usuario_ins
ON dbo.Usuario
AFTER INSERT
AS
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

CREATE OR ALTER TRIGGER dbo.trg_bit_usuario_upd
ON dbo.Usuario
AFTER UPDATE
AS
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
    INSERT INTO dbo.bit_usuario (id_usuario, accion, datos_antes)
    SELECT d.IdUsuario, N'DELETE',
        (SELECT d.IdUsuario, d.IdRol, d.NombreCompleto, d.Email, d.Iniciales,
                d.IdEstadoUsuario, d.IntentosFallidos, d.BloqueadoHasta,
                d.DebeCambiarPassword, d.FechaCreacion, d.FechaModificacion
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted d;
END;
GO

/* ===================== TRIGGERS PROVEEDOR ===================== */

CREATE OR ALTER TRIGGER dbo.trg_bit_proveedor_ins
ON dbo.Proveedor
AFTER INSERT
AS
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

CREATE OR ALTER TRIGGER dbo.trg_bit_proveedor_upd
ON dbo.Proveedor
AFTER UPDATE
AS
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

/* ===================== TRIGGERS PRODUCTO ===================== */

CREATE OR ALTER TRIGGER dbo.trg_bit_producto_ins
ON dbo.Producto
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_producto (id_producto, accion, datos_despues)
    SELECT i.IdProducto, N'INSERT',
        (SELECT i.IdProducto, i.Codigo, i.Nombre, i.Categoria, i.IdUnidad, i.Activo
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_producto_upd
ON dbo.Producto
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_producto (id_producto, accion, datos_antes, datos_despues)
    SELECT i.IdProducto, N'UPDATE',
        (SELECT d.IdProducto, d.Codigo, d.Nombre, d.Categoria, d.IdUnidad, d.Activo
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT i.IdProducto, i.Codigo, i.Nombre, i.Categoria, i.IdUnidad, i.Activo
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i
    INNER JOIN deleted d ON d.IdProducto = i.IdProducto;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_producto_del
ON dbo.Producto
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_producto (id_producto, accion, datos_antes)
    SELECT d.IdProducto, N'DELETE',
        (SELECT d.IdProducto, d.Codigo, d.Nombre, d.Categoria, d.IdUnidad, d.Activo
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted d;
END;
GO

/* ===================== TRIGGERS EVALUACION ===================== */

CREATE OR ALTER TRIGGER dbo.trg_bit_evaluacion_ins
ON dbo.Evaluacion
AFTER INSERT
AS
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

CREATE OR ALTER TRIGGER dbo.trg_bit_evaluacion_upd
ON dbo.Evaluacion
AFTER UPDATE
AS
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

/* ===================== TRIGGERS ROL ===================== */

CREATE OR ALTER TRIGGER dbo.trg_bit_rol_ins
ON dbo.Rol
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_rol (id_rol, accion, datos_despues)
    SELECT i.IdRol, N'INSERT',
        (SELECT i.IdRol, i.Nombre, i.Descripcion, i.Activo
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_rol_upd
ON dbo.Rol
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_rol (id_rol, accion, datos_antes, datos_despues)
    SELECT i.IdRol, N'UPDATE',
        (SELECT d.IdRol, d.Nombre, d.Descripcion, d.Activo
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT i.IdRol, i.Nombre, i.Descripcion, i.Activo
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i
    INNER JOIN deleted d ON d.IdRol = i.IdRol;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_bit_rol_del
ON dbo.Rol
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.bit_rol (id_rol, accion, datos_antes)
    SELECT d.IdRol, N'DELETE',
        (SELECT d.IdRol, d.Nombre, d.Descripcion, d.Activo
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted d;
END;
GO

PRINT N'Bitácoras bit_usuario, bit_proveedor, bit_producto, bit_evaluacion, bit_rol y triggers OK.';
GO
