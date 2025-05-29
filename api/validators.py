from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _


# Validar que el número de teléfono sea válido
def validate_phone(value):
    if len(value) != 10:
        raise ValidationError(
            _('%(value)s no es un número de teléfono válido'),
            params={'value': value},
        )


# Validar CURP
# Es probable que la validation no sea necesaria.
def validate_curp(value):
    if len(value) != 18:
        raise ValidationError(
            _('%(value)s no es un CURP válido'),
            params={'value': value},
        )

    if not value[:4].isalpha():
        raise ValidationError(
            _('%(value)s no es un CURP válido'),
            params={'value': value},
        )
