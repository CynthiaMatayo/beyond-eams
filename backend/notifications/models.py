from django.db import models
from django.contrib.auth import get_user_model
from django.core.mail import send_mail
from django.conf import settings
import logging

User = get_user_model()
logger = logging.getLogger(__name__)

class NotificationTemplate(models.Model):
    """Templates for different types of notifications"""
    name = models.CharField(max_length=100, unique=True)
    subject = models.CharField(max_length=200)
    email_template = models.TextField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return self.name
    
    class Meta:
        ordering = ['name']

class Notification(models.Model):
    """System notifications for users"""
    NOTIFICATION_TYPES = (
        ('general', 'General'),
        ('activity', 'Activity'),
        ('volunteer', 'Volunteer'),
        ('approval', 'Approval'),
        ('reminder', 'Reminder'),
        ('system', 'System'),
    )
    
    PRIORITY_CHOICES = (
        ('low', 'Low'),
        ('normal', 'Normal'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    )
    
    recipient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=200)
    message = models.TextField()
    notification_type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES, default='general')
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='normal')
    is_read = models.BooleanField(default=False)
    email_sent = models.BooleanField(default=False)
    email_sent_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    # Optional related objects
    related_activity = models.ForeignKey(
        'activities.Activity', 
        on_delete=models.CASCADE, 
        null=True, 
        blank=True,
        related_name='notifications'
    )
    
    def send_email(self):
        """Send notification via email if user has email notifications enabled"""
        try:
            if not self.recipient.email:
                logger.warning(f"No email address for user {self.recipient.username}")
                return False
                
            # Check user preferences (implement user email preferences model later)
            # For now, send to all users
            
            subject = f"[Beyond EAMS] {self.title}"
            message = f"""
Dear {self.recipient.get_full_name() or self.recipient.username},

{self.message}

---
This is an automated message from Beyond EAMS.
Please do not reply to this email.

Best regards,
Beyond EAMS Team
            """
            
            success = send_mail(
                subject=subject,
                message=message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[self.recipient.email],
                fail_silently=False,
            )
            
            if success:
                self.email_sent = True
                self.email_sent_at = models.timezone.now()
                self.save(update_fields=['email_sent', 'email_sent_at'])
                logger.info(f"Email sent successfully to {self.recipient.email}")
                return True
            else:
                logger.error(f"Failed to send email to {self.recipient.email}")
                return False
                
        except Exception as e:
            logger.error(f"Error sending email to {self.recipient.email}: {str(e)}")
            return False
    
    def mark_as_read(self):
        """Mark notification as read"""
        self.is_read = True
        self.save(update_fields=['is_read'])
    
    def __str__(self):
        return f"{self.recipient.username} - {self.title}"
    
    class Meta:
        ordering = ['-created_at']

class EmailLog(models.Model):
    """Log of all email attempts"""
    recipient_email = models.EmailField()
    subject = models.CharField(max_length=200)
    message = models.TextField()
    sent_successfully = models.BooleanField(default=False)
    error_message = models.TextField(blank=True)
    sent_at = models.DateTimeField(auto_now_add=True)
    notification = models.ForeignKey(
        Notification, 
        on_delete=models.CASCADE, 
        null=True, 
        blank=True,
        related_name='email_logs'
    )
    
    def __str__(self):
        status = "✓" if self.sent_successfully else "✗"
        return f"{status} {self.recipient_email} - {self.subject}"
    
    class Meta:
        ordering = ['-sent_at']
