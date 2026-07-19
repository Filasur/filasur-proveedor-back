using filasur.application.Interfaces;
using filasur.domain.Interfaces;
using filasur.domain.Models;

namespace filasur.application.Services;

public class DocumentoService : IDocumentoService
{
    private readonly IDocumentoRepository _documentos;
    private readonly IBitacoraRepository _bitacora;

    public DocumentoService(IDocumentoRepository documentos, IBitacoraRepository bitacora)
    {
        _documentos = documentos;
        _bitacora = bitacora;
    }

    public Task<IEnumerable<DocumentoListItem>> ListarAsync(int? idProveedor, string? busqueda) =>
        _documentos.ListarAsync(idProveedor, busqueda);

    public async Task<IReadOnlyList<int>> RegistrarProveedorAsync(
        int idProveedor,
        IEnumerable<DocumentoRegistro> documentos,
        int idUsuario)
    {
        var lista = documentos.ToList();
        if (lista.Count == 0)
            return Array.Empty<int>();

        var ids = new List<int>();
        foreach (var doc in lista)
        {
            var id = await _documentos.RegistrarAsync(idProveedor, doc);
            ids.Add(id);
        }

        await _bitacora.RegistrarAsync(
            idUsuario,
            "Documentos",
            "Documentos cargados",
            $"{lista.Count} archivo(s) para proveedor Id={idProveedor}");

        return ids;
    }

    public Task<DocumentoArchivo?> ObtenerArchivoAsync(int idDocumento) =>
        _documentos.ObtenerArchivoAsync(idDocumento);

    public async Task<DocumentoArchivo?> EliminarAsync(int idDocumento, int idUsuario)
    {
        var eliminado = await _documentos.EliminarAsync(idDocumento);
        if (eliminado is null)
            return null;

        await _bitacora.RegistrarAsync(
            idUsuario,
            "Documentos",
            "Documento eliminado",
            $"Archivo '{eliminado.NombreArchivo}' (Id={idDocumento})");

        return eliminado;
    }
}
