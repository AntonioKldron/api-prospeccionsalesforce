CREATE TABLE [dbo].[CA_OportunidadesProspeccion](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[DealerCode] [nvarchar](30)  NULL,
	[IdProspecto] [nvarchar](100) NOT NULL,
	[AgenteVentaDMS] [nvarchar](5) NULL,
	[VIN] [nvarchar](17) NULL,
	[Auto] [nvarchar](50) NULL,
	[Modelo] [nvarchar](50) NULL,
	[Version] [nvarchar](50) NULL,
	[Color] [nvarchar](50) NULL,
	[Mensaje] [nvarchar](255) NULL,
	[TipoPersona] [nvarchar](10) NOT NULL,
	[RazonComercialFactura] [nvarchar](100) NULL,
	[ActividadEconomicaFactura] [nvarchar](100) NULL,
	[ApellidoPaternoFactura] [nvarchar](50) NULL,
	[ApellidoMaternoFactura] [nvarchar](50) NULL,
	[NombreFactura] [nvarchar](50) NULL,
	[SegundoNombreFactura] [nvarchar](50) NULL,
	[EmailFactura] [nvarchar](100) NULL,
	[RFCFactura] [nvarchar](13)  NULL,
	[SexoFactura] [nvarchar](10) NULL,
	[FechaNacimientoFactura] [date] NULL,
	[CURPFactura] [nvarchar](18) NULL,
	[CalleFactura] [nvarchar](50) NULL,
	[No_ExtFactura] [nvarchar](10) NULL,
	[No_IntFactura] [varchar](30) NULL,
	[ColoniaFactura] [nvarchar](50)  NULL,
	[DelegacionMunicipioFactura] [nvarchar](50) NULL,
	[PoblacionFactura] [nvarchar](50)  NULL,
	[EstadoFactura] [nvarchar](50) NOT NULL,
	[CPFactura] [nvarchar](5) NOT NULL,
	[TelefonoCasaOficinaFactura] [nvarchar](10) NULL,
	[ExtTelefonoCasaOficinaFactura] [nvarchar](4) NULL,
	[TelefonoCelularFactura] [nvarchar](10) NULL,
	[MedioContactoFactura] [nvarchar](50) NULL,
	[HorarioContactoFactura] [nvarchar](20) NULL,
	[UsoCFDI] [nvarchar](5)  NULL,
	[RegimenFiscal] [nvarchar](5)  NULL,
	[ApellidoPaterno] [nvarchar](50) NULL,
	[ApellidoMaterno] [nvarchar](50) NULL,
	[Nombre] [nvarchar](50) NULL,
	[SegundoNombre] [nvarchar](50) NULL,
	[Email] [nvarchar](100) NULL,
	[RFC] [nvarchar](13) NULL,
	[Sexo] [nvarchar](10) NULL,
	[FechaNacimiento] [date] NULL,
	[CURP] [nvarchar](18) NULL,
	[Calle] [nvarchar](50) NULL,
	[No_Ext] [nvarchar](10) NULL,
	[No_Int] [varchar](30) NULL,
	[Colonia] [nvarchar](50) NULL,
	[DelegacionMunicipio] [nvarchar](50) NULL,
	[Poblacion] [nvarchar](50) NULL,
	[Estado] [nvarchar](50) NULL,
	[CP] [nvarchar](10) NULL,
	[TelefonoCelular] [nvarchar](10) NULL,
	[MedioContacto] [nvarchar](50) NULL,
	[HorarioContacto] [nvarchar](20) NULL,
	[ContactoId] [nvarchar](50) NULL,
	[ESTATUS] [varchar](45) NULL,
	[FECHA] [datetime] NULL,
	[IDPEDIDO] [int] NULL,
	[MOV] [varchar](50) NULL,
	[MOVID] [varchar](20) NULL,
	[IDCLIENTE] [varchar](45) NULL,
	[IDCONTACTO] [varchar](45) NULL,
	[Sucursal] [int] NULL,
PRIMARY KEY CLUSTERED
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
ALTER TABLE [dbo].[CA_OportunidadesProspeccion] ADD  DEFAULT ('NUEVO') FOR [ESTATUS]
GO
ALTER TABLE [dbo].[CA_OportunidadesProspeccion] ADD  DEFAULT (getdate()) FOR [FECHA]
GO
ALTER TABLE  [dbo].[CA_OportunidadesProspeccion] ADD [Articulo][nvarchar](50) NULL
GO


CREATE TABLE [dbo].[CA_InterfazCteProspectos]
(
    Cliente            varchar(20) not null,
    Estacion           int         not null,
    IDOportunidad      varchar(40),
    RFC                varchar(15),
    Direccion          varchar(100),
    DireccionNumero    varchar(20),
    DireccionNumeroInt varchar(20),
    Pais               varchar(50),
    Estado             varchar(30),
    Delegacion         varchar(100),
    Colonia            varchar(100),
    Poblacion          varchar(100),
    CodigoPostal       varchar(15),
    Telefono           varchar(20),
    Celular            varchar(20),
    eMail              varchar(50)
)
go