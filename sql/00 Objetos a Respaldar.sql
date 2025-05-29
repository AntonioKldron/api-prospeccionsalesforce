-- Descripción: Esta consulta tiene como finalidad poder crear un respaldo de los objetos existentes en el servidor.
  DECLARE @ProcName VARCHAR(255),
          @NAME VARCHAR(255),
		  @type VARCHAR(30),
		  @TypeScript VARCHAR(30)

  DECLARE @procedures TABLE(NAME VARCHAR(255))
  
  DECLARE @PROC_TABLE TABLE (X1  NVARCHAR(MAX))

  DECLARE @Proc NVARCHAR(MAX)
  DECLARE @Procedure NVARCHAR(MAX) 
  DECLARE @ProcLines TABLE (PLID INT IDENTITY(1,1), Line NVARCHAR(MAX))


	/***********************************SP*******************************************/
	INSERT INTO @procedures SELECT 'NombreSP'
  
	/***********************************FN*******************************************/
	INSERT INTO @procedures SELECT 'NombreFuncion'

	--/***********************************VW*******************************************/
	INSERT INTO @procedures SELECT 'NombreVista'

  
	/********************************************************************************/  
  
  INSERT @ProcLines SELECT ''

  DECLARE procedures_cursor CURSOR
    FOR SELECT NAME FROM @procedures
OPEN procedures_cursor
FETCH NEXT FROM procedures_cursor INTO @NAME 
IF @@FETCH_STATUS <> 0   
        PRINT '<<None>>'
    WHILE @@FETCH_STATUS = 0  
    BEGIN
      
	  SET @Type=''

	  SELECT @Type=RTRIM(LTRIM(type)) FROM SYSOBJECTS WHERE ID = OBJECT_ID('dbo.'+@NAME) 

	  IF @Type = 'P'
	  BEGIN
		SELECT @TypeScript='PROCEDURE'
	  END

	  IF @Type = 'V'
	  BEGIN
		SELECT @TypeScript='VIEW'
	  END

	  IF @Type = 'FN'
	  BEGIN
		SELECT @TypeScript='FUNCTION'
	  END

      SELECT @Procedure = 'SELECT DEFINITION FROM '+db_name()+'.SYS.SQL_MODULES WHERE OBJECT_ID = OBJECT_ID('''+@NAME+''')'
      
      INSERT @ProcLines SELECT '/********************' + REPLICATE('*',LEN(@NAME)) + '***********************/'
      INSERT @ProcLines SELECT '/********************' + @NAME                     + '***********************/'
      INSERT @ProcLines SELECT '/********************' + REPLICATE('*',LEN(@NAME)) + '***********************/'
      INSERT @ProcLines SELECT ''
      INSERT @ProcLines SELECT 'IF EXISTS(SELECT * FROM SYSOBJECTS WHERE ID = OBJECT_ID(''dbo.'+@NAME+''') AND TYPE = '''+@Type+''')'
	  INSERT @ProcLines SELECT 'DROP '+@TypeScript+' dbo.'+@NAME+';'
	  
	  INSERT @ProcLines SELECT 'GO'
      INSERT @ProcLines SELECT 'SET ANSI_NULLS OFF'
      INSERT @ProcLines SELECT 'GO'
      INSERT @ProcLines SELECT 'SET QUOTED_IDENTIFIER OFF'
      INSERT @ProcLines SELECT 'GO'
      
      DELETE FROM  @PROC_TABLE

      INSERT INTO @PROC_TABLE (X1)
            EXEC  (@Procedure)

      SELECT @Proc=X1 from @PROC_TABLE

      WHILE CHARINDEX(CHAR(13)+CHAR(10),@Proc) > 0
      BEGIN
            INSERT @ProcLines
            SELECT LEFT(@Proc,CHARINDEX(CHAR(13)+CHAR(10),@Proc)-1)
            SELECT @Proc = SUBSTRING(@Proc,CHARINDEX(CHAR(13)+CHAR(10),@Proc)+2,LEN(@Proc))
            
      END
      
      INSERT @ProcLines 
      SELECT @Proc ;
      INSERT @ProcLines
      SELECT 'GO'
      FETCH NEXT FROM procedures_cursor INTO @NAME 
    END
    CLOSE procedures_cursor;  
    DEALLOCATE procedures_cursor; 

    SELECT Line FROM @ProcLines ORDER BY PLID