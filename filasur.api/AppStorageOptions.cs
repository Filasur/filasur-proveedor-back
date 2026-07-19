namespace filasur.api;

/// <summary>
/// Rutas escribibles para archivos y logs (en Cloud Run se usa /tmp).
/// </summary>
public sealed class AppStorageOptions
{
    public const string SectionName = "Storage";

    public string UploadsPath { get; set; } = string.Empty;
    public string LogPath { get; set; } = string.Empty;

    public static AppStorageOptions CreateDefault(IHostEnvironment env, IConfiguration config)
    {
        var configuredUploads = config["Storage:UploadsPath"];
        var configuredLogs = config["Storage:LogPath"];

        // Contenedores Linux (Cloud Run): /tmp es escribible por el usuario no-root.
        var useTemp = IsRunningInContainer() || !env.IsDevelopment();

        var uploads = !string.IsNullOrWhiteSpace(configuredUploads)
            ? configuredUploads
            : useTemp
                ? Path.Combine(Path.GetTempPath(), "filasur-uploads")
                : Path.Combine(env.ContentRootPath, "uploads");

        var logs = !string.IsNullOrWhiteSpace(configuredLogs)
            ? configuredLogs
            : useTemp
                ? Path.Combine(Path.GetTempPath(), "filasur-logs")
                : Path.Combine(env.ContentRootPath, "log");

        Directory.CreateDirectory(uploads);
        Directory.CreateDirectory(logs);

        return new AppStorageOptions
        {
            UploadsPath = uploads,
            LogPath = logs
        };
    }

    private static bool IsRunningInContainer() =>
        string.Equals(
            Environment.GetEnvironmentVariable("DOTNET_RUNNING_IN_CONTAINER"),
            "true",
            StringComparison.OrdinalIgnoreCase);
}
