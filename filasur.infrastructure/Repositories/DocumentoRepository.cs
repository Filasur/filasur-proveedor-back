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
        p.Add("@CategoriaDocumento", documento.CategoriaDocumento);
        p.Add("@FechaVencimiento", documento.FechaVencimiento?.Date);
        p.Add("@IdDocumento", dbType: DbType.Int32, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
            "dbo.sp_Documento_Registrar",
            p,
            commandType: CommandType.StoredProcedure);

        return p.Get<int>("@IdDocumento");
    }

    public async Task<DocumentoArchivo?> ObtenerArchivoAsync(int idDocumento)
    {
        const string sql = """
            SELECT NombreArchivo, RutaAlmacenamiento
            FROM dbo.DocumentoProveedor
            WHERE IdDocumento = @IdDocumento
            """;

        using var conn = _factory.CreateConnection();
        return await conn.QueryFirstOrDefaultAsync<DocumentoArchivo>(
            sql,
            new { IdDocumento = idDocumento });
    }

    public async Task<DocumentoArchivo?> EliminarAsync(int idDocumento)
    {
        var archivo = await ObtenerArchivoAsync(idDocumento);
        if (archivo is null)
            return null;

        using var conn = _factory.CreateConnection();
        var p = new DynamicParameters();
        p.Add("@IdDocumento", idDocumento);
        p.Add("@RutaAlmacenamiento", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);
        p.Add("@NombreArchivo", dbType: DbType.String, size: 255, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
            "dbo.sp_Documento_Eliminar",
            p,
            commandType: CommandType.StoredProcedure);

        return archivo;
    }

    private static DocumentoListItem MapListItem(DocumentoListRow row)
    {
        return new DocumentoListItem
        {
            Id = row.Id,
            IdProveedor = row.IdProveedor,
            Proveedor = row.Proveedor,
            Nombre = row.Nombre,
            Tipo = row.Tipo,
            Categoria = row.Categoria,
            Tamano = FormatearTamano(row.TamanoBytes),
            Fecha = row.Fecha,
            FechaVencimiento = row.FechaVencimiento,
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
        public int IdProveedor { get; set; }
        public string Proveedor { get; set; } = string.Empty;
        public string Nombre { get; set; } = string.Empty;
        public string Tipo { get; set; } = string.Empty;
        public string? Categoria { get; set; }
        public long? TamanoBytes { get; set; }
        public string? Ruta { get; set; }
        public string Fecha { get; set; } = string.Empty;
        public string? FechaVencimiento { get; set; }
    }
}
