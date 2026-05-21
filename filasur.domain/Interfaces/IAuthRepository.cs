using filasur.domain.Models;

namespace filasur.domain.Interfaces;

public interface IAuthRepository
{
    Task<UsuarioCredencial?> ObtenerPorEmailAsync(string email);
}
