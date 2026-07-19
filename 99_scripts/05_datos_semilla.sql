/*
  FILASUR - Script 05: Datos iniciales (desarrollo / demostración)
*/
USE FilasurProveedores;
GO

/* Catálogos estado proveedor */
INSERT INTO dbo.CatEstadoProveedor (IdEstadoProveedor, Codigo, Nombre) VALUES
(1, N'ACTIVO', N'Activo'),
(2, N'EN_EVALUACION', N'En evaluación'),
(3, N'APROBADO', N'Aprobado'),
(4, N'RECHAZADO', N'Rechazado');
GO

/* Catálogos estado evaluación */
INSERT INTO dbo.CatEstadoEvaluacion (IdEstadoEvaluacion, Codigo, Nombre) VALUES
(1, N'EN_PROCESO', N'En proceso'),
(2, N'EN_EVALUACION', N'En evaluación'),
(3, N'FINALIZADA', N'Finalizada'),
(4, N'APROBADO', N'Aprobado'),
(5, N'OBSERVADO', N'Observado'),
(6, N'RECHAZADO', N'Rechazado');
GO

INSERT INTO dbo.CatClasificacionProveedor (IdClasificacion, Nombre, PuntajeMinimo) VALUES
('A', N'Excelente', 4.00),
('B', N'Aceptable', 3.50),
('C', N'En mejora', 0.00);
GO

INSERT INTO dbo.CatTipoProveedor (Nombre) VALUES
(N'Materia prima'),
(N'Servicio'),
(N'Mixto');
GO

/* Roles y módulos */
INSERT INTO dbo.Rol (Nombre, Descripcion) VALUES
(N'Administrador', N'Acceso total al sistema'),
(N'Compras', N'Gestión de proveedores y evaluaciones'),
(N'Calidad', N'Evaluación por áreas y criterios'),
(N'Logística', N'Evaluación logística y documentos');
GO

INSERT INTO dbo.RolModulo (IdRol, Modulo)
SELECT r.IdRol, m.Modulo
FROM dbo.Rol r
CROSS APPLY (VALUES
    (N'Administrador', N'Todos'),
    (N'Compras', N'Proveedores'),
    (N'Compras', N'Evaluaciones'),
    (N'Compras', N'Reportes'),
    (N'Compras', N'Documentos'),
    (N'Calidad', N'Evaluaciones'),
    (N'Calidad', N'Criterios'),
    (N'Logística', N'Evaluaciones'),
    (N'Logística', N'Documentos')
) AS m(RolNombre, Modulo)
WHERE r.Nombre = m.RolNombre;
GO

/* Usuario demo (hash de ejemplo; reemplazar en producción) */
INSERT INTO dbo.Usuario (IdRol, NombreCompleto, Email, PasswordHash, Iniciales)
SELECT r.IdRol, N'Anedd Montezuma', N'anedd@filasur.pe',
       N'$2a$10$EjemploHashReemplazarEnProduccion', N'AM'
FROM dbo.Rol r WHERE r.Nombre = N'Compras';
GO

INSERT INTO dbo.Usuario (IdRol, NombreCompleto, Email, PasswordHash, Iniciales)
SELECT r.IdRol, N'Carlos Vega', N'cvega@filasur.pe', N'$2a$10$EjemploHash', N'CV'
FROM dbo.Rol r WHERE r.Nombre = N'Calidad';

INSERT INTO dbo.Usuario (IdRol, NombreCompleto, Email, PasswordHash, Iniciales)
SELECT r.IdRol, N'María López', N'mlopez@filasur.pe', N'$2a$10$EjemploHash', N'ML'
FROM dbo.Rol r WHERE r.Nombre = N'Administrador';
GO

/* Configuración */
INSERT INTO dbo.ConfiguracionSistema (
    IdConfig, UmbralAprobacion, UmbralObservado, DiasAlertaVencimiento,
    NotificacionesEmail, IntegracionErp, FechaModificacion
) VALUES (1, 3.50, 3.00, 5, 1, N'Exactus', SYSUTCDATETIME());
GO

