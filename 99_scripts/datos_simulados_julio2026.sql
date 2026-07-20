/*
  FILASUR - Datos simulados de uso (julio 2026)
  ============================================================
  Escenario: el sistema entró a producción el 01/07/2026.
  Este script carga actividad realista hasta el viernes 17/07/2026.

  Requisitos: haber ejecutado antes 00_despliegue_produccion.sql
              (o 01→05 + 10).

  Usuarios (dominio @filasur.com) — contraseña de todos: fvelazco2026
    fvelazco@filasur.com   Administrador
    mlopez@filasur.com     Logística
    cvega@filasur.com      Calidad
    jramos@filasur.com     Compras
    aperalta@filasur.com   Calidad

  NOTA: Las fechas de bitácora se insertan ya en UTC (= hora Perú + 5 h)
  para que sp_Bitacora_Listar las muestre correctamente en hora local.
*/
USE FilasurProveedores;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;

DECLARE @Hash NVARCHAR(256) = N'$2a$11$JAXCsnEU3qQLdiXLO8FX1OR8Xeo5rCGA0NfFj27RZUHlwhhIOE1fO';
DECLARE @IdAdmin TINYINT = (SELECT IdRol FROM dbo.Rol WHERE Nombre = N'Administrador');
DECLARE @IdCompras TINYINT = (SELECT IdRol FROM dbo.Rol WHERE Nombre = N'Compras');
DECLARE @IdCalidad TINYINT = (SELECT IdRol FROM dbo.Rol WHERE Nombre = N'Calidad');
DECLARE @IdLogistica TINYINT = (SELECT IdRol FROM dbo.Rol WHERE Nombre = N'Logística');

/* ---------- Usuarios ---------- */
MERGE dbo.Usuario AS t
USING (VALUES
    (@IdAdmin,     N'Francisco Velazco', N'fvelazco@filasur.com', N'FV'),
    (@IdLogistica, N'María López',       N'mlopez@filasur.com',   N'ML'),
    (@IdCalidad,   N'Carlos Vega',       N'cvega@filasur.com',    N'CV'),
    (@IdCompras,   N'Jorge Ramos',       N'jramos@filasur.com',   N'JR'),
    (@IdCalidad,   N'Ana Peralta',       N'aperalta@filasur.com', N'AP')
) AS s(IdRol, NombreCompleto, Email, Iniciales)
ON t.Email = s.Email
WHEN MATCHED THEN
    UPDATE SET IdRol = s.IdRol, NombreCompleto = s.NombreCompleto,
               PasswordHash = @Hash, Iniciales = s.Iniciales, IdEstadoUsuario = 1
WHEN NOT MATCHED THEN
    INSERT (IdRol, NombreCompleto, Email, PasswordHash, Iniciales, IdEstadoUsuario)
    VALUES (s.IdRol, s.NombreCompleto, s.Email, @Hash, s.Iniciales, 1);

DECLARE @IdU_FV INT = (SELECT IdUsuario FROM dbo.Usuario WHERE Email = N'fvelazco@filasur.com');
DECLARE @IdU_ML INT = (SELECT IdUsuario FROM dbo.Usuario WHERE Email = N'mlopez@filasur.com');
DECLARE @IdU_CV INT = (SELECT IdUsuario FROM dbo.Usuario WHERE Email = N'cvega@filasur.com');
DECLARE @IdU_JR INT = (SELECT IdUsuario FROM dbo.Usuario WHERE Email = N'jramos@filasur.com');
DECLARE @IdU_AP INT = (SELECT IdUsuario FROM dbo.Usuario WHERE Email = N'aperalta@filasur.com');

DECLARE @TipoMP TINYINT = (SELECT IdTipoProveedor FROM dbo.CatTipoProveedor WHERE Nombre = N'Materia prima');
DECLARE @TipoSrv TINYINT = (SELECT IdTipoProveedor FROM dbo.CatTipoProveedor WHERE Nombre = N'Servicio');
DECLARE @TipoMix TINYINT = (SELECT IdTipoProveedor FROM dbo.CatTipoProveedor WHERE Nombre = N'Mixto');

