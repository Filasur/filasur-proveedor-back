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
    public async Task<ActionResult<ApiResult<object>>> Resumen()
    {
        var data = await _service.ObtenerAsync();
        if (data is null)
        {
            return Ok(ApiResult<object>.Ok(new
            {
                resumen = new DashboardResumen(),
                evaluacionesRecientes = Array.Empty<DashboardEvaluacionItem>(),
                proximasVencer = Array.Empty<DashboardEvaluacionItem>()
            }));
        }

        return Ok(ApiResult<object>.Ok(new
        {
            resumen = data.Resumen,
            evaluacionesRecientes = data.EvaluacionesRecientes,
            proximasVencer = data.ProximasVencer,
            chartLabels = data.EvolucionMensual.Select(x => x.Mes).ToList(),
            chartScores = data.EvolucionMensual.Select(x => x.Puntaje).ToList()
        }));
    }
}
