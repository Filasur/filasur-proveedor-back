using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System.Data;

namespace filasur.infrastructure.Data;

public class SqlConnectionFactory : ISqlConnectionFactory
{
    private readonly string _connectionString;

    public SqlConnectionFactory(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("FilasurDb")
            ?? throw new InvalidOperationException("Connection string 'FilasurDb' no configurada.");
    }

    public IDbConnection CreateConnection() => new SqlConnection(_connectionString);
}
