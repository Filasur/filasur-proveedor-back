using filasur.domain.Models;

namespace filasur.application.Interfaces;

public class LoginResult
{
    public string Token { get; set; } = string.Empty;
    public UsuarioLogin User { get; set; } = new();
}

public class RecuperarPasswordResult
{
    public string PasswordTemporal { get; set; } = string.Empty;
}

public interface IAuthService
{
    Task<LoginResult?> LoginAsync(string email, string password);
    Task<RecuperarPasswordResult?> RecuperarPasswordAsync(string email);
    Task CambiarPasswordAsync(int idUsuario, string passwordActual, string passwordNueva);
}