/* Unidades y productos */
INSERT INTO dbo.UnidadMedida (Codigo, Nombre, Descripcion, Activo) VALUES
(N'UND', N'Unidad', N'Pieza o unidad de venta', 1),
(N'KG', N'Kilogramo', N'Masa en kilogramos', 1),
(N'MT', N'Metro', N'Longitud en metros lineales', 1),
(N'ROLLO', N'Rollo', N'Rollo de material continuo', 1),
(N'LT', N'Litro', N'Volumen en litros', 1),
(N'M2', N'Metro cuadrado', N'Superficie en metros cuadrados', 0);
GO

INSERT INTO dbo.Producto (Codigo, Nombre, Categoria, IdUnidad) VALUES
(N'MAT-BOL-PP-50', N'Bolsa PP 50kg', N'Embalaje', (SELECT IdUnidad FROM dbo.UnidadMedida WHERE Codigo = N'UND')),
(N'MAT-HIL-ALG-30', N'Hilo Algodón 30/1', N'Textil', (SELECT IdUnidad FROM dbo.UnidadMedida WHERE Codigo = N'KG')),
(N'MAT-TEL-CRU-40', N'Tela cruda 40"', N'Textil', (SELECT IdUnidad FROM dbo.UnidadMedida WHERE Codigo = N'MT')),
(N'MAT-FILM-ST', N'Film stretch', N'Embalaje', (SELECT IdUnidad FROM dbo.UnidadMedida WHERE Codigo = N'ROLLO'));
GO

/* Criterios */
INSERT INTO dbo.CriterioEvaluacion (Nombre, Area, Peso, Activo) VALUES
(N'Calidad del producto', N'Calidad', 30, 1),
(N'Cumplimiento de plazos', N'Logística', 25, 1),
(N'Atención postventa', N'Comercial', 20, 1),
(N'Precio competitivo', N'Costos', 15, 1),
(N'Documentación', N'Calidad', 10, 1);
GO

/* Proveedores de ejemplo */
DECLARE @TipoMP TINYINT = (SELECT IdTipoProveedor FROM dbo.CatTipoProveedor WHERE Nombre = N'Materia prima');
DECLARE @TipoSrv TINYINT = (SELECT IdTipoProveedor FROM dbo.CatTipoProveedor WHERE Nombre = N'Servicio');

INSERT INTO dbo.Proveedor (Ruc, RazonSocial, IdTipoProveedor, Rubro, Contacto, Telefono, Correo, Direccion,
    IdEstadoProveedor, IdClasificacion, PuntajePromedio, TotalEvaluaciones)
VALUES
('20512345678', N'Textiles del Sur S.A.C.', @TipoMP, N'Textiles', N'Juan Pérez', N'+51 999 111 222',
 N'contacto@textilesdelsur.pe', N'Av. Industrial 120, Lima', 3, 'A', 4.25, 12),
('20198765432', N'Inversiones Globales S.A.', @TipoSrv, N'Logística', N'María Gómez', N'+51 999 333 444',
 N'info@invglobales.pe', N'Calle Los Olivos 45, Arequipa', 2, 'B', 3.80, 5),
('20456789123', N'Plásticos Nacionales S.A.', @TipoMP, N'Embalajes', N'Carlos Ruiz', N'+51 999 555 666',
 N'ventas@plasticosnacionales.pe', N'Mz. B Lt. 8, Trujillo', 3, 'A', 4.60, 8),
('20333444556', N'Empaques del Perú S.A.C.', @TipoMP, N'Embalajes', N'Laura Díaz', N'+51 999 777 888',
 N'compras@empaquesdelperu.pe', N'Av. Argentina 500, Callao', 4, 'C', 3.20, 4),
('20111222333', N'Industrias del Norte S.A.C.', @TipoMP, N'Hilos', N'Pedro Soto', N'+51 999 000 111',
 N'pedidos@indnorte.pe', N'Carretera Norte Km 12, Piura', 1, 'B', 4.10, 6);
GO

PRINT N'Datos semilla cargados.';
GO
