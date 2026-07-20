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
    private const long MaxBytesPorArchivo = 10 * 1024 * 1024;

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
    [AuthorizeModulo(AppModulos.Documentos, AppModulos.Proveedores, AppModulos.Evaluaciones)]
    public async Task<ActionResult<ApiResult<IEnumerable<DocumentoListItem>>>> Listar(
        [FromQuery] int? proveedorId,
        [FromQuery] string? q)
    {
        var data = await _documentoService.ListarAsync(proveedorId, q);
        return Ok(ApiResult<IEnumerable<DocumentoListItem>>.Ok(data));
    }

    [HttpGet("documentos/categorias")]
    [AuthorizeModulo(AppModulos.Documentos, AppModulos.Proveedores)]
    public ActionResult<ApiResult<IEnumerable<string>>> Categorias()
    {
        return Ok(ApiResult<IEnumerable<string>>.Ok(CategoriasPermitidas.OrderBy(c => c)));
    }

    /// <summary>
    /// Carga documentos via JSON + Base64 (evita multipart, que falla en Cloud Run con ERR_CONNECTION_CLOSED).
    /// </summary>
    [HttpPost("proveedores/{idProveedor:int}/documentos")]
    [AuthorizeModulo(AppModulos.Documentos, AppModulos.Proveedores)]
    [RequestSizeLimit(52_428_800)]
    public async Task<ActionResult<ApiResult<object>>> SubirProveedor(
        int idProveedor,
        [FromBody] DocumentoUploadRequest? request)
    {
        if (request?.Archivos is null || request.Archivos.Count == 0)
            return Ok(ApiResult<object>.Ok(new { ids = Array.Empty<int>() }));

        var categoriaNorm = NormalizarCategoria(request.Categoria);
        if (!string.IsNullOrWhiteSpace(request.Categoria) && categoriaNorm is null)
            return BadRequest(ApiResult<object>.Fail("Categoría documental no válida."));

        DateTime? fechaVenc = null;
        if (!string.IsNullOrWhiteSpace(request.FechaVencimiento))
        {
            if (!DateTime.TryParse(request.FechaVencimiento, out var parsed))
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

            foreach (var item in request.Archivos)
            {
                if (string.IsNullOrWhiteSpace(item.NombreArchivo) || string.IsNullOrWhiteSpace(item.ContenidoBase64))
                    continue;

                var extension = Path.GetExtension(item.NombreArchivo);
                if (string.IsNullOrEmpty(extension) || !ExtensionesPermitidas.Contains(extension))
                    return BadRequest(ApiResult<object>.Fail($"Tipo de archivo no permitido: {item.NombreArchivo}"));

                byte[] bytes;
                try
                {
                    var base64 = item.ContenidoBase64;
                    var comma = base64.IndexOf(',');
                    if (base64.StartsWith("data:", StringComparison.OrdinalIgnoreCase) && comma >= 0)
                        base64 = base64[(comma + 1)..];

                    bytes = Convert.FromBase64String(base64);
                }
                catch (FormatException)
                {
                    return BadRequest(ApiResult<object>.Fail($"Contenido inválido para: {item.NombreArchivo}"));
                }

                if (bytes.Length == 0)
                    continue;

                if (bytes.Length > MaxBytesPorArchivo)
                    return BadRequest(ApiResult<object>.Fail(
                        $"El archivo '{item.NombreArchivo}' supera el máximo de 10 MB."));

                var nombreSeguro = $"{Guid.NewGuid():N}_{Path.GetFileName(item.NombreArchivo)}";
                var rutaRelativa = Path.Combine(carpetaRelativa, nombreSeguro).Replace('\\', '/');
                var rutaFisica = Path.Combine(carpetaFisica, nombreSeguro);

                await System.IO.File.WriteAllBytesAsync(rutaFisica, bytes);
                rutasFisicas.Add(rutaFisica);

                registros.Add(new DocumentoRegistro
                {
                    NombreArchivo = Path.GetFileName(item.NombreArchivo),
                    TipoArchivo = extension.TrimStart('.').ToUpperInvariant(),
                    TamanoBytes = bytes.LongLength,
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
                ? "La base de datos no tiene actualizada la gestión documental. Ejecute el script 08_documentos_gestion.sql en la BD del ambiente (Cloud Run)."
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
    [AuthorizeModulo(AppModulos.Documentos, AppModulos.Proveedores, AppModulos.Evaluaciones)]
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
    [AuthorizeModulo(AppModulos.Documentos, AppModulos.Proveedores)]
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

public class DocumentoUploadRequest
{
    public List<DocumentoUploadItemDto> Archivos { get; set; } = [];
    public string? Categoria { get; set; }
    public string? FechaVencimiento { get; set; }
}

public class DocumentoUploadItemDto
{
    public string NombreArchivo { get; set; } = string.Empty;
    public string ContenidoBase64 { get; set; } = string.Empty;
}
