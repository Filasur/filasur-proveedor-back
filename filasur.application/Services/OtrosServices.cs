using filasur.application.Interfaces;
using filasur.domain.Interfaces;
using filasur.domain.Models;

namespace filasur.application.Services;

public class DashboardService : IDashboardService
{
    private readonly IDashboardRepository _repository;

    public DashboardService(IDashboardRepository repository) => _repository = repository;

    public Task<DashboardResumen?> ObtenerResumenAsync() => _repository.ObtenerResumenAsync();
}

public class RankingService : IRankingService
{
    private readonly IRankingRepository _repository;

    public RankingService(IRankingRepository repository) => _repository = repository;

    public Task<IEnumerable<RankingItem>> ListarAsync() => _repository.ListarAsync();
}

public class BitacoraService : IBitacoraService
{
    private readonly IBitacoraRepository _repository;

    public BitacoraService(IBitacoraRepository repository) => _repository = repository;

    public Task<IEnumerable<BitacoraItem>> ListarAsync(int top) => _repository.ListarAsync(top);
}

public class ConfiguracionService : IConfiguracionService
{
    private readonly IConfiguracionRepository _repository;

    public ConfiguracionService(IConfiguracionRepository repository) => _repository = repository;

    public Task<ConfiguracionSistema?> ObtenerAsync() => _repository.ObtenerAsync();

    public Task GuardarAsync(ConfiguracionGuardar config, int idUsuario) =>
        _repository.GuardarAsync(config, idUsuario);
}
