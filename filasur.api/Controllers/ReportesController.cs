using filasur.api.Models;
using filasur.api.Security;
using filasur.application.Interfaces;
using filasur.domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace filasur.api.Controllers;

[Authorize(Roles = AppRoles.Reportes)]
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
    public async Task<ActionResult<ApiResult<ReporteEvaluaciones>>> Listar(
        [FromQuery] string? estado,
        [FromQuery] DateTime? fechaDesde,
        [FromQuery] DateTime? fechaHasta,
        [FromQuery] string? producto)
    {
        var data = await _service.ObtenerReporteEvaluacionesAsync(estado, fechaDesde, fechaHasta, producto);
        return Ok(ApiResult<ReporteEvaluaciones>.Ok(data));
    }
}