/* ---------- Proveedores textiles / embalaje (si no existen por RUC) ---------- */
MERGE dbo.Proveedor AS t
USING (VALUES
    ('20512345678', N'Textiles del Sur S.A.C.',       @TipoMP,  N'Textiles',  N'Juan Pérez',   N'+51 999 111 222', N'contacto@textilesdelsur.pe', N'Av. Industrial 120, Lima',      3, 'A', 4.25, 3),
    ('20198765432', N'Inversiones Globales S.A.',     @TipoSrv, N'Logística', N'María Gómez',  N'+51 999 333 444', N'info@invglobales.pe',        N'Calle Los Olivos 45, Arequipa', 2, 'B', 3.80, 2),
    ('20456789123', N'Plásticos Nacionales S.A.',     @TipoMP,  N'Embalajes', N'Carlos Ruiz',  N'+51 999 555 666', N'ventas@plasticosnacionales.pe', N'Mz. B Lt. 8, Trujillo',     3, 'A', 4.40, 2),
    ('20333444556', N'Empaques del Perú S.A.C.',      @TipoMP,  N'Embalajes', N'Laura Díaz',   N'+51 999 777 888', N'compras@empaquesdelperu.pe', N'Av. Argentina 500, Callao',     1, 'C', 3.20, 1),
    ('20111222333', N'Industrias del Norte S.A.C.',   @TipoMP,  N'Hilos',     N'Pedro Soto',   N'+51 999 000 111', N'pedidos@indnorte.pe',        N'Carretera Norte Km 12, Piura',  1, 'B', 4.10, 1),
    ('20677889900', N'Hilandería Andina S.A.C.',      @TipoMP,  N'Textiles',  N'Rosa Quispe',  N'+51 987 654 321', N'ventas@hilanderiaandina.pe', N'Jr. Gamarra 880, La Victoria',  3, 'A', 4.55, 2),
    ('20555666777', N'Químicos Textiles S.A.',        @TipoMix, N'Químicos',  N'Diego Farfán', N'+51 955 222 333', N'contacto@quimtext.pe',       N'Av. Néstor Gambetta 2100, Callao', 2, 'B', 3.90, 1),
    ('20444333221', N'Tejidos Modernos E.I.R.L.',     @TipoMP,  N'Textiles',  N'Elena Castro', N'+51 944 111 000', N'elena@tejidosmodernos.pe',   N'Av. Argentina 1450, Lima',      1, 'B', NULL, 0)
) AS s(Ruc, RazonSocial, IdTipo, Rubro, Contacto, Telefono, Correo, Direccion, IdEst, Clasif, Puntaje, Total)
ON t.Ruc = s.Ruc
WHEN NOT MATCHED THEN
    INSERT (Ruc, RazonSocial, IdTipoProveedor, Rubro, Contacto, Telefono, Correo, Direccion,
            IdEstadoProveedor, IdClasificacion, PuntajePromedio, TotalEvaluaciones)
    VALUES (s.Ruc, s.RazonSocial, s.IdTipo, s.Rubro, s.Contacto, s.Telefono, s.Correo, s.Direccion,
            s.IdEst, s.Clasif, s.Puntaje, s.Total);

DECLARE @P1 INT = (SELECT IdProveedor FROM dbo.Proveedor WHERE Ruc = '20512345678');
DECLARE @P2 INT = (SELECT IdProveedor FROM dbo.Proveedor WHERE Ruc = '20198765432');
DECLARE @P3 INT = (SELECT IdProveedor FROM dbo.Proveedor WHERE Ruc = '20456789123');
DECLARE @P4 INT = (SELECT IdProveedor FROM dbo.Proveedor WHERE Ruc = '20333444556');
DECLARE @P5 INT = (SELECT IdProveedor FROM dbo.Proveedor WHERE Ruc = '20111222333');
DECLARE @P6 INT = (SELECT IdProveedor FROM dbo.Proveedor WHERE Ruc = '20677889900');
DECLARE @P7 INT = (SELECT IdProveedor FROM dbo.Proveedor WHERE Ruc = '20555666777');
DECLARE @P8 INT = (SELECT IdProveedor FROM dbo.Proveedor WHERE Ruc = '20444333221');

