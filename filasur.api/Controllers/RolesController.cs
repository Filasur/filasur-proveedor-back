using filasur.api.Models;
using filasur.api.Security;
using filasur.application.Interfaces;
using filasur.domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace filasur.api.Controllers;

[Authorize(Roles = AppRoles.Administracion)]
[ApiController]
[Route("api/roles")]
public class RolesController : ControllerBase
{
    private readonly ICatalogoService _service;

    public RolesController(ICatalogoService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResult<IEnumerable<RolListItem>>>> Listar()
    {
        var data = await _service.ListarRolesAsync();
        return Ok(ApiResult<IEnumerable<RolListItem>>.Ok(data));
    }

    [HttpPut("{id:int}/modulos")]
    public async Task<ActionResult<ApiResult<RolListItem>>> ActualizarModulos(
        int id,
        [FromBody] RolActualizarModulos request)
    {
        var data = await _service.ActualizarRolModulosAsync(id, request);
        return Ok(ApiResult<RolListItem>.Ok(data));
    }
}
