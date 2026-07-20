/*
  Actualiza sp_Evaluacion_GuardarCriterios para MERGE (upsert) por criterio
  en lugar de DELETE de todos los puntajes.

  Necesario para evaluación multi-rol: Calidad/Logística/Compras
  guardan solo sus áreas sin borrar las del resto.

  Ejecutar en BD existente (una sola vez).
*/

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Evaluacion_GuardarCriterios
    @IdEvaluacion INT,
    @CriteriosJson NVARCHAR(MAX)  -- [{"idCriterio":1,"puntaje":90},...]
AS
BEGIN
    SET NOCOUNT ON;

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

PRINT N'sp_Evaluacion_GuardarCriterios actualizado a MERGE.';
GO
