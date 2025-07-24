# attendance/admin.py
from django.contrib import admin
from .models import Attendance, ActivityQRCode

@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    list_display = ['activity', 'student', 'checked_in_at', 'verification_method']
    list_filter = ['verification_method', 'checked_in_at', 'activity']
    search_fields = ['student__username', 'student__first_name', 'student__last_name', 'activity__title']
    readonly_fields = ['checked_in_at']

@admin.register(ActivityQRCode)
class ActivityQRCodeAdmin(admin.ModelAdmin):
    list_display = ['activity', 'code', 'is_active', 'created_at']
    list_filter = ['is_active', 'created_at']
    readonly_fields = ['code', 'created_at']