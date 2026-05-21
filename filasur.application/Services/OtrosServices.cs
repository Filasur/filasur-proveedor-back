using filasur.application.Interfaces;
using filasur.domain.Interfaces;
using filasur.domain.Models;

namespace filasur.application.Services;

public class DashboardService : IDashboardService
{
    private readonly IDashboardRepository _repository;

    public DashboardService(IDashboardRepository repository) => _repository = repository;

    public Task<DashboardData?> ObtenerAsync() => _repository.ObtenerAsync();
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

public class CatalogoService : ICatalogoService
{
    private const string PasswordTemporal = "Filasur123";
    private readonly ICatalogoRepository _repository;

    public CatalogoService(ICatalogoRepository repository)
    {
        _repository = repository;
    }

    public Task<IEnumerable<UnidadMedidaItem>> ListarUnidadesAsync() =>
        _repository.ListarUnidadesAsync();

    public async Task<UnidadMedidaItem> RegistrarUnidadAsync(UnidadMedidaGuardar unidad)
    {
        var id = await _repository.RegistrarUnidadAsync(unidad);
        return (await _repository.ObtenerUnidadAsync(id))!;
    }

    public async Task<UnidadMedidaItem> ActualizarUnidadAsync(int id, UnidadMedidaGuardar unidad)
    {
        await _repository.ActualizarUnidadAsync(id, unidad);
        return (await _repository.ObtenerUnidadAsync(id))!;
    }

    public Task<IEnumerable<ProductoListItem>> ListarProductosAsync() =>
        _repository.ListarProductosAsync();

    public async Task<ProductoListItem> RegistrarProductoAsync(ProductoGuardar producto)
    {
        var id = await _repository.RegistrarProductoAsync(producto);
        return (await _repository.ObtenerProductoAsync(id))!;
    }

    public async Task<ProductoListItem> ActualizarProductoAsync(int id, ProductoGuardar producto)
    {
        await _repository.ActualizarProductoAsync(id, producto);
        return (await _repository.ObtenerProductoAsync(id))!;
    }

    public Task<IEnumerable<UsuarioListItem>> ListarUsuariosAsync() =>
        _repository.ListarUsuariosAsync();

    public async Task<UsuarioListItem> RegistrarUsuarioAsync(UsuarioCrear usuario)
    {
        var hash = BCrypt.Net.BCrypt.HashPassword(PasswordTemporal);
        var id = await _repository.RegistrarUsuarioAsync(usuario, hash);
        return (await _repository.ObtenerUsuarioAsync(id))!;
    }

    public async Task<UsuarioListItem> ActualizarUsuarioAsync(int id, UsuarioActualizar usuario)
    {
        await _repository.ActualizarUsuarioAsync(id, usuario);
        return (await _repository.ObtenerUsuarioAsync(id))!;
    }

    public Task<IEnumerable<RolListItem>> ListarRolesAsync() =>
        _repository.ListarRolesAsync();

    public Task<ReporteEvaluaciones> ObtenerReporteEvaluacionesAsync(
        string? estado,
        DateTime? fechaDesde,
        DateTime? fechaHasta,
        string? producto) =>
        _repository.ObtenerReporteEvaluacionesAsync(estado, fechaDesde, fechaHasta, producto);
}
