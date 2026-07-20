using Microsoft.AspNetCore.Authorization;

namespace filasur.api.Security;

/// <summary>
/// Autoriza si el JWT incluye al menos uno de los módulos (RolModulo).
/// Uso: [AuthorizeModulo(AppModulos.Reportes)]
///      [AuthorizeModulo(AppModulos.Proveedores, AppModulos.Reportes)]
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = true, Inherited = true)]
public sealed class AuthorizeModuloAttribute : AuthorizeAttribute
{
    public AuthorizeModuloAttribute(params string[] modulos)
    {
        if (modulos is null || modulos.Length == 0)
            throw new ArgumentException("Debe indicar al menos un módulo.", nameof(modulos));

        Policy = AppModulos.Policy(modulos);
    }
}
