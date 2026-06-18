using Dapper;
using filasur.domain.Interfaces;
using filasur.domain.Models;
using filasur.infrastructure.Data;
using System.Data;

namespace filasur.infrastructure.Repositories;

public class ProveedorRepository : IProveedorRepository
{
    private readonly ISqlConnectionFactory _factory;

    public ProveedorRepository(ISqlConnectionFactory factory)
    {
        _factory = factory;
    }

    public async Task<IEnumerable<ProveedorListItem>> ListarAsync(string? busqueda)
    {
        using var conn = _factory.CreateConnection();
        return await conn.QueryAsync<ProveedorListItem>(
            "dbo.sp_Proveedor_Listar",
            new { Busqueda = busqueda },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<ProveedorDetalle?> ObtenerDetalleAsync(int idProveedor)
    {
        using var conn = _factory.CreateConnection();
        using var multi = await conn.QueryMultipleAsync(
            "dbo.sp_Proveedor_Obtener",
            new { IdProveedor = idProveedor },
            commandType: CommandType.StoredProcedure);

        var cabecera = await multi.ReadFirstOrDefaultAsync<ProveedorDetalleRow>();
        if (cabecera is null)
            return null;

        var evaluaciones = (await multi.ReadAsync<EvaluacionListItem>()).ToList();
        var documentos = (await multi.ReadAsync<DocumentoListRow>()).ToList();
        var historial = (await multi.ReadAsync<BitacoraItem>()).ToList();

        return new ProveedorDetalle
        {
            Id = cabecera.Id,
            Ruc = cabecera.Ruc,
            RazonSocial = cabecera.RazonSocial,
            TipoProveedor = cabecera.TipoProveedor,
            Rubro = cabecera.Rubro,
            Contacto = cabecera.Contacto,
            Telefono = cabecera.Telefono,
            Correo = cabecera.Correo,
            Direccion = cabecera.Direccion,
            Estado = cabecera.Estado,
            Clasificacion = cabecera.Clasificacion,
            PuntajePromedio = cabecera.PuntajePromedio,
            Evaluaciones = cabecera.Evaluaciones,
            EvaluacionesLista = evaluaciones,
            Documentos = documentos.Select(d => new DocumentoListItem
            {
                Id = d.Id,
                Proveedor = d.Proveedor,
                Nombre = d.Nombre,
                Tipo = d.Tipo,
                Tamano = FormatearTamano(d.TamanoBytes),
                Fecha = d.Fecha,
                Ruta = d.Ruta
            }).ToList(),
            Historial = historial
        };
    }

    private static string FormatearTamano(long? bytes)
    {
        if (bytes is null or < 1024) return $"{bytes ?? 0} B";
        if (bytes < 1024 * 1024) return $"{bytes / 1024.0:0.#} KB";
        return $"{bytes / (1024.0 * 1024.0):0.#} MB";
    }

    public async Task<int> RegistrarAsync(ProveedorRegistrar proveedor, int idUsuario)
    {
        using var conn = _factory.CreateConnection();
        var p = new DynamicParameters();
        p.Add("@Ruc", proveedor.Ruc);
        p.Add("@RazonSocial", proveedor.RazonSocial);
        p.Add("@IdTipoProveedor", proveedor.IdTipoProveedor);
        p.Add("@Rubro", proveedor.Rubro);
        p.Add("@Contacto", proveedor.Contacto);
        p.Add("@Telefono", proveedor.Telefono);
        p.Add("@Correo", proveedor.Correo);
        p.Add("@Direccion", proveedor.Direccion);
        p.Add("@IdUsuario", idUsuario);
        p.Add("@IdProveedor", dbType: DbType.Int32, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
            "dbo.sp_Proveedor_Registrar",
            p,
            commandType: CommandType.StoredProcedure);

        return p.Get<int>("@IdProveedor");
    }

    public async Task ActualizarAsync(int idProveedor, ProveedorActualizar proveedor, int idUsuario)
    {
        using var conn = _factory.CreateConnection();
        await conn.ExecuteAsync(
            "dbo.sp_Proveedor_Actualizar",
            new
            {
                IdProveedor = idProveedor,
                proveedor.RazonSocial,
                proveedor.IdTipoProveedor,
                proveedor.Rubro,
                proveedor.Contacto,
                proveedor.Telefono,
                proveedor.Correo,
                proveedor.Direccion,
                proveedor.IdEstadoProveedor,
                IdUsuario = idUsuario
            },
            commandType: CommandType.StoredProcedure);
    }

    private sealed class ProveedorDetalleRow
    {
        public int Id { get; set; }
        public string Ruc { get; set; } = string.Empty;
        public string RazonSocial { get; set; } = string.Empty;
        public string TipoProveedor { get; set; } = string.Empty;
        public string? Rubro { get; set; }
        public string? Contacto { get; set; }
        public string? Telefono { get; set; }
        public string? Correo { get; set; }
        public string? Direccion { get; set; }
        public string Estado { get; set; } = string.Empty;
        public string? Clasificacion { get; set; }
        public decimal? PuntajePromedio { get; set; }
        public int Evaluaciones { get; set; }
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
