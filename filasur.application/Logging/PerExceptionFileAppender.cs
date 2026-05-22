using log4net.Appender;
using log4net.Core;
using System.Text;

namespace filasur.application.Logging;

public class PerExceptionFileAppender : AppenderSkeleton
{
    public string LogDirectory { get; set; } = "log";

    protected override void Append(LoggingEvent loggingEvent)
    {
        Directory.CreateDirectory(LogDirectory);

        var fileName = $"exception_{DateTime.Now:yyyyMMdd_HHmmss_fff}_{Guid.NewGuid():N}.log";
        var path = Path.Combine(LogDirectory, fileName);

        using var writer = new StreamWriter(path, append: false, Encoding.UTF8);
        if (Layout is not null)
            Layout.Format(writer, loggingEvent);
        else
            writer.Write(RenderLoggingEvent(loggingEvent));
    }
}
