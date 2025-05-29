IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.xpCA_Transform_to_JSON')
            AND TYPE = 'P')
    DROP PROCEDURE dbo.xpCA_Transform_to_JSON;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

/* =============================================
-- Autor:Giovanni Trujillo Silvas
-- Descripción: Genera un JSON a partir de una Vista o tabla SQL, convirtiendo las columnas a etiquetas. Permite indicar campos específicos y filtrar por un valor específico mediante un WHERE y la condición acorde a los campos de la vista o tabla. También se puede especificar si el resultado debe ser un array de JSON o único. En caso de ser un array, se incluyen [] (llaves de apertura y cierre) en la respuesta.
-- Parámetros:
    - @Table: "Nombre de la tabla o vista a trabajar"
    - @Array: "1 para indicar que se agreguen [] o 0 para no agregar. Por defecto se inicializa en 0"
    - @Condition: "FILTRO WHERE con la condición a validar. Por defecto se inicializa en '' "
    - @Fields: "Campos de la tabla o vista a transformar a etiquetas, separados por : (dos puntos) ejemplos: sucursal:nombre. Por defecto se inicializa en ''"
    - @JSON: "Variable de salida declarada como @JSON NVARCHAR(MAX)"
-- Resultado: JSON de la tabla o vista indicada
-- Ejemplo:
	DECLARE
	@JSON NVARCHAR(MAX),
	@Condition NVARCHAR(MAX)='WHERE cliente='+CHAR(39)+'1000014'+CHAR(39)
	EXEC xpCA_Transform_to_JSON 'Sucursal',1,'','Nombre:Sucursal',@JSON=@JSON OUTPUT--CAMPOS ESPECIFICOS
	SELECT @JSON,'CAMPOS ESPECIFICOS Y ARRAY'
	EXEC xpCA_Transform_to_JSON 'Sucursal',1,'','',@JSON=@JSON OUTPUT----
	SELECT @JSON,'JSON SIN ARRAY, SÍ LA CONSULTA POSEE MULTIPLES REGISTROS DE SALIDA SE PERDERAN Y SOLO RETORNARA EL PRIMER'
	EXEC xpCA_Transform_to_JSON 'Empresa',@JSON=@JSON OUTPUT---JSON SIN ARRAY PERO SIN PONER PARAMETROS
	SELECT @JSON,'JSON SIN ARRAY PERO SIN PONER PARAMETROS'
	EXEC xpCA_Transform_to_JSON 'CTE',0,@Condition,@JSON=@JSON OUTPUT--JSON CON CONDICION PERO SIN CAMPOS ESPECIFICOS
	SELECT @JSON,'JSON CON CONDICION PERO SIN CAMPOS ESPECIFICOS'
	EXEC xpCA_Transform_to_JSON 'CTE',0,@Condition,'DelegeacionMunicipio:Sexo',@JSON=@JSON OUTPUT--JSON CON CONDICION Y CAMPOS ESPECIFICOS
	SELECT @JSON,'JSON CON CONDICION Y CAMPOS ESPECIFICOS'
-- =============================================*/

CREATE PROCEDURE dbo.xpCA_Transform_to_JSON @Table NVARCHAR(MAX), @Array bit =0, @Condition NVARCHAR(MAX) = '',
                                            @Fields NVARCHAR(MAX) = '', @JSON NVARCHAR(MAX) OUTPUT
