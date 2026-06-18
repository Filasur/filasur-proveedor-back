using filasur.domain.Models;

namespace filasur.application.Interfaces;

public interface IDocumentoService
{
    Task<IEnumerable<DocumentoListItem>> ListarAsync(int? idProveedor, string? busqueda);
    Task<IReadOnlyList<int>> RegistrarProveedorAsync(
        int idProveedor,
        IEnumerable<DocumentoRegistro> documentos,
        int idUsuario);
    Task<DocumentoArchivo?> ObtenerArchivoAsync(int idDocumento);
}
