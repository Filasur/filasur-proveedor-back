using filasur.domain.Models;

namespace filasur.domain.Interfaces;

public interface IEvaluacionRepository
{
    Task<IEnumerable<EvaluacionListItem>> ListarAsync(int? idProveedor, string? estadoCodigo);
    Task<EvaluacionBorradorDetalle?> ObtenerBorradorAsync(int idEvaluacion);
    Task<int> GuardarBorradorAsync(EvaluacionBorradorRequest request, int idUsuario);
    Task GuardarCriteriosAsync(int idEvaluacion, IEnumerable<CriterioPuntaje> criterios);
    Task FinalizarAsync(int idEvaluacion, int idUsuario);
    Task AprobarAsync(int idEvaluacion, int idUsuario);
    Task RechazarAsync(int idEvaluacion, int idUsuario, string? motivo);
    Task<EvaluacionConsolidacion?> ObtenerConsolidacionAsync(int idEvaluacion);
}
