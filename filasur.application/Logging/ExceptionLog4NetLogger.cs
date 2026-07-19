using log4net;
using log4net.Layout;
using log4net.Repository.Hierarchy;

namespace filasur.application.Logging;

public sealed class ExceptionLog4NetLogger : IExceptionLogger
{
    private static readonly object ConfigureLock = new();
    private static ILog? _log;

    public ExceptionLog4NetLogger(string logDirectory)
    {
        lock (ConfigureLock)
        {
            if (_log is not null)
                return;

            Directory.CreateDirectory(logDirectory);

            var hierarchy = (Hierarchy)LogManager.GetRepository();
            hierarchy.Configured = false;
            hierarchy.Root.RemoveAllAppenders();

            var appender = new PerExceptionFileAppender
            {
                LogDirectory = logDirectory,
                Layout = new PatternLayout("%date{yyyy-MM-dd HH:mm:ss.fff} [%level]%newline%message%newline%exception%newline")
            };
            appender.ActivateOptions();

            hierarchy.Root.AddAppender(appender);
            hierarchy.Root.Level = log4net.Core.Level.All;
            hierarchy.Configured = true;
            _log = LogManager.GetLogger(typeof(ExceptionLog4NetLogger));
        }
    }

    public void Log(Exception exception, string? context = null)
    {
        try
        {
            if (_log is null)
                return;

            var message = string.IsNullOrWhiteSpace(context)
                ? "Excepción en servicio"
                : $"Excepción en servicio. Contexto: {context}";

            _log.Error(message, exception);
        }
        catch
        {
            // Evitar que un fallo de I/O en logs tumbe la respuesta HTTP.
        }
    }
}