AS
BEGIN
    DECLARE
        @Sql NVARCHAR(MAX)=CHAR(39) + '{',
        @Query NVARCHAR(MAX);

    DECLARE
        @Columns TABLE
                 (
                     COLUMN_NAME NVARCHAR(MAX),
                     DATA_TYPE   NVARCHAR(MAX)
                 );

    INSERT INTO @Columns (COLUMN_NAME, DATA_TYPE)
    SELECT COLUMN_NAME, DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = @Table;

    IF CHARINDEX(':', @Fields) > 0
        BEGIN
            DELETE
            FROM @Columns
            where COLUMN_NAME NOT in (SELECT *
                                      FROM dbo.fnCA_StringSplit(@Fields, null))
        END

    SET @Sql +=(SELECT ' "' + COLUMN_NAME + '" : ' +
                       CASE
                           WHEN DATA_TYPE IN ('varchar', 'nvarchar', 'char') THEN '"' + CHAR(39) + CHAR(43) +
                                                                                  'ISNULL(' + COLUMN_NAME + ',' +
                                                                                  CHAR(39) + CHAR(39) + ')' + CHAR(43) +
                                                                                  CHAR(39) + '"'
                           WHEN DATA_TYPE IN ('bit', 'int', 'float', 'money') THEN CHAR(39) + CHAR(43) +
                                                                                   'CONVERT(VARCHAR(10),'---
                               + IIF(DATA_TYPE = 'bit',
                                     'IIF(' + COLUMN_NAME + '=' + CHAR(39) + '1' + CHAR(39) + ',' + CHAR(39) + 'true' +
                                     CHAR(39) + ',' + CHAR(39) + 'false' + CHAR(39) + ')',
                                     'ISNULL(' + COLUMN_NAME + ',' + CHAR(39) + CHAR(39) + ')') + ')' + CHAR(43) +
                                                                                   CHAR(39)
                           WHEN DATA_TYPE IN ('datetime') THEN '"' + CHAR(39) + CHAR(43) +
                                                               'CONVERT(VARCHAR(19),ISNULL(' + COLUMN_NAME + ',' +
                                                               CHAR(39) + CHAR(39) + ')' + ',120)' + CHAR(43) +
                                                               CHAR(39) + '"'
                           END + ',' AS [text()]
                FROM @Columns
                FOR XML PATH(''));
    --SELECT @Sql
    SET @Sql = LEFT(@Sql, LEN(@Sql) - 1);
    --SELECT @Sql
    SELECT @Sql =
           IIF(@Array = 1, CHAR(39) + ',' + CHAR(39) + CHAR(43), '') + @Sql + CHAR(39) + CHAR(43) + CHAR(39) + '}' +
           CHAR(39)

    IF @Array = 1
        BEGIN
            SELECT @Query = 'SELECT ' + @Sql + ' FROM ' + @Table + ' ' + @Condition;
            SELECT @Query =
                   ' SELECT @JSON = ' + CHAR(39) + '[' + CHAR(39) + CHAR(43) + '  STUFF((
			' + @Query + '
			FOR XML PATH('''')), 1, 1, '''')' + CHAR(43) + CHAR(39) + ']' + CHAR(39)
        END
    ELSE
        BEGIN
            SELECT @Query = 'SELECT @JSON = ' + @Sql + ' FROM ' + @Table + ' ' + @Condition;
        END

    EXEC sp_executesql @Query, N'@JSON NVARCHAR(MAX) OUTPUT', @JSON OUTPUT;

    RETURN
END
go


IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.xpCA_InterfazCargarOportunidadST')
            AND TYPE = 'P')
    DROP PROCEDURE dbo.xpCA_InterfazCargarOportunidadST;
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* =============================================
-- Author: Rivack Mares
-- Creación: 11/10/2023
-- =============================================*/
CREATE PROCEDURE [dbo].[xpCA_InterfazCargarOportunidadST](@id VARCHAR(20), @Sucursal INT = 0,
                                                          @Cliente VARCHAR(20) = NULL, @UpdateCte INT = NULL) as
BEGIN
    SET NOCOUNT ON

    DECLARE @cte varchar(30) = '0',
        @ok varchar(35),
        @okref varchar(250),
        @Contacto VARCHAR(50),
        @agente varchar(10),
        @Condicion varchar(50) = 'Contado',
        @Vin varchar(20),
        @idprospecto varchar(100) = @id,
        @estatusPedido varchar(50),
        @mensajePedido varchar(200),
        @mensaje varchar(200),
        @TipoPersona INT

    SELECT @TipoPersona = ISNULL(IIF(TipoPersona LIKE '%Moral%', 1, 0), 0),
           @mensaje = '',
           @Sucursal = Sucursal
    --@Cliente = ISNULL(IDCLIENTE,'')
    FROM CA_OportunidadesProspeccion
    WHERE IdProspecto = @id


    IF ISNULL(@Cliente, '') = ''
        BEGIN
            IF EXISTS(SELECT SEXO,
                             FECHANACIMIENTO,
                             CURP,
                             CALLE,
                             No_Ext,
                             Colonia,
                             DelegacionMunicipio,
                             Poblacion,
                             Estado,
                             CP,
                             TelefonoCelular
                      FROM CA_OportunidadesProspeccion
                      where IdProspecto = @id
                        AND (SEXO IS NOT NULL OR FechaNacimiento IS NOT NULL OR CALLE IS NOT NULL OR
                             No_Ext IS NOT NULL OR Colonia IS NOT NULL OR DelegacionMunicipio IS NOT NULL OR
                             Poblacion IS NOT NULL OR ESTADO IS NOT NULL OR CP IS NOT NULL OR
                             TelefonoCelular IS NOT NULL))
                BEGIN
                    EXEC xpCA_GeneraClienteProspecto @id, 1, @OK OUTPUT, @OkRef OUTPUT, @Contacto OUTPUT
                end
            ELSE
                BEGIN
                    EXEC xpCA_GeneraClienteProspecto @id, 0, @OK OUTPUT, @OkRef OUTPUT,
                         @Contacto OUTPUT --- Aqui retornar el id del cliente en @OkRef
                END
            SET @CTE = @OkRef
            SET @OkRef = ''
        END
    ELSE
        BEGIN
            IF @Cliente IS NOT NULL AND @UpdateCte = 1
                BEGIN
                    EXEC xpCA_ActualizaClienteProspecto @id, @Cliente, @OK OUTPUT, @OkRef OUTPUT, @Contacto OUTPUT
                end
            SET @CTE = @Cliente
            SET @OkRef = ''
        END

    if @okref = ''
        BEGIN
            select top 1 @agente = valor from CA_ParametrosAgencia where sucursal = 0 and clave = 'AgenteSF'

            BEGIN TRANSACTION [GeneraPedido]
                BEGIN TRY
                    IF EXISTS(SELECT * FROM CTE WHERE CLIENTE = @cte)
                        BEGIN
                            exec [xpCA_InterfazGeneraPedidoOP] @cte, @agente, @Condicion, @Vin, @Sucursal,
                                 @idProspecto, @estatusPedido output, @mensajePedido output
                        END
                    --COMMIT TRANSACTION [GeneraPedido]
                END TRY
                BEGIN CATCH
                    SELECT N'Ocurrio un error, número de error: ' + ERROR_NUMBER() + ', error: ' + ERROR_MESSAGE()
                END CATCH

                if (@estatusPedido = 'error')
                    BEGIN
                        ROLLBACK TRANSACTION [GeneraPedido]
                        update CA_OportunidadesProspeccion
                        set idcliente  = @cte,
                            idcontacto = @Contacto,
                            mensaje    = @mensajePedido
                        where IdProspecto = @id
                        select @mensaje = @mensajePedido
                    END
                if (@estatusPedido = 'success')
                    BEGIN
                        update CA_OportunidadesProspeccion
                        set idcliente  = @cte,
                            idcontacto = @Contacto,
                            estatus    = 'PROCESADO',
                            mensaje    = 'Pedido Generado',
                            IDPEDIDO   = @mensajePedido
                        where IdProspecto = @id
                        select @mensaje = 'Pedido Generado'
                        COMMIT TRANSACTION [GeneraPedido]
                    END
        END
    SELECT ISNULL(@mensaje, 'Proceso Terminado')
