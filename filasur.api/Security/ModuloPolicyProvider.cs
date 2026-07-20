using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Options;

namespace filasur.api.Security;

/// <summary>
/// Resuelve políticas dinámicas «Modulo:A,B,C» (OR entre módulos listados).
/// </summary>
public sealed class ModuloPolicyProvider : IAuthorizationPolicyProvider
{
    public const string Prefix = "Modulo:";

    private readonly DefaultAuthorizationPolicyProvider _fallback;

    public ModuloPolicyProvider(IOptions<AuthorizationOptions> options)
    {
        _fallback = new DefaultAuthorizationPolicyProvider(options);
    }

    public Task<AuthorizationPolicy> GetDefaultPolicyAsync() =>
        _fallback.GetDefaultPolicyAsync();

    public Task<AuthorizationPolicy?> GetFallbackPolicyAsync() =>
        _fallback.GetFallbackPolicyAsync();

    public Task<AuthorizationPolicy?> GetPolicyAsync(string policyName)
    {
        if (policyName.StartsWith(Prefix, StringComparison.OrdinalIgnoreCase))
        {
            var lista = policyName[Prefix.Length..]
                .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

            var policy = new AuthorizationPolicyBuilder()
                .RequireAuthenticatedUser()
                .AddRequirements(new ModuloRequirement(lista))
                .Build();

            return Task.FromResult<AuthorizationPolicy?>(policy);
        }

        return _fallback.GetPolicyAsync(policyName);
    }
}
