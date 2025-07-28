# backend/beyond_eams/urls.py - FINAL FIX
from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from django.conf import settings
from django.conf.urls.static import static
from accounts import views as accounts_views

def home(request):
    return JsonResponse({
        'message': 'Beyond EAMS API Server',
        'status': 'running',
        'version': '1.0.0',
        'available_endpoints': [
            '/admin/',
            '/api/auth/login/',
            '/api/auth/register/',
            '/api/activities/',
            '/api/coordinator/activities/',  # This should work now

        ]
    })

# Fix for missing admin routes
def admin_volunteer_approvals(request):
    return JsonResponse({
        'message': 'Volunteer approvals redirected',
        'redirect_to': '/api/activities/instructor/pending-applications/',
    })

def admin_users(request):
    return JsonResponse({
        'message': 'Admin users redirected', 
        'redirect_to': '/api/activities/instructor/students/',
    })

def admin_system_reports(request):
    return JsonResponse({
        'message': 'System reports redirected',
        'redirect_to': '/api/activities/coordinator/reports/',
    })

urlpatterns = [
    # Custom admin routes BEFORE main admin
    path('admin/volunteer-approvals/', admin_volunteer_approvals, name='admin_volunteer_approvals'),
    path('admin/users/', admin_users, name='admin_users'), 
    path('admin/system/', admin_system_reports, name='admin_system_reports'),
    path('admin/reports/', admin_system_reports, name='admin_reports'),
    
    # Main routes
    path('', home, name='home'),
    path('admin/', admin.site.urls),
    
    # API routes - FIXED ORDER
    path('api/auth/', include('accounts.urls')),
    path('api/notifications/', include('notifications.urls')),
    path('api/', include('activities.urls')),  # This includes coordinator/activities/
    path('api/instructor/', include('activities.urls')),
    path('api/admin/', include('activities.urls')),

    # Additional API routes
    path('api/admin/users/', admin_users, name='api_admin_users'),
    path('api/admin/system/', admin_system_reports, name='api_admin_system_reports'),
    path('api/admin/reports/', admin_system_reports, name='api_admin_reports'),
    
    # Specific admin endpoints for Flutter app
    path('api/admin/system-stats/', accounts_views.admin_get_system_reports, name='admin_system_stats'),
    path('api/admin/recent-activities/', accounts_views.admin_get_recent_activities, name='admin_recent_activities'),
    
    # Dashboard endpoints
    path('api/admin/dashboard/stats/', accounts_views.admin_get_dashboard_stats, name='admin_dashboard_stats'),
    path('api/admin/analytics/', accounts_views.admin_get_analytics, name='admin_analytics'),

]

# Serve media files during development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)