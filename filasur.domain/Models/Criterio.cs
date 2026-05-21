namespace filasur.domain.Models;

public class CriterioListItem
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string Area { get; set; } = string.Empty;
    public decimal Peso { get; set; }
    public bool Activo { get; set; }
}
