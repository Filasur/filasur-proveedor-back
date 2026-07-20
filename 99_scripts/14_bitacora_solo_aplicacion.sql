/*
  Bitácora del portal: solo acciones de aplicación (dbo.Bitacora).
  La auditoría técnica bit_* sigue en BD para DBA, pero ya no se mezcla en esta pantalla.

  Ejecutar en BD existente (una sola vez).
*/
SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Bitacora_Listar
    @Top INT = 300
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Top)
        CAST(b.IdBitacora AS NVARCHAR(40)) AS id,
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

PRINT N'sp_Bitacora_Listar: solo bitácora de aplicación.';
GO
