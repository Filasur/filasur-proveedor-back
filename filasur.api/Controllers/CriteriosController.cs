using filasur.api.Models;
using filasur.application.Interfaces;
using filasur.domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace filasur.api.Controllers;

[Authorize]
[ApiController]
[Route("api/criterios")]
public class CriteriosController : ControllerBase
{
    private readonly ICriterioService _service;

    public CriteriosController(ICriterioService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResult<IEnumerable<CriterioListItem>>>> Listar()
    {
        var data = await _service.ListarAsync();
        return Ok(ApiResult<IEnumerable<CriterioListItem>>.Ok(data));
    }

    [HttpPut]
    public async Task<ActionResult<ApiResult<IEnumerable<CriterioListItem>>>> Guardar(
        [FromBody] List<CriterioGuardarItem> lista)
    {
        var data = await _service.GuardarAsync(lista);
        return Ok(ApiResult<IEnumerable<CriterioListItem>>.Ok(data));
    }
}
