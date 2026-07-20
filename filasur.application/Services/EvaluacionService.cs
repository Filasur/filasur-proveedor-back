using filasur.application.Interfaces;
using filasur.application.Security;
using filasur.domain.Interfaces;
using filasur.domain.Models;

namespace filasur.application.Services;

public class EvaluacionService : IEvaluacionService
{
    private readonly IEvaluacionRepository _repository;
    private readonly ICriterioRepository _criterios;
    private readonly IConfiguracionRepository _configuracion;
    private readonly IAuthRepository _auth;
    private readonly IEmailService _email;

    public EvaluacionService(
        IEvaluacionRepository repository,
        ICriterioRepository criterios,
        IConfiguracionRepository configuracion,
        IAuthRepository auth,
        IEmailService email)
    {
        _repository = repository;
        _criterios = criterios;
        _configuracion = configuracion;
        _auth = auth;
        _email = email;
    }

    public async Task<IEnumerable<EvaluacionListItem>> ListarAsync(int? proveedorId, string? estado, bool? pendientes)
    {
        var items = await _repository.ListarAsync(proveedorId, estado);
        if (pendientes == true)
            return items.Where(e => e.AreasPendientes > 0);
        return items;
    }

    public Task<EvaluacionBorradorDetalle?> ObtenerBorradorAsync(int id) =>
        _repository.ObtenerBorradorAsync(id);

    public async Task<int> GuardarBorradorAsync(EvaluacionBorradorRequest request, int idUsuario, string? rolUsuario)
    {
        var criterios = (await _criterios.ListarAsync()).ToList();
        var porId = criterios.ToDictionary(c => c.Id);

        var puntajesFiltrados = new Dictionary<string, decimal>(StringComparer.Ordinal);
        foreach (var kv in request.Puntajes)
        {
            if (!int.TryParse(kv.Key, out var idCriterio) || !porId.TryGetValue(idCriterio, out var criterio))
                throw new InvalidOperationException($"Criterio inválido: {kv.Key}");

            if (!AreaEvaluacionRoles.PuedeCalificarArea(rolUsuario, criterio.Area))
            {
                throw new UnauthorizedAccessException(
                    $"El rol «{rolUsuario}» no puede calificar el criterio «{criterio.Nombre}» (área {criterio.Area}).");
            }

            puntajesFiltrados[kv.Key] = kv.Value;
        }

        var requestFiltrado = new EvaluacionBorradorRequest
        {
            Id = request.Id,
            ProveedorId = request.ProveedorId,
            Periodo = request.Periodo,
            IdProducto = request.IdProducto,
            OrdenCompra = request.OrdenCompra,
            FechaLimite = request.FechaLimite,
            Observaciones = request.Observaciones,
            Puntajes = puntajesFiltrados,
            Finalizar = request.Finalizar
        };

        if (request.Finalizar)
            await ValidarPuntajesCompletosParaFinalizarAsync(requestFiltrado, criterios);

        return await _repository.GuardarBorradorAsync(requestFiltrado, idUsuario);
    }

    public Task<EvaluacionConsolidacion?> ObtenerConsolidacionAsync(int id) =>
        _repository.ObtenerConsolidacionAsync(id);

    public async Task AprobarAsync(int id, int idUsuario)
    {
        await _repository.AprobarAsync(id, idUsuario);
        await NotificarDecisionAsync(id, aprobada: true, motivo: null);
    }

    public async Task RechazarAsync(int id, int idUsuario, string? motivo)
    {
        await _repository.RechazarAsync(id, idUsuario, motivo);
        await NotificarDecisionAsync(id, aprobada: false, motivo);
    }

    private async Task NotificarDecisionAsync(int idEvaluacion, bool aprobada, string? motivo)
    {
        var cfg = await _configuracion.ObtenerAsync();
        if (cfg?.NotificacionesEmail != 1)
            return;

        var data = await _repository.ObtenerConsolidacionAsync(idEvaluacion);
        if (data is null)
            return;

        var destinarios = await _auth.ObtenerEmailsPorRolesAsync(
            AreaEvaluacionRoles.Administrador,
            AreaEvaluacionRoles.Compras);

        var resultado = aprobada ? "APROBADO" : "RECHAZADO";
        var asunto = $"Filasur — Evaluación {resultado}: {data.Cabecera.Proveedor}";
        var cuerpo =
            $"<p>La evaluación <strong>#{idEvaluacion}</strong> del proveedor "
            + $"<strong>{data.Cabecera.Proveedor}</strong> fue marcada como <strong>{resultado}</strong>.</p>"
            + $"<p>Producto: {data.Cabecera.Producto ?? "—"}<br/>"
            + $"Puntaje: {data.Cabecera.PuntajeFinal} / {data.Cabecera.PuntajeMax}</p>"
            + (string.IsNullOrWhiteSpace(motivo) ? string.Empty : $"<p>Motivo: {motivo}</p>");

        await _email.EnviarAsync(destinarios, asunto, cuerpo);
    }

    private async Task ValidarPuntajesCompletosParaFinalizarAsync(
        EvaluacionBorradorRequest request,
        List<CriterioListItem> criterios)
    {
        var activos = criterios.Where(c => c.Activo).ToList();
        var existentes = new Dictionary<string, decimal>(StringComparer.Ordinal);

        if (request.Id is > 0)
        {
            var borrador = await _repository.ObtenerBorradorAsync(request.Id.Value);
            if (borrador?.Puntajes is not null)
            {
                foreach (var kv in borrador.Puntajes)
                    existentes[kv.Key] = kv.Value;
            }
        }

        foreach (var kv in request.Puntajes)
            existentes[kv.Key] = kv.Value;

        var faltantes = activos
            .Where(c => !existentes.ContainsKey(c.Id.ToString()))
            .Select(c => c.Nombre)
            .ToList();

        if (faltantes.Count > 0)
        {
            throw new InvalidOperationException(
                $"No se puede finalizar: faltan puntajes de {faltantes.Count} criterio(s) "
                + $"(p. ej. «{faltantes[0]}»). Cada área debe completar los suyos.");
        }
    }
}
