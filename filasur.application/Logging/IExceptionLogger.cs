namespace filasur.application.Logging;

public interface IExceptionLogger
{
    void Log(Exception exception, string? context = null);
}
