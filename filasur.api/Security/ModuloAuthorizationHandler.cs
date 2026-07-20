using Microsoft.AspNetCore.Authorization;

namespace filasur.api.Security;

/// <summary>
/// Exige que el usuario tenga al menos uno de los módulos indicados
/// (claim JWT «modulo»), o el módulo «Todos».
/// </summary>
public sealed class ModuloRequirement : IAuthorizationRequirement
{
    public IReadOnlyList<string> Modulos { get; }

    public ModuloRequirement(IEnumerable<string> modulos)
    {
        Modulos = modulos
            .Where(m => !string.IsNullOrWhiteSpace(m))
            .Select(m => m.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }
}

public sealed class ModuloAuthorizationHandler : AuthorizationHandler<ModuloRequirement>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        ModuloRequirement requirement)
    {
        if (requirement.Modulos.Count == 0)
            return Task.CompletedTask;

        var otorgados = context.User.FindAll(AppModulos.ClaimType)
            .Select(c => c.Value)
            .Where(v => !string.IsNullOrWhiteSpace(v))
            .ToList();

        if (otorgados.Count == 0)
            return Task.CompletedTask;

        if (otorgados.Any(m => string.Equals(m, AppModulos.Todos, StringComparison.OrdinalIgnoreCase)))
        {
            context.Succeed(requirement);
            return Task.CompletedTask;
        }

        var ok = requirement.Modulos.Any(req =>
            otorgados.Any(m => string.Equals(m, req, StringComparison.OrdinalIgnoreCase)));

        if (ok)
            context.Succeed(requirement);

        return Task.CompletedTask;
    }
}
