# backend/attendance/urls.py - Updated to match simplified views
from django.urls import path
from . import views

urlpatterns = [
    # QR Code attendance marking (for students)
    path('mark/', views.mark_attendance, name='mark-attendance'),
    
    # Manual attendance marking (for instructors/coordinators)
    path('activity/<int:activity_id>/mark-manual/', views.mark_attendance_manual, name='mark-attendance-manual'),
    
    # Get attendance for an activity (for instructors/coordinators)
    path('activity/<int:activity_id>/', views.get_activity_attendance, name='activity-attendance'),
    
    # Get student's own attendance records
    path('my-attendance/', views.get_student_attendance, name='my-attendance'),
    
    # QR Code management
    path('activity/<int:activity_id>/generate-qr/', views.generate_qr_code, name='generate-qr-code'),
    path('activity/<int:activity_id>/qr-code/', views.get_qr_code, name='get-qr-code'),
]