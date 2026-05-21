using filasur.application.Interfaces;
using filasur.domain.Interfaces;
using filasur.domain.Models;

namespace filasur.application.Services;

public class EvaluacionService : IEvaluacionService
{
    private readonly IEvaluacionRepository _repository;

    public EvaluacionService(IEvaluacionRepository repository)
    {
        _repository = repository;
    }

    public async Task<IEnumerable<EvaluacionListItem>> ListarAsync(int? proveedorId, string? estado, bool? pendientes)
    {
        var items = await _repository.ListarAsync(proveedorId, estado);
        if (pendientes == true)
            return items.Where(e => e.AreasPendientes > 0);
        return items;
    }

    public Task<int> GuardarBorradorAsync(EvaluacionBorradorRequest request, int idUsuario) =>
        _repository.GuardarBorradorAsync(request, idUsuario);

    public async Task<EvaluacionConsolidacion?> ObtenerConsolidacionAsync(int id)
    {
        var data = await _repository.ObtenerConsolidacionAsync(id);
        return data;
    }

    public Task AprobarAsync(int id, int idUsuario) =>
        _repository.AprobarAsync(id, idUsuario);

    public Task RechazarAsync(int id, int idUsuario, string? motivo) =>
        _repository.RechazarAsync(id, idUsuario, motivo);
}
