# backend/activities/urls.py - UPDATED WITH MISSING VOLUNTEER ENDPOINTS
from django.urls import path
from . import views

urlpatterns = [
    # Health check
    path('health/', views.health_check, name='health_check'),
    
    # =======================================
    # FIXED: STUDENT DASHBOARD ENDPOINTS
    # =======================================
    
    # NEW: Student-specific data endpoints for persistence
    path('student-enrolled/', views.get_student_enrolled_activities, name='student_enrolled_activities'),
    path('student-recent/', views.get_student_recent_activities, name='student_recent_activities'),
    path('student-volunteer-applications/', views.get_student_volunteer_applications, name='student_volunteer_applications'),
    path('student-dashboard-data/', views.get_student_dashboard_data, name='student_dashboard_data'),
    
    # =======================================
    # ACTIVITY ENDPOINTS - UPDATED
    # =======================================
    
    # Main activities endpoint with enrollment status
    path('activities/', views.get_activities_with_enrollment_status, name='get_activities'),
    path('activities/recent/', views.get_student_recent_activities, name='get_recent_activities'),
    
    # FIXED: Enrollment endpoint
    path('activities/<int:activity_id>/enroll/', views.enroll_in_activity_fixed, name='enroll_activity'),
    
    # =======================================
    # COORDINATOR ENDPOINTS - KEEP EXISTING
    # =======================================
    
    # Coordinator Dashboard
    path('coordinator/stats/', views.get_coordinator_stats, name='coordinator_stats'),
    path('coordinator/activities/', views.get_coordinator_activities, name='coordinator_activities'),
    path('coordinator/reports/', views.get_activity_reports, name='coordinator_reports'),
    
    # Activity Management (CRUD)
    path('coordinator/activities/create/', views.create_activity, name='create_activity'),
    path('coordinator/activities/<int:activity_id>/update/', views.update_activity, name='update_activity'),
    path('coordinator/activities/<int:activity_id>/delete/', views.delete_activity, name='delete_activity'),
    path('coordinator/activities/<int:activity_id>/publish/', views.publish_activity, name='publish_activity'),
    
    # Supporting Endpoints
    path('coordinator/categories/', views.get_activity_categories, name='activity_categories'),
    
    # =======================================
    # VOLUNTEERING ENDPOINTS - KEEP EXISTING
    # =======================================
    
    path('volunteering/', views.get_volunteering_opportunities, name='volunteer_opportunities'),
    path('volunteering/user-stats/', views.get_volunteering_stats, name='volunteering_stats'),
    path('volunteering/my-applications/', views.get_my_volunteer_applications, name='my_volunteer_applications'),
    path('volunteering/apply/', views.submit_volunteer_application, name='submit_volunteer_application'),
    path('volunteering/by-activity/<int:activity_id>/', views.get_opportunity_by_activity, name='opportunity_by_activity'),
    path('volunteering/create-from-activities/', views.create_volunteer_opportunities_from_activities, name='create_from_activities'),

    
    # =======================================
    # INSTRUCTOR ENDPOINTS - KEEP EXISTING + NEW VOLUNTEER ENDPOINTS
    # =======================================
    
    path('instructor/stats/', views.get_instructor_stats, name='instructor_stats'),
    path('instructor/activities/', views.get_instructor_activities, name='instructor_activities'),
    path('instructor/students/', views.get_instructor_students, name='instructor_students'),
    path('instructor/student/<int:student_id>/participation/', views.get_student_participation, name='instructor_student_participation'),
    path('instructor/reject-hours/<int:verification_id>/', views.reject_volunteer_hours, name='instructor_reject_hours'),
    path('instructor/pending-verifications/', views.get_pending_verifications, name='pending_verifications'),
    path('instructor/mark-attendance/<int:activity_id>/', views.mark_attendance, name='mark_attendance'),
    path('instructor/approve-hours/<int:verification_id>/', views.approve_volunteer_hours, name='approve_volunteer_hours'),
    path('instructor/student-report/<int:student_id>/', views.get_student_report, name='student_report'),
    path('instructor/monthly-report/', views.get_monthly_report, name='monthly_report'),
    path('instructor/activity-participants/<int:activity_id>/', views.get_activity_participants, name='activity_participants'),
    path('instructor/pending-applications/', views.get_pending_volunteer_applications, name='instructor_pending_applications'),
    path('instructor/pending-count/', views.get_pending_volunteer_count, name='instructor_pending_count'),
    path('instructor/approve-application/<int:application_id>/', views.approve_volunteer_application, name='instructor_approve_application'),
    path('instructor/reject-application/<int:application_id>/', views.reject_volunteer_application, name='instructor_reject_application'),
    path('instructor/all-applications/', views.get_all_volunteer_applications, name='instructor_all_applications'),

    path('admin/activities/', views.get_admin_activities, name='get_admin_activities'),
    path('admin/dashboard/stats/', views.get_admin_dashboard_stats, name='admin_dashboard_stats'),
    path('admin/analytics/', views.get_admin_analytics, name='admin_analytics'),
    path('admin/users/', views.get_admin_users, name='admin_users'),
    path('admin/volunteer-approvals/', views.get_admin_volunteer_approvals, name='admin_volunteer_approvals'),
    path('admin/analytics/', views.get_admin_system_analytics, name='admin_system_analytics'),
    path('admin/settings/', views.get_admin_settings, name='admin_system_settings'),
    path('admin/users/all/', views.get_all_users_for_export, name='admin_users_all'),
    path('admin/logs/', views.get_system_logs_for_export, name='admin_system_logs'),
    # =======================================
    # LEGACY COMPATIBILITY (if needed)
    # =======================================
    
    # Map old endpoints to new ones for backward compatibility
    path('dashboard/student-stats/', views.get_student_dashboard_data, name='student_stats'),  # Fixed mapping
]