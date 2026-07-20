/*
  Amplía módulos de Logística: Proveedores + Reportes
  (alineado con AppRoles.Reportes / GestionProveedores y menú del front).

  Ejecutar en BD existente (una sola vez). Seguro si ya existen.
*/
SET NOCOUNT ON;
GO

DECLARE @IdLogistica TINYINT = (SELECT IdRol FROM dbo.Rol WHERE Nombre = N'Logística');

IF @IdLogistica IS NOT NULL
BEGIN
    INSERT INTO dbo.RolModulo (IdRol, Modulo)
    SELECT @IdLogistica, v.Modulo
    FROM (VALUES (N'Proveedores'), (N'Reportes')) AS v(Modulo)
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.RolModulo rm
        WHERE rm.IdRol = @IdLogistica AND rm.Modulo = v.Modulo
    );
END
GO

PRINT N'RolModulo de Logística actualizado (Proveedores, Reportes).';
GO
