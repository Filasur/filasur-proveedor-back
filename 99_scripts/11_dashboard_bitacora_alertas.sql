/*
  FILASUR - Script 11: Dashboard documentos por vencer + bitácora unificada
  Ejecutar en BD existente DESPUÉS de 08, 09 y 10 (requiere tablas bit_*).
*/
USE FilasurProveedores;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Dashboard_Resumen
AS
BEGIN
    SET NOCOUNT ON;

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
           AND d.FechaVencimiento <= DATEADD(DAY, @DiasAlerta, CAST(SYSUTCDATETIME() AS DATE))
        ) AS documentosPorVencer;

    /* 2. Evaluaciones recientes */
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

    /* 3. Evaluaciones por vencer */
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
      AND e.FechaLimite <= DATEADD(DAY, @DiasAlerta, CAST(SYSUTCDATETIME() AS DATE))
    ORDER BY e.FechaLimite ASC;

    /* 4. Evolución mensual */
    ;WITH UltimosMeses AS (
        SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2
        UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
    ),
    Meses AS (
        SELECT DATEADD(MONTH, -n, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)) AS PrimerDiaMes
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
            WHEN d.FechaVencimiento < CAST(SYSUTCDATETIME() AS DATE) THEN N'Vencido'
            ELSE N'Por vencer'
        END AS estado
    FROM dbo.DocumentoProveedor d
    INNER JOIN dbo.Proveedor p ON p.IdProveedor = d.IdProveedor
    WHERE d.FechaVencimiento IS NOT NULL
      AND d.FechaVencimiento <= DATEADD(DAY, @DiasAlerta, CAST(SYSUTCDATETIME() AS DATE))
    ORDER BY d.FechaVencimiento ASC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Bitacora_Listar
    @Top INT = 200
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Combined AS (
        SELECT
            CAST(N'A-' + CAST(b.IdBitacora AS NVARCHAR(20)) AS NVARCHAR(40)) AS id,
            b.FechaHora AS fechaOrden,
            CONVERT(VARCHAR(16), b.FechaHora, 103) + N' ' + CONVERT(VARCHAR(5), b.FechaHora, 108) AS fecha,
            ISNULL(u.NombreCompleto, N'Sistema') AS usuario,
            b.Accion AS accion,
            b.Detalle AS detalle,
            b.Modulo AS modulo
        FROM dbo.Bitacora b
        LEFT JOIN dbo.Usuario u ON u.IdUsuario = b.IdUsuario

        UNION ALL

        SELECT
            CAST(N'U-' + CAST(bu.id_bit_usuario AS NVARCHAR(20)) AS NVARCHAR(40)),
            bu.fecha_hora,
            CONVERT(VARCHAR(16), bu.fecha_hora, 103) + N' ' + CONVERT(VARCHAR(5), bu.fecha_hora, 108),
            ISNULL(bu.usuario_sql, N'SQL'),
            bu.accion,
            LEFT(ISNULL(bu.datos_despues, bu.datos_antes), 500),
            N'Auditoría Usuario'
        FROM dbo.bit_usuario bu

        UNION ALL

        SELECT
            CAST(N'P-' + CAST(bp.id_bit_proveedor AS NVARCHAR(20)) AS NVARCHAR(40)),
            bp.fecha_hora,
            CONVERT(VARCHAR(16), bp.fecha_hora, 103) + N' ' + CONVERT(VARCHAR(5), bp.fecha_hora, 108),
            ISNULL(bp.usuario_sql, N'SQL'),
            bp.accion,
            LEFT(ISNULL(bp.datos_despues, bp.datos_antes), 500),
            N'Auditoría Proveedor'
        FROM dbo.bit_proveedor bp

        UNION ALL

        SELECT
            CAST(N'R-' + CAST(br.id_bit_producto AS NVARCHAR(20)) AS NVARCHAR(40)),
            br.fecha_hora,
            CONVERT(VARCHAR(16), br.fecha_hora, 103) + N' ' + CONVERT(VARCHAR(5), br.fecha_hora, 108),
            ISNULL(br.usuario_sql, N'SQL'),
            br.accion,
            LEFT(ISNULL(br.datos_despues, br.datos_antes), 500),
            N'Auditoría Producto'
        FROM dbo.bit_producto br

        UNION ALL

        SELECT
            CAST(N'E-' + CAST(be.id_bit_evaluacion AS NVARCHAR(20)) AS NVARCHAR(40)),
            be.fecha_hora,
            CONVERT(VARCHAR(16), be.fecha_hora, 103) + N' ' + CONVERT(VARCHAR(5), be.fecha_hora, 108),
            ISNULL(be.usuario_sql, N'SQL'),
            be.accion,
            LEFT(ISNULL(be.datos_despues, be.datos_antes), 500),
            N'Auditoría Evaluación'
        FROM dbo.bit_evaluacion be

        UNION ALL

        SELECT
            CAST(N'L-' + CAST(bl.id_bit_rol AS NVARCHAR(20)) AS NVARCHAR(40)),
            bl.fecha_hora,
            CONVERT(VARCHAR(16), bl.fecha_hora, 103) + N' ' + CONVERT(VARCHAR(5), bl.fecha_hora, 108),
            ISNULL(bl.usuario_sql, N'SQL'),
            bl.accion,
            LEFT(ISNULL(bl.datos_despues, bl.datos_antes), 500),
            N'Auditoría Rol'
        FROM dbo.bit_rol bl
    )
    SELECT TOP (@Top)
        id,
        fecha,
        usuario,
        accion,
        detalle,
        modulo
    FROM Combined
    ORDER BY fechaOrden DESC;
END;
GO

PRINT N'Script 11 OK: dashboard documentos + bitácora unificada.';
GO

/* Ampliar RolModulo para que coincida con menú real del front */
DECLARE @IdCompras INT = (SELECT IdRol FROM dbo.Rol WHERE Nombre = N'Compras');
DECLARE @IdAdmin INT = (SELECT IdRol FROM dbo.Rol WHERE Nombre = N'Administrador');

IF @IdCompras IS NOT NULL
BEGIN
    INSERT INTO dbo.RolModulo (IdRol, Modulo)
    SELECT @IdCompras, v.Modulo
    FROM (VALUES
        (N'Criterios'), (N'Unidades'), (N'Productos'), (N'Configuración')
    ) AS v(Modulo)
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.RolModulo rm
        WHERE rm.IdRol = @IdCompras AND rm.Modulo = v.Modulo
    );
END;

IF @IdAdmin IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM dbo.RolModulo WHERE IdRol = @IdAdmin AND Modulo = N'Todos')
BEGIN
    INSERT INTO dbo.RolModulo (IdRol, Modulo) VALUES (@IdAdmin, N'Todos');
END;
GO

PRINT N'RolModulo ampliado para Compras/Administrador.';
GO
