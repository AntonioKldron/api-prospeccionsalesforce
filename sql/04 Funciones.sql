IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.fnCA_BuscarPermiso')
            AND TYPE = 'FN')
    DROP FUNCTION dbo.fnCA_BuscarPermiso;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[fnCA_BuscarPermiso](@Clave Varchar(20), @Usuario Varchar(10), @Sucursal int, @Empresa Varchar(5))
    Returns int
AS
BEGIN
    Declare
        @Permitido BIT
    Select @Permitido = 0

    IF Exists (Select *
               from CA_Permisos
               where Clave = @Clave
                 and Usuario = @Usuario
                 and (Sucursal IS NULL OR Sucursal = @Sucursal)
                 and Empresa = @Empresa)
        Select @Permitido = 1

    RETURN @Permitido
END
GO
/********************************************************************************************************************************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************************************************************************************************************************/

IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.fnCA_CatParametrosSucursalValor')
            AND TYPE = 'FN')
    DROP FUNCTION dbo.fnCA_CatParametrosSucursalValor;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[fnCA_CatParametrosSucursalValor](
    @Sucursal int,
    @Clave VARCHAR(100)
)
    RETURNS VARCHAR(255)
AS
BEGIN
    DECLARE @Valor varchar(255)

    IF EXISTS(SELECT * FROM dbo.CA_CatParametrosSucursal ccps WHERE ccps.Clave = @clave AND ccps.Sucursal = @Sucursal)
        SELECT @Valor = ccps.Valor
        FROM dbo.CA_CatParametrosSucursal ccps
        WHERE ccps.Clave = @Clave AND ccps.Sucursal = @Sucursal
    ELSE
        SET @Valor = ''

    RETURN @Valor
END
GO
/********************************************************************************************************************************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************************************************************************************************************************/
IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.fnCA_fnExisteRuta')
            AND TYPE = 'FN')
    DROP FUNCTION dbo.fnCA_fnExisteRuta;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[fnCA_fnExisteRuta](@Ruta VARCHAR(256))
    RETURNS INT
AS
BEGIN
    DECLARE @RutaBuscar VARCHAR(256),
        @Existe INT,
        @objFso INT,
        @folderExists VARCHAR(20)

    IF ISNULL(@Ruta, '') = ''
        BEGIN
            SELECT @Existe = 0
        END
    ELSE
        BEGIN
            SET @Ruta = REPLACE(@Ruta, '"', '')
            EXEC sp_OACreate 'Scripting.FileSystemObject', @objFSO OUT
            EXEC sp_OAMethod @objFSO, 'FolderExists', @folderExists OUT, @Ruta
            SELECT @Existe = CASE
                                 WHEN @folderExists = 'True'
                                     THEN 1
                                 ELSE 0
                END
        END
    RETURN @Existe
END
GO

/********************************************************************************************************************************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************************************************************************************************************************/

IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.fnCA_fnObtenerRutaInterfaz')
            AND TYPE = 'FN')
    DROP FUNCTION dbo.fnCA_fnObtenerRutaInterfaz;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[fnCA_fnObtenerRutaInterfaz](@Empresa VARCHAR(5),
                                                   @Sucursal INT,
                                                   @Interfaz VARCHAR(100))
    RETURNS VARCHAR(256)
AS
BEGIN
    DECLARE @Ruta VARCHAR(256)

    SELECT @Ruta = ISNULL(Ruta, '')
    FROM CA_InterfazRutaArchivo
    WHERE Empresa = @Empresa
      AND Sucursal = ISNULL(@Sucursal, Sucursal)
      AND Interfaz = @Interfaz

    IF ISNULL(@Ruta, '') = ''
        BEGIN
            SELECT @Ruta = 'E00|No existe la configuraci?n'
        END
    ELSE
        BEGIN
            IF (SELECT dbo.fnCA_fnExisteRuta(@Ruta)) = 0
                BEGIN
                    SELECT @Ruta = 'E01|La ruta ' + @Ruta + ' no existe'
                END
        END

    IF SUBSTRING(@Ruta, 1, 2) <> 'E0'
        BEGIN
            IF SUBSTRING(@Ruta, LEN(@Ruta), 1) <> '\'
                BEGIN
                    SELECT @Ruta = @Ruta + '\'
                END
        END
    RETURN @Ruta
END
GO
/********************************************************************************************************************************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************************************************************************************************************************/

IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.fnCA_fnObtenerArchivoInterfaz')
            AND TYPE = 'FN')
    DROP FUNCTION dbo.fnCA_fnObtenerArchivoInterfaz;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[fnCA_fnObtenerArchivoInterfaz](@Empresa varchar(5), @Sucursal int, @Interfaz varchar(100))
    RETURNS varchar(128)
AS
BEGIN
    DECLARE @Archivo varchar(128)

    SELECT top (1) @Archivo = ISNULL(Archivo, '')
    FROM CA_InterfazRutaArchivo
    WHERE Empresa = @Empresa
      AND Sucursal = ISNULL(@Sucursal, Sucursal)
      AND Interfaz = @Interfaz

    IF ISNULL(@Archivo, '') = ''
        BEGIN
            SELECT @Archivo = 'E00|No existe la configuraci?n'
        END

    RETURN @Archivo
END
GO


/********************************************************************************************************************************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************************************************************************************************************************/
IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.fnCA_PermisoMonitor')
            AND TYPE = 'FN')
    DROP FUNCTION dbo.fnCA_PermisoMonitor;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* =============================================
-- Autor:Giovanni Trujillo Silvas
-- Creaci?n: 06/04/2021
-- Ejemplo: SELECT dbo.fnCA_PermisoMonitor('DDC','Nissan')
-- Descripci?n: Revisa si la interfaz cuenta con los permisos para activar los botones de la interfaz
-- Par?metros: Interfaz,Marca
-- Resultado: Regresa un valor 1 si tiene el permiso necesario y un 0 de ser lo contrario
   =============================================*/
CREATE FUNCTION [dbo].[fnCA_PermisoMonitor](@Interfaz Varchar(100), @Marca Varchar(50)=NULL, @Tipo Varchar(50))
    Returns int
AS
BEGIN
    Declare
        @Permitido BIT
    Select @Permitido = 0

    IF ISNULL(@Marca, '') = ''
        SELECT TOP 1 @Marca = VERSION FROM Sucursal


    IF @Tipo = 'Mov'
        BEGIN
            SELECT TOP 1 @Permitido = AbrirMov
            FROM CA_InterfacesPredefinidas
            WHERE Interfaz = @Interfaz AND MARCA = @Marca AND Estatus = 1

        END
    ELSE
        IF @Tipo = 'Rango'
            BEGIN
                SELECT TOP 1 @Permitido = ReenvioRango
                FROM CA_InterfacesPredefinidas
                WHERE Interfaz = @Interfaz
                  AND MARCA = @Marca
                  AND Estatus = 1

            END
        ELSE
            BEGIN
                SELECT TOP 1 @Permitido = ReenvioMultiple
                FROM CA_InterfacesPredefinidas
                WHERE Interfaz = @Interfaz
                  AND MARCA = @Marca
                  AND Estatus = 1

            END
    RETURN @Permitido
END
GO
/********************************************************************************************************************************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************************************************************************************************************************/

IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.fnCA_BusquedaClaveParametroInterfaz')
            AND TYPE = 'FN')
    DROP FUNCTION dbo.fnCA_BusquedaClaveParametroInterfaz;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* =============================================
-- Autor:Giovanni Trujillo Silvas
-- Creaci?n: 07/04/2021
-- Ejemplo: SELECT dbo.fnCA_BusquedaClaveParametroInterfaz(1,'SeekopCitas','Usuario')
-- Descripci?n: Busca en la tabla de Interfaces el valor para el parametro que se configuro
-- Par?metros: Sucursal,Interfaz,Clave
-- Resultado: Valor que Posee el parametro con que se configuro en una interfaz para una sucursal especifica
   =============================================*/
CREATE FUNCTION [dbo].[fnCA_BusquedaClaveParametroInterfaz](@Sucursal INT, @Interfaz VARCHAR(100), @Clave VARCHAR(100))
    RETURNS VARCHAR(255)
AS
BEGIN
    DECLARE
        @Valor VARCHAR(255);

    SELECT @Valor = ISNULL(Valor, '')
    FROM CA_Interfaces AS I
             INNER JOIN CA_InterfacesD AS ID ON I.ID = ID.ID
    WHERE I.Interfaz = @Interfaz
      AND I.Sucursal = @Sucursal
      AND ID.Clave = @Clave

    RETURN @Valor
END
GO

/********************************************************************************************************************************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************************************************************************************************************************/

IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.fnCA_BusquedaClaveParametroInterfazEmpresa')
            AND TYPE = 'FN')
    DROP FUNCTION dbo.fnCA_BusquedaClaveParametroInterfazEmpresa;
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* =============================================
-- Autor:Giovanni Trujillo Silvas
-- Creaci?n: 21/06/2021
-- Ejemplo: SELECT dbo.fnCA_BusquedaClaveParametroInterfazEmpresa('SeekopCitas','Usuario')
-- Descripci?n: Busca en la tabla de InterfacesPredefinidasDEmpresa el valor para el parametro que se configuro
-- Par?metros: Sucursal,Interfaz,Clave
-- Resultado: Valor que Posee el parametro con que se configuro en una interfaz para la empresa actual
   =============================================*/
CREATE FUNCTION [dbo].[fnCA_BusquedaClaveParametroInterfazEmpresa](@Interfaz VARCHAR(100), @Clave VARCHAR(100))
    RETURNS VARCHAR(255)
AS
BEGIN
    DECLARE
        @Valor VARCHAR(255);

    SELECT TOP 1 @Valor = ISNULL(IDE.ValorDefault, '')
    FROM CA_InterfacesPredefinidas AS I
             INNER JOIN CA_InterfacesPredefinidasDEmpresa AS IDE ON I.ID = IDE.ID
    WHERE I.Interfaz = @Interfaz
      AND IDE.Clave = @Clave


    RETURN @Valor
END
GO

/********************************************************************************************************************************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************************************************************************************************************************/
IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.fnCA_verificarInterfaz')
            AND TYPE = 'FN')
    DROP FUNCTION dbo.fnCA_verificarInterfaz;
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* =============================================
-- Autor:Ivan Rosales
-- Creaci?n: 17/08/2023
-- Ejemplo: SELECT dbo.fnCA_verificarInterfaz('SeekopCitas',@Sucursal)
-- Descripci?n: Busca que la interfaz se encuentre activa tanto en la Empresa o en una sucursal
-- Par?metros: Interfaz,Sucursal
-- Resultado: 0 - no existe la interfaz, 1 - interfaz existe a nivel empresa, 2 - interfaz existe a nivel sucursal
   =============================================*/
CREATE FUNCTION [dbo].[fnCA_verificarInterfaz](@Interfaz VARCHAR(100), @Sucursal VARCHAR(100))
    RETURNS INT
AS
BEGIN
    /*
        RETURN
            0 - no existe la interfaz
            1 - interfaz existe a nivel empresa
            2 - interfaz existe a nivel sucursal
    */
    DECLARE @Result INT = 0;

    IF @Sucursal IS NULL AND EXISTS(SELECT * FROM CA_InterfacesPredefinidas WHERE Interfaz = @Interfaz AND Estatus = 1)
        SET @Result = 1;

    IF @Sucursal IS NOT NULL AND
       EXISTS(SELECT * FROM CA_Interfaces WHERE Interfaz = @Interfaz AND Sucursal = @Sucursal AND Estatus = 1)
        SET @Result = 2;


    RETURN @Result
END
GO

/********************************************************************************************************************************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************************************************************************************************************************/
IF EXISTS(SELECT *
          FROM SYSOBJECTS
          WHERE ID = OBJECT_ID('dbo.fnCA_StringSplit')
            AND TYPE = 'TF')
    DROP FUNCTION dbo.fnCA_StringSplit;
GO
CREATE FUNCTION [dbo].[fnCA_StringSplit](@stringToSplit VARCHAR(MAX), @Delimiter char(1) = NULL)
    RETURNS
        @returnList TABLE
                    (
                        [Name][nvarchar](MAX)
                    )
AS
BEGIN
    /*********************************************************************************************************/
    DECLARE @name NVARCHAR(MAX),
        @pos INT

    IF @Delimiter IS NULL
        SET @Delimiter = ':'
    WHILE CHARINDEX(@Delimiter, @stringToSplit) > 0
        BEGIN
            SELECT @pos = CHARINDEX(@Delimiter, @stringToSplit)
            SELECT @name = SUBSTRING(@stringToSplit, 1, @pos - 1)
            INSERT INTO @returnList
            SELECT @name
            SELECT @stringToSplit = SUBSTRING(@stringToSplit, @pos + 1, LEN(@stringToSplit) - @pos)
        END
    INSERT INTO @returnList
    SELECT @stringToSplit
    RETURN
END

GO

/********************************************************************************************************************************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************************************************************************************************************************/
