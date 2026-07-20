using filasur.api.Models;
using filasur.api.Extensions;
using filasur.application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace filasur.api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [AllowAnonymous]
    [HttpPost("login")]
    public async Task<ActionResult<ApiResult<object>>> Login([FromBody] LoginRequest request)
    {
        LoginResult? result;
        try
        {
            result = await _authService.LoginAsync(request.Email, request.Password);
            if (result is null)
                return Unauthorized(ApiResult<object>.Fail("Credenciales inválidas"));
        }
        catch (InvalidOperationException ex)
        {
            return Unauthorized(ApiResult<object>.Fail(ex.Message));
        }

        return Ok(ApiResult<object>.Ok(new { token = result.Token, user = result.User }));
    }

    [AllowAnonymous]
    [HttpPost("recuperar-password")]
    public async Task<ActionResult<ApiResult<object>>> RecuperarPassword([FromBody] RecuperarPasswordRequest request)
    {
        var result = await _authService.RecuperarPasswordAsync(request.Email);
        if (result is null)
            return Ok(ApiResult<object>.Ok(new { message = "Si el correo existe, se generará una contraseña temporal." }));

        return Ok(ApiResult<object>.Ok(new
        {
            message = "Contraseña temporal generada. Cámbiela al iniciar sesión.",
            passwordTemporal = result.PasswordTemporal
        }));
    }

    [Authorize]
    [HttpPost("logout")]
    public async Task<ActionResult<ApiResult<object>>> Logout()
    {
        await _authService.LogoutAsync(
            User.GetUserId(),
            User.FindFirst(ClaimTypes.Email)?.Value,
            User.FindFirst(ClaimTypes.Role)?.Value);
        return Ok(ApiResult<object>.Ok(new { message = "Sesión cerrada." }));
    }

    [Authorize]
    [HttpPost("cambiar-password")]
    public async Task<ActionResult<ApiResult<object>>> CambiarPassword([FromBody] CambiarPasswordRequest request)
    {
        try
        {
            await _authService.CambiarPasswordAsync(User.GetUserId(), request.PasswordActual, request.PasswordNueva);
            return Ok(ApiResult<object>.Ok(new { message = "Contraseña actualizada correctamente." }));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResult<object>.Fail(ex.Message));
        }
    }
}

public class LoginRequest
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public class RecuperarPasswordRequest
{
    public string Email { get; set; } = string.Empty;
}

public class CambiarPasswordRequest
{
    public string PasswordActual { get; set; } = string.Empty;
    public string PasswordNueva { get; set; } = string.Empty;
}
