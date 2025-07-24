# attendance/serializers.py - COMPLETE ENHANCED VERSION
from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta
import json

from .models import Attendance, ActivityQRCode, QRScanLog
from accounts.serializers import UserProfileSerializer
from activities.serializers import ActivityListSerializer
from activities.models import Activity

User = get_user_model()

class AttendanceSerializer(serializers.ModelSerializer):
    student = UserProfileSerializer(read_only=True)
    verified_by = UserProfileSerializer(read_only=True)
    student_name = serializers.CharField(source='student_name', read_only=True)
    is_qr_checkin = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = Attendance
        fields = [
            'id', 'activity', 'student', 'student_name', 'checked_in_at',
            'verified_by', 'verification_method', 'qr_code', 'qr_scanned_at',
            'latitude', 'longitude', 'is_qr_checkin'
        ]
        read_only_fields = ['id', 'checked_in_at', 'qr_scanned_at']

class AttendanceListSerializer(serializers.ModelSerializer):
    student_name = serializers.CharField(source='student.get_full_name', read_only=True)
    student_id = serializers.IntegerField(source='student.id', read_only=True)
    student_username = serializers.CharField(source='student.username', read_only=True)
    verification_method_display = serializers.CharField(source='get_verification_method_display', read_only=True)
    qr_session_id = serializers.CharField(source='qr_code.session_id', read_only=True, allow_null=True)
    
    class Meta:
        model = Attendance
        fields = [
            'id', 'student_id', 'student_name', 'student_username', 
            'checked_in_at', 'verification_method', 'verification_method_display',
            'qr_scanned_at', 'qr_session_id'
        ]

class ActivityQRCodeSerializer(serializers.ModelSerializer):
    activity_title = serializers.CharField(source='activity.title', read_only=True)
    activity_location = serializers.CharField(source='activity.location', read_only=True)
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)
    is_expired = serializers.BooleanField(read_only=True)
    is_valid = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = ActivityQRCode
        fields = [
            'id', 'activity', 'activity_title', 'activity_location', 'code',
            'created_at', 'expires_at', 'is_active', 'is_expired', 'is_valid',
            'created_by', 'created_by_name', 'session_id', 'max_uses', 
            'current_uses', 'qr_data'
        ]
        read_only_fields = ['id', 'code', 'created_at', 'session_id', 'current_uses', 'qr_data']

class QRScanLogSerializer(serializers.ModelSerializer):
    student_name = serializers.CharField(source='student.get_full_name', read_only=True)
    activity_title = serializers.CharField(source='activity.title', read_only=True)
    attendance_id = serializers.IntegerField(source='attendance.id', read_only=True, allow_null=True)
    
    class Meta:
        model = QRScanLog
        fields = [
            'id', 'qr_code', 'student', 'student_name', 'activity', 'activity_title',
            'scanned_at', 'success', 'error_message', 'ip_address', 'attendance_id'
        ]
        read_only_fields = ['id', 'scanned_at']

class QRCheckInSerializer(serializers.Serializer):
    qr_code = serializers.UUIDField()
    student_id = serializers.IntegerField()
    latitude = serializers.DecimalField(max_digits=10, decimal_places=8, required=False, allow_null=True)
    longitude = serializers.DecimalField(max_digits=11, decimal_places=8, required=False, allow_null=True)

class QRCheckinRequestSerializer(serializers.Serializer):
    """Enhanced QR check-in request serializer"""
    qr_data = serializers.JSONField(help_text="QR code data as JSON")
    latitude = serializers.DecimalField(max_digits=10, decimal_places=8, required=False)
    longitude = serializers.DecimalField(max_digits=11, decimal_places=8, required=False)
    
    def validate_qr_data(self, value):
        """Validate QR code data structure"""
        if not isinstance(value, dict):
            raise serializers.ValidationError("QR data must be a JSON object")
        
        required_fields = ['type', 'activity_id', 'session_id', 'timestamp']
        for field in required_fields:
            if field not in value:
                raise serializers.ValidationError(f"Missing required field: {field}")
        
        if value['type'] != 'activity_checkin':
            raise serializers.ValidationError("Invalid QR code type")
        
        return value
    
    def validate(self, attrs):
        """Validate the entire QR check-in request"""
        qr_data = attrs['qr_data']
        
        # Check if activity exists
        try:
            activity = Activity.objects.get(id=qr_data['activity_id'])
        except Activity.DoesNotExist:
            raise serializers.ValidationError("Activity not found")
        
        # Check if QR code exists and is valid
        try:
            qr_code = ActivityQRCode.objects.get(
                session_id=qr_data['session_id'],
                activity=activity,
                is_active=True
            )
        except ActivityQRCode.DoesNotExist:
            raise serializers.ValidationError("Invalid or expired QR code")
        
        if not qr_code.is_valid:
            raise serializers.ValidationError("QR code is no longer valid")
        
        # Check if check-in is allowed for this activity (using helper function)
        if hasattr(activity, 'is_qr_checkin_allowed') and not activity.is_qr_checkin_allowed():
            raise serializers.ValidationError("Check-in is not currently allowed for this activity")
        
        attrs['activity'] = activity
        attrs['qr_code'] = qr_code
        return attrs

