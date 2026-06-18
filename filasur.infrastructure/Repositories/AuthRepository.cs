using Dapper;
using filasur.domain.Interfaces;
using filasur.domain.Models;
using filasur.infrastructure.Data;

namespace filasur.infrastructure.Repositories;

public class AuthRepository : IAuthRepository
{
    private readonly ISqlConnectionFactory _factory;

    public AuthRepository(ISqlConnectionFactory factory)
    {
        _factory = factory;
    }

    public async Task<UsuarioCredencial?> ObtenerPorEmailAsync(string email)
    {
        const string sql = """
            SELECT
                u.IdUsuario AS Id,
                u.NombreCompleto AS Nombre,
                u.Email AS Email,
                r.Nombre AS Rol,
                u.Iniciales AS Iniciales,
                u.PasswordHash AS PasswordHash,
                ISNULL(u.IntentosFallidos, 0) AS IntentosFallidos,
                u.BloqueadoHasta AS BloqueadoHasta,
                ISNULL(u.DebeCambiarPassword, 0) AS DebeCambiarPassword,
                CASE WHEN u.IdEstadoUsuario = 1 THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS Activo
            FROM dbo.Usuario u
            INNER JOIN dbo.Rol r ON r.IdRol = u.IdRol
            WHERE u.Email = @Email
            """;

        using var conn = _factory.CreateConnection();
        return await conn.QueryFirstOrDefaultAsync<UsuarioCredencial>(sql, new { Email = email });
    }

    public async Task<UsuarioCredencial?> ObtenerPorIdAsync(int idUsuario)
    {
        const string sql = """
            SELECT
                u.IdUsuario AS Id,
                u.NombreCompleto AS Nombre,
                u.Email AS Email,
                r.Nombre AS Rol,
                u.Iniciales AS Iniciales,
                u.PasswordHash AS PasswordHash,
                ISNULL(u.IntentosFallidos, 0) AS IntentosFallidos,
                u.BloqueadoHasta AS BloqueadoHasta,
                ISNULL(u.DebeCambiarPassword, 0) AS DebeCambiarPassword,
                CASE WHEN u.IdEstadoUsuario = 1 THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS Activo
            FROM dbo.Usuario u
            INNER JOIN dbo.Rol r ON r.IdRol = u.IdRol
            WHERE u.IdUsuario = @IdUsuario AND u.IdEstadoUsuario = 1
            """;

        using var conn = _factory.CreateConnection();
        return await conn.QueryFirstOrDefaultAsync<UsuarioCredencial>(sql, new { IdUsuario = idUsuario });
    }

    public async Task RegistrarIntentoFallidoAsync(int idUsuario, bool bloquear)
    {
        const string sql = """
            UPDATE dbo.Usuario
            SET IntentosFallidos = ISNULL(IntentosFallidos, 0) + 1,
                BloqueadoHasta = CASE WHEN @Bloquear = 1 THEN DATEADD(MINUTE, 15, SYSUTCDATETIME()) ELSE BloqueadoHasta END,
                FechaModificacion = SYSUTCDATETIME()
            WHERE IdUsuario = @IdUsuario
            """;

        using var conn = _factory.CreateConnection();
        await conn.ExecuteAsync(sql, new { IdUsuario = idUsuario, Bloquear = bloquear });
    }

    public async Task ResetearIntentosAsync(int idUsuario)
    {
        const string sql = """
            UPDATE dbo.Usuario
            SET IntentosFallidos = 0,
                BloqueadoHasta = NULL,
                FechaModificacion = SYSUTCDATETIME()
            WHERE IdUsuario = @IdUsuario
            """;

        using var conn = _factory.CreateConnection();
        await conn.ExecuteAsync(sql, new { IdUsuario = idUsuario });
    }

    public async Task ActualizarPasswordAsync(int idUsuario, string passwordHash, bool debeCambiarPassword)
    {
        const string sql = """
            UPDATE dbo.Usuario
            SET PasswordHash = @PasswordHash,
                DebeCambiarPassword = @DebeCambiarPassword,
                IntentosFallidos = 0,
                BloqueadoHasta = NULL,
                FechaModificacion = SYSUTCDATETIME()
            WHERE IdUsuario = @IdUsuario
            """;

        using var conn = _factory.CreateConnection();
        await conn.ExecuteAsync(sql, new
        {
            IdUsuario = idUsuario,
            PasswordHash = passwordHash,
            DebeCambiarPassword = debeCambiarPassword
        });
    }
}
