using filasur.domain.Models;

namespace filasur.application.Interfaces;

public interface ICriterioService
{
    Task<IEnumerable<CriterioListItem>> ListarAsync();
    Task<IEnumerable<CriterioListItem>> GuardarAsync(IEnumerable<CriterioGuardarItem> criterios);
}
