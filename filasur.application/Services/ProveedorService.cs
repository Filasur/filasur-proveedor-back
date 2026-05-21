using filasur.application.Interfaces;
using filasur.domain.Interfaces;
using filasur.domain.Models;

namespace filasur.application.Services;

public class ProveedorService : IProveedorService
{
    private readonly IProveedorRepository _repository;

    public ProveedorService(IProveedorRepository repository)
    {
        _repository = repository;
    }

    public Task<IEnumerable<ProveedorListItem>> ListarAsync(string? busqueda) =>
        _repository.ListarAsync(busqueda);

    public Task<ProveedorDetalle?> ObtenerAsync(int id) =>
        _repository.ObtenerDetalleAsync(id);

    public Task<int> RegistrarAsync(ProveedorRegistrar proveedor, int idUsuario) =>
        _repository.RegistrarAsync(proveedor, idUsuario);

    public Task ActualizarAsync(int id, ProveedorActualizar proveedor, int idUsuario) =>
        _repository.ActualizarAsync(id, proveedor, idUsuario);
}
