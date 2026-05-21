using Dapper;
using filasur.domain.Interfaces;
using filasur.domain.Models;
using filasur.infrastructure.Data;
using System.Data;

namespace filasur.infrastructure.Repositories;

public class DocumentoRepository : IDocumentoRepository
{
    private readonly ISqlConnectionFactory _factory;

    public DocumentoRepository(ISqlConnectionFactory factory)
    {
        _factory = factory;
    }

    public async Task<IEnumerable<DocumentoListItem>> ListarAsync(int? idProveedor, string? busqueda)
    {
        using var conn = _factory.CreateConnection();
        var rows = await conn.QueryAsync<DocumentoListRow>(
            "dbo.sp_Documento_Listar",
            new { IdProveedor = idProveedor, Busqueda = busqueda },
            commandType: CommandType.StoredProcedure);

        return rows.Select(MapListItem);
    }

    public async Task<int> RegistrarAsync(int idProveedor, DocumentoRegistro documento)
    {
        using var conn = _factory.CreateConnection();
        var p = new DynamicParameters();
        p.Add("@IdProveedor", idProveedor);
        p.Add("@NombreArchivo", documento.NombreArchivo);
        p.Add("@TipoArchivo", documento.TipoArchivo);
        p.Add("@TamanoBytes", documento.TamanoBytes);
        p.Add("@RutaAlmacenamiento", documento.RutaAlmacenamiento);
        p.Add("@IdDocumento", dbType: DbType.Int32, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
            "dbo.sp_Documento_Registrar",
            p,
            commandType: CommandType.StoredProcedure);

        return p.Get<int>("@IdDocumento");
    }

    private static DocumentoListItem MapListItem(DocumentoListRow row)
    {
        return new DocumentoListItem
        {
            Id = row.Id,
            Proveedor = row.Proveedor,
            Nombre = row.Nombre,
            Tipo = row.Tipo,
            Tamano = FormatearTamano(row.TamanoBytes),
            Fecha = row.Fecha,
            Ruta = row.Ruta
        };
    }

    private static string FormatearTamano(long? bytes)
    {
        if (bytes is null or < 1024) return $"{bytes ?? 0} B";
        if (bytes < 1024 * 1024) return $"{bytes / 1024.0:0.#} KB";
        return $"{bytes / (1024.0 * 1024.0):0.#} MB";
    }

    private sealed class DocumentoListRow
    {
        public int Id { get; set; }
        public string Proveedor { get; set; } = string.Empty;
        public string Nombre { get; set; } = string.Empty;
        public string Tipo { get; set; } = string.Empty;
        public long? TamanoBytes { get; set; }
        public string? Ruta { get; set; }
        public string Fecha { get; set; } = string.Empty;
    }
}
