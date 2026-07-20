using filasur.application.Interfaces;
using filasur.domain.Interfaces;
using filasur.domain.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;

namespace filasur.application.Services;

public class AuthService : IAuthService
{
    private const int MaxIntentosFallidos = 5;
    private readonly IAuthRepository _authRepository;
    private readonly IBitacoraRepository _bitacora;
    private readonly IConfiguracionRepository _configuracion;
    private readonly IEmailService _email;
    private readonly IConfiguration _configuration;

    public AuthService(
        IAuthRepository authRepository,
        IBitacoraRepository bitacora,
        IConfiguracionRepository configuracion,
        IEmailService email,
        IConfiguration configuration)
    {
        _authRepository = authRepository;
        _bitacora = bitacora;
        _configuracion = configuracion;
        _email = email;
        _configuration = configuration;
    }

    public async Task<LoginResult?> LoginAsync(string email, string password)
    {
        var credencial = await _authRepository.ObtenerPorEmailAsync(email);
        if (credencial is null)
        {
            await _bitacora.RegistrarAsync(
                null,
                "Autenticación",
                "Intento de inicio de sesión fallido",
                $"Email no registrado: {email}");
            return null;
        }

        if (!credencial.Activo)
            throw new InvalidOperationException("El usuario está inactivo. Contacte al administrador.");

        if (credencial.BloqueadoHasta.HasValue && credencial.BloqueadoHasta.Value > DateTime.UtcNow)
            throw new InvalidOperationException("La cuenta está bloqueada temporalmente. Intente nuevamente más tarde.");

        if (!BCrypt.Net.BCrypt.Verify(password, credencial.PasswordHash))
        {
            var bloquear = credencial.IntentosFallidos + 1 >= MaxIntentosFallidos;
            await _authRepository.RegistrarIntentoFallidoAsync(credencial.Id, bloquear);
            await _bitacora.RegistrarAsync(
                credencial.Id,
                "Autenticación",
                "Intento de inicio de sesión fallido",
                $"Usuario {credencial.Email} falló autenticación (intento {credencial.IntentosFallidos + 1})."
                    + (bloquear ? " Cuenta bloqueada temporalmente." : string.Empty));
            return null;
        }

        await _authRepository.ResetearIntentosAsync(credencial.Id);

        var modulos = await _authRepository.ObtenerModulosPorRolAsync(credencial.Rol);
        var user = new UsuarioLogin
        {
            Id = credencial.Id,
            Nombre = credencial.Nombre,
            Email = credencial.Email,
            Rol = credencial.Rol,
            Iniciales = credencial.Iniciales,
            DebeCambiarPassword = credencial.DebeCambiarPassword,
            Modulos = modulos.ToList()
        };

        await _bitacora.RegistrarAsync(
            user.Id,
            "Autenticación",
            "Inicio de sesión",
            $"Usuario {user.Email} ({user.Rol}) inició sesión.");

        return new LoginResult { Token = GenerarToken(user), User = user };
    }

    public async Task<RecuperarPasswordResult?> RecuperarPasswordAsync(string email)
    {
        var credencial = await _authRepository.ObtenerPorEmailAsync(email);
        if (credencial is null || !credencial.Activo)
            return null;

        var passwordTemporal = GenerarPasswordTemporal();
        var hash = BCrypt.Net.BCrypt.HashPassword(passwordTemporal);
        await _authRepository.ActualizarPasswordAsync(credencial.Id, hash, debeCambiarPassword: true);

        await _bitacora.RegistrarAsync(
            credencial.Id,
            "Autenticación",
            "Recuperación de contraseña",
            $"Se generó contraseña temporal para {credencial.Email}.");

        var cfg = await _configuracion.ObtenerAsync();
        if (cfg?.NotificacionesEmail == 1)
        {
            await _email.EnviarAsync(
                [credencial.Email],
                "Filasur — Contraseña temporal",
                $"<p>Hola {credencial.Nombre},</p>"
                + "<p>Se generó una contraseña temporal para su cuenta:</p>"
                + $"<p><strong>{passwordTemporal}</strong></p>"
                + "<p>Debe cambiarla al iniciar sesión.</p>");
        }

        return new RecuperarPasswordResult { PasswordTemporal = passwordTemporal };
    }

    public async Task CambiarPasswordAsync(int idUsuario, string passwordActual, string passwordNueva)
    {
        var credencial = await _authRepository.ObtenerPorIdAsync(idUsuario);
        if (credencial is null || !BCrypt.Net.BCrypt.Verify(passwordActual, credencial.PasswordHash))
            throw new InvalidOperationException("La contraseña actual no es válida.");

        ValidarPoliticaPassword(passwordNueva);

        if (BCrypt.Net.BCrypt.Verify(passwordNueva, credencial.PasswordHash))
            throw new InvalidOperationException("La nueva contraseña debe ser distinta a la actual.");

        var hash = BCrypt.Net.BCrypt.HashPassword(passwordNueva);
        await _authRepository.ActualizarPasswordAsync(idUsuario, hash, debeCambiarPassword: false);
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
            new Claim(ClaimTypes.Role, user.Rol),
            new Claim("debeCambiarPassword", user.DebeCambiarPassword ? "true" : "false")
        };

        var token = new JwtSecurityToken(
            issuer: jwt["Issuer"],
            audience: jwt["Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddHours(8),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static string GenerarPasswordTemporal()
    {
        const string chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789@$!%*?";
        return new string(Enumerable.Range(0, 12)
            .Select(_ => chars[RandomNumberGenerator.GetInt32(chars.Length)])
            .ToArray());
    }

    private static void ValidarPoliticaPassword(string password)
    {
        if (string.IsNullOrWhiteSpace(password) || password.Length < 8)
            throw new InvalidOperationException("La contraseña debe tener al menos 8 caracteres.");
        if (!Regex.IsMatch(password, "[A-Z]"))
            throw new InvalidOperationException("La contraseña debe incluir al menos una mayúscula.");
        if (!Regex.IsMatch(password, "[a-z]"))
            throw new InvalidOperationException("La contraseña debe incluir al menos una minúscula.");
        if (!Regex.IsMatch(password, "[0-9]"))
            throw new InvalidOperationException("La contraseña debe incluir al menos un número.");
        if (!Regex.IsMatch(password, "[^a-zA-Z0-9]"))
            throw new InvalidOperationException("La contraseña debe incluir al menos un carácter especial.");
    }
}