DECLARE @ProdBolsa INT = (SELECT IdProducto FROM dbo.Producto WHERE Codigo = N'MAT-BOL-PP-50');
DECLARE @ProdHilo  INT = (SELECT IdProducto FROM dbo.Producto WHERE Codigo = N'MAT-HIL-ALG-30');
DECLARE @ProdTela  INT = (SELECT IdProducto FROM dbo.Producto WHERE Codigo = N'MAT-TEL-CRU-40');
DECLARE @ProdFilm  INT = (SELECT IdProducto FROM dbo.Producto WHERE Codigo = N'MAT-FILM-ST');
DECLARE @ProdTinte INT = (SELECT IdProducto FROM dbo.Producto WHERE Codigo = N'MAT-TINTE-IND');
DECLARE @ProdEtiq  INT = (SELECT IdProducto FROM dbo.Producto WHERE Codigo = N'MAT-ETIQ-TEJ');

DECLARE @EstProceso TINYINT = (SELECT IdEstadoEvaluacion FROM dbo.CatEstadoEvaluacion WHERE Codigo = N'EN_PROCESO');
DECLARE @EstFinal   TINYINT = (SELECT IdEstadoEvaluacion FROM dbo.CatEstadoEvaluacion WHERE Codigo = N'FINALIZADA');
DECLARE @EstAprob   TINYINT = (SELECT IdEstadoEvaluacion FROM dbo.CatEstadoEvaluacion WHERE Codigo = N'APROBADO');
DECLARE @EstObs     TINYINT = (SELECT IdEstadoEvaluacion FROM dbo.CatEstadoEvaluacion WHERE Codigo = N'OBSERVADO');

/* Helper: UTC = hora Perú + 5 horas */
DECLARE @UtcFrom DATETIME2(0) = DATETIME2FROMPARTS(2026, 7, 1, 13, 15, 0, 0, 0); -- 08:15 Perú

/* Limpiar solo evaluaciones/docs/bitácora del periodo simulado (idempotente suave) */
DELETE FROM dbo.Bitacora
WHERE FechaHora >= '2026-07-01' AND FechaHora < '2026-07-18'
  AND Detalle LIKE N'%sim jul2026%';


/* ---------- Documentos (algunos por vencer respecto a ~20 jul) ---------- */
IF NOT EXISTS (SELECT 1 FROM dbo.DocumentoProveedor WHERE NombreArchivo = N'RUC_TextilesSur.pdf')
INSERT INTO dbo.DocumentoProveedor (IdProveedor, NombreArchivo, TipoArchivo, TamanoBytes, CategoriaDocumento, FechaCarga, FechaVencimiento)
VALUES
(@P1, N'RUC_TextilesSur.pdf',           N'pdf', 245000, N'Legal',          '2026-07-02', '2026-07-22'),
(@P1, N'Ficha_tecnica_hilo30.pdf',       N'pdf', 512000, N'Técnico',        '2026-07-03', '2026-08-15'),
(@P3, N'ISO9001_PlasticosNac.pdf',       N'pdf', 890000, N'Certificación',  '2026-07-05', '2026-07-25'),
(@P6, N'Homologacion_Hilanderia.pdf',    N'pdf', 334000, N'Homologación',   '2026-07-08', '2026-07-19'),
(@P7, N'MSDS_TinteIndustrial.pdf',       N'pdf', 198000, N'Seguridad',      '2026-07-10', '2026-07-18'),
(@P4, N'Licencia_funcionamiento.pdf',    N'pdf', 410000, N'Legal',          '2026-07-12', '2026-07-16'), -- vencido
(@P8, N'Catalogo_tejidos_2026.pdf',      N'pdf', 1200000,N'Comercial',      '2026-07-14', NULL);

/* ---------- Evaluaciones ----------
   Finalizadas: 1–12 jul
   En proceso con FechaLimite cercana: aparecen en «Próximas por vencer»
*/
DECLARE @E1 INT, @E2 INT, @E3 INT, @E4 INT, @E5 INT, @E6 INT, @E7 INT, @E8 INT;

