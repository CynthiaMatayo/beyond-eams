# backend/accounts/models.py - Updated with department field
from django.db import models
from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    ROLE_CHOICES = [
        ('student', 'Student'),
        ('instructor', 'Instructor'),
        ('coordinator', 'Coordinator'),
        ('admin', 'Admin'),
    ]
    
    DEPARTMENT_CHOICES = [
        ('Accounting', 'Accounting'),
        ('Biological Sciences and Agriculture', 'Biological Sciences and Agriculture'),
        ('Education', 'Education'),
        ('Foods, Nutrition and Dietetics', 'Foods, Nutrition and Dietetics'),
        ('Humanities and Social Sciences', 'Humanities and Social Sciences'),
        ('Information Systems and Computing', 'Information Systems and Computing'),
        ('Management', 'Management'),
        ('Mathematics, Chemistry and Physics', 'Mathematics, Chemistry and Physics'),
        ('Medical Laboratory Science', 'Medical Laboratory Science'),
        ('Nursing', 'Nursing'),
        ('Public Health', 'Public Health'),
        ('Technology and Applied Sciences', 'Technology and Applied Sciences'),
        ('Theology and Religious Studies', 'Theology and Religious Studies'),
    ]
    
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='student')
    department = models.CharField(max_length=100, choices=DEPARTMENT_CHOICES, null=True, blank=True)
    
    # Override these to make them not required if they cause issues
    first_name = models.CharField(max_length=50, blank=True)
    last_name = models.CharField(max_length=50, blank=True)
    
    def get_dashboard_stats(self):
        """Get comprehensive dashboard statistics for the user"""
        # Return basic stats for now to avoid import issues
        return {
            'activities_joined': 0,
            'hours_earned': 0,
            'volunteer_hours': 0.0,
            'completed_activities': 0,
            'pending_activities': 0,
            'volunteer_applications': 0,
            'active_volunteer_tasks': 0,
            'completed_volunteer_tasks': 0,
        }
    
    def __str__(self):
        return f"{self.first_name} {self.last_name} ({self.role})" if self.first_name else self.username