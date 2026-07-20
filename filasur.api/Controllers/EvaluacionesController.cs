using filasur.api.Extensions;
using filasur.api.Models;
using filasur.api.Security;
using filasur.application.Interfaces;
using filasur.domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace filasur.api.Controllers;

[AuthorizeModulo(AppModulos.Evaluaciones)]
[ApiController]
[Route("api/evaluaciones")]
public class EvaluacionesController : ControllerBase
{
    private readonly IEvaluacionService _service;
    private readonly ICriterioService _criterioService;

    public EvaluacionesController(IEvaluacionService service, ICriterioService criterioService)
    {
        _service = service;
        _criterioService = criterioService;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResult<IEnumerable<EvaluacionListItem>>>> Listar(
        [FromQuery] int? proveedorId,
        [FromQuery] string? estado,
        [FromQuery] bool? pendientes)
    {
        var data = await _service.ListarAsync(proveedorId, estado, pendientes);
        return Ok(ApiResult<IEnumerable<EvaluacionListItem>>.Ok(data));
    }

    [HttpGet("criterios")]
    public async Task<ActionResult<ApiResult<IEnumerable<CriterioListItem>>>> ListarCriterios()
    {
        var data = await _criterioService.ListarAsync();
        return Ok(ApiResult<IEnumerable<CriterioListItem>>.Ok(data));
    }

    [HttpGet("{id:int}/borrador")]
    public async Task<ActionResult<ApiResult<EvaluacionBorradorDetalle>>> ObtenerBorrador(int id)
    {
        var data = await _service.ObtenerBorradorAsync(id);
        if (data is null)
            return NotFound(ApiResult<EvaluacionBorradorDetalle>.Fail("Borrador no encontrado"));

        return Ok(ApiResult<EvaluacionBorradorDetalle>.Ok(data));
    }

    [HttpPost("borrador")]
    public async Task<ActionResult<ApiResult<object>>> GuardarBorrador([FromBody] EvaluacionBorradorRequest request)
    {
        try
        {
            var id = await _service.GuardarBorradorAsync(request, User.GetUserId(), User.GetUserRole());
            return Ok(ApiResult<object>.Ok(new { id }));
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, ApiResult<object>.Fail(ex.Message));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResult<object>.Fail(ex.Message));
        }
    }

    [HttpGet("{id:int}/consolidacion")]
    public async Task<ActionResult<ApiResult<object>>> Consolidacion(int id)
    {
        var data = await _service.ObtenerConsolidacionAsync(id);
        if (data is null)
            return NotFound(ApiResult<object>.Fail("Evaluación no encontrada"));

        return Ok(ApiResult<object>.Ok(new
        {
            id = data.Cabecera.Id,
            proveedor = data.Cabecera.Proveedor,
            producto = data.Cabecera.Producto,
            ordenCompra = data.Cabecera.OrdenCompra,
            fechaEvaluacion = data.Cabecera.FechaEvaluacion,
            periodo = data.Cabecera.Periodo,
            puntajeFinal = data.Cabecera.PuntajeFinal,
            puntajeMax = data.Cabecera.PuntajeMax,
            nivel = data.Cabecera.Nivel,
            resultado = data.Cabecera.Resultado,
            observaciones = data.Cabecera.Observaciones,
            areas = data.Areas,
            criterios = data.Criterios
        }));
    }

    [HttpPost("{id:int}/aprobar")]
    [Authorize(Roles = AppRoles.AprobacionEvaluaciones)]
    public async Task<ActionResult<ApiResult<object>>> Aprobar(int id)
    {
        await _service.AprobarAsync(id, User.GetUserId());
        return Ok(ApiResult<object>.Ok(new { id }));
    }

    [HttpPost("{id:int}/rechazar")]
    [Authorize(Roles = AppRoles.AprobacionEvaluaciones)]
    public async Task<ActionResult<ApiResult<object>>> Rechazar(int id, [FromBody] RechazarRequest? request)
    {
        await _service.RechazarAsync(id, User.GetUserId(), request?.Motivo);
        return Ok(ApiResult<object>.Ok(new { id }));
    }
}

public class RechazarRequest
{
    public string? Motivo { get; set; }
}