IF NOT EXISTS (SELECT 1 FROM dbo.Evaluacion WHERE Periodo = N'2026-3Q' AND OrdenCompra = N'OC-260701')
BEGIN
    INSERT INTO dbo.Evaluacion (IdProveedor, IdProducto, Periodo, OrdenCompra, FechaLimite, FechaEvaluacion,
        PuntajeFinal, IdEstadoEvaluacion, NivelResultado, Observaciones, IdUsuarioCreador, FechaCreacion)
    VALUES
    (@P1, @ProdHilo,  N'2026-3Q', N'OC-260701', '2026-07-10', '2026-07-08', 4.30, @EstAprob, N'APROBADO',
     N'Buen desempeño general. [sim jul2026]', @IdU_CV, DATETIME2FROMPARTS(2026,7,1,14,20,0,0,0)),
    (@P3, @ProdBolsa, N'2026-3Q', N'OC-260703', '2026-07-12', '2026-07-10', 4.55, @EstAprob, N'APROBADO',
     N'Embalaje conforme. [sim jul2026]', @IdU_AP, DATETIME2FROMPARTS(2026,7,3,15,5,0,0,0)),
    (@P6, @ProdTela,  N'2026-3Q', N'OC-260705', '2026-07-14', '2026-07-11', 3.40, @EstObs, N'OBSERVADO',
     N'Retrasos menores en despacho. [sim jul2026]', @IdU_CV, DATETIME2FROMPARTS(2026,7,5,13,40,0,0,0)),
    (@P2, @ProdFilm,  N'2026-3Q', N'OC-260708', '2026-07-16', '2026-07-14', 4.10, @EstFinal, N'APROBADO',
     N'Servicio logístico estable. [sim jul2026]', @IdU_AP, DATETIME2FROMPARTS(2026,7,8,16,10,0,0,0)),
    (@P7, @ProdTinte, N'2026-3Q', N'OC-260710', '2026-07-18', '2026-07-15', 3.85, @EstFinal, N'OBSERVADO',
     N'Documentación MSDS pendiente de actualizar. [sim jul2026]', @IdU_CV, DATETIME2FROMPARTS(2026,7,10,14,55,0,0,0)),
    (@P5, @ProdHilo,  N'2026-3Q', N'OC-260712', '2026-07-20', '2026-07-16', 4.00, @EstAprob, N'APROBADO',
     N'Calidad de hilo aceptable. [sim jul2026]', @IdU_AP, DATETIME2FROMPARTS(2026,7,12,13,25,0,0,0));

    /* En proceso — aparecen en dashboard «por vencer» (límite <= hoy+15) */
    INSERT INTO dbo.Evaluacion (IdProveedor, IdProducto, Periodo, OrdenCompra, FechaLimite, FechaEvaluacion,
        PuntajeFinal, IdEstadoEvaluacion, NivelResultado, Observaciones, IdUsuarioCreador, FechaCreacion)
    VALUES
    (@P4, @ProdBolsa, N'2026-3Q', N'OC-260714', '2026-07-22', NULL, NULL, @EstProceso, NULL,
     N'Iniciada por Calidad; pendiente Compras/Logística. [sim jul2026]', @IdU_CV, DATETIME2FROMPARTS(2026,7,14,15,30,0,0,0)),
    (@P8, @ProdEtiq,  N'2026-3Q', N'OC-260716', '2026-07-24', NULL, NULL, @EstProceso, NULL,
     N'Nueva evaluación de etiquetas. [sim jul2026]', @IdU_AP, DATETIME2FROMPARTS(2026,7,16,14,0,0,0,0)),
    (@P1, @ProdTela,  N'2026-3Q', N'OC-260717', '2026-07-20', NULL, NULL, @EstProceso, NULL,
     N'Reevaluación de tela cruda Q3. [sim jul2026]', @IdU_CV, DATETIME2FROMPARTS(2026,7,17,13,45,0,0,0));
END;

