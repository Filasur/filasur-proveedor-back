namespace filasur.application.Interfaces;

public interface IEmailService
{
    Task EnviarAsync(IEnumerable<string> destinatarios, string asunto, string cuerpoHtml, CancellationToken ct = default);
}
