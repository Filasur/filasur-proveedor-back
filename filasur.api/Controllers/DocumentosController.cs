using filasur.api.Extensions;
using filasur.api.Models;
using filasur.api.Security;
using filasur.application.Interfaces;
using filasur.domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace filasur.api.Controllers;

[Authorize]
[ApiController]
[Route("api")]
public class DocumentosController : ControllerBase
{
    private static readonly HashSet<string> ExtensionesPermitidas = new(StringComparer.OrdinalIgnoreCase)
    {
        ".pdf", ".doc", ".docx", ".png", ".jpg", ".jpeg"
    };

    private static readonly HashSet<string> CategoriasPermitidas = new(StringComparer.OrdinalIgnoreCase)
    {
        "Ficha técnica",
        "Certificado",
        "RUC / Constancia",
        "Contrato",
        "Otro"
    };

    private readonly IDocumentoService _documentoService;
    private readonly IWebHostEnvironment _env;

    public DocumentosController(IDocumentoService documentoService, IWebHostEnvironment env)
    {
        _documentoService = documentoService;
        _env = env;
    }

    [HttpGet("documentos")]
    [Authorize(Roles = AppRoles.GestionEvaluaciones)]
    public async Task<ActionResult<ApiResult<IEnumerable<DocumentoListItem>>>> Listar(
        [FromQuery] int? proveedorId,
        [FromQuery] string? q)
    {
        var data = await _documentoService.ListarAsync(proveedorId, q);
        return Ok(ApiResult<IEnumerable<DocumentoListItem>>.Ok(data));
    }

    [HttpGet("documentos/categorias")]
    [Authorize(Roles = AppRoles.GestionProveedores)]
    public ActionResult<ApiResult<IEnumerable<string>>> Categorias()
    {
        return Ok(ApiResult<IEnumerable<string>>.Ok(CategoriasPermitidas.OrderBy(c => c)));
    }

    [HttpPost("proveedores/{idProveedor:int}/documentos")]
    [Authorize(Roles = AppRoles.GestionProveedores)]
    [RequestSizeLimit(52_428_800)]
    public async Task<ActionResult<ApiResult<object>>> SubirProveedor(
        int idProveedor,
        [FromForm] List<IFormFile>? archivos,
        [FromForm] string? categoria,
        [FromForm] DateTime? fechaVencimiento)
    {
        if (archivos is null || archivos.Count == 0)
            return Ok(ApiResult<object>.Ok(new { ids = Array.Empty<int>() }));

        var categoriaNorm = NormalizarCategoria(categoria);
        if (!string.IsNullOrWhiteSpace(categoria) && categoriaNorm is null)
            return BadRequest(ApiResult<object>.Fail("Categoría documental no válida."));

        var registros = new List<DocumentoRegistro>();
        var carpetaRelativa = Path.Combine("proveedores", idProveedor.ToString());
        var carpetaFisica = Path.Combine(_env.ContentRootPath, "uploads", carpetaRelativa);
        Directory.CreateDirectory(carpetaFisica);

        foreach (var archivo in archivos)
        {
            if (archivo.Length == 0)
                continue;

            var extension = Path.GetExtension(archivo.FileName);
            if (string.IsNullOrEmpty(extension) || !ExtensionesPermitidas.Contains(extension))
                return BadRequest(ApiResult<object>.Fail($"Tipo de archivo no permitido: {archivo.FileName}"));

            var nombreSeguro = $"{Guid.NewGuid():N}_{Path.GetFileName(archivo.FileName)}";
            var rutaRelativa = Path.Combine(carpetaRelativa, nombreSeguro).Replace('\\', '/');
            var rutaFisica = Path.Combine(carpetaFisica, nombreSeguro);

            await using (var stream = new FileStream(rutaFisica, FileMode.Create))
            {
                await archivo.CopyToAsync(stream);
            }

            registros.Add(new DocumentoRegistro
            {
                NombreArchivo = archivo.FileName,
                TipoArchivo = extension.TrimStart('.').ToUpperInvariant(),
                TamanoBytes = archivo.Length,
                RutaAlmacenamiento = rutaRelativa,
                CategoriaDocumento = categoriaNorm,
                FechaVencimiento = fechaVencimiento?.Date
            });
        }

        if (registros.Count == 0)
            return BadRequest(ApiResult<object>.Fail("No se recibieron archivos válidos."));

        var ids = await _documentoService.RegistrarProveedorAsync(
            idProveedor,
            registros,
            User.GetUserId());

        return Ok(ApiResult<object>.Ok(new { ids }));
    }

    [HttpGet("documentos/{id:int}/descargar")]
    [Authorize(Roles = AppRoles.GestionEvaluaciones)]
    public async Task<IActionResult> Descargar(int id)
    {
        var meta = await _documentoService.ObtenerArchivoAsync(id);
        if (meta is null || string.IsNullOrWhiteSpace(meta.RutaAlmacenamiento))
            return NotFound();

        var rutaFisica = Path.Combine(_env.ContentRootPath, "uploads", meta.RutaAlmacenamiento.Replace('/', Path.DirectorySeparatorChar));
        if (!System.IO.File.Exists(rutaFisica))
            return NotFound();

        var contentType = ObtenerContentType(meta.NombreArchivo);
        return PhysicalFile(rutaFisica, contentType, meta.NombreArchivo);
    }

    [HttpDelete("documentos/{id:int}")]
    [Authorize(Roles = AppRoles.GestionProveedores)]
    public async Task<ActionResult<ApiResult<object>>> Eliminar(int id)
    {
        var eliminado = await _documentoService.EliminarAsync(id, User.GetUserId());
        if (eliminado is null)
            return NotFound(ApiResult<object>.Fail("Documento no encontrado."));

        if (!string.IsNullOrWhiteSpace(eliminado.RutaAlmacenamiento))
        {
            var rutaFisica = Path.Combine(
                _env.ContentRootPath,
                "uploads",
                eliminado.RutaAlmacenamiento.Replace('/', Path.DirectorySeparatorChar));

            if (System.IO.File.Exists(rutaFisica))
                System.IO.File.Delete(rutaFisica);
        }

        return Ok(ApiResult<object>.Ok(new { id }));
    }

    private static string? NormalizarCategoria(string? categoria)
    {
        if (string.IsNullOrWhiteSpace(categoria))
            return null;

        return CategoriasPermitidas.FirstOrDefault(c =>
            string.Equals(c, categoria.Trim(), StringComparison.OrdinalIgnoreCase));
    }

    private static string ObtenerContentType(string nombreArchivo)
    {
        var ext = Path.GetExtension(nombreArchivo).ToLowerInvariant();
        return ext switch
        {
            ".pdf" => "application/pdf",
            ".png" => "image/png",
            ".jpg" or ".jpeg" => "image/jpeg",
            ".doc" => "application/msword",
            ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            _ => "application/octet-stream"
        };
    }
}
