/* =============================================
-- Autor:Giovanni Trujillo Silvas
-- Creaci�n: 05/01/2024
-- Descripci�n: Genera un JSON a partir de una Vista o tabla SQL, convirtiendo las columnas a etiquetas. Permite indicar campos espec�ficos y filtrar por un valor espec�fico mediante un WHERE y la condici�n acorde a los campos de la vista o tabla. Tambi�n se puede especificar si el resultado debe ser un array de JSON o �nico. En caso de ser un array, se incluyen [] (llaves de apertura y cierre) en la respuesta.
-- Par�metros:
    - @Table: "Nombre de la tabla o vista a trabajar"
    - @Array: "1 para indicar que se agreguen [] o 0 para no agregar. Por defecto se inicializa en 0"
    - @Condition: "FILTRO WHERE con la condici�n a validar. Por defecto se inicializa en '' "
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
	SELECT @JSON,'JSON SIN ARRAY, S� LA CONSULTA POSEE MULTIPLES REGISTROS DE SALIDA SE PERDERAN Y SOLO RETORNARA EL PRIMER'
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
                                      FROM dbo.fnCA_StringSplit(@Fields))
        END

    SET @Sql +=(SELECT ' "' + COLUMN_NAME + '" : ' +

						CASE	WHEN DATA_TYPE IN ( 'varchar','nvarchar','char')  THEN '"' + CHAR(39) + CHAR(43)+'ISNULL('+COLUMN_NAME+ ','+CHAR(39)+CHAR(39)+')'+CHAR(43) + CHAR(39) + '"'
								WHEN DATA_TYPE IN ( 'bit' ,'int','float') THEN CHAR(39) + CHAR(43) + 'CONVERT(VARCHAR(10),'---
								+ IIF(DATA_TYPE = 'bit','IIF(' + COLUMN_NAME + '=' +CHAR(39) + '1' + CHAR(39) +',' + CHAR(39) + 'true' +CHAR(39) + ',' + CHAR(39) +'false' + CHAR(39) + ')',
                                                                               'ISNULL('+COLUMN_NAME+ ','+CHAR(39)+CHAR(39)+')')+')' + CHAR(43) + CHAR(39)
								WHEN DATA_TYPE IN ('datetime') THEN '"' +  CHAR(39) + CHAR(43) + 'CONVERT(VARCHAR(10),ISNULL('+COLUMN_NAME+ ','+CHAR(39)+CHAR(39)+')'+',126)' + CHAR(43) + CHAR(39) + '"'
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

/********************************************************************************************************************************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************************************************************************************************************************/
IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.xpCA_InsertaLogs')
            AND TYPE = 'P')
    DROP PROCEDURE dbo.xpCA_InsertaLogs;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
-- =============================================
-- Author:		Cristian Fern�ndez Nieto
-- Create date: 26-01-2023
-- Description:	Store que inserta los logs en las tablas CA_LogMovimientosInterfaz, CA_LogMovimientosInterfazD
-- =============================================
CREATE PROCEDURE [dbo].[xpCA_InsertaLogs](@ID INT, @Sucursal INT = 0, @Tipo Varchar(20), @Modulo Varchar(5) = 'VTAS',
                                          @Mov Varchar(20) = NULL, @MovID Varchar(20) = NULL,
                                          @Estatus Varchar(10) = 'ENVIADO', @Request Varchar(MAX) = NULL,
                                          @Response Varchar(MAX) = NULL, @DescripcionResponse Varchar(MAX) = '',
                                          @Interfaz Varchar(30), @Historico bit=0)
