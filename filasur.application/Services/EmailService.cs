using System.Net;
using System.Net.Mail;
using filasur.application.Interfaces;
using filasur.application.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace filasur.application.Services;

public class EmailService : IEmailService
{
    private readonly SmtpOptions _options;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IOptions<SmtpOptions> options, ILogger<EmailService> logger)
    {
        _options = options.Value;
        _logger = logger;
    }

    public async Task EnviarAsync(
        IEnumerable<string> destinatarios,
        string asunto,
        string cuerpoHtml,
        CancellationToken ct = default)
    {
        if (!_options.Enabled
            || string.IsNullOrWhiteSpace(_options.Host)
            || string.IsNullOrWhiteSpace(_options.FromEmail))
        {
            _logger.LogInformation("SMTP deshabilitado o incompleto; no se envió correo: {Asunto}", asunto);
            return;
        }

        var lista = destinatarios
            .Where(e => !string.IsNullOrWhiteSpace(e))
            .Select(e => e.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (lista.Count == 0)
            return;

        using var message = new MailMessage
        {
            From = new MailAddress(_options.FromEmail, _options.FromName),
            Subject = asunto,
            Body = cuerpoHtml,
            IsBodyHtml = true
        };
        foreach (var email in lista)
            message.To.Add(email);

        using var client = new SmtpClient(_options.Host, _options.Port)
        {
            EnableSsl = _options.EnableSsl,
            DeliveryMethod = SmtpDeliveryMethod.Network
        };

        if (!string.IsNullOrWhiteSpace(_options.User))
            client.Credentials = new NetworkCredential(_options.User, _options.Password);

        try
        {
            await client.SendMailAsync(message, ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error al enviar correo: {Asunto}", asunto);
        }
    }
}
