using filasur.application.Interfaces;
using filasur.domain.Interfaces;
using filasur.domain.Models;

namespace filasur.application.Services;

public class CriterioService : ICriterioService
{
    private readonly ICriterioRepository _repository;

    public CriterioService(ICriterioRepository repository)
    {
        _repository = repository;
    }

    public Task<IEnumerable<CriterioListItem>> ListarAsync() => _repository.ListarAsync();

    public Task<IEnumerable<CriterioListItem>> GuardarAsync(IEnumerable<CriterioGuardarItem> criterios) =>
        _repository.GuardarAsync(criterios);
}
