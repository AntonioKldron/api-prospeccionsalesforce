from django.db import models
from datetime import datetime
from django.core.validators import MinLengthValidator, EmailValidator
from .validators import validate_phone


# Modelo para Base de Datos de SalesForce
class Logs(models.Model):
    jsons = models.TextField()
    fecha = models.DateTimeField(auto_now_add=True)
    estatus = models.CharField(max_length=10, null=True, blank=True)

    class Meta:
        managed = False
        db_table = 'CA_LOGS_OportunidadesProspeccion'
        app_label = 'SalesForce'


class SolicitudBase(models.Model):
    BID = models.CharField(max_length=30, verbose_name='BID', db_column='DealerCode')
    Sucursal = models.IntegerField(verbose_name='Sucursal', db_column='sucursal')
    OportunidadId = models.CharField(max_length=100, verbose_name='OportunidadId', db_column='IdProspecto')
    # Campos probablemente no utilizados
    AgenteVentaDMS = models.CharField(max_length=5, null=True, blank=True,
                                      db_column='AgenteVentaDMS')  # Debería ser obligatorio
    VIN = models.CharField(max_length=17, null=True, blank=True, validators=[MinLengthValidator(limit_value=17)])
    Auto = models.CharField(max_length=50, null=True, blank=True)
    Modelo = models.CharField(max_length=4, null=True, blank=True)
    Version = models.CharField(max_length=20, null=True, blank=True)
    Color = models.CharField(max_length=20, null=True, blank=True)
    Mensaje = models.TextField(max_length=100, null=True, blank=True)

    # Campos de DatosFactura
    Tipo = models.CharField(max_length=10, verbose_name='Tipo', db_column='TipoPersona')  # Requerido
    Email = models.EmailField(max_length=100, db_column='EmailFactura', blank=True,
                              validators=[EmailValidator()])  # Requerido
    RFC = models.CharField(max_length=13, verbose_name='RFC', db_column='RFCFactura')  # Requerido
    Calle = models.CharField(max_length=50, null=True, verbose_name='Calle', db_column='CalleFactura')
    NoExterior = models.CharField(max_length=10, db_column='No_ExtFactura')  # Obligatorio
    NoInterior = models.CharField(max_length=30, blank=True, null=True, verbose_name='NoInterior',
                                  db_column='No_IntFactura')
    Colonia = models.CharField(max_length=50, verbose_name='Colonia', db_column='ColoniaFactura')
    DelegacionMunicipioFactura = models.CharField(max_length=50, blank=True, null=True)
    Ciudad = models.CharField(max_length=50, verbose_name='Ciudad', db_column='PoblacionFactura')
    Estado = models.CharField(max_length=50, verbose_name='Estado', db_column='EstadoFactura')
    CodigoPostal = models.CharField(max_length=10, verbose_name='CodigoPostal', db_column='CPFactura')
    TelefonoCasaOficinaFactura = models.CharField(max_length=10, null=True, validators=[validate_phone], blank=True)
    ExtTelefonoCasaOficinaFactura = models.CharField(max_length=4, null=True, blank=True)
    MedioContactoFactura = models.CharField(max_length=50, null=True, blank=True)
    HorarioContactoFactura = models.CharField(max_length=20, null=True, blank=True)
    UsoCFDI = models.CharField(max_length=5)
    RegimenFiscal = models.CharField(max_length=5)

    class Meta:
        abstract = True
        managed = False


