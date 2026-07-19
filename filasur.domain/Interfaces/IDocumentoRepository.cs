using filasur.domain.Models;

namespace filasur.domain.Interfaces;

public interface IDocumentoRepository
{
    Task<IEnumerable<DocumentoListItem>> ListarAsync(int? idProveedor, string? busqueda);
    Task<int> RegistrarAsync(int idProveedor, DocumentoRegistro documento);
    Task<DocumentoArchivo?> ObtenerArchivoAsync(int idDocumento);
    Task<DocumentoArchivo?> EliminarAsync(int idDocumento);
}
