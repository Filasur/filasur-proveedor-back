using filasur.api.Models;
using filasur.api.Security;
using filasur.application.Interfaces;
using filasur.domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace filasur.api.Controllers;

[Authorize]
[ApiController]
[Route("api/unidades")]
public class UnidadesController : ControllerBase
{
    private readonly ICatalogoService _service;

    public UnidadesController(ICatalogoService service)
    {
        _service = service;
    }

    [HttpGet]
    [AuthorizeModulo(AppModulos.Unidades, AppModulos.Evaluaciones, AppModulos.Proveedores)]
    public async Task<ActionResult<ApiResult<IEnumerable<UnidadMedidaItem>>>> Listar()
    {
        var data = await _service.ListarUnidadesAsync();
        return Ok(ApiResult<IEnumerable<UnidadMedidaItem>>.Ok(data));
    }

    [HttpPost]
    [AuthorizeModulo(AppModulos.Unidades)]
    public async Task<ActionResult<ApiResult<UnidadMedidaItem>>> Crear([FromBody] UnidadMedidaGuardar request)
    {
        var data = await _service.RegistrarUnidadAsync(request);
        return Ok(ApiResult<UnidadMedidaItem>.Ok(data));
    }

    [HttpPut("{id:int}")]
    [AuthorizeModulo(AppModulos.Unidades)]
    public async Task<ActionResult<ApiResult<UnidadMedidaItem>>> Actualizar(int id, [FromBody] UnidadMedidaGuardar request)
    {
        var data = await _service.ActualizarUnidadAsync(id, request);
        return Ok(ApiResult<UnidadMedidaItem>.Ok(data));
    }
}
