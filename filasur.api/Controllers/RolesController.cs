using filasur.api.Models;
using filasur.application.Interfaces;
using filasur.domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace filasur.api.Controllers;

[Authorize]
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
}
