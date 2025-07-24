# backend/activities/serializers.py - FINAL FIX
from rest_framework import serializers
from .models import Activity, Enrollment

class ActivitySerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)
    enrolled_count = serializers.SerializerMethodField()  # Use SerializerMethodField instead
    enrollment_count = serializers.SerializerMethodField()  # For compatibility
    is_enrolled = serializers.SerializerMethodField()
    
    class Meta:
        model = Activity
        fields = [
            'id',
            'title', 
            'description',
            'location',
            'start_time',
            'end_time', 
            'created_by',
            'created_by_name',
            'created_at',
            'is_volunteering',
            'status',
            'enrolled_count',
            'enrollment_count',  # Both fields for compatibility
            'is_enrolled'
        ]
        read_only_fields = ['id', 'created_at', 'created_by_name', 'enrolled_count', 'enrollment_count', 'is_enrolled']
    
    def get_enrolled_count(self, obj):
        """Get the number of users enrolled in this activity"""
        return obj.enrollment_count  # Use the model property
    
    def get_enrollment_count(self, obj):
        """Get the number of users enrolled in this activity (compatibility)"""
        return obj.enrollment_count  # Use the model property
    
    def get_is_enrolled(self, obj):
        """Check if the current user is enrolled in this activity"""
        request = self.context.get('request')
        if request and hasattr(request, 'user') and request.user.is_authenticated:
            return Enrollment.objects.filter(
                user=request.user,
                activity=obj,
                status__in=['enrolled', 'completed']
            ).exists()
        return False