end
go

IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.xpCA_GeneraClienteProspecto')
            AND TYPE = 'P')
    DROP PROCEDURE dbo.xpCA_GeneraClienteProspecto;
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* =============================================
-- Author: Rivack Mares
-- Creación: 11/01/2024
-- Descripción:
-- =============================================*/

CREATE PROCEDURE [dbo].[xpCA_GeneraClienteProspecto](
    @IdProspecto VARCHAR(50),
    @Contacto BIT,
    @OK INT OUTPUT,
    @OkRef VARCHAR(100) OUTPUT,
    @Contactos VARCHAR(100) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON
    DECLARE
        @Consecutivo VARCHAR(10),
        @Empresa VARCHAR(10),
        @ConsecutivoContacto VARCHAR(30)

    SELECT TOP 1 @Empresa = Empresa FROM Empresa
    EXEC spConsecutivo 'CTE', 0, @Consecutivo OUTPUT

    IF @contacto = 1
        BEGIN
            BEGIN TRY
                BEGIN TRANSACTION
                    EXEC spConsecutivo 'CTE', 0, @ConsecutivoContacto OUTPUT

                    INSERT INTO CTE (Cliente, CURP, Estatus, Nombre, PersonalNombres, PersonalNombres2,
                                     PersonalApellidoPaterno, PersonalApellidoMaterno, Delegacion, Colonia, Poblacion,
                                     CodigoPostal, Estado, Pais, DefMoneda, Direccion, DireccionNumero,
                                     DireccionNumeroInt, RFC, PersonalTelefonoMovil, eMail1, Sexo, FechaNacimiento,SociedadMercantil)
                    SELECT TOP 1 @ConsecutivoContacto AS Consecutivo,
                                 CURP,
                                 'ALTA',
                                 Nombre + IIF(SegundoNombre IS NOT NULL, ' ' + SegundoNombre + ' ', ' ') +
                                 ApellidoPaterno +
                                 IIF(ApellidoMaterno IS NOT NULL, ' ' + ApellidoMaterno, ''),
                                 Nombre,
                                 SegundoNombre,
                                 ApellidoPaterno,
                                 ISNULL(ApellidoMaterno, ''),
                                 ISNULL(DelegacionMunicipio, Poblacion),
                                 Colonia,
                                 Poblacion,
                                 CP,
                                 Estado,
                                 N'México',
                                 N'Pesos',
                                 Calle,
                                 ISNULL(No_Ext, 0),
                                 ISNULL(No_Int, 0),
                                 ISNULL(RFC, 'XAXX010101000'),
                                 ISNULL(TelefonoCelular, '5555555555'),
                                 ISNULL(Email, 'notiene@gmail.com'),
                                 Sexo,
                                 FechaNacimiento,
                                 SociedadMercantil
                    FROM CA_OportunidadesProspeccion
                    WHERE IdProspecto = @IdProspecto

                    SET @Contactos = @ConsecutivoContacto
                COMMIT TRANSACTION
            END TRY
            BEGIN CATCH
                SELECT @OkRef = ERROR_MESSAGE(), @OK = 666
                ROLLBACK TRANSACTION
            END CATCH
        END

    BEGIN TRY
        BEGIN TRANSACTION
            INSERT INTO CTE (Cliente, CURP, Estatus, Nombre, PersonalNombres, PersonalNombres2, PersonalApellidoPaterno,
                             PersonalApellidoMaterno, Delegacion, Colonia, Poblacion, Estado, CodigoPostal, Pais,
                             DefMoneda, Direccion, DireccionNumero, DireccionNumeroInt, RFC, FiscalRegimen,
                             TelefonosLada,
                             Telefonos, PersonalTelefonoMovil, eMail1, Sexo, FechaNacimiento, CteMantenimiento,SociedadMercantil)
            SELECT TOP 1 @Consecutivo as Consecutivo,
                         CURPFactura,
                         'ALTA',
                         IIF(TipoPersona = 'MORAL', RazonComercialFactura,
                             (NombreFactura + IIF(SegundoNombreFactura IS NOT NULL, ' ' + SegundoNombreFactura, ' ') +
                              ApellidoPaternoFactura +
                              IIF(ApellidoMaternoFactura IS NOT NULL, ' ' + ApellidoMaternoFactura, ''))),
                         NombreFactura,
                         SegundoNombreFactura,
                         ApellidoPaternoFactura,
                         ApellidoMaternoFactura,
                         ISNULL(DelegacionMunicipioFactura, Poblacion),
                         ColoniaFactura,
                         PoblacionFactura,
                         EstadoFactura,
                         ISNULL(CPFactura, '00000'),
                         N'México', -- Pais
                         N'Pesos',
                         CalleFactura,
                         ISNULL(No_ExtFactura, 0),
                         ISNULL(No_IntFactura, 0),
                         ISNULL(RFCFactura, 'XAXX010101000'),
                         RegimenFiscal,
                         RIGHT(TelefonoCasaOficinaFactura, 7),
                         LEFT(TelefonoCasaOficinaFactura, 3),
                         ISNULL(TelefonoCelularFactura, '5555555555'),
                         ISNULL(EmailFactura, 'notiene@gmail.com'),
                         SexoFactura,
                         FechaNacimientoFactura,
                         @ConsecutivoContacto,
                         SociedadMercantil
            FROM CA_OportunidadesProspeccion
            WHERE IdProspecto = @IdProspecto

            SET @OkRef = @Consecutivo
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        SELECT @OkRef = ERROR_MESSAGE(), @OK = 666
        ROLLBACK TRANSACTION
    END CATCH;
END
go


IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.xpCA_ActualizaClienteProspecto')
            AND TYPE = 'P')
    DROP PROCEDURE dbo.xpCA_ActualizaClienteProspecto;
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* =============================================
-- Author: Rivack Mares
-- Creación: 11/01/2024
-- Descripción:
-- =============================================*/

