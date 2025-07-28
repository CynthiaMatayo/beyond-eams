# backend/accounts/urls.py
from django.urls import path
from . import views

urlpatterns = [
    # Authentication endpoints
    path('register/', views.register_user, name='register'),
    path('login/', views.login_user, name='login'),
    path('profile/', views.get_current_user, name='current_user'),
    path('reset-password/', views.reset_password, name='reset_password'),
    path('users/', views.list_users, name='list_users'),  # For testing only
    
    # Admin dashboard endpoints
    path('admin/dashboard/stats/', views.admin_dashboard_stats, name='admin_dashboard_stats'),
    path('admin/users/', views.admin_get_users, name='admin_get_users'),
    path('admin/users/<int:user_id>/role/', views.admin_update_user_role, name='admin_update_user_role'),
    path('admin/users/<int:user_id>/status/', views.admin_toggle_user_status, name='admin_toggle_user_status'),
    path('admin/analytics/', views.admin_get_analytics, name='admin_get_analytics'),
    path('admin/export/<str:data_type>/', views.admin_export_data, name='admin_export_data'),
    path('admin/settings/', views.admin_get_settings, name='admin_get_settings'),
    path('admin/settings/', views.admin_update_settings, name='admin_update_settings'),
    path('admin/notifications/', views.admin_send_notification, name='admin_send_notification'),
    path('admin/backup/', views.admin_create_backup, name='admin_create_backup'),
    path('admin/role-requests/', views.admin_get_role_requests, name='admin_get_role_requests'),
    path('admin/reports/system/', views.admin_get_system_reports, name='admin_get_system_reports'),
    path('admin/system-stats/', views.admin_get_system_reports, name='admin_system_stats'),
    path('admin/recent-activities/', views.admin_get_recent_activities, name='admin_recent_activities'),
]