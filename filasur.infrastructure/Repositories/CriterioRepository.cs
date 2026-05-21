using Dapper;
using filasur.domain.Interfaces;
using filasur.domain.Models;
using filasur.infrastructure.Data;
using System.Data;
using System.Text.Json;

namespace filasur.infrastructure.Repositories;

public class CriterioRepository : ICriterioRepository
{
    private readonly ISqlConnectionFactory _factory;

    public CriterioRepository(ISqlConnectionFactory factory)
    {
        _factory = factory;
    }

    public async Task<IEnumerable<CriterioListItem>> ListarAsync()
    {
        using var conn = _factory.CreateConnection();
        return await conn.QueryAsync<CriterioListItem>(
            "dbo.sp_Criterio_Listar",
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<CriterioListItem>> GuardarAsync(IEnumerable<CriterioGuardarItem> criterios)
    {
        var json = JsonSerializer.Serialize(criterios.Select(c => new
        {
            id = c.Id,
            nombre = c.Nombre,
            area = c.Area,
            peso = c.Peso,
            activo = c.Activo
        }));

        using var conn = _factory.CreateConnection();
        await conn.ExecuteAsync(
            "dbo.sp_Criterio_Guardar",
            new { CriteriosJson = json },
            commandType: CommandType.StoredProcedure);

        return await ListarAsync();
    }
}