CREATE PROCEDURE [dbo].[xpCA_ActualizaClienteProspecto](
    @IdProspecto VARCHAR(50),
    @Cliente VARCHAR(80),
    @OK INT OUTPUT,
    @OkRef VARCHAR(100) OUTPUT,
    @Contactos VARCHAR(100) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON
    DECLARE
        @Contacto BIT,
        @Empresa VARCHAR(10),
        @ConsecutivoContacto VARCHAR(30)
    SELECT TOP 1 @Empresa = Empresa FROM Empresa

    SELECT @Contacto = IIF(CteMantenimiento IS NOT NULL, 1, 0), @ConsecutivoContacto = CteMantenimiento
    FROM CTE
    WHERE CLIENTE = @Cliente

    IF @contacto = 1
        BEGIN
            BEGIN TRY
                BEGIN TRANSACTION
                    UPDATE CTE
                    SET CTE.CURP                    = CAP.CURP,
                        CTE.Nombre                  = CAP.Nombre +
                                                      IIF(CAP.SegundoNombre IS NOT NULL, ' ' + CAP.SegundoNombre, ' ') +
                                                      CAP.ApellidoPaterno +
                                                      IIF(CAP.ApellidoMaterno IS NOT NULL, ' ' + CAP.ApellidoMaterno, ''),
                        CTE.PersonalNombres         = CAP.Nombre,
                        CTE.PersonalNombres2        = CAP.SegundoNombre,
                        CTE.PersonalApellidoPaterno = CAP.ApellidoPaterno,
                        CTE.PersonalApellidoMaterno = ISNULL(CAP.ApellidoMaterno, ''),
                        CTE.DELEGACION              = ISNULL(CAP.DelegacionMunicipio, CAP.Poblacion),
                        CTE.Colonia                 = CAP.Colonia,
                        CTE.Poblacion               = CAP.Poblacion,
                        CTE.CodigoPostal            = CAP.CP,
                        CTE.ESTADO                  = CAP.Estado,
                        CTE.Direccion               = CAP.Calle,
                        CTE.DireccionNumero         = CAP.No_Ext,
                        CTE.DireccionNumeroInt      = CAP.No_Int,
                        CTE.RFC                     = IIF(CAP.RFC = 'XAXX010101000', CAP.RFC, CTE.RFC),
                        CTE.PersonalTelefonoMovil= CAP.TelefonoCelular,
                        CTE.EMAIL1                  = CAP.Email,
                        CTE.Sexo                    = CAP.Sexo,
                        CTE.FechaNacimiento         = CAP.FechaNacimiento,
                        CTE.SociedadMercantil       = CAP.SociedadMercantil
                    FROM CTE
                             LEFT JOIN CA_OportunidadesProspeccion CAP ON CAP.IdProspecto = @IdProspecto
                    WHERE Cte.Cliente = @ConsecutivoContacto
                    SET @Contactos = @ConsecutivoContacto
                COMMIT TRANSACTION
            END TRY
            BEGIN CATCH
                SELECT @OkRef = ERROR_MESSAGE(), @OK = 666
                ROLLBACK TRANSACTION
            END CATCH
        END


    ELSE
        BEGIN
            IF EXISTS(SELECT SEXO,
                             FECHANACIMIENTO,
                             CURP,
                             CALLE,
                             No_Ext,
                             Colonia,
                             DelegacionMunicipio,
                             Poblacion,
                             Estado,
                             CP,
                             TelefonoCelular
                      FROM CA_OportunidadesProspeccion
                      where IdProspecto = @IdProspecto
                        AND (SEXO IS NOT NULL OR FechaNacimiento IS NOT NULL OR CALLE IS NOT NULL OR
                             No_Ext IS NOT NULL OR Colonia IS NOT NULL OR DelegacionMunicipio IS NOT NULL OR
                             Poblacion IS NOT NULL OR ESTADO IS NOT NULL OR CP IS NOT NULL OR
                             TelefonoCelular IS NOT NULL))
                BEGIN
                    SET @ConsecutivoContacto = NULL
                    EXEC spConsecutivo 'CTE', 0, @ConsecutivoContacto OUTPUT
                    INSERT INTO CTE (Cliente, CURP, Estatus, Nombre, PersonalNombres, PersonalNombres2,
                                     PersonalApellidoPaterno,
                                     PersonalApellidoMaterno, Delegacion, Colonia, Poblacion, CodigoPostal, Estado,
                                     Pais,
                                     Direccion, DireccionNumero, DireccionNumeroInt, RFC,
                                     PersonalTelefonoMovil, eMail1, Sexo, FechaNacimiento,SociedadMercantil)
                    SELECT TOP 1 @ConsecutivoContacto AS Consecutivo,
                                 CURP,
                                 'ALTA',
                                 Nombre + IIF(SegundoNombre IS NOT NULL, ' ' + SegundoNombre, ' ') + ApellidoPaterno +
                                 IIF(ApellidoMaterno IS NOT NULL, ' ' + ApellidoMaterno, ''),
                                 Nombre,
                                 SegundoNombre,
                                 ApellidoPaterno,
                                 ISNULL(ApellidoMaterno, ''),
                                 ISNULL(DelegacionMunicipio, Poblacion),
                                 Colonia,
                                 Poblacion,
                                 CP,
                                 Estado,
                                 N'México',
                                 Calle,
                                 No_Ext,
                                 No_Int,
                                 ISNULL(RFC, 'XAXX010101000'),
                                 TelefonoCelular,
                                 Email,
                                 Sexo,
                                 FechaNacimiento,
                                 SociedadMercantil
                    FROM CA_OportunidadesProspeccion
                    WHERE IdProspecto = @IdProspecto
                end
        END

    BEGIN TRY
        BEGIN TRANSACTION
            UPDATE CTE
            SET CTE.CURP                    = CAD.CPFactura,
                CTE.ESTATUS                 = 'ALTA',
                CTE.Nombre                  = IIF(CAD.TipoPersona = 'MORAL', CAD.RazonComercialFactura,
                                                  (CAD.NombreFactura +
                                                   IIF(CAD.SegundoNombreFactura IS NOT NULL,
                                                       ' ' + CAD.SegundoNombreFactura, ' ') +
                                                   CAD.ApellidoPaternoFactura +
                                                   IIF(CAD.ApellidoMaternoFactura IS NOT NULL,
                                                       ' ' + CAD.ApellidoMaternoFactura,
                                                       ''))),
                CTE.PersonalNombres         = CAD.NombreFactura,
                CTE.PersonalNombres2        = CAD.SegundoNombreFactura,
                CTE.PersonalApellidoPaterno = CAD.ApellidoPaternoFactura,
                CTE.PersonalApellidoMaterno = CAD.ApellidoMaternoFactura,
                CTE.Delegacion              = ISNULL(CAD.DelegacionMunicipioFactura, CAD.Poblacion),
                CTE.Colonia                 = CAD.ColoniaFactura,
                CTE.Poblacion               = CAD.PoblacionFactura,
                CTE.Estado                  = CAD.EstadoFactura,
                CTE.CodigoPostal            = CAD.CPFactura,
                CTE.Pais                    = N'México',                                         -- Pais
                CTE.Direccion               = CAD.CalleFactura,
                CTE.DireccionNumero         = CAD.No_ExtFactura,
                CTE.DireccionNumeroInt      = CAD.No_IntFactura,
                CTE.RFC                     = ISNULL(RFCFactura, 'XAXX010101000'),
                CTE.FiscalRegimen           = CAD.RegimenFiscal,
                CTE.TelefonosLada           = RIGHT(CAD.TelefonoCasaOficinaFactura, 7),
                CTE.Telefonos               = LEFT(CAD.TelefonoCasaOficinaFactura, 3),
                CTE.PersonalTelefonoMovil   = CAD.TelefonoCelularFactura,
                CTE.eMail1                  = CAD.EmailFactura,
                CTE.Sexo                    = CAD.SexoFactura,
                CTE.FechaNacimiento         = CAD.FechaNacimientoFactura,
                CTE.CteMantenimiento        = ISNULL(CTE.CteMantenimiento, @ConsecutivoContacto), -- COLOCAR UN ISNULL CON EL ACTUAL Y SINO COLOCAR LA VARIABLE
                CTE.SociedadMercantil       = CAD.SociedadMercantil
            FROM CTE
                     INNER JOIN CA_OportunidadesProspeccion CAD ON CAD.IdProspecto = @IdProspecto
            WHERE Cliente = @Cliente
            SET @OkRef = @Cliente
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        SELECT @OkRef = ERROR_MESSAGE(), @OK = 666
        ROLLBACK TRANSACTION
    END CATCH;

END
go



IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.xpCA_InterfazGeneraPedidoOP')
            AND TYPE = 'P')
    DROP PROCEDURE dbo.xpCA_InterfazGeneraPedidoOP;
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* =============================================
-- Author: Rivack Mares
-- Creación: 11/01/2024
-- Descripción:
-- =============================================*/

