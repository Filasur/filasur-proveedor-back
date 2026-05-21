using Dapper;
using filasur.domain.Interfaces;
using filasur.domain.Models;
using filasur.infrastructure.Data;
using System.Data;
using System.Text.Json;

namespace filasur.infrastructure.Repositories;

public class EvaluacionRepository : IEvaluacionRepository
{
    private readonly ISqlConnectionFactory _factory;

    public EvaluacionRepository(ISqlConnectionFactory factory)
    {
        _factory = factory;
    }

    public async Task<IEnumerable<EvaluacionListItem>> ListarAsync(int? idProveedor, string? estadoCodigo)
    {
        using var conn = _factory.CreateConnection();
        return await conn.QueryAsync<EvaluacionListItem>(
            "dbo.sp_Evaluacion_Listar",
            new { IdProveedor = idProveedor, EstadoCodigo = estadoCodigo },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> GuardarBorradorAsync(EvaluacionBorradorRequest request, int idUsuario)
    {
        using var conn = _factory.CreateConnection();
        conn.Open();
        using var tx = conn.BeginTransaction();
        try
        {
            var p = new DynamicParameters();
            p.Add("@IdProveedor", request.ProveedorId);
            p.Add("@Periodo", request.Periodo);
            p.Add("@IdProducto", request.IdProducto);
            p.Add("@OrdenCompra", request.OrdenCompra);
            p.Add("@FechaLimite", request.FechaLimite);
            p.Add("@Observaciones", request.Observaciones);
            p.Add("@IdUsuarioCreador", idUsuario);
            p.Add("@IdEvaluacion", dbType: DbType.Int32, direction: ParameterDirection.Output);

            await conn.ExecuteAsync(
                "dbo.sp_Evaluacion_GuardarBorrador",
                p,
                tx,
                commandType: CommandType.StoredProcedure);

            var idEvaluacion = p.Get<int>("@IdEvaluacion");

            if (request.Puntajes.Count > 0)
            {
                var criterios = request.Puntajes.Select(kv => new CriterioPuntaje
                {
                    IdCriterio = int.Parse(kv.Key),
                    Puntaje = kv.Value
                });
                await GuardarCriteriosInternalAsync(conn, tx, idEvaluacion, criterios);
            }

            if (request.Finalizar)
            {
                await conn.ExecuteAsync(
                    "dbo.sp_Evaluacion_Finalizar",
                    new { IdEvaluacion = idEvaluacion, IdUsuario = idUsuario },
                    tx,
                    commandType: CommandType.StoredProcedure);
            }

            tx.Commit();
            return idEvaluacion;
        }
        catch
        {
            tx.Rollback();
            throw;
        }
    }

    public async Task GuardarCriteriosAsync(int idEvaluacion, IEnumerable<CriterioPuntaje> criterios)
    {
        using var conn = _factory.CreateConnection();
        await GuardarCriteriosInternalAsync(conn, null, idEvaluacion, criterios);
    }

    private static async Task GuardarCriteriosInternalAsync(
        IDbConnection conn,
        IDbTransaction? tx,
        int idEvaluacion,
        IEnumerable<CriterioPuntaje> criterios)
    {
        var json = JsonSerializer.Serialize(criterios.Select(c => new { idCriterio = c.IdCriterio, puntaje = c.Puntaje }));
        await conn.ExecuteAsync(
            "dbo.sp_Evaluacion_GuardarCriterios",
            new { IdEvaluacion = idEvaluacion, CriteriosJson = json },
            tx,
            commandType: CommandType.StoredProcedure);
    }

    public async Task FinalizarAsync(int idEvaluacion, int idUsuario)
    {
        using var conn = _factory.CreateConnection();
        await conn.ExecuteAsync(
            "dbo.sp_Evaluacion_Finalizar",
            new { IdEvaluacion = idEvaluacion, IdUsuario = idUsuario },
            commandType: CommandType.StoredProcedure);
    }

    public async Task AprobarAsync(int idEvaluacion, int idUsuario)
    {
        using var conn = _factory.CreateConnection();
        await conn.ExecuteAsync(
            "dbo.sp_Evaluacion_Aprobar",
            new { IdEvaluacion = idEvaluacion, IdUsuario = idUsuario },
            commandType: CommandType.StoredProcedure);
    }

    public async Task RechazarAsync(int idEvaluacion, int idUsuario, string? motivo)
    {
        using var conn = _factory.CreateConnection();
        await conn.ExecuteAsync(
            "dbo.sp_Evaluacion_Rechazar",
            new { IdEvaluacion = idEvaluacion, IdUsuario = idUsuario, Motivo = motivo },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<EvaluacionConsolidacion?> ObtenerConsolidacionAsync(int idEvaluacion)
    {
        using var conn = _factory.CreateConnection();
        using var multi = await conn.QueryMultipleAsync(
            "dbo.sp_Evaluacion_ObtenerConsolidacion",
            new { IdEvaluacion = idEvaluacion },
            commandType: CommandType.StoredProcedure);

        var cabecera = await multi.ReadFirstOrDefaultAsync<EvaluacionConsolidacionCabecera>();
        if (cabecera is null)
            return null;

        var areas = (await multi.ReadAsync<EvaluacionConsolidacionArea>()).ToList();
        var criterios = (await multi.ReadAsync<EvaluacionConsolidacionCriterio>()).ToList();

        return new EvaluacionConsolidacion
        {
            Cabecera = cabecera,
            Areas = areas,
            Criterios = criterios
        };
    }
}
