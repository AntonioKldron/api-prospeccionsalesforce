IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'CA_OportunidadesProspeccion' 
    AND COLUMN_NAME = 'SociedadMercantil'
)
BEGIN
    ALTER TABLE CA_OportunidadesProspeccion 
    ADD SociedadMercantil VARCHAR(100) NULL;
END