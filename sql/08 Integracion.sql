/* Incorporar a Ca_EntregaUnidad y despuesafectarmarca */

    IF (DBO.fnCA_verificarInterfaz('ProspeccionSF', @Sucursal) = 2)
        BEGIN
            IF @MOV IN (SELECT MOV FROM CA_CATPARAMETROSMOV WHERE Clave = 'ProspeccionSF')
                BEGIN
                    EXEC xpCA_EnvioProspectosSalesForce @ID, @MOVID, 'vwCA_PROSPECTOSENVIO'
                END
        END


/* Incorporar a spMovCopiarEncabezado*/
/***************Prospectos SalesForce******************/
	IF @Modulo='VTAS'
		BEGIN
			DECLARE @IDGenerada INT = NULL

			SELECT @IDGenerada =IDENT_CURRENT('Venta')

			INSERT INTO CA_Venta(IDVenta,IdProspecto)
			SELECT @IDGenerada,IdProspecto FROM CA_Venta WHERE IDVenta = @ID
		END
/***************Prospectos SalesForce******************/
