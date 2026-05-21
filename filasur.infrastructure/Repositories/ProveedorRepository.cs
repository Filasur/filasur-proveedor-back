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
}
