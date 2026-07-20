/*
  FILASUR - Parche para BD ya desplegada
  Actualiza dashboard (docs por vencer) + bitácora en hora Perú.
  No recrea tablas. Ejecutar en FilasurProveedores.
*/
USE FilasurProveedores;
GO

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

UPDATE dbo.ConfiguracionSistema
SET DiasAlertaVencimiento = 15
WHERE IdConfig = 1 AND ISNULL(DiasAlertaVencimiento, 0) < 15;
GO

PRINT N'Parche aplicado: dashboard + bitácora hora Perú.';
GO