using filasur.api.Models;
using filasur.application.Interfaces;
using filasur.domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace filasur.api.Controllers;

[Authorize]
[ApiController]
[Route("api/productos")]
public class ProductosController : ControllerBase
{
    private readonly ICatalogoService _service;

    public ProductosController(ICatalogoService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResult<IEnumerable<ProductoListItem>>>> Listar()
    {
        var data = await _service.ListarProductosAsync();
        return Ok(ApiResult<IEnumerable<ProductoListItem>>.Ok(data));
    }

    [HttpPost]
    public async Task<ActionResult<ApiResult<ProductoListItem>>> Crear([FromBody] ProductoGuardar request)
    {
        var data = await _service.RegistrarProductoAsync(request);
        return Ok(ApiResult<ProductoListItem>.Ok(data));
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<ApiResult<ProductoListItem>>> Actualizar(int id, [FromBody] ProductoGuardar request)
    {
        var data = await _service.ActualizarProductoAsync(id, request);
        return Ok(ApiResult<ProductoListItem>.Ok(data));
    }
}
