using filasur.domain.Models;

namespace filasur.application.Interfaces;

public class LoginResult
{
    public string Token { get; set; } = string.Empty;
    public UsuarioLogin User { get; set; } = new();
}

public interface IAuthService
{
    Task<LoginResult?> LoginAsync(string email, string password);
}
