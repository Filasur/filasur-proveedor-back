using filasur.domain.Models;

namespace filasur.domain.Interfaces;

public interface IAuthRepository
{
    Task<UsuarioCredencial?> ObtenerPorEmailAsync(string email);
    Task<UsuarioCredencial?> ObtenerPorIdAsync(int idUsuario);
    Task RegistrarIntentoFallidoAsync(int idUsuario, bool bloquear);
    Task ResetearIntentosAsync(int idUsuario);
    Task ActualizarPasswordAsync(int idUsuario, string passwordHash, bool debeCambiarPassword);
}
