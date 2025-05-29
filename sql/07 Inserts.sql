INSERT INTO dbo.CA_CatParametros (Clave, Tipo, Marca, Grupo, DescCorta, DescCompleta)
values (N'ProspeccionSF', N'Empresa', N'Mazda', N'ProspeccionSF', N'Endpoint de envio a salesforce',
        N'Endpoint de envio a salesforce');

INSERT INTO dbo.CA_CatParametros (Clave, Tipo, Marca, Grupo, DescCorta, DescCompleta)
VALUES (N'GrantType', N'Empresa', N'Mazda', N'ProspeccionSF', N'Tipo de autorización para el endpoint de salesforce',
        N'Tipo de autorización para el endpoint de salesforce');

INSERT INTO dbo.CA_CatParametros (Clave, Tipo, Marca, Grupo, DescCorta, DescCompleta)
VALUES (N'URLToken', N'Empresa', N'Mazda', N'ProspeccionSF', N'Url Base para el token de salesforce',
        N'Url Base para el token de salesforce, no aplica para endpoint');

INSERT INTO dbo.CA_CatParametros (Clave, Tipo, Marca, Grupo, DescCorta, DescCompleta)
VALUES (N'URLProspectos', N'Empresa', N'Mazda', N'ProspeccionSF',
        N'Url para el envio de prospectos, no es igual a la del token',
        N'Url del dominio para el token de salesforce, no aplica para token+');

INSERT INTO dbo.CA_CatParametros (Clave, Tipo, Marca, Grupo, DescCorta, DescCompleta)
values (N'Username', N'Sucursal', N'Mazda', N'ProspeccionSF', N'Usuario del endpoint de Salesforce',
        N'Usuario del endpoint de Salesforce'),
       (N'Password', N'Sucursal', N'Mazda', N'ProspeccionSF', N'Contraseña del endpoint de salesforce',
        N'Contraseña del endpoint de salesforce'),
       (N'ClientID', N'Sucursal', N'Mazda', N'ProspeccionSF', N'ClientID del endpoint de salesforce',
        N'ClientID del endpoint de salesforce'),
       (N'ClientSecret', N'Sucursal', N'Mazda', N'ProspeccionSF', N'ClientSecret del endpoint de salesforce',
        N'ClientSecret del endpoint de salesforce');

DECLARE @EMPRESA VARCHAR(40)
SELECT @EMPRESA = EMPRESA FROM EMPRESA
INSERT INTO dbo.CA_CatParametrosMov (Empresa, Mov, Modulo, Clave, Descripcion)
VALUES (@EMPRESA, N'FEL Unidad', N'VTAS', N'ProspeccionSF',
        N'Movimientos válidos para el envío de prospectos a salesforce');



