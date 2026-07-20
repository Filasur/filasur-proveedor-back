namespace filasur.api.Security;

/// <summary>
/// Nombres de módulo alineados con RolModulo (BD) y el front (MODULOS).
/// </summary>
public static class AppModulos
{
    public const string ClaimType = "modulo";

    public const string Todos = "Todos";
    public const string Proveedores = "Proveedores";
    public const string Evaluaciones = "Evaluaciones";
    public const string Reportes = "Reportes";
    public const string Documentos = "Documentos";
    public const string Criterios = "Criterios";
    public const string Unidades = "Unidades";
    public const string Productos = "Productos";
    public const string Usuarios = "Usuarios";
    public const string Roles = "Roles";
    public const string Configuracion = "Configuración";
    public const string Bitacora = "Bitácora";

    public static string Policy(params string[] modulos) =>
        "Modulo:" + string.Join(',', modulos);
}
