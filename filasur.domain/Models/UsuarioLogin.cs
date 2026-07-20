namespace filasur.domain.Models;

public class UsuarioLogin
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Rol { get; set; } = string.Empty;
    public string Iniciales { get; set; } = string.Empty;
    public bool DebeCambiarPassword { get; set; }
    public List<string> Modulos { get; set; } = [];
}

public class UsuarioCredencial
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Rol { get; set; } = string.Empty;
    public string Iniciales { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public int IntentosFallidos { get; set; }
    public DateTime? BloqueadoHasta { get; set; }
    public bool DebeCambiarPassword { get; set; }
    public bool Activo { get; set; }
}
