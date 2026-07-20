/*
  Corrige fn_ContarAreasPendientes: no tratar PuntajeFinal como evaluación cerrada.
  PuntajeFinal se actualiza en cada guardado parcial de criterios (Calidad/Compras/Logística).

  Ejecutar en BD existente (una sola vez).
*/
SET NOCOUNT ON;
GO

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

PRINT N'fn_ContarAreasPendientes actualizada.';
GO
