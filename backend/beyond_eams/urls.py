# backend/beyond_eams/urls.py
from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from django.conf import settings
from django.conf.urls.static import static

def home(request):
    return JsonResponse({
        'message': 'Beyond EAMS API Server',
        'status': 'running',
        'version': '1.0.0',
        'available_endpoints': [
            '/admin/',
            '/api/auth/login/',
            '/api/auth/register/',
            '/api/auth/admin/dashboard/stats/',
            '/api/auth/admin/users/',
            '/api/auth/admin/analytics/',
            '/api/auth/admin/settings/',
            '/api/activities/',
            '/api/coordinator/stats/',
            '/api/coordinator/activities/',
            '/api/coordinator/activities/create/',
            '/api/instructor/stats/',
            '/api/volunteering/',
        ]
    })

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', home, name='home'),
    path('api/auth/', include('accounts.urls')),
    path('api/', include('activities.urls')),
]

# Serve media files during development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)