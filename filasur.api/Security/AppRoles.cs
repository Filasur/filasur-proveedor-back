namespace filasur.api.Security;

public static class AppRoles
{
    public const string Administrador = "Administrador";
    public const string Compras = "Compras";
    public const string Calidad = "Calidad";
    public const string Logistica = "Logística";

    public const string Administracion = Administrador;
    public const string GestionProveedores = $"{Administrador},{Compras},{Logistica}";
    public const string GestionEvaluaciones = $"{Administrador},{Compras},{Calidad},{Logistica}";
    /// <summary>Legacy; el acceso a reportes usa RolModulo / AuthorizeModulo.</summary>
    public const string Reportes = $"{Administrador},{Compras},{Logistica}";
    public const string Catalogos = $"{Administrador},{Compras}";
    public const string Documentos = $"{Administrador},{Compras},{Logistica}";
    /// <summary>Regla de negocio: solo Admin/Compras aprueban o rechazan (no se delega solo por módulo).</summary>
    public const string AprobacionEvaluaciones = $"{Administrador},{Compras}";
}
