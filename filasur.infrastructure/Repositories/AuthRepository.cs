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
                u.PasswordHash AS PasswordHash
            FROM dbo.Usuario u
            INNER JOIN dbo.Rol r ON r.IdRol = u.IdRol
            WHERE u.Email = @Email AND u.IdEstadoUsuario = 1
            """;

        using var conn = _factory.CreateConnection();
        return await conn.QueryFirstOrDefaultAsync<UsuarioCredencial>(sql, new { Email = email });
    }
}
