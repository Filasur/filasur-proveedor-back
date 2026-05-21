using System.Data;

namespace filasur.infrastructure.Data;

public interface ISqlConnectionFactory
{
    IDbConnection CreateConnection();
}
