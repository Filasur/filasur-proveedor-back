namespace filasur.domain.Models;

public class EvaluacionListItem
{
    public int Id { get; set; }
    public int ProveedorId { get; set; }
    public string Proveedor { get; set; } = string.Empty;
    public string? Producto { get; set; }
    public string? OrdenCompra { get; set; }
    public string? FechaEvaluacion { get; set; }
    public decimal? PuntajeFinal { get; set; }
    public string Estado { get; set; } = string.Empty;
    public int AreasPendientes { get; set; }
}

public class EvaluacionBorradorRequest
{
    public int ProveedorId { get; set; }
    public string Periodo { get; set; } = string.Empty;
    public int? IdProducto { get; set; }
    public string? OrdenCompra { get; set; }
    public DateTime? FechaLimite { get; set; }
    public string? Observaciones { get; set; }
    public Dictionary<string, decimal> Puntajes { get; set; } = new();
    public bool Finalizar { get; set; }
}

public class CriterioPuntaje
{
    public int IdCriterio { get; set; }
    public decimal Puntaje { get; set; }
}

public class EvaluacionConsolidacionCabecera
{
    public int Id { get; set; }
    public string Proveedor { get; set; } = string.Empty;
    public string? Producto { get; set; }
    public string? OrdenCompra { get; set; }
    public string? FechaEvaluacion { get; set; }
    public string? Periodo { get; set; }
    public decimal? PuntajeFinal { get; set; }
    public decimal PuntajeMax { get; set; }
    public string? Nivel { get; set; }
    public string? Resultado { get; set; }
    public string? Observaciones { get; set; }
}

public class EvaluacionConsolidacionArea
{
    public string Area { get; set; } = string.Empty;
    public string? Evaluador { get; set; }
    public decimal? Puntaje { get; set; }
    public decimal? Peso { get; set; }
    public decimal? Ponderado { get; set; }
    public string? Observaciones { get; set; }
}

public class EvaluacionConsolidacionCriterio
{
    public string Nombre { get; set; } = string.Empty;
    public decimal? Puntaje { get; set; }
    public decimal? Peso { get; set; }
}

public class EvaluacionConsolidacion
{
    public EvaluacionConsolidacionCabecera Cabecera { get; set; } = new();
    public List<EvaluacionConsolidacionArea> Areas { get; set; } = [];
    public List<EvaluacionConsolidacionCriterio> Criterios { get; set; } = [];
}
