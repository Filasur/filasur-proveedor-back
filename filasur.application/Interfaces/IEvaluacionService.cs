using filasur.domain.Models;

namespace filasur.application.Interfaces;

public interface IEvaluacionService
{
    Task<IEnumerable<EvaluacionListItem>> ListarAsync(int? proveedorId, string? estado, bool? pendientes);
    Task<int> GuardarBorradorAsync(EvaluacionBorradorRequest request, int idUsuario);
    Task<EvaluacionConsolidacion?> ObtenerConsolidacionAsync(int id);
    Task AprobarAsync(int id, int idUsuario);
    Task RechazarAsync(int id, int idUsuario, string? motivo);
}
