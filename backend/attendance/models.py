# attendance/models.py - COMPLETE ENHANCED VERSION
from django.db import models
from django.conf import settings
from activities.models import Activity
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta
import uuid
import json

User = get_user_model()

class Attendance(models.Model):
    activity = models.ForeignKey(
        Activity,
        on_delete=models.CASCADE,
        related_name='attendances'
    )
    student = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='attendances'
    )
    checked_in_at = models.DateTimeField(auto_now_add=True)
    verified_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='verified_attendances'
    )
    verification_method = models.CharField(
        max_length=20,
        choices=[
            ('qr_code', 'QR Code'),
            ('manual', 'Manual Entry'),
        ],
        default='qr_code'
    )
    
    # Enhanced fields for QR tracking
    qr_code = models.ForeignKey(
        'ActivityQRCode',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='attendances',
        help_text="QR code used for check-in (if applicable)"
    )
    qr_scanned_at = models.DateTimeField(
        null=True, 
        blank=True, 
        help_text="When QR was scanned"
    )
    
    # Location tracking (optional)
    latitude = models.DecimalField(
        max_digits=10, 
        decimal_places=8, 
        null=True, 
        blank=True
    )
    longitude = models.DecimalField(
        max_digits=11, 
        decimal_places=8, 
        null=True, 
        blank=True
    )
    
    # Additional tracking
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    
    class Meta:
        unique_together = ('activity', 'student')
        ordering = ['-checked_in_at']
        indexes = [
            models.Index(fields=['activity', 'verification_method']),
            models.Index(fields=['student', 'checked_in_at']),
            models.Index(fields=['qr_code']),
        ]
    
    def __str__(self):
        return f"{self.student.username} - {self.activity.title}"
    
    @property
    def student_name(self):
        """Get student's full name"""
        return self.student.get_full_name() if hasattr(self.student, 'get_full_name') else self.student.username
    
    @property
    def is_qr_checkin(self):
        """Check if this was a QR code check-in"""
        return self.verification_method == 'qr_code' and self.qr_code is not None


class ActivityQRCode(models.Model):
    activity = models.ForeignKey(
        Activity,
        on_delete=models.CASCADE,
        related_name='qr_codes'  # Changed from OneToOne to allow multiple QR codes
    )
    code = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    
    # Enhanced QR functionality
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='created_qr_codes',
        null=True,     # Added this
        blank=True     # Added this
    )
    session_id = models.UUIDField(default=uuid.uuid4, help_text="Unique session identifier")
    max_uses = models.IntegerField(
        default=None, 
        null=True, 
        blank=True, 
        help_text="Max number of scans (null = unlimited)"
    )
    current_uses = models.IntegerField(default=0, help_text="Current number of scans")
    
    # QR Code data (JSON string)
    qr_data = models.TextField(blank=True, help_text="QR code data as JSON string")
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['activity', 'is_active']),
            models.Index(fields=['created_at']),
            models.Index(fields=['session_id']),
            models.Index(fields=['code']),
        ]
    
    def __str__(self):
        return f"QR Code for {self.activity.title} - {self.created_at.strftime('%Y-%m-%d %H:%M')}"
    
    @property
    def is_expired(self):
        """Check if QR code has expired"""
        if self.expires_at:
            return timezone.now() > self.expires_at
        return False
    
    @property
    def is_valid(self):
        """Check if QR code is valid for use"""
        if not self.is_active:
            return False
        if self.is_expired:
            return False
        if self.max_uses and self.current_uses >= self.max_uses:
            return False
        return True
    
    def generate_qr_data(self):
        """Generate QR code data as JSON string"""
        qr_data = {
            'type': 'activity_checkin',
            'activity_id': self.activity.id,
            'activity_title': self.activity.title,
            'session_id': str(self.session_id),
            'timestamp': int(self.created_at.timestamp() * 1000),
            'location': self.activity.location,
            'expires_at': int(self.expires_at.timestamp() * 1000) if self.expires_at else None,
        }
        self.qr_data = json.dumps(qr_data)
        return self.qr_data
    
    def increment_usage(self):
        """Increment usage count"""
        self.current_uses += 1
        self.save(update_fields=['current_uses'])
    
    def deactivate(self):
        """Deactivate QR code"""
        self.is_active = False
        self.save(update_fields=['is_active'])
    
    @classmethod
    def create_for_activity(cls, activity, created_by, expires_in_hours=2):
        """Create a new QR code for an activity"""
        # Deactivate any existing active QR codes for this activity
        cls.objects.filter(activity=activity, is_active=True).update(is_active=False)
        
        # Create new QR code
        expires_at = timezone.now() + timedelta(hours=expires_in_hours)
        qr_code = cls.objects.create(
            activity=activity,
            created_by=created_by,
            expires_at=expires_at,
            is_active=True,
        )
        
        # Generate QR data
        qr_code.generate_qr_data()
        qr_code.save()
        
        return qr_code
    
    def save(self, *args, **kwargs):
        """Override save to generate QR data"""
        super().save(*args, **kwargs)
        if not self.qr_data:
            self.generate_qr_data()
            super().save(update_fields=['qr_data'])