CREATE PROCEDURE [dbo].[xpCA_InterfazGeneraPedidoOP] @Cliente varchar(10),
                                                     @Agente varchar(10), --- agente
                                                     @Condicion varchar(50), ---credito o contado
                                                     @Vin varchar(20),
                                                     @Sucursal int, --- Intelisis (sucursal archivo)
                                                     @idProspecto varchar(200),
                                                     @ok varchar(50) output,
                                                     @mensaje varchar(200) output
AS
BEGIN
    DECLARE
        @Articulo varchar(20) ,
        @Precio money ,
        @Error int ,
        @ErrorDescripcion varchar(255),
        @IVA float ,
        @Moneda varchar(10) ,
        @Empresa char(5),
        @Usuario varchar(10) = 'SOPDESA',
        @Estatus varchar(15) = 'SINAFECTAR',
        @Almacen varchar(10),
        @UEN INT,
        @Mov VARCHAR(25)

    SELECT @Error = 0

    SELECT top 1 @Empresa = empresa FROM empresa
    SELECT @Mov     =   IIF((SELECT TOP 1 Grupo FROM EMPRESA) = 'ALDEN', 'Pre Pedido', 'Pedido Unidad')
    SELECT @Almacen =   ISNULL(dbo.fnCA_GeneraAlmacenlValido('VTAS', @Mov,
                        dbo.fnCA_GeneraSucursalValida('VTAS', @Mov, @sucursal)),
                        (SELECT almacen FROM ALM WHERE Sucursal = @Sucursal AND ALMACEN LIKE 'V%')
                        )
    SELECT @UEN     =   dbo.fnCA_GeneraUENValida('VTAS', @Mov,
                        dbo.fnCA_GeneraSucursalValida('VTAS', @Mov, @sucursal),
                        'Tradicional')
    --almacen FROM ALM WHERE Sucursal = @Sucursal AND ALMACEN LIKE 'V%'

    IF ISNULL(@Vin, '') != ''
        BEGIN
            SELECT @Articulo = VIN.Articulo,
                   @Precio = VIN.PrecioContado,
                   @Moneda = Art.MonedaPrecio,
                   @IVA = Art.Impuesto1
            FROM Vin
                     JOIN Art ON Art.Articulo = VIN.Articulo
            WHERE Vin.Vin = @Vin
        END

    BEGIN TRY

        INSERT Venta (Sucursal, Empresa, Mov, FechaEmision, FechaRequerida, Moneda, TipoCambio, Almacen, Cliente,
                      EnviarA,
                      ListaPreciosEsp, Condicion, Concepto, Referencia, Observaciones, Usuario, Estatus, OrigenTipo,
                      Origen, --, venta_grupo,idsucursalorigen
                      OrigenID, Agente, Proyecto, UEN,
                      DesglosarImpuesto2) --- se quito nombresucursal -- se quito lead_Id
        VALUES (@Sucursal, @Empresa, @Mov,
                CONVERT(varchar(10), GETDATE(), 103),
                CONVERT(varchar(10), GETDATE(), 103), ISNULL(@Moneda, 'Pesos'), 1.0, @Almacen, @Cliente, NULL,
                '(Precio Lista)', @Condicion, 'Tradicional', NULL, 'DESDE SALESFORCE', @Usuario, @Estatus, NULL, NULL,
                NULL, @Agente, NULL, @UEN,1)
        SELECT @ok = 'success', @mensaje = CONVERT(INT, @@IDENTITY)
        INSERT INTO CA_Venta(IDVENTA, idProspecto) values (@mensaje, @idProspecto)
    END TRY
    BEGIN CATCH

        SELECT @ErrorDescripcion = ERROR_MESSAGE()
        SELECT @ok = 'error', @mensaje = @ErrorDescripcion

    END CATCH

