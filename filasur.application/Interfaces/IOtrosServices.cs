using filasur.domain.Models;

namespace filasur.application.Interfaces;

public interface IDashboardService
{
    Task<DashboardData?> ObtenerAsync();
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

public interface ICatalogoService
{
    Task<IEnumerable<UnidadMedidaItem>> ListarUnidadesAsync();
    Task<UnidadMedidaItem> RegistrarUnidadAsync(UnidadMedidaGuardar unidad);
    Task<UnidadMedidaItem> ActualizarUnidadAsync(int id, UnidadMedidaGuardar unidad);

    Task<IEnumerable<ProductoListItem>> ListarProductosAsync();
    Task<ProductoListItem> RegistrarProductoAsync(ProductoGuardar producto);
    Task<ProductoListItem> ActualizarProductoAsync(int id, ProductoGuardar producto);

    Task<IEnumerable<UsuarioListItem>> ListarUsuariosAsync();
    Task<UsuarioListItem> RegistrarUsuarioAsync(UsuarioCrear usuario);
    Task<UsuarioListItem> ActualizarUsuarioAsync(int id, UsuarioActualizar usuario);

    Task<IEnumerable<RolListItem>> ListarRolesAsync();
    Task<RolListItem> ActualizarRolModulosAsync(int id, RolActualizarModulos request);
    Task<ReporteEvaluaciones> ObtenerReporteEvaluacionesAsync(
        string? estado,
        DateTime? fechaDesde,
        DateTime? fechaHasta,
        string? producto);
}
