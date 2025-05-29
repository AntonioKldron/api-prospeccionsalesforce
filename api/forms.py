from django import forms
from .models import SolicitudPersonaMoral, SolicitudPersonaFisica
import re


class FormBase(forms.ModelForm):
    
    def existe_oportunidad(oportunidad_id, using='default'):
        # Revisar en persona física
        existe_fisica = SolicitudPersonaFisica.objects.using(using).filter(OportunidadId=oportunidad_id).exists()
        if existe_fisica:
            return True

        # Revisar en persona moral
        existe_moral = SolicitudPersonaMoral.objects.using(using).filter(OportunidadId=oportunidad_id).exists()
        if existe_moral:
            return True

        return False

    def validar_rfc(self, rfc):
        patron_rfc = re.compile(
            r'([A-ZÑ&]{3,4}) ?(?:- ?)?(\d{2}(?:0[1-9]|1[0-2])(?:0[1-9]|[12]\d|3[01])) ?(?:- ?)?([A-Z\d]{2})([A\d])',
            re.IGNORECASE)

        if not patron_rfc.match(rfc):
            return False
        return True

    def clean(self):
        cleaned_data = super().clean()
        rfc = cleaned_data.get('RFC')
        tipo_persona = cleaned_data.get('Tipo')

        if not self.validar_rfc(rfc):
            self.add_error('RFC', 'El RFC no es válido')

        if tipo_persona == 'Fisica' or tipo_persona == 'Física':
            if len(rfc) != 13:
                self.add_error('RFC', 'El RFC de una persona física debe tener 13 caracteres')
        else:
            if len(rfc) != 12:
                self.add_error('RFC', 'El RFC de una persona moral debe tener 12 caracteres')
        return cleaned_data

    def save(self, commit=True, using='default'):
        instance = super().save(commit=False)
        if commit:
            instance.save(using=using)
        return instance


class FormPersonaMoral(FormBase):
    class Meta:
        model = SolicitudPersonaMoral
        fields = '__all__'


class FormPersonaFisica(FormBase):
    class Meta:
        model = SolicitudPersonaFisica
        fields = '__all__'
