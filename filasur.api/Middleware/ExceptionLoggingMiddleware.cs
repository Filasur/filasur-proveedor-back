using filasur.api.Models;
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

            if (context.Response.HasStarted)
                throw;

            context.Response.Clear();
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            context.Response.ContentType = "application/json";

            await context.Response.WriteAsJsonAsync(
                ApiResult<object>.Fail($"Error interno del servidor: {ex.Message}"));
        }
    }
}
