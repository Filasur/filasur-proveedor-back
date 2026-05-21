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
    /* Requiere OPENJSON (SQL Server 2016+) */
    DELETE FROM dbo.EvaluacionCriterio WHERE IdEvaluacion = @IdEvaluacion;

    INSERT INTO dbo.EvaluacionCriterio (IdEvaluacion, IdCriterio, Puntaje, PuntajePonderado)
    SELECT
        @IdEvaluacion,
        j.IdCriterio,
        j.Puntaje,
        j.Puntaje * c.Peso / 100.0
    FROM OPENJSON(@CriteriosJson)
    WITH (
        IdCriterio INT '$.idCriterio',
        Puntaje DECIMAL(5, 2) '$.puntaje'
    ) AS j
    INNER JOIN dbo.CriterioEvaluacion c ON c.IdCriterio = j.IdCriterio;

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
            WHEN N'APROBADO' THEN N'Proveedor apto para registro en Exactus ERP'
            WHEN N'OBSERVADO' THEN N'Proveedor con observaciones; requiere seguimiento'
            ELSE N'Proveedor no cumple umbral mínimo'
        END,
        FechaModificacion = SYSUTCDATETIME()
    WHERE IdEvaluacion = @IdEvaluacion;

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

    /* Áreas */
    SELECT
        ea.Area AS area,
        u.NombreCompleto AS evaluador,
        ea.Puntaje AS puntaje,
        ea.Peso AS peso,
        ea.PuntajePonderado AS ponderado,
        ea.Observaciones AS observaciones
    FROM dbo.EvaluacionArea ea
    LEFT JOIN dbo.Usuario u ON u.IdUsuario = ea.IdUsuarioEvaluador
    WHERE ea.IdEvaluacion = @IdEvaluacion;

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
        (SELECT AVG(PuntajePromedio) FROM dbo.Proveedor WHERE PuntajePromedio IS NOT NULL) AS puntajePromedio;
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
    @Top INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top)
        b.IdBitacora AS id,
        CONVERT(VARCHAR(16), b.FechaHora, 103) + N' ' + CONVERT(VARCHAR(5), b.FechaHora, 108) AS fecha,
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
        IdProveedor, NombreArchivo, TipoArchivo, TamanoBytes, RutaAlmacenamiento
    )
    VALUES (
        @IdProveedor, @NombreArchivo, @TipoArchivo, @TamanoBytes, @RutaAlmacenamiento
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
        d.NombreArchivo AS nombre,
        d.TipoArchivo AS tipo,
        d.TamanoBytes AS tamanoBytes,
        d.RutaAlmacenamiento AS ruta,
        CONVERT(VARCHAR(10), d.FechaCarga, 103) AS fecha
    FROM dbo.DocumentoProveedor d
    INNER JOIN dbo.Proveedor p ON p.IdProveedor = d.IdProveedor
    WHERE (@IdProveedor IS NULL OR d.IdProveedor = @IdProveedor)
      AND (
          @Busqueda IS NULL
          OR p.RazonSocial LIKE N'%' + @Busqueda + N'%'
          OR d.NombreArchivo LIKE N'%' + @Busqueda + N'%'
      )
    ORDER BY d.FechaCarga DESC, d.IdDocumento DESC;
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
        b.IdBitacora AS id,
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
        CASE WHEN u.IdEstadoUsuario = 1 THEN N'Activo' ELSE N'Inactivo' END AS estado
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

    INSERT INTO dbo.Usuario (IdRol, NombreCompleto, Email, PasswordHash, Iniciales, IdEstadoUsuario)
    VALUES (
        @IdRol,
        @NombreCompleto,
        @Email,
        @PasswordHash,
        UPPER(LEFT(@NombreCompleto, 1)) + ISNULL(UPPER(SUBSTRING(@NombreCompleto, CHARINDEX(N' ', @NombreCompleto) + 1, 1)), N''),
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
    @Estado NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Estado = N'Todos'
        SET @Estado = NULL;

    SELECT
        e.IdEvaluacion AS id,
        p.RazonSocial AS proveedor,
        pr.Nombre AS producto,
        CONVERT(VARCHAR(10), e.FechaEvaluacion, 103) AS fechaEvaluacion,
        e.PuntajeFinal AS puntajeFinal,
        ce.Nombre AS estado
    FROM dbo.Evaluacion e
    INNER JOIN dbo.Proveedor p ON p.IdProveedor = e.IdProveedor
    INNER JOIN dbo.CatEstadoEvaluacion ce ON ce.IdEstadoEvaluacion = e.IdEstadoEvaluacion
    LEFT JOIN dbo.Producto pr ON pr.IdProducto = e.IdProducto
    WHERE @Estado IS NULL OR ce.Nombre = @Estado
    ORDER BY e.FechaCreacion DESC;

    SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN ce.Nombre = N'Aprobado' THEN 1 ELSE 0 END) AS aprobados,
        SUM(CASE WHEN ce.Nombre = N'Observado' THEN 1 ELSE 0 END) AS observados,
        SUM(CASE WHEN ce.Nombre = N'Rechazado' THEN 1 ELSE 0 END) AS rechazados
    FROM dbo.Evaluacion e
    INNER JOIN dbo.CatEstadoEvaluacion ce ON ce.IdEstadoEvaluacion = e.IdEstadoEvaluacion
    WHERE @Estado IS NULL OR ce.Nombre = @Estado;
END;
GO

PRINT N'Procedimientos almacenados creados correctamente.';
GO