SET @E1 = (SELECT IdEvaluacion FROM dbo.Evaluacion WHERE OrdenCompra = N'OC-260701');
SET @E2 = (SELECT IdEvaluacion FROM dbo.Evaluacion WHERE OrdenCompra = N'OC-260703');
SET @E3 = (SELECT IdEvaluacion FROM dbo.Evaluacion WHERE OrdenCompra = N'OC-260705');
SET @E4 = (SELECT IdEvaluacion FROM dbo.Evaluacion WHERE OrdenCompra = N'OC-260708');
SET @E5 = (SELECT IdEvaluacion FROM dbo.Evaluacion WHERE OrdenCompra = N'OC-260710');
SET @E6 = (SELECT IdEvaluacion FROM dbo.Evaluacion WHERE OrdenCompra = N'OC-260712');
SET @E7 = (SELECT IdEvaluacion FROM dbo.Evaluacion WHERE OrdenCompra = N'OC-260714');
SET @E8 = (SELECT IdEvaluacion FROM dbo.Evaluacion WHERE OrdenCompra = N'OC-260716');
DECLARE @E9 INT = (SELECT IdEvaluacion FROM dbo.Evaluacion WHERE OrdenCompra = N'OC-260717');

/* Criterios activos */
DECLARE @C1 INT = (SELECT TOP 1 IdCriterio FROM dbo.CriterioEvaluacion WHERE Area = N'Calidad' ORDER BY IdCriterio);
DECLARE @C2 INT = (SELECT TOP 1 IdCriterio FROM dbo.CriterioEvaluacion WHERE Area = N'Calidad' AND IdCriterio <> @C1 ORDER BY IdCriterio);
DECLARE @C3 INT = (SELECT TOP 1 IdCriterio FROM dbo.CriterioEvaluacion WHERE Area = N'Compras' ORDER BY IdCriterio);
DECLARE @C4 INT = (SELECT TOP 1 IdCriterio FROM dbo.CriterioEvaluacion WHERE Area = N'Compras' AND IdCriterio <> @C3 ORDER BY IdCriterio);
DECLARE @C5 INT = (SELECT TOP 1 IdCriterio FROM dbo.CriterioEvaluacion WHERE Area = N'Logística' ORDER BY IdCriterio);
DECLARE @C6 INT = (SELECT TOP 1 IdCriterio FROM dbo.CriterioEvaluacion WHERE Area = N'Logística' AND IdCriterio <> @C5 ORDER BY IdCriterio);

/* Puntajes completos en finalizadas */
IF @E1 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.EvaluacionCriterio WHERE IdEvaluacion = @E1)
BEGIN
    ;WITH Evals AS (
        SELECT v.IdEval, v.P1, v.P2, v.P3, v.P4, v.P5, v.P6
        FROM (VALUES
            (@E1, 92, 88, 85, 90, 86, 84),
            (@E2, 95, 90, 88, 92, 90, 88),
            (@E3, 78, 80, 70, 75, 68, 72),
            (@E4, 88, 85, 82, 80, 84, 86),
            (@E5, 80, 78, 76, 74, 72, 70),
            (@E6, 86, 84, 82, 80, 78, 80)
        ) AS v(IdEval, P1, P2, P3, P4, P5, P6)
    )
    INSERT INTO dbo.EvaluacionCriterio (IdEvaluacion, IdCriterio, Puntaje, PuntajePonderado)
    SELECT e.IdEval, c.IdCriterio, c.Puntaje,
           CAST(c.Puntaje * crit.Peso / 100.0 AS DECIMAL(8, 4))
    FROM Evals e
    CROSS APPLY (VALUES
        (@C1, e.P1), (@C2, e.P2), (@C3, e.P3), (@C4, e.P4), (@C5, e.P5), (@C6, e.P6)
    ) AS c(IdCriterio, Puntaje)
    INNER JOIN dbo.CriterioEvaluacion crit ON crit.IdCriterio = c.IdCriterio
    WHERE e.IdEval IS NOT NULL AND c.IdCriterio IS NOT NULL;

    INSERT INTO dbo.EvaluacionArea (IdEvaluacion, Area, IdUsuarioEvaluador, Puntaje, Peso, PuntajePonderado)
    SELECT e.IdEvaluacion, a.Area, a.IdUsr, a.Puntaje, a.Peso, CAST(a.Puntaje * a.Peso / 100.0 AS DECIMAL(6,3))
    FROM (VALUES (@E1), (@E2), (@E3), (@E4), (@E5), (@E6)) AS e(IdEvaluacion)
    CROSS APPLY (VALUES
        (N'Calidad',   @IdU_CV, CAST(4.40 AS DECIMAL(4,2)), CAST(35.0 AS DECIMAL(5,2))),
        (N'Compras',   @IdU_JR, CAST(4.20 AS DECIMAL(4,2)), CAST(35.0 AS DECIMAL(5,2))),
        (N'Logística', @IdU_ML, CAST(4.10 AS DECIMAL(4,2)), CAST(30.0 AS DECIMAL(5,2)))
    ) AS a(Area, IdUsr, Puntaje, Peso)
    WHERE e.IdEvaluacion IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM dbo.EvaluacionArea ea WHERE ea.IdEvaluacion = e.IdEvaluacion);
