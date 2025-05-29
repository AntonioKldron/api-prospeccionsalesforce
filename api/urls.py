from django.urls import path
from .views import *

urlpatterns = [
    path('api/salesforce/', SalesForce.as_view(), name='salesforce'),
]