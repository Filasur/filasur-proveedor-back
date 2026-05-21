namespace filasur.domain.Models;

public class UsuarioLogin
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Rol { get; set; } = string.Empty;
    public string Iniciales { get; set; } = string.Empty;
}

public class UsuarioCredencial
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Rol { get; set; } = string.Empty;
    public string Iniciales { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
}