END;

/* En proceso: solo Calidad cargó puntajes → áreas pendientes Compras/Logística */
IF @E7 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.EvaluacionCriterio WHERE IdEvaluacion = @E7)
BEGIN
    INSERT INTO dbo.EvaluacionCriterio (IdEvaluacion, IdCriterio, Puntaje, PuntajePonderado)
    SELECT @E7, c.IdCriterio, c.Puntaje, CAST(c.Puntaje * crit.Peso / 100.0 AS DECIMAL(8,4))
    FROM (VALUES (@C1, 82), (@C2, 78)) AS c(IdCriterio, Puntaje)
    INNER JOIN dbo.CriterioEvaluacion crit ON crit.IdCriterio = c.IdCriterio
    WHERE c.IdCriterio IS NOT NULL;

    INSERT INTO dbo.EvaluacionArea (IdEvaluacion, Area, IdUsuarioEvaluador, Puntaje, Peso, PuntajePonderado)
    VALUES (@E7, N'Calidad', @IdU_CV, 4.00, 35.00, 1.400);
END;

IF @E9 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.EvaluacionCriterio WHERE IdEvaluacion = @E9)
BEGIN
    INSERT INTO dbo.EvaluacionCriterio (IdEvaluacion, IdCriterio, Puntaje, PuntajePonderado)
    SELECT @E9, c.IdCriterio, c.Puntaje, CAST(c.Puntaje * crit.Peso / 100.0 AS DECIMAL(8,4))
    FROM (VALUES (@C1, 88), (@C2, 85)) AS c(IdCriterio, Puntaje)
    INNER JOIN dbo.CriterioEvaluacion crit ON crit.IdCriterio = c.IdCriterio
    WHERE c.IdCriterio IS NOT NULL;

    INSERT INTO dbo.EvaluacionArea (IdEvaluacion, Area, IdUsuarioEvaluador, Puntaje, Peso, PuntajePonderado)
    VALUES (@E9, N'Calidad', @IdU_CV, 4.30, 35.00, 1.505);
END;

/* ---------- Bitácora de aplicación (UTC = Perú + 5h) 01–17 jul ---------- */
INSERT INTO dbo.Bitacora (IdUsuario, Modulo, Accion, Detalle, FechaHora)
VALUES
(@IdU_FV, N'Autenticación', N'Inicio de sesión',
 N'Usuario fvelazco@filasur.com (Administrador) inició sesión. [sim jul2026]',
 DATETIME2FROMPARTS(2026,7,1,13,10,0,0,0)),
(@IdU_CV, N'Autenticación', N'Inicio de sesión',
 N'Usuario cvega@filasur.com (Calidad) inició sesión. [sim jul2026]',
 DATETIME2FROMPARTS(2026,7,1,14,5,0,0,0)),
(@IdU_CV, N'Evaluaciones', N'Evaluación iniciada',
 N'Evaluación #' + CAST(ISNULL(@E1,0) AS NVARCHAR(10)) + N'; rol Calidad; proveedorId=' + CAST(@P1 AS NVARCHAR(10)) + N'; periodo=2026-3Q. [sim jul2026]',
 DATETIME2FROMPARTS(2026,7,1,14,25,0,0,0)),
