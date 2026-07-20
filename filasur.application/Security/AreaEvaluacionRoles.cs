namespace filasur.application.Security;

/// <summary>
/// Mapeo área de criterio → rol del sistema que puede calificar.
/// Comercial y Costos los cubre Compras (no existen roles homónimos).
/// </summary>
public static class AreaEvaluacionRoles
{
    public const string Administrador = "Administrador";
    public const string Compras = "Compras";
    public const string Calidad = "Calidad";
    public const string Logistica = "Logística";

    private static readonly Dictionary<string, string> AreaARol = new(StringComparer.OrdinalIgnoreCase)
    {
        ["Calidad"] = Calidad,
        ["Logística"] = Logistica,
        ["Logistica"] = Logistica,
        ["Comercial"] = Compras,
        ["Costos"] = Compras,
        ["Compras"] = Compras,
    };

    public static string? RolParaArea(string? area)
    {
        if (string.IsNullOrWhiteSpace(area))
            return null;
        return AreaARol.TryGetValue(area.Trim(), out var rol) ? rol : null;
    }

    public static bool PuedeCalificarArea(string? rolUsuario, string? area)
    {
        if (string.IsNullOrWhiteSpace(rolUsuario))
            return false;
        if (string.Equals(rolUsuario, Administrador, StringComparison.OrdinalIgnoreCase))
            return true;
        var rolArea = RolParaArea(area);
        return rolArea is not null
            && string.Equals(rolUsuario, rolArea, StringComparison.OrdinalIgnoreCase);
    }
}
