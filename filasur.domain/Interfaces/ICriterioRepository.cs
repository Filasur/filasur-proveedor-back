using filasur.domain.Models;

namespace filasur.domain.Interfaces;

public interface ICriterioRepository
{
    Task<IEnumerable<CriterioListItem>> ListarAsync();
    Task<IEnumerable<CriterioListItem>> GuardarAsync(IEnumerable<CriterioGuardarItem> criterios);
}
