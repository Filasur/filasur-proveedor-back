namespace filasur.domain.Models;

public class DocumentoListItem
{
    public int Id { get; set; }
    public int IdProveedor { get; set; }
    public string Proveedor { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public string Tipo { get; set; } = string.Empty;
    public string? Categoria { get; set; }
    public string Tamano { get; set; } = string.Empty;
    public string Fecha { get; set; } = string.Empty;
    public string? FechaVencimiento { get; set; }
    public string? Ruta { get; set; }
}

public class DocumentoRegistro
{
    public string NombreArchivo { get; set; } = string.Empty;
    public string TipoArchivo { get; set; } = string.Empty;
    public long TamanoBytes { get; set; }
    public string RutaAlmacenamiento { get; set; } = string.Empty;
    public string? CategoriaDocumento { get; set; }
    public DateTime? FechaVencimiento { get; set; }
}

public class DocumentoArchivo
{
    public string NombreArchivo { get; set; } = string.Empty;
    public string RutaAlmacenamiento { get; set; } = string.Empty;
}
