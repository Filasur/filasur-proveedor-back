using filasur.domain.Models;

namespace filasur.application.Interfaces;

public interface IDashboardService
{
    Task<DashboardResumen?> ObtenerResumenAsync();
}

public interface IRankingService
{
    Task<IEnumerable<RankingItem>> ListarAsync();
}

public interface IBitacoraService
{
    Task<IEnumerable<BitacoraItem>> ListarAsync(int top);
}

public interface IConfiguracionService
{
    Task<ConfiguracionSistema?> ObtenerAsync();
    Task GuardarAsync(ConfiguracionGuardar config, int idUsuario);
}
