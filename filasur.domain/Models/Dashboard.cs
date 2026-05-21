namespace filasur.domain.Models;

public class DashboardResumen
{
    public int ProveedoresRegistrados { get; set; }
    public int EvaluacionesEnProceso { get; set; }
    public int EvaluacionesFinalizadas { get; set; }
    public int ProveedoresAprobados { get; set; }
    public decimal? PuntajePromedio { get; set; }
}

public class RankingItem
{
    public int Posicion { get; set; }
    public string Proveedor { get; set; } = string.Empty;
    public decimal Puntaje { get; set; }
    public string Clasificacion { get; set; } = string.Empty;
    public int Evaluaciones { get; set; }
}

public class BitacoraItem
{
    public int Id { get; set; }
    public string Fecha { get; set; } = string.Empty;
    public string Usuario { get; set; } = string.Empty;
    public string Accion { get; set; } = string.Empty;
    public string? Detalle { get; set; }
    public string Modulo { get; set; } = string.Empty;
}

public class ConfiguracionSistema
{
    public decimal UmbralAprobacion { get; set; }
    public decimal UmbralObservado { get; set; }
    public int DiasAlertaVencimiento { get; set; }
    public byte NotificacionesEmail { get; set; }
    public string IntegracionErp { get; set; } = string.Empty;
}

public class ConfiguracionGuardar
{
    public decimal UmbralAprobacion { get; set; }
    public decimal UmbralObservado { get; set; }
    public int DiasAlertaVencimiento { get; set; }
    public byte NotificacionesEmail { get; set; }
    public string IntegracionErp { get; set; } = string.Empty;
}
