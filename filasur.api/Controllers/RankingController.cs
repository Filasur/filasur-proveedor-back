using filasur.api.Models;
using filasur.api.Security;
using filasur.application.Interfaces;
using filasur.domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace filasur.api.Controllers;

[Authorize(Roles = AppRoles.Reportes)]
[ApiController]
[Route("api/ranking")]
public class RankingController : ControllerBase
{
    private readonly IRankingService _service;

    public RankingController(IRankingService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResult<IEnumerable<RankingItem>>>> Listar()
    {
        var data = await _service.ListarAsync();
        return Ok(ApiResult<IEnumerable<RankingItem>>.Ok(data));
    }
}