END
GO

IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.xpCA_EnvioProspectosSalesForce')
            AND TYPE = 'P')
    DROP PROCEDURE dbo.xpCA_EnvioProspectosSalesForce;
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* =============================================
-- Author: Rivack Mares
-- Creación: 11/01/2024
-- Descripción: El procedimiento realiza un envio a SalesForce
-- =============================================*/

CREATE PROCEDURE [dbo].[xpCA_EnvioProspectosSalesForce] @ID INT,
                                                       @MovID VARCHAR(20) = NULL,
                                                       @Table VARCHAR(MAX) = 'vwCA_PROSPECTOSENVIO'
AS
BEGIN
    DECLARE
        @JSON NVARCHAR(MAX),
        @Condition VARCHAR(400)= ' WHERE ',
        @Credenciales NVARCHAR(MAX),
        @UrlProspectos VARCHAR(MAX) = dbo.fnCA_BusquedaClaveParametroInterfazEmpresa('ProspeccionSF', 'URLProspectos'),
        @UrlToken VARCHAR(MAX)= dbo.fnCA_BusquedaClaveParametroInterfazEmpresa('ProspeccionSF', 'URLToken'),
        @Headers NVARCHAR(MAX)='',
        @Metodo VARCHAR(10)='POST',
        @Token VARCHAR(300),
        @Response NVARCHAR(MAX),
        @Sucursal INT,
        @Mov NVARCHAR(MAX)='',
        @Modulo VARCHAR(5)= 'VTAS',
        @Estatus VARCHAR(20) = 'Error',
        @Interfaz VARCHAR(15) = 'ProspeccionSF'

    IF NOT EXISTS(SELECT * FROM CA_VENTA WHERE IDVENTA = @ID)
        BEGIN
            RETURN
        end

    BEGIN TRY
        SELECT @Sucursal = Sucursal, @Mov = Mov, @MovId = IIF(@MovId is null, MovId, @MovId) FROM VENTA WHERE ID = @ID

        /* Se crea la condición de la vista. */
        SELECT @Condition +=
               'IDOPORTUNIDAD =' + CHAR(39) + IDPROSPECTO + CHAR(39) + ' AND numeroFacturacion=' +
               CHAR(39) +
               @MOVID + CHAR(39)
        FROM CA_VENTA
        WHERE IDVENTA = @ID

        /* Se genera el Json a enviar. */
        EXEC xpCA_Transform_to_JSON @Table, 1, @Condition, @JSON=@JSON OUTPUT

        /* Se crea body para obtener el token. */
        SELECT @Credenciales =
               'username=' + dbo.fnCA_CatParametrosSucursalValor(@Sucursal, 'Username') + '&password=' +
               dbo.fnCA_CatParametrosSucursalValor(@Sucursal, 'Password') +
               '&client_id=' + dbo.fnCA_CatParametrosSucursalValor(@Sucursal, 'ClientID') +
               '&client_secret=' + dbo.fnCA_CatParametrosSucursalValor(0, 'ClientSecret') +
               '&grant_type=' + dbo.fnCA_BusquedaClaveParametroInterfazEmpresa(@Interfaz, 'GrantType')

        EXEC xpCA_PeticionHTTP @UrlToken, @Credenciales, 'Content-Type:application/x-www-form-urlencoded', @Metodo,
             @Token OUTPUT

        /* Se recorta la repuesta para obtener el token. */
        SELECT @Token = DBO.fnCA_ValorEtiquetaJSON(@Token, 'access_token')

        /* Se crea el Header para enviar a la petición. */
        SET @Headers = 'Content-Type:application/json:Authorization:Bearer ' + @Token

        /* Se envía la petición a SalesForce. */
        IF @Token IS NOT NULL AND @Headers IS NOT NULL
            EXEC xpCA_PeticionHTTP @UrlProspectos, @JSON, @Headers, @Metodo, @Response OUTPUT
        ELSE
            SET @Response = 'Error al obtener el token'

        /* Se inserta en el log el resultado de la petición. */
        IF @Response LIKE '%"statusCode"%:%"200"%'
            BEGIN
                SET @Estatus = 'Enviado'
            end

        EXEC xpCA_InsertaLogs @ID, @Sucursal, 'VTAS', @Modulo, @Mov, @MovID, @Estatus, @JSON, @Response, @Response,
             @Interfaz

    END TRY
    BEGIN CATCH
        EXEC xpCA_InsertaLogs @ID, 0, 'VTAS', 'VTAS', '',
             @MovID, 'Error', '', 'Error al ejecutar el procedimiento',
             'Ha ocurrido un error al ejecutar el procedimiento, no deberias ver este error', 'ProspeccionSF'
    end catch