(@IdU_JR, N'Evaluaciones', N'Fase «Compras» enviada',
 N'Evaluación #' + CAST(ISNULL(@E1,0) AS NVARCHAR(10)) + N'; rol Compras; 2 criterio(s). [sim jul2026]',
 DATETIME2FROMPARTS(2026,7,2,15,40,0,0,0)),
(@IdU_ML, N'Evaluaciones', N'Fase «Logística» enviada y evaluación finalizada',
 N'Evaluación #' + CAST(ISNULL(@E1,0) AS NVARCHAR(10)) + N'; rol Logística; 2 criterio(s). [sim jul2026]',
 DATETIME2FROMPARTS(2026,7,8,16,20,0,0,0)),
(@IdU_AP, N'Evaluaciones', N'Evaluación iniciada',
 N'Evaluación #' + CAST(ISNULL(@E2,0) AS NVARCHAR(10)) + N'; rol Calidad; proveedorId=' + CAST(@P3 AS NVARCHAR(10)) + N'; periodo=2026-3Q. [sim jul2026]',
 DATETIME2FROMPARTS(2026,7,3,15,10,0,0,0)),
(@IdU_FV, N'Proveedores', N'Consulta de proveedor',
 N'Revisión de ficha Textiles del Sur S.A.C. [sim jul2026]',
 DATETIME2FROMPARTS(2026,7,4,14,0,0,0,0)),
(@IdU_ML, N'Documentos', N'Documento cargado',
 N'Archivo Homologacion_Hilanderia.pdf — Hilandería Andina. [sim jul2026]',
 DATETIME2FROMPARTS(2026,7,8,18,15,0,0,0)),
(@IdU_CV, N'Evaluaciones', N'Evaluación iniciada',
 N'Evaluación #' + CAST(ISNULL(@E7,0) AS NVARCHAR(10)) + N'; rol Calidad; OC-260714. [sim jul2026]',
 DATETIME2FROMPARTS(2026,7,14,15,35,0,0,0)),
(@IdU_JR, N'Autenticación', N'Inicio de sesión',
 N'Usuario jramos@filasur.com (Compras) inició sesión. [sim jul2026]',
 DATETIME2FROMPARTS(2026,7,15,13,50,0,0,0)),
(@IdU_AP, N'Evaluaciones', N'Evaluación iniciada',
 N'Evaluación #' + CAST(ISNULL(@E8,0) AS NVARCHAR(10)) + N'; rol Calidad; OC-260716. [sim jul2026]',
 DATETIME2FROMPARTS(2026,7,16,14,5,0,0,0)),
(@IdU_CV, N'Evaluaciones', N'Fase «Calidad» enviada',
 N'Evaluación #' + CAST(ISNULL(@E9,0) AS NVARCHAR(10)) + N'; rol Calidad; 2 criterio(s); periodo=2026-3Q. [sim jul2026]',
 DATETIME2FROMPARTS(2026,7,17,13,50,0,0,0)),
(@IdU_ML, N'Autenticación', N'Cierre de sesión',
 N'Usuario mlopez@filasur.com (Logística) cerró sesión. [sim jul2026]',
 DATETIME2FROMPARTS(2026,7,17,19,5,0,0,0)),
(@IdU_FV, N'Autenticación', N'Inicio de sesión',
 N'Usuario fvelazco@filasur.com (Administrador) inició sesión. [sim jul2026]',
 DATETIME2FROMPARTS(2026,7,17,20,0,0,0,0));

/* Ampliar días de alerta si quedó en 5 */
UPDATE dbo.ConfiguracionSistema
SET DiasAlertaVencimiento = 15
WHERE IdConfig = 1 AND DiasAlertaVencimiento < 15;

COMMIT TRANSACTION;

PRINT N'Datos simulados julio 2026 cargados (hasta 17/07).';
PRINT N'Usuarios @filasur.com — contraseña: fvelazco2026';
GO
