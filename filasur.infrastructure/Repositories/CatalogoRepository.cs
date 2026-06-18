using Dapper;
using filasur.domain.Interfaces;
using filasur.domain.Models;
using filasur.infrastructure.Data;
using System.Data;

namespace filasur.infrastructure.Repositories;

public class CatalogoRepository : ICatalogoRepository
{
    private readonly ISqlConnectionFactory _factory;

    public CatalogoRepository(ISqlConnectionFactory factory)
    {
        _factory = factory;
    }

    public async Task<IEnumerable<UnidadMedidaItem>> ListarUnidadesAsync()
    {
        using var conn = _factory.CreateConnection();
        return await conn.QueryAsync<UnidadMedidaItem>(
            "dbo.sp_UnidadMedida_Listar",
            commandType: CommandType.StoredProcedure);
    }

    public async Task<UnidadMedidaItem?> ObtenerUnidadAsync(int id)
    {
        var lista = await ListarUnidadesAsync();
        return lista.FirstOrDefault(u => u.Id == id);
    }

    public async Task<int> RegistrarUnidadAsync(UnidadMedidaGuardar unidad)
    {
        using var conn = _factory.CreateConnection();
        var p = new DynamicParameters();
        p.Add("@Codigo", unidad.Codigo);
        p.Add("@Nombre", unidad.Nombre);
        p.Add("@Descripcion", unidad.Descripcion);
        p.Add("@Activo", unidad.Activo);
        p.Add("@IdUnidad", dbType: DbType.Int32, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
            "dbo.sp_UnidadMedida_Registrar",
            p,
            commandType: CommandType.StoredProcedure);

        return p.Get<int>("@IdUnidad");
    }

