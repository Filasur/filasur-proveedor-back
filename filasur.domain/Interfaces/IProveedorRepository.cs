using filasur.domain.Models;

namespace filasur.domain.Interfaces;

public interface IProveedorRepository
{
    Task<IEnumerable<ProveedorListItem>> ListarAsync(string? busqueda);
    Task<int> RegistrarAsync(ProveedorRegistrar proveedor, int idUsuario);
    Task ActualizarAsync(int idProveedor, ProveedorActualizar proveedor, int idUsuario);
}