class SolicitudPersonaFisica(SolicitudBase):
    # Campos de DatosFactura
    RazonComercialFactura = models.CharField(max_length=100, null=True, blank=True, db_column='RazonComercialFactura',
                                             verbose_name='RazonSocial')  # Opcional (Se arma en el formulario)
    SociedadMercantil = models.CharField(max_length=100, null=True, blank=True, db_column='SociedadMercantil',
                                             verbose_name='SociedadMercantil')  # Opcional (Se arma en el formulario)
    ActividadEconomica = models.CharField(max_length=10, blank=True, db_column='ActividadEconomicaFactura',
                                          verbose_name='ActividadEconomica')  # Opcional
    ApellidoPaterno = models.CharField(max_length=50, db_column='ApellidoPaternoFactura',
                                       verbose_name='ApellidoPaterno')  # Requerido en caso de ser persona física
    ApellidoMaterno = models.CharField(max_length=50, null=True, blank=True, verbose_name='ApellidoMaterno',
                                       db_column='ApellidoMaternoFactura')
    PrimerNombre = models.CharField(max_length=50, db_column='NombreFactura',
                                    verbose_name='PrimerNombre')  # Requerido en caso de ser persona física
    SegundoNombre = models.CharField(max_length=50, null=True, blank=True, db_column='SegundoNombreFactura',
                                     verbose_name='SegundoNombre')
    Sexo = models.CharField(max_length=10, verbose_name='Sexo',
                            db_column='SexoFactura')  # Requerido en caso de ser persona física
    FechaNacimiento = models.DateField(max_length=10, db_column='FechaNacimientoFactura',
                                       verbose_name='FechaNacimiento')  # Requerido en caso de ser persona física
    CURP = models.CharField(max_length=18, blank=False, null=True, verbose_name='CURP', db_column='CURPFactura',
                            validators=[
                                MinLengthValidator(limit_value=18)])  # Requerido en caso de ser persona física
    Celular = models.CharField(max_length=10, null=True, blank=False, verbose_name='Celular',
                               db_column='TelefonoCelularFactura',
                               validators=[validate_phone])  # Se vuelve requerido si es persona física

    class Meta:
        managed = False
        db_table = 'CA_OportunidadesProspeccion'
        app_label = 'SalesForce'


