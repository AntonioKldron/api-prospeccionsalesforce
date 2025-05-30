<div>
<h1 align="center"> ProspectosSalesForce </h1>
<h3 align="center"> Generación y Envío de Prospectos a través de SalesForce </h3>
<p align="center"><img src="https://acpdelsureste.com/wp-content/uploads/LOGO_INTELISIS_letras_azules.png" width="270" height="100"></p>
</div>
<div align="center">

  <a href="">[![Licence][licence]][licence-url]</a>
  <a href="">[![Latest][version]][version-url]</a>
</div>

[licence]: https://img.shields.io/badge/Licencia-Propietaria-blue.svg
[version]: https://img.shields.io/badge/Versión-1.0-green
[version-url]: https://gitlabv2.intelisis-solutions.com:8008/TICS/Interfaces/Mazda/ProspeccionSalesFoce/-/releases
[licence-url]: https://gitlabv2.intelisis-solutions.com:8008/TICS/Interfaces/Mazda/ProspeccionSalesFoce

Envío de partes de refacciones a través de FTP generando un archivo CSV.

## Estándares

Todos los objetos nuevos deberán de llevar el prefijo tipo de objeto concatenado con CA_ (Capa Automotriz)
EJEMPLOS.

    • Tablas .- CA_NombreTabla
    • Triggers.- tgCA_NombreTrigger, sugerencia tgCA_NombreTriggerAccion
    • Funciones.-fnCA_NombreFuncion, sugerencia fnCA_NombreFuncionAccion
    • Procedimientos.-xpCA_NombreProcedure, sugerencia xpCA_NombreProcedureAccion
    • Vistas.- vwCA_NombreVista

Se debe intentar en la mayoría de lo posible evitar el modificar código que viene compilado de mexico, es decir, en lo posible modificar solamente los xp y no los sp, evitar tocar acciones como afectar, timbrar, cancelar, etc…

### Commits

Para las modificaciiones del proyecto recomendamos el siguiente estandar:

    • FIX: Correcciones a bugs, fallas de integridad de información o fallas de programación.
    • REFACTOR: Reconstrucción, modificación o anexo a funcionalidades y modulos ya existentes.
    • FEAT: Nueva funcionalidad.
    • SQL: Acciones a base de datos, archivos sql, actividades a migrations.
    • STYLE: Desarrollo referente a ajustes de estetica.
    • DOCS: Carga o modificacion de archivos de documentacion, minutas, acuerdos y soporte a modificaciones

## Información de proyecto


### Dependencias
```
SP xpCA_EntregaUnidad:
    FN fnCA_BusquedaClaveParametroInterfazEmpresa: {}
    SP xpCA_EnvioProspectosSalesForce:
        FN fnCA_BusquedaClaveParametroInterfazEmpresa: {}
        FN fnCA_CatParametrosSucursalValor: {}
        FN fnCA_ValorEtiquetaJSON: {}
        SP xpCA_InsertaLogs: {}
        SP xpCA_PeticionHTTP:
            FN fnCA_StringSplit: {}
        SP xpCA_Transform_to_JSON:
            FN fnCA_StringSplit: {}
```

### Clonar Repositorio

Use git to clone this repository into your computer.

```
git clone https://gitlabv2.intelisis-solutions.com:8008/TICS/Interfaces/Mazda/ProspeccionSalesFoce.git
```
## Configuración de las interfaces

Configurar las interfaces en Intelisis de acuerdo al manual.