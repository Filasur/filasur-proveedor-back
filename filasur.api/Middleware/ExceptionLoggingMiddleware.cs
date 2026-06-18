using filasur.application.Logging;

namespace filasur.api.Middleware;

public class ExceptionLoggingMiddleware
{
    private readonly RequestDelegate _next;

    public ExceptionLoggingMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, IExceptionLogger exceptionLogger)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            var path = context.Request.Path.HasValue ? context.Request.Path.Value : "/";
            exceptionLogger.Log(ex, $"{context.Request.Method} {path}");
            throw;
        }
    }
}