class SolicitudPersonaMoral(SolicitudBase):
    # Campos de DatosFactura
    # RazonComercial es requerido en caso de ser persona moral (Se arma en el formulario)
    RazonComercialFactura = models.CharField(max_length=100, db_column='RazonComercialFactura',
                                             blank=False)  # Requerido
    SociedadMercantil = models.CharField(max_length=100, db_column='SociedadMercantil',
                                         blank=False)  # Requerido
    GiroMercantil = models.CharField(max_length=10, blank=False, verbose_name='GiroMercantil',
                                     db_column='ActividadEconomicaFactura')  # Requerido
    ApellidoPaterno = models.CharField(max_length=50, null=True, verbose_name='ApellidoPaterno',
                                       db_column='ApellidoPaternoFactura',
                                       blank=True)  # No requerido en caso de ser persona moral
    ApellidoMaterno = models.CharField(max_length=50, null=True, verbose_name='ApellidoMaterno',
                                       db_column='ApellidoMaternoFactura',
                                       blank=True)  # No requerido en caso de ser persona moral
    PrimerNombre = models.CharField(max_length=50, null=True, blank=True,
                                    db_column='NombreFactura')  # No requerido en caso de ser persona moral
    SegundoNombre = models.CharField(max_length=50, null=True, blank=True, verbose_name='SegundoNombre',
                                     db_column='SegundoNombreFactura')
    Sexo = models.CharField(max_length=10, null=True, blank=True, db_column='SexoFactura',
                            verbose_name='Sexo')  # No requerido en caso de ser persona moral
    FechaNacimiento = models.DateField(max_length=10, null=True, db_column='FechaNacimientoFactura',
                                       blank=True)  # No requerido en caso de ser persona moral
    CURP = models.CharField(max_length=18, blank=True, null=True, db_column='CURPFactura', validators=[
        MinLengthValidator(limit_value=18)])
    Celular = models.CharField(max_length=10, null=True, blank=True, db_column='TelefonoCelularFactura',
                               validators=[validate_phone])  # Se vuelve requerido si es persona física

    # Contacto
    Contacto_ApellidoPaterno = models.CharField(max_length=50, blank=True, null=True,
                                                verbose_name='Contacto_ApellidoPaterno',
                                                db_column='ApellidoPaterno')
    Contacto_ApellidoMaterno = models.CharField(max_length=50, blank=True, null=True,
                                                verbose_name='Contacto_ApellidoMaterno',
                                                db_column='ApellidoMaterno')
    Contacto_PrimerNombre = models.CharField(max_length=50, blank=False, null=True, verbose_name='Contacto_Nombre',
                                       db_column='Nombre')
    Contacto_SegundoNombre = models.CharField(max_length=50, null=True, blank=True,
                                              verbose_name='Contacto_SegundoNombre', db_column='SegundoNombre')
    Contacto_Email = models.EmailField(max_length=100, blank=True, null=True, validators=[EmailValidator()],
                                       verbose_name='Contacto_Email', db_column='Email')
    Contacto_RFC = models.CharField(max_length=13, blank=True, null=True,
                                    validators=[MinLengthValidator(limit_value=13)],
                                    db_column='RFC',
                                    verbose_name='Contacto_RFC')
    Contacto_Sexo = models.CharField(max_length=10, blank=True, verbose_name='Contacto_Sexo', db_column='Sexo')
    Contacto_FechaNacimiento = models.DateField(max_length=10, blank=True, verbose_name='Contacto_FechaNacimiento',
                                                db_column='FechaNacimiento')
    Contacto_CURP = models.CharField(max_length=18, blank=False, validators=[MinLengthValidator(limit_value=18)],
                                     verbose_name='Contacto_CURP', db_column='CURP')
    Contacto_Calle = models.CharField(max_length=50, blank=True, verbose_name='Contacto_Calle', db_column='Calle')
    Contacto_NoExterior = models.CharField(max_length=10, blank=True, verbose_name='Contacto_NoExterior',
                                           db_column='No_Ext')
    Contacto_NoInterior = models.CharField(max_length=30, null=True, blank=True, verbose_name='Contacto_NoInterior',
                                           db_column='No_Int')
    Contacto_Colonia = models.CharField(max_length=50, blank=True, verbose_name='Contacto_Colonia', db_column='Colonia')
    Contacto_DelegacionMunicipio = models.CharField(max_length=50, blank=True,
                                                    verbose_name='Contacto_DelegacionMunicipio',
                                                    db_column='DelegacionMunicipio')
    Contacto_Ciudad = models.CharField(max_length=50, blank=True, verbose_name='Contacto_Ciudad', db_column='Poblacion')
    Contacto_Estado = models.CharField(max_length=50, blank=True, verbose_name='Contacto_Estado', db_column='Estado')
    Contacto_CodigoPostal = models.CharField(max_length=10, blank=True, verbose_name='Contacto_CodigoPostal',
                                             db_column='CP')
    Contacto_Celular = models.CharField(max_length=10, validators=[validate_phone], verbose_name='Contacto_Celular',
                                        db_column='TelefonoCelular')
    Contacto_MedioPreferidoContacto = models.CharField(max_length=50, null=True, blank=True, db_column='MedioContacto',
                                                       verbose_name='Contacto_MedioPreferidoContacto')
    Contacto_HorarioPreferidoContacto = models.CharField(max_length=20, null=True, blank=True,
                                                         db_column='HorarioContacto',
                                                         verbose_name='Contacto_HorarioPreferidoContacto')
    Contacto_ContactoId = models.CharField(max_length=100, null=True, blank=True, db_column='ContactoId',
                                           verbose_name='Contacto_ContactoId')  # No es requerido por nuestra documentación

    def save(self, *args, **kwargs):
        # Email
        self.Email = self.Email or self.Contacto_Email
        # Sexo
        self.Contacto_Sexo = self.Contacto_Sexo or self.Contacto_CURP[10]

        # FechaNacimiento
        self.Contacto_FechaNacimiento = self.Contacto_FechaNacimiento or datetime(
            int(self.Contacto_CURP[4:6]) + 1900,
            int(self.Contacto_CURP[6:8]),
            int(self.Contacto_CURP[8:10])
        ).date()

        if not self.Contacto_Calle and not self.Contacto_NoExterior and not self.Contacto_Colonia and not self.Contacto_Ciudad and not self.Contacto_Estado and not self.Contacto_CodigoPostal:
            self.Contacto_Calle = self.Calle
            self.Contacto_NoExterior = self.NoExterior
            self.Contacto_NoInterior = self.NoInterior or None
            self.Contacto_Colonia = self.Colonia
            self.Contacto_DelegacionMunicipio = self.DelegacionMunicipioFactura
            self.Contacto_Ciudad = self.Ciudad
            self.Contacto_Estado = self.Estado
            self.Contacto_CodigoPostal = self.CodigoPostal

        super().save(*args, **kwargs)

    class Meta:
        managed = False
        db_table = 'CA_OportunidadesProspeccion'
        app_label = 'SalesForce'
