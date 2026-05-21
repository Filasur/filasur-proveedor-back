using Dapper;
using filasur.domain.Interfaces;
using filasur.domain.Models;
using filasur.infrastructure.Data;
using System.Data;

namespace filasur.infrastructure.Repositories;

public class DashboardRepository : IDashboardRepository
{
    private readonly ISqlConnectionFactory _factory;

    public DashboardRepository(ISqlConnectionFactory factory)
    {
        _factory = factory;
    }

    public async Task<DashboardData?> ObtenerAsync()
    {
        using var conn = _factory.CreateConnection();
        using var multi = await conn.QueryMultipleAsync(
            "dbo.sp_Dashboard_Resumen",
            commandType: CommandType.StoredProcedure);

        var resumen = await multi.ReadFirstOrDefaultAsync<DashboardResumen>();
        if (resumen is null)
            return null;

        var recientes = (await multi.ReadAsync<DashboardEvaluacionItem>()).ToList();
        var proximas = (await multi.ReadAsync<DashboardEvaluacionItem>()).ToList();
        var evolucion = (await multi.ReadAsync<DashboardEvolucionMensualItem>()).ToList();

        return new DashboardData
        {
            Resumen = resumen,
            EvaluacionesRecientes = recientes,
            ProximasVencer = proximas,
            EvolucionMensual = evolucion
        };
    }
}

public class RankingRepository : IRankingRepository
{
    private readonly ISqlConnectionFactory _factory;

    public RankingRepository(ISqlConnectionFactory factory)
    {
        _factory = factory;
    }

    public async Task<IEnumerable<RankingItem>> ListarAsync()
    {
        using var conn = _factory.CreateConnection();
        return await conn.QueryAsync<RankingItem>(
            "dbo.sp_Ranking_Listar",
            commandType: CommandType.StoredProcedure);
    }
}

public class BitacoraRepository : IBitacoraRepository
{
    private readonly ISqlConnectionFactory _factory;

    public BitacoraRepository(ISqlConnectionFactory factory)
    {
        _factory = factory;
    }

    public async Task<IEnumerable<BitacoraItem>> ListarAsync(int top = 100)
    {
        using var conn = _factory.CreateConnection();
        return await conn.QueryAsync<BitacoraItem>(
            "dbo.sp_Bitacora_Listar",
            new { Top = top },
            commandType: CommandType.StoredProcedure);
    }

    public async Task RegistrarAsync(int? idUsuario, string modulo, string accion, string? detalle = null)
    {
        using var conn = _factory.CreateConnection();
        await conn.ExecuteAsync(
            "dbo.sp_Bitacora_Registrar",
            new { IdUsuario = idUsuario, Modulo = modulo, Accion = accion, Detalle = detalle },
            commandType: CommandType.StoredProcedure);
    }
}

public class ConfiguracionRepository : IConfiguracionRepository
{
    private readonly ISqlConnectionFactory _factory;

    public ConfiguracionRepository(ISqlConnectionFactory factory)
    {
        _factory = factory;
    }

    public async Task<ConfiguracionSistema?> ObtenerAsync()
    {
        using var conn = _factory.CreateConnection();
        return await conn.QueryFirstOrDefaultAsync<ConfiguracionSistema>(
            "dbo.sp_Configuracion_Obtener",
            commandType: CommandType.StoredProcedure);
    }

    public async Task GuardarAsync(ConfiguracionGuardar config, int idUsuario)
    {
        using var conn = _factory.CreateConnection();
        await conn.ExecuteAsync(
            "dbo.sp_Configuracion_Guardar",
            new
            {
                config.UmbralAprobacion,
                config.UmbralObservado,
                config.DiasAlertaVencimiento,
                config.NotificacionesEmail,
                config.IntegracionErp,
                IdUsuario = idUsuario
            },
            commandType: CommandType.StoredProcedure);
    }
}