END
GO


IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.xpCA_InterfazOportunidadProspectosST')
            AND TYPE = 'P')
    DROP PROCEDURE dbo.xpCA_InterfazOportunidadProspectosST;
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* =============================================
-- Author: Rivack Mares
-- Creación: 11/01/2024
-- Descripción: El procedimiento una busqueda.
-- =============================================*/

CREATE PROCEDURE [dbo].[xpCA_InterfazOportunidadProspectosST](@Estacion INT=NULL, @IDProspecto VARCHAR(20),
                                                              @HayCliente VARCHAR(10) OUTPUT)
AS
BEGIN
    DECLARE
        @Nombre VARCHAR(50),
        @Apaterno VARCHAR(50),
        @Amaterno VARCHAR(50),
        @Telefono VARCHAR(50),
        @Celular VARCHAR(50),
        @Email VARCHAR(100),
        @RFC VARCHAR(100),
        @Estado VARCHAR(100),
        @Delegacion VARCHAR(50),
        @DireccionNumero VARCHAR(5),
        @DireccionNumeroInt VARCHAR(5),
        @CodigoPostal VARCHAR(10),
        @TipoPersona VARCHAR(40),
        @NombreContacto VARCHAR(50),
        @ApaternoContacto VARCHAR(50),
        @AmaternoContacto VARCHAR(50),
        @RazonComercialFactura varchar(200),
        @CLIENTE VARCHAR(50)

    SELECT @Email = ISNULL(EmailFactura, ''),
           @Nombre = ISNULL(NombreFactura, ''),
           @Apaterno = ISNULL(ApellidoPaternoFactura, ''),
           @Amaterno = ISNULL(ApellidoMaternoFactura, ''),
           @Telefono = ISNULL(TelefonoCasaOficinaFactura, ''),
           @Celular = ISNULL(TelefonoCelularFactura, ''),
           @RFC = ISNULL(RFCFactura, ''),
           @Estado = ISNULL(EstadoFactura, ''),
           @Delegacion = ISNULL(DelegacionMunicipioFactura, ''),
           @DireccionNumero = ISNULL(No_ExtFactura, ''),
           @DireccionNumeroInt = ISNULL(No_IntFactura, ''),
           @CodigoPostal = ISNULL(CPFactura, ''),
           @TipoPersona = ISNULL(TipoPersona, 0),
           @NombreContacto = ISNULL(Nombre, ''),
           @ApaternoContacto = ISNULL(ApellidoPaterno, ''),
           @AmaternoContacto = ISNULL(ApellidoMaterno, ''),
           @RazonComercialFactura = ISNULL(RazonComercialFactura, ''),
           @CLIENTE = ISNULL(IDCLIENTE, '')
    FROM CA_OportunidadesProspeccion AS P
    WHERE P.IDProspecto = @IDProspecto

    DELETE FROM CA_InterfazCteProspectos WHERE Estacion = @Estacion

    IF NULLIF(@CLIENTE, '') IS NOT NULL
        BEGIN
            PRINT @CLIENTE
            PRINT 'HOLA'
            SELECT @HayCliente = '0'
            INSERT INTO CA_InterfazCteProspectos
            SELECT Cliente,
                   @Estacion,
                   @IDProspecto,
                   RFC,
                   Direccion,
                   DireccionNumero,
                   DireccionNumeroInt,
                   Pais,
                   Estado,
                   Delegacion,
                   Colonia,
                   Poblacion,
                   CodigoPostal,
                   Telefonos,
                   PersonalTelefonoMovil,
                   eMail1
            FROM Cte
            WHERE Cliente = @CLIENTE
            RETURN
        end


    SELECT @HayCliente = '1'


    IF @TipoPersona LIKE '%Moral%'
        BEGIN
            INSERT INTO CA_InterfazCteProspectos
            SELECT Cliente,
                   @Estacion,
                   @IDProspecto,
                   RFC,
                   Direccion,
                   DireccionNumero,
                   DireccionNumeroInt,
                   Pais,
                   Estado,
                   Delegacion,
                   Colonia,
                   Poblacion,
                   CodigoPostal,
                   Telefonos,
                   PersonalTelefonoMovil,
                   eMail1
            FROM Cte
            WHERE CTE.Nombre LIKE '%' + @RazonComercialFactura + '%'
              AND IIF(CTE.eMail1 = @Email OR CTE.RFC = @RFC OR CTE.Estado = @Estado OR
                      CTE.DireccionNumero = @DireccionNumero, 1, 0) = 1
        END
    ELSE
        BEGIN
            INSERT INTO CA_InterfazCteProspectos
            SELECT Cliente,
                   @Estacion,
                   @IDProspecto,
                   RFC,
                   Direccion,
                   DireccionNumero,
                   DireccionNumeroInt,
                   Pais,
                   Estado,
                   Delegacion,
                   Colonia,
                   Poblacion,
                   CodigoPostal,
                   Telefonos,
                   PersonalTelefonoMovil,
                   eMail1
            FROM Cte
            WHERE (CTE.PersonalNombres LIKE '%' + @Nombre + '%'
                AND CTE.PersonalApellidoPaterno LIKE '%' + @Apaterno + '%'
                AND CTE.PersonalApellidoMaterno LIKE '%' + @Amaterno + '%')
              AND IIF(CTE.eMail1 = @Email OR CTE.Estado = @Estado OR
                      CTE.DireccionNumero = @DireccionNumero, 1, 0) = 1
        end
END
GO
