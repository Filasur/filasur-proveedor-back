/*
  Registrar / actualizar usuario de aplicación
  Email:    fvelazco@filasur.com
  Password: fvelazco2026  (hash BCrypt, mismo algoritmo que AuthService)

  Ejecutar en SSMS o sqlcmd contra la base FilasurProveedores.
*/

USE FilasurProveedores;
GO

DECLARE @Email           NVARCHAR(120) = N'fvelazco@filasur.com';
DECLARE @NombreCompleto  NVARCHAR(120) = N'Francisco Velazco';
DECLARE @Iniciales       NVARCHAR(5)   = N'FV';
DECLARE @RolNombre       NVARCHAR(50)  = N'Administrador'; -- Cambiar si necesitas otro rol
DECLARE @PasswordHash    NVARCHAR(256) = N'$2a$11$JAXCsnEU3qQLdiXLO8FX1OR8Xeo5rCGA0NfFj27RZUHlwhhIOE1fO';

DECLARE @IdRol INT;

SELECT @IdRol = r.IdRol
FROM dbo.Rol r
WHERE r.Nombre = @RolNombre;

IF @IdRol IS NULL
BEGIN
    RAISERROR(N'No existe el rol "%s". Revise dbo.Rol.', 16, 1, @RolNombre);
    RETURN;
END;

IF EXISTS (SELECT 1 FROM dbo.Usuario WHERE Email = @Email)
BEGIN
    UPDATE dbo.Usuario
    SET
        IdRol             = @IdRol,
        NombreCompleto    = @NombreCompleto,
        PasswordHash      = @PasswordHash,
        Iniciales         = @Iniciales,
        IdEstadoUsuario   = 1,
        FechaModificacion = SYSUTCDATETIME()
    WHERE Email = @Email;

    PRINT N'Usuario actualizado: ' + @Email;
END
ELSE
BEGIN
    INSERT INTO dbo.Usuario (IdRol, NombreCompleto, Email, PasswordHash, Iniciales, IdEstadoUsuario)
    VALUES (@IdRol, @NombreCompleto, @Email, @PasswordHash, @Iniciales, 1);

    PRINT N'Usuario registrado: ' + @Email;
END;
GO

-- Verificación
SELECT
    u.IdUsuario,
    u.NombreCompleto,
    u.Email,
    r.Nombre AS Rol,
    u.Iniciales,
    u.IdEstadoUsuario,
    u.FechaCreacion
FROM dbo.Usuario u
INNER JOIN dbo.Rol r ON r.IdRol = u.IdRol
WHERE u.Email = N'fvelazco@filasur.com';
GO
