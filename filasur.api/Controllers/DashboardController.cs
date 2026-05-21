using filasur.api.Models;
using filasur.application.Interfaces;
using filasur.domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace filasur.api.Controllers;

[Authorize]
[ApiController]
[Route("api/dashboard")]
public class DashboardController : ControllerBase
{
    private readonly IDashboardService _service;

    public DashboardController(IDashboardService service)
    {
        _service = service;
    }

    [HttpGet("resumen")]
    public async Task<ActionResult<ApiResult<DashboardResumen>>> Resumen()
    {
        var data = await _service.ObtenerResumenAsync();
        return Ok(ApiResult<DashboardResumen>.Ok(data ?? new DashboardResumen()));
    }
}
