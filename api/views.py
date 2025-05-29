from django.http import JsonResponse
from isapilib.external.connection import add_conn
from isapilib.logger.decorators import insert_log, logger_method
from isapilib.api.models import SepaBranch, UserAPI
from .forms import FormPersonaFisica, FormPersonaMoral,FormBase
from rest_framework.decorators import action
from rest_framework.views import APIView


class SalesForce(APIView):
    required_scopes = ['write']

    @logger_method('POST', interfaz=None, log_all=True)
    @action(detail=True, methods=['POST'])
    def post(self, request):
        try:
            # Obtenemos los datos de la solicitud
            organization_id = request.headers.get('organizationId')
            username=UserAPI.objects.get(username=request.user.username)
            sepa = SepaBranch.objects.get(id=organization_id)
            external = add_conn(username,sepa)
            sucursal = SepaBranch.objects.get(pk=organization_id).id_intelisis
            datos = request.data
            respaldo_datos = datos.copy()

            try:
                datos_cliente = dict(datos.get('Contactos')[0])
            except Exception as e:
                datos_cliente = None
            tipo_persona = datos.get('Tipo')
            dato = {}
            datos['Sucursal'] = sucursal

            oportunidad_id = datos.get('OportunidadId')
            if FormBase.existe_oportunidad(oportunidad_id, using=external):
                return JsonResponse({
                    'Resultado': 'Error',
                    'Mensaje': f'Ya existe un lead con OportunidadId "{oportunidad_id}" dentro de INTELISIS'
                }, status=201)
                        
            
            # Validamos que el tipo de persona sea correcto
            if datos_cliente is not None:
                datos.pop('Contactos')
                for key, value in datos_cliente.items():
                    new_key = 'Contacto_' + key
                    dato[new_key] = value
                datos = {**datos, **dato}

                if tipo_persona == 'Física':
                    razon_social = datos.get('RazonSocial')
                    datos['RazonComercialFactura'] = f'{razon_social}'
                    formulario = FormPersonaFisica(datos)
                else:
                    razon_social = datos.get('RazonSocial')
                    regimen_capital = datos.get('RegimenCapital')
                    datos['RazonComercialFactura'] = f'{razon_social}'
                    datos['SociedadMercantil'] = f'{regimen_capital}'
                    formulario = FormPersonaMoral(datos) 
            else:
                if tipo_persona == 'Fisica':
                    formulario = FormPersonaFisica(datos)
                elif tipo_persona == 'Moral':
                    raise Exception('DatosClienteContacto es requerido para personas morales')
                else:
                    raise Exception('El tipo de persona no es válido')

            # Validamos que el formulario sea válido
            if not formulario.is_valid():
                insert_log(request=request, response=str(formulario.errors), interfaz='ProspeccionSalesForce', tipo='Error')
                raise Exception(dict(formulario.errors.items()))

            # Guardamos la solicitud
            formulario.save(using=external)
            response_data = {
                'Resultado': 'Éxito',
                'Mensaje': 'La solicitud se procesó correctamente'
            }

            return JsonResponse(response_data, status=200)
        except Exception as e:
            return JsonResponse({'Resultado': 'Error', 'Mensaje': f'Ha ocurrido un error, {e}'}, status=405)
