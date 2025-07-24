# backend/volunteering/models.py
from django.db import models
from django.conf import settings
from activities.models import Activity

class VolunteerTask(models.Model):
    STATUS_CHOICES = [
        ('open', 'Open'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    title = models.CharField(max_length=200)
    description = models.TextField()
    activity = models.ForeignKey(Activity, on_delete=models.CASCADE, related_name='volunteer_tasks')
    posted_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='posted_tasks')
    required_volunteers = models.PositiveIntegerField(default=1)
    hours_commitment = models.DecimalField(max_digits=5, decimal_places=2, help_text="Expected hours of work")
    due_date = models.DateTimeField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.title} - {self.activity.title}"
    
    @property
    def applied_volunteers_count(self):
        return self.applications.filter(status='approved').count()
    
    @property
    def is_full(self):
        return self.applied_volunteers_count >= self.required_volunteers

class VolunteerApplication(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('completed', 'Completed'),
    ]
    
    task = models.ForeignKey(VolunteerTask, on_delete=models.CASCADE, related_name='applications')
    volunteer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='volunteer_applications')
    message = models.TextField(blank=True, help_text="Why do you want to volunteer for this task?")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    hours_completed = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    approved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='approved_applications'
    )
    applied_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        unique_together = ['task', 'volunteer']
    
    def __str__(self):
        return f"{self.volunteer.username} - {self.task.title}"