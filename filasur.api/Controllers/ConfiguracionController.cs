using filasur.api.Extensions;
using filasur.api.Models;
using filasur.api.Security;
using filasur.application.Interfaces;
using filasur.domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace filasur.api.Controllers;

[AuthorizeModulo(AppModulos.Configuracion)]
[ApiController]
[Route("api/configuracion")]
public class ConfiguracionController : ControllerBase
{
    private readonly IConfiguracionService _service;

    public ConfiguracionController(IConfiguracionService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResult<ConfiguracionSistema>>> Obtener()
    {
        var data = await _service.ObtenerAsync();
        return Ok(ApiResult<ConfiguracionSistema>.Ok(data ?? new ConfiguracionSistema()));
    }

    [HttpPut]
    public async Task<ActionResult<ApiResult<object>>> Guardar([FromBody] ConfiguracionGuardar request)
    {
        await _service.GuardarAsync(request, User.GetUserId());
        return Ok(ApiResult<object>.Ok(new { ok = true }));
    }
}
