using filasur.api.Models;
using filasur.application.Interfaces;
using filasur.domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace filasur.api.Controllers;

[Authorize]
[ApiController]
[Route("api/reportes")]
public class ReportesController : ControllerBase
{
    private readonly ICatalogoService _service;

    public ReportesController(ICatalogoService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResult<ReporteEvaluaciones>>> Listar([FromQuery] string? estado)
    {
        var data = await _service.ObtenerReporteEvaluacionesAsync(estado);
        return Ok(ApiResult<ReporteEvaluaciones>.Ok(data));
    }
}