AS
BEGIN
    DECLARE
        @IDLog INT = 0,
        @Marca Varchar(15),
        @TipoError Varchar(10) = NULL,
        @OrigenError Varchar(10) = NULL
    Select TOP 1 @Marca = VERSION FROM Sucursal
    IF @Estatus = 'OK'
        BEGIN
            SET @Estatus = 'ENVIADO'
        END
    IF @Estatus = 'ERROR'
        BEGIN
            SELECT @TipoError = 'ERR', @OrigenError = 'WS'
        END
    IF @Historico = 1
        BEGIN
            INSERT INTO CA_LogInterfaces (Sucursal, Tipo, IDDocumento, Modulo, Mov, MovID, FechaCreacion, FechaEnvio,
                                          TipoError, OrigenError, Estatus, Request, Response, Marca)
            SELECT @Sucursal,
                   @Tipo,
                   @ID,
                   @Modulo,
                   @Mov,
                   @MovID,
                   GETDATE(),
                   GETDATE(),
                   @TipoError,
                   @OrigenError,
                   @Estatus,
                   @Request,
                   @Response,
                   @Marca
        END
    SELECT TOP 1 @IDLog = ID
    FROM CA_LogMovimientosInterfaz
    WHERE IDDocumento = @ID
      AND Interfaz = @Interfaz
      AND Tipo = @tipo
    ORDER BY ID DESC
    IF @IDLog != 0 AND @IDLog IS NOT NULL
        BEGIN
            UPDATE CA_LogMovimientosInterfaz
            SET Tipo       = ISNULL(@Tipo, Tipo),
                Modulo     = ISNULL(@Modulo, Modulo),
                Mov        = ISNULL(@Mov, Mov),
                MovID      = ISNULL(@MovID, MovID),
                FechaEnvio = GETDATE(),
                Estatus    = ISNULL(@Estatus, Estatus),
                Request    = @Request,
                Sucursal   = ISNULL(@Sucursal, Sucursal),
                Interfaz   = ISNULL(@Interfaz, Interfaz),
                Marca      = ISNULL(@Marca, Marca)
            WHERE ID = @IDLog
            IF @Estatus = 'ENVIADO'
                BEGIN
                    UPDATE CA_LogMovimientosInterfazD
                    SET TipoError   = @TipoError,
                        Response    = ISNULL(@Response, Response),
                        Descripcion = ISNULL(@DescripcionResponse, Descripcion)
                    WHERE logID = @IDLog
                END
            ELSE
                BEGIN
                    UPDATE CA_LogMovimientosInterfazD
                    SET TipoError   = @TipoError,
                        Response    = ISNULL(@Response, Response),
                        Descripcion = ISNULL(@DescripcionResponse, Descripcion)
                    WHERE logID = @IDLog
                END
        END
    ELSE
        BEGIN
            IF @ID = 0 OR @ID IS NULL
                BEGIN
                    SELECT @ID = ISNULL(MAX(IDDOCUMENTO), 0)
                    FROM CA_LogMovimientosInterfaz
                    WHERE INTERFAZ = @Interfaz
                      AND Tipo = @tipo
                    SET @ID = @ID + 1
                END
            INSERT INTO CA_LogMovimientosInterfaz
            SELECT @Sucursal,
                   @Tipo,
                   @ID,
                   @Modulo,
                   @Mov,
                   @MovID,
                   GETDATE(),
                   GETDATE(),
                   @TipoError,
                   @OrigenError,
                   @Estatus,
                   @Request,
                   @Interfaz,
                   @Marca
            SELECT @IDLog = scope_identity()--IDENT_CURRENT('CA_LogMovimientosInterfaz')
            IF @Estatus = 'ENVIADO'
                BEGIN
                    INSERT INTO CA_LogMovimientosInterfazD
                    SELECT @IDLog, @TipoError, @OrigenError, @Response, @DescripcionResponse
                END
            ELSE
                BEGIN
                    INSERT INTO CA_LogMovimientosInterfazD
                    SELECT @IDLog, @TipoError, @OrigenError, @Response, @DescripcionResponse
                END
        END
END
GO

/********************************************************************************************************************************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************************************************************************************************************************/

IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.xpCA_PeticionHTTP')
            AND TYPE = 'P')
    DROP PROCEDURE dbo.xpCA_PeticionHTTP;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* =============================================
    Modificado por: Rivack Emiliano Mares Castro
    Modificado: 22/08/2023
============================================= */
CREATE PROCEDURE [dbo].[xpCA_PeticionHTTP](@Url VARCHAR(MAX),
                                           @RequestBody varchar(MAX),
                                           @Headers varchar(MAX),
                                           @Metodo VARCHAR(10),
                                           @Consulta VARCHAR(MAX) OUTPUT,
                                           @Delimitador CHAR(1)=NULL)
AS
BEGIN
    /* =============================================
    Ejemplo de uso:
    --GET
    DECLARE @Url varchar(200) = 'https://tkint.herokuapp.com/prd',
    @Metodo varchar(200) = '',
    @RequestBody varchar(MAX) = '',
    @Salida varchar(MAX),
    @Headers varchar(MAX) = '"ContentType":"application/json"';
    EXECUTE xpCA_PeticionHTTP @Url,@RequestBody,@Headers,@Metodo,@Consulta=@Salida Output
    SELECT @Salida


    --POST
    DECLARE @Url varchar(200) = 'https://login.microsoftonline.com/tmnab2c.onmicrosoft.com/oauth2/token',
    @Metodo varchar(200) = 'POST',
    @RequestBody varchar(MAX) = 'grant_type=client_credentials&client_id=1e3222ee-5dd5-41f8-a1c3-93708df30a6d&resource=https://ddoa-rs.toyota.com&client_assertion=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsIng1dCI6ImhSK2xsYy8walhzbVhuTDlmb2dldEh2bmUzST0ifQ.eyJleHAiOjE2OTAyNDI5MjMsInN1YiI6IjFlMzIyMmVlLTVkZDUtNDFmOC1hMWMzLTkzNzA4ZGYzMGE2ZCIsIm5iZiI6MTY5MDIyNDc0MywiYXVkIjoiaHR0cHM6Ly9sb2dpbi5taWNyb3NvZnRvbmxpbmUuY29tL3RtbmFiMmMub25taWNyb3NvZnQuY29tL29hdXRoMi90b2tlbiIsImlzcyI6IjFlMzIyMmVlLTVkZDUtNDFmOC1hMWMzLTkzNzA4ZGYzMGE2ZCIsImp0aSI6IjM2N2VlMThjLTM1NWItNDdlMS1hYTRlLTdmZjkxNzgzY2FmNSIsImFsZ29yaXRobSI6IlJTMjU2IiwiaWF0IjoxNjkwMjI0OTIzfQ.WQPpaSAaI57wjvB8giJag2tiJJq0TSns5Xz3RMVkW3Sl1WXzoiLwT2R7jYT_jkIzuvKesE0DnoF36-IpHiNdYbzGwOmaFJAD0p7fjlEgRYfQL7Ntcwa31Md7TSyKVVlncFHNKgKM3cT-U0qxX_BY5FQCGDnkIIlWUpeHPZIw_HWJlpBNpP1UcIkgwxSrrfZ_B1cxXFdiiJaFN6e0RMxTdJG5MfXINg8p43czAzLcmj3etcLMyK_GgwKLGBNkm8Hrv55wtaW_uS7yF5eSNdqJnuoWka9dOsWaiwlvWI0VhRpdbMdEvMN07vzP9WzIaUzyMfSOW6tVsPysvcur-SDO6ah2_Y7TZKMdp7opgsdl6oHQUMJ1P43X5kX1OyZpcxhmu0JS2yC6GFrovCy8ZnON0RkxQUjRid5Pdd2KsBlxj1rjvjhV73ZDC_GTL6dokBHVngpL5tp_EqkJ6--zRXQoNSUkmkcVQQsLJildCEWlIeOiH3PZ0chTcfJW7CTXnhvxCnLytYoV1eOTS1guEj0QUmhpgUtEuyoo5-nNZUWfGnrNd6n6dUQbOpo3TzjwLMMhcFvEEIDYetzWlV5tljgcO5t-T8585UM4itJZ3_sWoEOr2VXcDTtYzkXN3xVi_i_ORpo5CYLeBLyuuSY5yhOlEL-NuPjBSpSe74E2UvMsVkY&client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
    @Salida varchar(MAX),
@Headers varchar(MAX) = 'Content-Type|application/x-www-form-urlencoded';
EXECUTE xpCA_PeticionHTTP @Url,@RequestBody,@Headers,@Metodo,@Consulta=@Salida Output,@Delimitador=':'
    SELECT @Salida
    ============================================= */
    SET NOCOUNT ON;
    DECLARE
        @Object int,
        @ResponseText varchar(8000),
        @Status Int,
        @HeaderKey as Varchar(MAX),
        @HeaderValue as Varchar(MAX),
        @ID AS INT;

