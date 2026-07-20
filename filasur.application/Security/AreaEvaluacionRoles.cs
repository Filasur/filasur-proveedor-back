namespace filasur.application.Security;

/// <summary>
/// Mapeo área de criterio → rol del sistema que puede calificar.
/// Comercial y Costos los cubre Compras (no existen roles homónimos).
/// Evaluación por partes: Calidad → Compras → Logística.
/// </summary>
public static class AreaEvaluacionRoles
{
    public const string Administrador = "Administrador";
    public const string Compras = "Compras";
    public const string Calidad = "Calidad";
    public const string Logistica = "Logística";

    /// <summary>Orden obligatorio de fases por rol.</summary>
    public static readonly string[] OrdenFases = [Calidad, Compras, Logistica];

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

    public static bool PuedeIniciarEvaluacion(string? rolUsuario) =>
        string.Equals(rolUsuario, Administrador, StringComparison.OrdinalIgnoreCase)
        || string.Equals(rolUsuario, Calidad, StringComparison.OrdinalIgnoreCase);

    public static bool EsAdministrador(string? rolUsuario) =>
        string.Equals(rolUsuario, Administrador, StringComparison.OrdinalIgnoreCase);

    public static bool FaseCompleta(
        IEnumerable<(int Id, string? Area)> criteriosActivos,
        IReadOnlyDictionary<string, decimal> puntajes,
        string rolFase)
    {
        var deFase = criteriosActivos
            .Where(c => string.Equals(RolParaArea(c.Area), rolFase, StringComparison.OrdinalIgnoreCase))
            .ToList();

        if (deFase.Count == 0)
            return true;

        return deFase.All(c =>
            puntajes.ContainsKey(c.Id.ToString())
            || puntajes.ContainsKey(c.Id.ToString(System.Globalization.CultureInfo.InvariantCulture)));
    }

    /// <summary>Rol cuyo turno es ahora, o null si todas las fases están completas.</summary>
    public static string? FaseActual(
        IEnumerable<(int Id, string? Area)> criteriosActivos,
        IReadOnlyDictionary<string, decimal> puntajes)
    {
        var lista = criteriosActivos.ToList();
        foreach (var fase in OrdenFases)
        {
            if (!FaseCompleta(lista, puntajes, fase))
                return fase;
        }
        return null;
    }

    public static bool EsTurnoDelRol(
        string? rolUsuario,
        IEnumerable<(int Id, string? Area)> criteriosActivos,
        IReadOnlyDictionary<string, decimal> puntajes)
    {
        if (string.IsNullOrWhiteSpace(rolUsuario))
            return false;
        if (EsAdministrador(rolUsuario))
            return true;

        var actual = FaseActual(criteriosActivos, puntajes);
        return actual is not null
            && string.Equals(rolUsuario, actual, StringComparison.OrdinalIgnoreCase);
    }
}
