using filasur.domain.Models;

namespace filasur.application.Interfaces;

public interface IProveedorService
{
    Task<IEnumerable<ProveedorListItem>> ListarAsync(string? busqueda);
    Task<int> RegistrarAsync(ProveedorRegistrar proveedor, int idUsuario);
    Task ActualizarAsync(int id, ProveedorActualizar proveedor, int idUsuario);
}
