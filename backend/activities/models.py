# backend/activities/models.py - Updated with QR code support
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.core.validators import MinValueValidator, MaxValueValidator
from django.core.files.storage import default_storage
import os
import uuid

# Get the User model from accounts app
User = get_user_model()

class ActivityCategory(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    color = models.CharField(max_length=7, default="#007bff")  # Hex color
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name_plural = "Activity Categories"
    
    def __str__(self):
        return self.name

class Activity(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('upcoming', 'Upcoming'),
        ('ongoing', 'Ongoing'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    DIFFICULTY_CHOICES = [
        ('beginner', 'Beginner'),
        ('intermediate', 'Intermediate'),
        ('advanced', 'Advanced'),
    ]
    
    # Basic Information
    title = models.CharField(max_length=200)
    description = models.TextField()
    location = models.CharField(max_length=200)
    
    # NEW: QR Code for attendance
    qr_code = models.CharField(max_length=100, unique=True, blank=True, null=True, 
                              help_text="QR code for attendance marking")
    
    # Enhanced fields for coordinator functionality
    category = models.ForeignKey(
        ActivityCategory, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='activities'
    )
    difficulty = models.CharField(max_length=20, choices=DIFFICULTY_CHOICES, default='beginner')
    max_participants = models.PositiveIntegerField(default=50, validators=[MinValueValidator(1)])
    requirements = models.TextField(blank=True, help_text="Prerequisites or special requirements")
    
    # Virtual/Physical location
    is_virtual = models.BooleanField(default=False)
    virtual_link = models.URLField(blank=True, help_text="Zoom, Teams, or other virtual meeting link")
    
    # Timing
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    registration_deadline = models.DateTimeField(null=True, blank=True)
    
    # Activity Features
    is_volunteering = models.BooleanField(default=False)
    is_featured = models.BooleanField(default=False, help_text="Show on featured activities")
    certificate_available = models.BooleanField(default=False)
    points_reward = models.PositiveIntegerField(
        default=10, 
        validators=[MinValueValidator(5), MaxValueValidator(50)],
        help_text="Points awarded for participation"
    )
    
    # Media
    poster_image = models.ImageField(
        upload_to='activity_posters/', 
        null=True, 
        blank=True,
        help_text="Activity poster or promotional image"
    )
    
    # Status and Management
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    created_by = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        null=True, 
        blank=True, 
        related_name='activities_created'
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        # Generate QR code if not exists
        if not self.qr_code:
            if self.pk:
                self.qr_code = f"ACT_{self.pk}_{uuid.uuid4().hex[:8].upper()}"
            else:
                self.qr_code = f"ACT_{uuid.uuid4().hex[:8].upper()}_{uuid.uuid4().hex[:8].upper()}"
        
        self.full_clean()
        super().save(*args, **kwargs)
    
    # Computed Properties (maintain backward compatibility)
    @property
    def date(self):
        """Alias for start_time to maintain compatibility"""
        return self.start_time
    
    @property
    def requires_volunteering(self):
        """Alias for is_volunteering to maintain compatibility"""
        return self.is_volunteering
    
    @property
    def coordinator(self):
        """Alias for created_by to maintain compatibility"""
        return self.created_by
    
    @property
    def created_by_name(self):
        """Get coordinator name"""
        if self.created_by:
            return f"{self.created_by.first_name} {self.created_by.last_name}".strip() or self.created_by.username
        return "Unknown"
    
    @property
    def is_active(self):
        """Check if activity is active based on status"""
        return self.status in ['upcoming', 'ongoing']
    
    @property
    def enrollment_count(self):
        """Get the actual count of enrolled participants"""
        return self.activity_enrollments.filter(status__in=['enrolled', 'completed']).count()
    
    @property
    def enrolled_count(self):
        """Alias for enrollment_count for frontend compatibility"""
        return self.enrollment_count
    
    @property
    def available_spots(self):
        """Get remaining spots available"""
        return max(0, self.max_participants - self.enrollment_count)
    
    @property
    def is_full(self):
        """Check if activity is at capacity"""
        return self.enrollment_count >= self.max_participants
    
    @property
    def is_past(self):
        """Check if activity date has passed"""
        return self.start_time < timezone.now()
    
    @property
    def is_registration_open(self):
        """Check if registration is still open"""
        if self.registration_deadline:
            return timezone.now() <= self.registration_deadline
        return not self.is_past and self.is_active
    
    @property
    def days_until_activity(self):
        """Get days until activity starts"""
        if self.is_past:
            return 0
        return (self.start_time.date() - timezone.now().date()).days
    
    @property
    def duration_hours(self):
        """Get activity duration in hours"""
        return (self.end_time - self.start_time).total_seconds() / 3600
    
    def can_enroll(self, user):
        """Check if user can enroll in this activity"""
        if self.is_past or not self.is_active or self.is_full or not self.is_registration_open:
            return False
        
        # Check if user is already enrolled
        existing_enrollment = self.activity_enrollments.filter(
            user=user,
            status__in=['enrolled', 'completed']
        ).exists()
        
        return not existing_enrollment
    
    def can_edit(self, user):
        """Check if user can edit this activity"""
        return (
            user == self.created_by or 
            user.role in ['coordinator', 'admin'] or
            user.is_staff
        )
    
    def generate_qr_code_data(self):
        """Generate QR code data for attendance marking"""
        return f"{self.id}:{self.qr_code}"
    
    def get_coordinator_stats(self):
        """Get statistics for coordinator dashboard"""
        total_enrolled = self.enrollment_count
        present_count = self.activity_attendance_records.filter(status='present').count()
        absent_count = self.activity_attendance_records.filter(status='absent').count()
        
        return {
            'total_enrolled': total_enrolled,
            'present_count': present_count,
            'absent_count': absent_count,
            'attendance_rate': (present_count / total_enrolled * 100) if total_enrolled > 0 else 0,
            'available_spots': self.available_spots,
            'is_full': self.is_full,
        }
    
    def publish(self):
        """Publish a draft activity"""
        if self.status == 'draft':
            self.status = 'upcoming'
            self.save()
            
            # Create notifications for interested users
            self._create_activity_notification()
    
    def _create_activity_notification(self):
        """Create notifications when activity is published"""
        # Create notification for all users interested in this category
        # TODO: Implement notification logic based on user preferences
        pass
    
    def clean(self):
        """Validate model data"""
        from django.core.exceptions import ValidationError
        
        if self.end_time <= self.start_time:
            raise ValidationError("End time must be after start time")
        
        if self.registration_deadline and self.registration_deadline >= self.start_time:
            raise ValidationError("Registration deadline must be before activity start time")
        
        if self.is_virtual and not self.virtual_link:
            raise ValidationError("Virtual link is required for virtual activities")
    
    def __str__(self):
        return f"{self.title} - {self.start_time.strftime('%Y-%m-%d')}"
    
    class Meta:
        ordering = ['-start_time']
        verbose_name_plural = "Activities"

class Enrollment(models.Model):
    STATUS_CHOICES = [
        ('enrolled', 'Enrolled'),
        ('completed', 'Completed'),
        ('withdrawn', 'Withdrawn'),
        ('cancelled', 'Cancelled'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='user_enrollments')
    activity = models.ForeignKey(Activity, on_delete=models.CASCADE, related_name='activity_enrollments')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='enrolled')
    enrolled_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    completion_notes = models.TextField(blank=True)
    points_awarded = models.PositiveIntegerField(default=0)
    
    class Meta:
        unique_together = ['user', 'activity']
    
    def award_points(self):
        """Award points when activity is completed"""
        if self.status == 'completed' and self.points_awarded == 0:
            self.points_awarded = self.activity.points_reward
            self.save()
            
            # Update user's total points (if you have a user profile model)
            # self.user.profile.add_points(self.points_awarded)
    
    def __str__(self):
        return f"{self.user} - {self.activity.title} ({self.status})"

class Attendance(models.Model):
    STATUS_CHOICES = [
        ('present', 'Present'),
        ('absent', 'Absent'),
        ('excused', 'Excused'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='user_attendance_records')
    activity = models.ForeignKey(Activity, on_delete=models.CASCADE, related_name='activity_attendance_records')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES)
    marked_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='attendance_marked_by_user')
    timestamp = models.DateTimeField(auto_now_add=True)
    notes = models.TextField(blank=True)
    
    # NEW: QR Code verification
    qr_code_used = models.CharField(max_length=100, blank=True, null=True,
                                   help_text="QR code that was scanned for this attendance")
    
    class Meta:
        unique_together = ['user', 'activity']
    
    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        
        # Update enrollment status if attendance is marked as present
        if self.status == 'present':
            enrollment = Enrollment.objects.filter(
                user=self.user,
                activity=self.activity
            ).first()
            
            if enrollment and enrollment.status == 'enrolled':
                enrollment.status = 'completed'
                enrollment.save()
                enrollment.award_points()
    
    def __str__(self):
        return f"{self.user} - {self.activity.title} ({self.status})"

class VolunteerOpportunity(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField()
    requirements = models.TextField(blank=True)
    time_commitment = models.CharField(max_length=100)  # e.g., "2 hours/week"
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    max_volunteers = models.PositiveIntegerField(default=10)
    coordinator = models.ForeignKey(User, on_delete=models.CASCADE, related_name='volunteer_opportunities_coordinated')
    activity = models.ForeignKey(Activity, on_delete=models.CASCADE, null=True, blank=True, related_name='volunteer_opportunities_for_activity')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    @property
    def application_count(self):
        """Get count of applications"""
        return self.volunteer_opportunity_applications.filter(status__in=['pending', 'approved', 'active', 'completed']).count()
    
    @property
    def available_spots(self):
        """Get remaining volunteer spots"""
        return max(0, self.max_volunteers - self.application_count)
    
    def __str__(self):
        return self.title
    
    class Meta:
        ordering = ['-created_at']

class VolunteerApplication(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending Review'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('active', 'Active'),
        ('completed', 'Completed'),
        ('withdrawn', 'Withdrawn'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='user_volunteer_applications')
    opportunity = models.ForeignKey(VolunteerOpportunity, on_delete=models.CASCADE, related_name='volunteer_opportunity_applications')
    
    # Application form fields
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)
    email = models.EmailField()
    student_id = models.CharField(max_length=20)
    phone_primary = models.CharField(max_length=15)
    phone_secondary = models.CharField(max_length=15, blank=True)
    department = models.CharField(max_length=100)
    academic_year = models.CharField(max_length=50)
    interest_reason = models.TextField()
    skills_experience = models.TextField()
    availability = models.TextField()
    
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    hours_completed = models.FloatField(default=0.0, validators=[MinValueValidator(0)])
    approved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='volunteer_applications_approved_by_user')
    submitted_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['user', 'opportunity']
    
    def __str__(self):
        return f"{self.first_name} {self.last_name} - {self.opportunity.title} ({self.status})"

class Notification(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='user_notifications')
    title = models.CharField(max_length=200)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    notification_type = models.CharField(max_length=50, default='general')  # general, activity, volunteer, etc.
    related_activity = models.ForeignKey(Activity, on_delete=models.CASCADE, null=True, blank=True, related_name='activity_notifications')
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.username} - {self.title}"

# Coordinator-specific models for analytics and reporting
class ActivityStatistics(models.Model):
    """Model to store pre-computed statistics for better performance"""
    activity = models.OneToOneField(Activity, on_delete=models.CASCADE, related_name='statistics')
    total_enrollments = models.PositiveIntegerField(default=0)
    total_attendance = models.PositiveIntegerField(default=0)
    completion_rate = models.FloatField(default=0.0)  # Percentage
    volunteer_hours = models.FloatField(default=0.0)
    last_updated = models.DateTimeField(auto_now=True)
    
    def update_statistics(self):
        """Update all statistics for this activity"""
        activity = self.activity
        
        self.total_enrollments = activity.enrollment_count
        self.total_attendance = activity.activity_attendance_records.filter(status='present').count()
        self.completion_rate = (self.total_attendance / self.total_enrollments * 100) if self.total_enrollments > 0 else 0
        
        # Calculate volunteer hours if it's a volunteering activity
        if activity.is_volunteering:
            volunteer_apps = VolunteerApplication.objects.filter(
                opportunity__activity=activity,
                status__in=['completed', 'active']
            )
            self.volunteer_hours = sum(app.hours_completed for app in volunteer_apps)
        
        self.save()
    
    def __str__(self):
        return f"Stats for {self.activity.title}"

class CoordinatorProfile(models.Model):
    """Extended profile for coordinators"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='coordinator_profile')
    bio = models.TextField(blank=True)
    department = models.CharField(max_length=100, blank=True)
    contact_email = models.EmailField(blank=True)
    phone = models.CharField(max_length=15, blank=True)
    office_location = models.CharField(max_length=100, blank=True)
    specializations = models.TextField(blank=True, help_text="Areas of expertise or interests")
    
    # Statistics
    activities_created = models.PositiveIntegerField(default=0)
    total_participants_managed = models.PositiveIntegerField(default=0)
    volunteer_hours_coordinated = models.FloatField(default=0.0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def update_statistics(self):
        """Update coordinator statistics"""
        activities = Activity.objects.filter(created_by=self.user)
        
        self.activities_created = activities.count()
        self.total_participants_managed = sum(activity.enrollment_count for activity in activities)
        
        # Calculate total volunteer hours coordinated
        volunteer_activities = activities.filter(is_volunteering=True)
        total_volunteer_hours = 0
        for activity in volunteer_activities:
            volunteer_apps = VolunteerApplication.objects.filter(
                opportunity__activity=activity,
                status__in=['completed', 'active']
            )
            total_volunteer_hours += sum(app.hours_completed for app in volunteer_apps)
        
        self.volunteer_hours_coordinated = total_volunteer_hours
        self.save()
    
    def __str__(self):
        return f"Coordinator Profile: {self.user.get_full_name() or self.user.username}"

