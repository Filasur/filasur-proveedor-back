using filasur.api.Extensions;
using filasur.api.Models;
using filasur.api.Security;
using filasur.application.Interfaces;
using filasur.domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

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
    private readonly AppStorageOptions _storage;

    public DocumentosController(IDocumentoService documentoService, AppStorageOptions storage)
    {
        _documentoService = documentoService;
        _storage = storage;
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
    [RequestFormLimits(MultipartBodyLengthLimit = 52_428_800)]
    public async Task<ActionResult<ApiResult<object>>> SubirProveedor(
        int idProveedor,
        [FromForm] List<IFormFile>? archivos,
        [FromForm] string? categoria,
        [FromForm] string? fechaVencimiento)
    {
        if (archivos is null || archivos.Count == 0)
            return Ok(ApiResult<object>.Ok(new { ids = Array.Empty<int>() }));

        var categoriaNorm = NormalizarCategoria(categoria);
        if (!string.IsNullOrWhiteSpace(categoria) && categoriaNorm is null)
            return BadRequest(ApiResult<object>.Fail("Categoría documental no válida."));

        DateTime? fechaVenc = null;
        if (!string.IsNullOrWhiteSpace(fechaVencimiento))
        {
            if (!DateTime.TryParse(fechaVencimiento, out var parsed))
                return BadRequest(ApiResult<object>.Fail("Fecha de vencimiento no válida."));
            fechaVenc = parsed.Date;
        }

        var registros = new List<DocumentoRegistro>();
        var rutasFisicas = new List<string>();
        var carpetaRelativa = Path.Combine("proveedores", idProveedor.ToString());
        var carpetaFisica = Path.Combine(_storage.UploadsPath, carpetaRelativa);

        try
        {
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

                rutasFisicas.Add(rutaFisica);
                registros.Add(new DocumentoRegistro
                {
                    NombreArchivo = archivo.FileName,
                    TipoArchivo = extension.TrimStart('.').ToUpperInvariant(),
                    TamanoBytes = archivo.Length,
                    RutaAlmacenamiento = rutaRelativa,
                    CategoriaDocumento = categoriaNorm,
                    FechaVencimiento = fechaVenc
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
        catch (SqlException ex)
        {
            CleanupFiles(rutasFisicas);
            var msg = ex.Message.Contains("CategoriaDocumento", StringComparison.OrdinalIgnoreCase)
                || ex.Message.Contains("FechaVencimiento", StringComparison.OrdinalIgnoreCase)
                || ex.Message.Contains("too many arguments", StringComparison.OrdinalIgnoreCase)
                || ex.Message.Contains("demasiados argumentos", StringComparison.OrdinalIgnoreCase)
                ? "La base de datos no tiene actualizada la gestión documental. Ejecute el script 08_documentos_gestion.sql."
                : $"Error al registrar documentos: {ex.Message}";
            return StatusCode(StatusCodes.Status500InternalServerError, ApiResult<object>.Fail(msg));
        }
        catch (IOException ex)
        {
            CleanupFiles(rutasFisicas);
            return StatusCode(
                StatusCodes.Status500InternalServerError,
                ApiResult<object>.Fail($"No se pudo guardar el archivo en el servidor: {ex.Message}"));
        }
        catch (UnauthorizedAccessException ex)
        {
            CleanupFiles(rutasFisicas);
            return StatusCode(
                StatusCodes.Status500InternalServerError,
                ApiResult<object>.Fail($"Sin permiso para guardar archivos en el servidor: {ex.Message}"));
        }
    }

    [HttpGet("documentos/{id:int}/descargar")]
    [Authorize(Roles = AppRoles.GestionEvaluaciones)]
    public async Task<IActionResult> Descargar(int id)
    {
        var meta = await _documentoService.ObtenerArchivoAsync(id);
        if (meta is null || string.IsNullOrWhiteSpace(meta.RutaAlmacenamiento))
            return NotFound();

        var rutaFisica = Path.Combine(
            _storage.UploadsPath,
            meta.RutaAlmacenamiento.Replace('/', Path.DirectorySeparatorChar));
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
                _storage.UploadsPath,
                eliminado.RutaAlmacenamiento.Replace('/', Path.DirectorySeparatorChar));

            if (System.IO.File.Exists(rutaFisica))
                System.IO.File.Delete(rutaFisica);
        }

        return Ok(ApiResult<object>.Ok(new { id }));
    }

    private static void CleanupFiles(IEnumerable<string> rutas)
    {
        foreach (var ruta in rutas)
        {
            try
            {
                if (System.IO.File.Exists(ruta))
                    System.IO.File.Delete(ruta);
            }
            catch
            {
                // best-effort
            }
        }
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
