using filasur.api.Models;
using filasur.api.Security;
using filasur.application.Interfaces;
using filasur.domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace filasur.api.Controllers;

[Authorize(Roles = AppRoles.Administracion)]
[ApiController]
[Route("api/bitacora")]
public class BitacoraController : ControllerBase
{
    private readonly IBitacoraService _service;

    public BitacoraController(IBitacoraService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResult<IEnumerable<BitacoraItem>>>> Listar([FromQuery] int top = 100)
    {
        var data = await _service.ListarAsync(top);
        return Ok(ApiResult<IEnumerable<BitacoraItem>>.Ok(data));
    }
}
