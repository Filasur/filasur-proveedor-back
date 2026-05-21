using filasur.application.Interfaces;
using filasur.domain.Interfaces;
using filasur.domain.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace filasur.application.Services;

public class AuthService : IAuthService
{
    private readonly IAuthRepository _authRepository;
    private readonly IConfiguration _configuration;

    public AuthService(IAuthRepository authRepository, IConfiguration configuration)
    {
        _authRepository = authRepository;
        _configuration = configuration;
    }

    public async Task<LoginResult?> LoginAsync(string email, string password)
    {
        var credencial = await _authRepository.ObtenerPorEmailAsync(email);
        if (credencial is null || !BCrypt.Net.BCrypt.Verify(password, credencial.PasswordHash))
            return null;

        var user = new UsuarioLogin
        {
            Id = credencial.Id,
            Nombre = credencial.Nombre,
            Email = credencial.Email,
            Rol = credencial.Rol,
            Iniciales = credencial.Iniciales
        };

        return new LoginResult { Token = GenerarToken(user), User = user };
    }

    private string GenerarToken(UsuarioLogin user)
    {
        var jwt = _configuration.GetSection("Jwt");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt["Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Name, user.Nombre),
            new Claim(ClaimTypes.Role, user.Rol)
        };

        var token = new JwtSecurityToken(
            issuer: jwt["Issuer"],
            audience: jwt["Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddHours(1),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