-- Crear objeto de solicitud HTTP
    EXEC sp_OACreate 'WinHttp.WinHttpRequest.5.1', @Object OUT;
-- Reemplazar el valor vac�o por 'ValorPredeterminado'
    SET @Metodo = COALESCE(NULLIF(@Metodo, ''), 'GET')
-- Abrir la conexi�n a la API
    EXEC sp_OAMethod @Object, 'Open', NULL, @Metodo, @Url, 'false';

--Establecer encabezados de la solicitud

    IF OBJECT_ID('#CA_Headers') IS NOT NULL DROP TABLE #CA_Headers
    CREATE TABLE #CA_Headers
    (
        ID     INT IDENTITY (1,1),
        Cadena Varchar(max)
    );

    IF @Delimitador IS NULL
        SET @Delimitador = ':'

    INSERT INTO #CA_Headers
    SELECT *
    FROM dbo.fnCA_StringSplit(@Headers, @Delimitador)


    WHILE (SELECT COUNT(*) FROM #CA_Headers WHERE Cadena IS NOT NULL) > 0
        BEGIN
            SELECT TOP 1 @ID = ID, @HeaderKey = Cadena FROM #CA_Headers ORDER BY ID
            DELETE FROM #CA_Headers WHERE Cadena = @HeaderKey AND ID = @ID
            SELECT TOP 1 @ID = ID, @HeaderValue = Cadena FROM #CA_Headers ORDER BY ID
            DELETE FROM #CA_Headers WHERE Cadena = @HeaderValue AND ID = @ID
            EXEC sp_OAMethod @Object, 'setRequestHeader', NULL, @HeaderKey, @HeaderValue
        END

    IF @Metodo IN ('POST', 'PUT')
        BEGIN
            EXEC sp_OAMethod @Object, 'send', NULL, @RequestBody;
        END
    ELSE
        BEGIN
            EXEC sp_OAMethod @Object, 'Send';
        END

    -- Obtener la respuesta de la API
    EXEC sp_OAGetProperty @Object, 'Status', @Status OUT
    --EXEC sp_OAMethod @Object, 'responseText', @ResponseText OUT;
    IF @Status IS NOT NULL
        BEGIN
            DECLARE @Response table
                              (
                                  ResponseText nvarchar(max)
                              );

            INSERT INTO @Response(ResponseText)
                EXEC sp_OAMethod @Object, 'responseText';
            select @Consulta = ResponseText
            from @Response

            declare @responseHeaders VARCHAR(MAX)
            EXEC sp_OAGetProperty @object, 'LastResponseHeader', @responseHeaders OUT
        END
    ELSE
        SELECT @Consulta = '504 Timeout: La solicitud ha excedido el tiempo de espera'
    -- Cerrar el objeto de solicitud HTTP
    EXEC sp_OADestroy @Object;
END
GO
/********************************************************************************************************************************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************************************************************************************************************************/