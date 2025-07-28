from django.contrib import admin
from .models import Notification, NotificationTemplate, EmailLog

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['title', 'recipient', 'notification_type', 'priority', 'is_read', 'email_sent', 'created_at']
    list_filter = ['notification_type', 'priority', 'is_read', 'email_sent', 'created_at']
    search_fields = ['title', 'message', 'recipient__username', 'recipient__email']
    readonly_fields = ['created_at', 'email_sent_at']
    ordering = ['-created_at']
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('recipient', 'related_activity')

@admin.register(NotificationTemplate)
class NotificationTemplateAdmin(admin.ModelAdmin):
    list_display = ['name', 'subject', 'is_active', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name', 'subject']
    readonly_fields = ['created_at', 'updated_at']

@admin.register(EmailLog)
class EmailLogAdmin(admin.ModelAdmin):
    list_display = ['recipient_email', 'subject', 'sent_successfully', 'sent_at']
    list_filter = ['sent_successfully', 'sent_at']
    search_fields = ['recipient_email', 'subject']
    readonly_fields = ['sent_at']
    ordering = ['-sent_at']