class QRCheckinResponseSerializer(serializers.Serializer):
    """Serializer for QR check-in responses"""
    success = serializers.BooleanField()
    message = serializers.CharField()
    activity_id = serializers.IntegerField()
    activity_title = serializers.CharField()
    attendance_id = serializers.IntegerField(required=False)
    checked_in_at = serializers.DateTimeField(required=False)
    
    # Error details (if success is False)
    error_code = serializers.CharField(required=False)
    error_details = serializers.DictField(required=False)

class QRGenerateRequestSerializer(serializers.Serializer):
    """Serializer for QR code generation requests"""
    expires_in_hours = serializers.IntegerField(
        default=2, 
        min_value=1, 
        max_value=24,
        help_text="Hours until QR code expires"
    )
    max_uses = serializers.IntegerField(
        required=False, 
        min_value=1,
        help_text="Maximum number of times QR can be scanned"
    )
    
    def validate_expires_in_hours(self, value):
        """Validate expiration time"""
        if value < 1 or value > 24:
            raise serializers.ValidationError("Expiration must be between 1 and 24 hours")
        return value

class ActivityWithQRSerializer(serializers.ModelSerializer):
    """Activity serializer with QR code information"""
    active_qr_code = ActivityQRCodeSerializer(source='get_active_qr_code', read_only=True)
    can_generate_qr = serializers.SerializerMethodField()
    is_qr_checkin_allowed = serializers.SerializerMethodField()
    total_attendees = serializers.SerializerMethodField()
    qr_checkins = serializers.SerializerMethodField()
    manual_checkins = serializers.SerializerMethodField()
    
    class Meta:
        model = Activity
        fields = [
            'id', 'title', 'location', 'start_time', 'end_time', 'status',
            'active_qr_code', 'can_generate_qr', 'is_qr_checkin_allowed',
            'total_attendees', 'qr_checkins', 'manual_checkins'
        ]
    
    def get_can_generate_qr(self, obj):
        """Check if QR code can be generated for this activity"""
        return hasattr(obj, 'can_generate_qr') and obj.can_generate_qr()
    
    def get_is_qr_checkin_allowed(self, obj):
        """Check if QR check-in is currently allowed"""
        return hasattr(obj, 'is_qr_checkin_allowed') and obj.is_qr_checkin_allowed()
    
    def get_total_attendees(self, obj):
        """Get total number of attendees"""
        return obj.attendances.count()
    
    def get_qr_checkins(self, obj):
        """Get number of QR check-ins"""
        return obj.attendances.filter(verification_method='qr_code').count()
    
    def get_manual_checkins(self, obj):
        """Get number of manual check-ins"""
        return obj.attendances.filter(verification_method='manual').count()

class AttendanceWithQRDetailSerializer(serializers.ModelSerializer):
    """Enhanced Attendance serializer with detailed QR information"""
    student = UserProfileSerializer(read_only=True)
    verified_by = UserProfileSerializer(read_only=True)
    activity_title = serializers.CharField(source='activity.title', read_only=True)
    qr_code_info = ActivityQRCodeSerializer(source='qr_code', read_only=True)
    scan_logs = QRScanLogSerializer(many=True, read_only=True)
    
    class Meta:
        model = Attendance
        fields = [
            'id', 'activity', 'activity_title', 'student', 'checked_in_at',
            'verified_by', 'verification_method', 'qr_scanned_at',
            'latitude', 'longitude', 'ip_address', 'qr_code_info', 'scan_logs'
        ]
        read_only_fields = ['id', 'checked_in_at', 'qr_scanned_at']

class QRAnalyticsSerializer(serializers.Serializer):
    """Serializer for QR analytics data"""
    activity_id = serializers.IntegerField()
    activity_title = serializers.CharField()
    total_qr_codes_generated = serializers.IntegerField()
    active_qr_codes = serializers.IntegerField()
    total_scans = serializers.IntegerField()
    successful_scans = serializers.IntegerField()
    failed_scans = serializers.IntegerField()
    unique_scanners = serializers.IntegerField()
    scan_success_rate = serializers.FloatField()
    total_attendees = serializers.IntegerField()
    qr_checkins = serializers.IntegerField()
    manual_checkins = serializers.IntegerField()

class ManualAttendanceSerializer(serializers.Serializer):
    """Serializer for manual attendance marking"""
    student_id = serializers.IntegerField()
    notes = serializers.CharField(max_length=500, required=False, allow_blank=True)
    
    def validate_student_id(self, value):
        """Validate that student exists and has student role"""
        try:
            user = User.objects.get(id=value)
            if not hasattr(user, 'role') or user.role != 'student':
                raise serializers.ValidationError("User must be a student")
            return value
        except User.DoesNotExist:
            raise serializers.ValidationError("Student not found")