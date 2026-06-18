using filasur.api.Extensions;
using filasur.api.Models;
using filasur.api.Security;
using filasur.application.Interfaces;
using filasur.domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace filasur.api.Controllers;

[Authorize(Roles = AppRoles.GestionProveedores)]
[ApiController]
[Route("api/proveedores")]
public class ProveedoresController : ControllerBase
{
    private readonly IProveedorService _service;

    public ProveedoresController(IProveedorService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResult<IEnumerable<ProveedorListItem>>>> Listar([FromQuery] string? q)
    {
        var data = await _service.ListarAsync(q);
        return Ok(ApiResult<IEnumerable<ProveedorListItem>>.Ok(data));
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ApiResult<object>>> Obtener(int id)
    {
        var data = await _service.ObtenerAsync(id);
        if (data is null)
            return NotFound(ApiResult<object>.Fail("Proveedor no encontrado"));

        return Ok(ApiResult<object>.Ok(new
        {
            data.Id,
            data.Ruc,
            data.RazonSocial,
            data.TipoProveedor,
            data.Rubro,
            data.Contacto,
            data.Telefono,
            data.Correo,
            data.Direccion,
            data.Estado,
            data.Clasificacion,
            data.PuntajePromedio,
            evaluaciones = data.EvaluacionesLista,
            documentos = data.Documentos,
            historial = data.Historial
        }));
    }

    [HttpPost]
    public async Task<ActionResult<ApiResult<object>>> Registrar([FromBody] ProveedorRegistrar request)
    {
        var id = await _service.RegistrarAsync(request, User.GetUserId());
        return Ok(ApiResult<object>.Ok(new { id }));
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<ApiResult<object>>> Actualizar(int id, [FromBody] ProveedorActualizar request)
    {
        await _service.ActualizarAsync(id, request, User.GetUserId());
        return Ok(ApiResult<object>.Ok(new { id }));
    }
}
