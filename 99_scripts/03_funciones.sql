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

/* Áreas pendientes: áreas de criterios activos sin fila en EvaluacionArea */
CREATE OR ALTER FUNCTION dbo.fn_ContarAreasPendientes (@IdEvaluacion INT)
RETURNS INT
AS
BEGIN
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
