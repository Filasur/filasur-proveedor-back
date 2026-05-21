namespace filasur.domain.Models;

public class ProveedorListItem
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

public class ProveedorRegistrar
{
    public string Ruc { get; set; } = string.Empty;
    public string RazonSocial { get; set; } = string.Empty;
    public byte IdTipoProveedor { get; set; }
    public string? Rubro { get; set; }
    public string? Contacto { get; set; }
    public string? Telefono { get; set; }
    public string? Correo { get; set; }
    public string? Direccion { get; set; }
}

public class ProveedorDetalle
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
    public List<EvaluacionListItem> EvaluacionesLista { get; set; } = [];
    public List<DocumentoListItem> Documentos { get; set; } = [];
    public List<BitacoraItem> Historial { get; set; } = [];
}

public class ProveedorActualizar
{
    public string RazonSocial { get; set; } = string.Empty;
    public byte IdTipoProveedor { get; set; }
    public string? Rubro { get; set; }
    public string? Contacto { get; set; }
    public string? Telefono { get; set; }
    public string? Correo { get; set; }
    public string? Direccion { get; set; }
    public byte? IdEstadoProveedor { get; set; }
}