    public async Task ActualizarUnidadAsync(int id, UnidadMedidaGuardar unidad)
    {
        using var conn = _factory.CreateConnection();
        await conn.ExecuteAsync(
            "dbo.sp_UnidadMedida_Actualizar",
            new
            {
                IdUnidad = id,
                unidad.Codigo,
                unidad.Nombre,
                unidad.Descripcion,
                unidad.Activo
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<ProductoListItem>> ListarProductosAsync()
    {
        using var conn = _factory.CreateConnection();
        return await conn.QueryAsync<ProductoListItem>(
            "dbo.sp_Producto_Listar",
            commandType: CommandType.StoredProcedure);
    }

    public async Task<ProductoListItem?> ObtenerProductoAsync(int id)
    {
        var lista = await ListarProductosAsync();
        return lista.FirstOrDefault(p => p.Id == id);
    }

    public async Task<int> RegistrarProductoAsync(ProductoGuardar producto)
    {
        using var conn = _factory.CreateConnection();
        var p = new DynamicParameters();
        p.Add("@Codigo", producto.Codigo);
        p.Add("@Nombre", producto.Nombre);
        p.Add("@Categoria", producto.Categoria);
        p.Add("@UnidadCodigo", producto.Unidad);
        p.Add("@IdProducto", dbType: DbType.Int32, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
            "dbo.sp_Producto_Registrar",
            p,
            commandType: CommandType.StoredProcedure);

        return p.Get<int>("@IdProducto");
    }

    public async Task ActualizarProductoAsync(int id, ProductoGuardar producto)
    {
        using var conn = _factory.CreateConnection();
        await conn.ExecuteAsync(
            "dbo.sp_Producto_Actualizar",
            new
            {
                IdProducto = id,
                producto.Codigo,
                producto.Nombre,
                producto.Categoria,
                UnidadCodigo = producto.Unidad
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<UsuarioListItem>> ListarUsuariosAsync()
    {
        using var conn = _factory.CreateConnection();
        return await conn.QueryAsync<UsuarioListItem>(
            "dbo.sp_Usuario_Listar",
            commandType: CommandType.StoredProcedure);
    }

    public async Task<UsuarioListItem?> ObtenerUsuarioAsync(int id)
    {
        var lista = await ListarUsuariosAsync();
        return lista.FirstOrDefault(u => u.Id == id);
    }

    public async Task<int> RegistrarUsuarioAsync(UsuarioCrear usuario, string passwordHash)
    {
        using var conn = _factory.CreateConnection();
        var p = new DynamicParameters();
        p.Add("@NombreCompleto", usuario.Nombre);
        p.Add("@Email", usuario.Email);
        p.Add("@RolNombre", usuario.Rol);
        p.Add("@PasswordHash", passwordHash);
        p.Add("@IdUsuario", dbType: DbType.Int32, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
            "dbo.sp_Usuario_Registrar",
            p,
            commandType: CommandType.StoredProcedure);

        return p.Get<int>("@IdUsuario");
    }

    public async Task ActualizarUsuarioAsync(int id, UsuarioActualizar usuario)
    {
        using var conn = _factory.CreateConnection();
        await conn.ExecuteAsync(
            "dbo.sp_Usuario_Actualizar",
            new
            {
                IdUsuario = id,
                NombreCompleto = usuario.Nombre,
                usuario.Email,
                RolNombre = usuario.Rol,
                usuario.Estado
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task DesbloquearUsuarioAsync(int id)
    {
        using var conn = _factory.CreateConnection();
        await conn.ExecuteAsync(
            """
            UPDATE dbo.Usuario
            SET IntentosFallidos = 0,
                BloqueadoHasta = NULL,
                FechaModificacion = SYSUTCDATETIME()
            WHERE IdUsuario = @IdUsuario
            """,
            new { IdUsuario = id });
    }

    public async Task<IEnumerable<RolListItem>> ListarRolesAsync()
    {
        using var conn = _factory.CreateConnection();
        using var multi = await conn.QueryMultipleAsync(
            "dbo.sp_Rol_Listar",
            commandType: CommandType.StoredProcedure);

        var roles = (await multi.ReadAsync<RolRow>()).ToList();
        var modulos = (await multi.ReadAsync<RolModuloRow>()).ToList();

        return roles.Select(r => new RolListItem
        {
            Id = r.Id,
            Nombre = r.Nombre,
            Descripcion = r.Descripcion,
            Modulos = modulos.Where(m => m.IdRol == r.Id).Select(m => m.Modulo).ToList()
        }).ToList();
    }

    public async Task ActualizarRolModulosAsync(int idRol, IEnumerable<string> modulos)
    {
        var modulosNormalizados = modulos
            .Select(m => m.Trim())
            .Where(m => !string.IsNullOrWhiteSpace(m))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        using var conn = _factory.CreateConnection();
        conn.Open();
        using var tx = conn.BeginTransaction();

        try
        {
            await conn.ExecuteAsync(
                "DELETE FROM dbo.RolModulo WHERE IdRol = @IdRol",
                new { IdRol = idRol },
                tx);

            foreach (var modulo in modulosNormalizados)
            {
                await conn.ExecuteAsync(
                    "INSERT INTO dbo.RolModulo (IdRol, Modulo) VALUES (@IdRol, @Modulo)",
                    new { IdRol = idRol, Modulo = modulo },
                    tx);
            }

            tx.Commit();
        }
        catch
        {
            tx.Rollback();
            throw;
        }
    }

    public async Task<ReporteEvaluaciones> ObtenerReporteEvaluacionesAsync(
        string? estado,
        DateTime? fechaDesde,
        DateTime? fechaHasta,
        string? producto)
    {
        using var conn = _factory.CreateConnection();
        using var multi = await conn.QueryMultipleAsync(
            "dbo.sp_Reporte_Evaluaciones",
            new { Estado = estado, FechaDesde = fechaDesde, FechaHasta = fechaHasta, Producto = producto },
            commandType: CommandType.StoredProcedure);

        var filas = (await multi.ReadAsync<ReporteEvaluacionFila>()).ToList();
        var stats = await multi.ReadFirstOrDefaultAsync<ReporteStatsRow>();

        return new ReporteEvaluaciones
        {
            Total = stats?.Total ?? filas.Count,
            Aprobados = stats?.Aprobados ?? 0,
            Observados = stats?.Observados ?? 0,
            Rechazados = stats?.Rechazados ?? 0,
            Filas = filas
        };
    }

    private sealed class RolRow
    {
        public int Id { get; set; }
        public string Nombre { get; set; } = string.Empty;
        public string? Descripcion { get; set; }
    }

    private sealed class RolModuloRow
    {
        public int IdRol { get; set; }
        public string Modulo { get; set; } = string.Empty;
    }

    private sealed class ReporteStatsRow
    {
        public int Total { get; set; }
        public int Aprobados { get; set; }
        public int Observados { get; set; }
        public int Rechazados { get; set; }
    }
}