class QRScanLog(models.Model):
    """Log of QR code scans for analytics and security"""
    
    qr_code = models.ForeignKey(
        ActivityQRCode, 
        on_delete=models.CASCADE, 
        related_name='scan_logs'
    )
    student = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='qr_scan_logs'
    )
    activity = models.ForeignKey(Activity, on_delete=models.CASCADE)
    
    # Scan details
    scanned_at = models.DateTimeField(auto_now_add=True)
    success = models.BooleanField(default=False, help_text="Whether scan resulted in successful check-in")
    error_message = models.TextField(blank=True, help_text="Error message if scan failed")
    
    # Technical details
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    
    # Location verification (optional)
    latitude = models.DecimalField(max_digits=10, decimal_places=8, null=True, blank=True)
    longitude = models.DecimalField(max_digits=11, decimal_places=8, null=True, blank=True)
    
    # Associated attendance record (if successful)
    attendance = models.ForeignKey(
        Attendance,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='scan_logs'
    )
    
    class Meta:
        ordering = ['-scanned_at']
        indexes = [
            models.Index(fields=['qr_code', 'scanned_at']),
            models.Index(fields=['activity', 'success']),
            models.Index(fields=['student', 'scanned_at']),
            models.Index(fields=['success', 'scanned_at']),
        ]
    
    def __str__(self):
        status = "Success" if self.success else "Failed"
        student_info = f" by {self.student.username}" if self.student else " (Anonymous)"
        return f"QR Scan {status}{student_info} - {self.scanned_at.strftime('%Y-%m-%d %H:%M')}"


# Add these methods to your existing Activity model
# If you can't modify the Activity model directly, create a separate file or use these in your views
def get_active_qr_code(activity):
    """Get the currently active QR code for an activity"""
    return activity.qr_codes.filter(is_active=True).first()

def generate_qr_code(activity, created_by, expires_in_hours=2):
    """Generate a new QR code for an activity"""
    return ActivityQRCode.create_for_activity(activity, created_by, expires_in_hours)

def can_generate_qr(activity):
    """Check if QR code can be generated for an activity"""
    # Only allow QR generation for upcoming or ongoing activities
    return activity.status in ['upcoming', 'ongoing']

def is_qr_checkin_allowed(activity):
    """Check if QR check-in is currently allowed"""
    now = timezone.now()
    # Allow check-in 30 minutes before start and 2 hours after start
    checkin_start = activity.start_time - timedelta(minutes=30)
    checkin_end = activity.start_time + timedelta(hours=2)
    return checkin_start <= now <= checkin_end

# Helper functions for activity QR operations
Activity.get_active_qr_code = get_active_qr_code
Activity.generate_qr_code = generate_qr_code
Activity.can_generate_qr = can_generate_qr
Activity.is_qr_checkin_allowed = is_qr_checkin_allowed