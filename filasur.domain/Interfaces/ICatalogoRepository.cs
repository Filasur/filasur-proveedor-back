using filasur.domain.Models;

namespace filasur.domain.Interfaces;

public interface ICatalogoRepository
{
    Task<IEnumerable<UnidadMedidaItem>> ListarUnidadesAsync();
    Task<UnidadMedidaItem?> ObtenerUnidadAsync(int id);
    Task<int> RegistrarUnidadAsync(UnidadMedidaGuardar unidad);
    Task ActualizarUnidadAsync(int id, UnidadMedidaGuardar unidad);

    Task<IEnumerable<ProductoListItem>> ListarProductosAsync();
    Task<ProductoListItem?> ObtenerProductoAsync(int id);
    Task<int> RegistrarProductoAsync(ProductoGuardar producto);
    Task ActualizarProductoAsync(int id, ProductoGuardar producto);

    Task<IEnumerable<UsuarioListItem>> ListarUsuariosAsync();
    Task<UsuarioListItem?> ObtenerUsuarioAsync(int id);
    Task<int> RegistrarUsuarioAsync(UsuarioCrear usuario, string passwordHash);
    Task ActualizarUsuarioAsync(int id, UsuarioActualizar usuario);

    Task<IEnumerable<RolListItem>> ListarRolesAsync();
    Task<ReporteEvaluaciones> ObtenerReporteEvaluacionesAsync(string? estado);
}
