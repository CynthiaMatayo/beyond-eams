# backend/notifications/urls.py
from django.urls import path
from . import views

app_name = 'notifications'

urlpatterns = [
    # User notification endpoints
    path('', views.get_user_notifications, name='get_notifications'),
    path('count/', views.get_notification_count, name='notification_count'),
    path('<int:notification_id>/read/', views.mark_notification_read, name='mark_read'),
    
    # Admin notification endpoints
    path('send/', views.send_notification, name='send_notification'),
    path('send-activity/', views.send_activity_notification, name='send_activity_notification'),
    
    # Email testing
    path('test-email/', views.test_email, name='test_email'),
]
