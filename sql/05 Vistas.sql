CREATE VIEW [dbo].[vwCA_PROSPECTOSENVIO] AS
SELECT VIN.VIN             AS vin,
       V.MOVID             AS numeroFacturacion,
       VIN.numeroeconomico AS numeroInventario,
       VIN.Motor           AS numeroMotor,
       V.UltimoCambio      AS fechaHoraFactura,
       MB.Fecha            AS fechaEntrega,
       CA.idProspecto      AS idOportunidad
FROM CA_Venta CA
         INNER JOIN VENTA V ON CA.IDVENTA = V.ID
         LEFT JOIN VIN ON V.ServicioSerie = VIN.VIN
         LEFT JOIN MOVBITACORA MB ON V.ID = MB.ID
WHERE idProspecto IS NOT NULL
  AND MOV = 'Fel Unidad'

GO

CREATE VIEW [dbo].[vwCA_CteProspectosEstandarizado]
AS
SELECT CA_CteProspectosEstandarizado.Cliente,
       CA_CteProspectosEstandarizado.Estacion,
       CA_CteProspectosEstandarizado.IDOportunidad,
       CA_CteProspectosEstandarizado.RFC,
       CA_CteProspectosEstandarizado.Direccion,
       CA_CteProspectosEstandarizado.DireccionNumero,
       CA_CteProspectosEstandarizado.DireccionNumeroInt,
       CA_CteProspectosEstandarizado.Estado,
       CA_CteProspectosEstandarizado.Delegacion,
       CA_CteProspectosEstandarizado.Colonia,
       CA_CteProspectosEstandarizado.Poblacion,
       CA_CteProspectosEstandarizado.CodigoPostal,
       CA_CteProspectosEstandarizado.Telefono,
       CA_CteProspectosEstandarizado.Celular,
       CA_CteProspectosEstandarizado.eMail,
       CA_CteProspectosEstandarizado.Pais,
       Cte.Nombre,
       Cte.PersonalNombres,
       Cte.PersonalApellidoPaterno,
       Cte.PersonalApellidoMaterno
FROM CA_InterfazCteProspectos CA_CteProspectosEstandarizado
         LEFT OUTER JOIN Cte ON CA_CteProspectosEstandarizado.Cliente = Cte.Cliente
GO
