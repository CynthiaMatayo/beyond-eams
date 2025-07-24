# backend/activities/admin.py
from django.contrib import admin
from .models import Activity, ActivityCategory, Enrollment, Attendance, VolunteerOpportunity, VolunteerApplication, Notification

# Don't register User here since it's registered in accounts/admin.py

@admin.register(Activity)
class ActivityAdmin(admin.ModelAdmin):
    # Use fields that actually exist in your database
    list_display = ['title', 'start_time', 'location', 'created_by', 'status']
    list_filter = ['status', 'start_time', 'is_volunteering']
    search_fields = ['title', 'description', 'location']
    ordering = ['-start_time']

@admin.register(ActivityCategory)
class ActivityCategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'color', 'created_at']

@admin.register(Enrollment)
class EnrollmentAdmin(admin.ModelAdmin):
    list_display = ['user', 'activity', 'status', 'enrolled_at']
    list_filter = ['status', 'enrolled_at']

@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    list_display = ['user', 'activity', 'status', 'timestamp', 'marked_by']
    list_filter = ['status', 'timestamp']

@admin.register(VolunteerOpportunity)
class VolunteerOpportunityAdmin(admin.ModelAdmin):
    list_display = ['title', 'start_date', 'coordinator', 'max_volunteers', 'is_active']
    list_filter = ['is_active', 'start_date']

@admin.register(VolunteerApplication)
class VolunteerApplicationAdmin(admin.ModelAdmin):
    list_display = ['user', 'opportunity', 'status', 'submitted_at', 'hours_completed']
    list_filter = ['status', 'submitted_at']

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['user', 'title', 'notification_type', 'is_read', 'created_at']
    list_filter = ['notification_type', 'is_read', 'created_at']