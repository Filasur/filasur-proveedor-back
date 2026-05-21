namespace filasur.domain.Models;

public class UnidadMedidaItem
{
    public int Id { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public string? Descripcion { get; set; }
    public bool Activo { get; set; }
}

public class UnidadMedidaGuardar
{
    public string Codigo { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public string? Descripcion { get; set; }
    public bool Activo { get; set; } = true;
}

public class ProductoListItem
{
    public int Id { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public string? Categoria { get; set; }
    public string Unidad { get; set; } = string.Empty;
}

public class ProductoGuardar
{
    public string Codigo { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public string? Categoria { get; set; }
    public string Unidad { get; set; } = string.Empty;
}

public class UsuarioListItem
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Rol { get; set; } = string.Empty;
    public string Estado { get; set; } = string.Empty;
}

public class UsuarioCrear
{
    public string Nombre { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Rol { get; set; } = string.Empty;
}

public class UsuarioActualizar
{
    public string Nombre { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Rol { get; set; } = string.Empty;
    public string Estado { get; set; } = string.Empty;
}

public class RolListItem
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string? Descripcion { get; set; }
    public List<string> Modulos { get; set; } = [];
}

public class ReporteEvaluaciones
{
    public int Total { get; set; }
    public int Aprobados { get; set; }
    public int Observados { get; set; }
    public int Rechazados { get; set; }
    public List<ReporteEvaluacionFila> Filas { get; set; } = [];
}

public class ReporteEvaluacionFila
{
    public int Id { get; set; }
    public string Proveedor { get; set; } = string.Empty;
    public string? Producto { get; set; }
    public string? FechaEvaluacion { get; set; }
    public decimal? PuntajeFinal { get; set; }
    public string Estado { get; set; } = string.Empty;
}

public class CriterioGuardarItem
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string Area { get; set; } = string.Empty;
    public decimal Peso { get; set; }
    public bool Activo { get; set; }
}
