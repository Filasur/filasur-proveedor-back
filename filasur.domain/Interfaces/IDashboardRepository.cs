using filasur.domain.Models;

namespace filasur.domain.Interfaces;

public interface IDashboardRepository
{
    Task<DashboardResumen?> ObtenerResumenAsync();
}

public interface IRankingRepository
{
    Task<IEnumerable<RankingItem>> ListarAsync();
}

public interface IBitacoraRepository
{
    Task<IEnumerable<BitacoraItem>> ListarAsync(int top = 100);
}

public interface IConfiguracionRepository
{
    Task<ConfiguracionSistema?> ObtenerAsync();
    Task GuardarAsync(ConfiguracionGuardar config, int idUsuario);
}
