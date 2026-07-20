using System.Security.Claims;

namespace filasur.api.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static int GetUserId(this ClaimsPrincipal user)
    {
        var id = user.FindFirstValue(ClaimTypes.NameIdentifier);
        return int.TryParse(id, out var userId) ? userId : 0;
    }

    public static string? GetUserRole(this ClaimsPrincipal user) =>
        user.FindFirstValue(ClaimTypes.Role);
}
