using filasur.api.Models;
using filasur.api.Security;
using filasur.application.Interfaces;
using filasur.domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace filasur.api.Controllers;

[AuthorizeModulo(AppModulos.Usuarios)]
[ApiController]
[Route("api/usuarios")]
public class UsuariosController : ControllerBase
{
    private readonly ICatalogoService _service;

    public UsuariosController(ICatalogoService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResult<IEnumerable<UsuarioListItem>>>> Listar()
    {
        var data = await _service.ListarUsuariosAsync();
        return Ok(ApiResult<IEnumerable<UsuarioListItem>>.Ok(data));
    }

    [HttpPost]
    public async Task<ActionResult<ApiResult<UsuarioListItem>>> Crear([FromBody] UsuarioCrear request)
    {
        var data = await _service.RegistrarUsuarioAsync(request);
        return Ok(ApiResult<UsuarioListItem>.Ok(data));
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<ApiResult<UsuarioListItem>>> Actualizar(int id, [FromBody] UsuarioActualizar request)
    {
        var data = await _service.ActualizarUsuarioAsync(id, request);
        return Ok(ApiResult<UsuarioListItem>.Ok(data));
    }

    [HttpPost("{id:int}/desbloquear")]
    public async Task<ActionResult<ApiResult<UsuarioListItem>>> Desbloquear(int id)
    {
        var data = await _service.DesbloquearUsuarioAsync(id);
        return Ok(ApiResult<UsuarioListItem>.Ok(data));
    }
}
