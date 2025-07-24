# backend/attendance/views.py - Simplified for existing models
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db import transaction
from django.utils import timezone
import logging

from activities.models import Activity, Enrollment, Attendance
from accounts.models import User

logger = logging.getLogger(__name__)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_attendance(request):
    """Mark attendance via QR code scan"""
    # Only students can check in via QR
    if request.user.role != 'student':
        return Response({
            'success': False,
            'error': 'Only students can check in via QR code'
        }, status=status.HTTP_403_FORBIDDEN)
    
    # Get data from request
    activity_id = request.data.get('activity_id')
    qr_code = request.data.get('qr_code')
    
    if not activity_id or not qr_code:
        return Response({
            'success': False,
            'error': 'Activity ID and QR code are required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        activity_id = int(activity_id)
    except (ValueError, TypeError):
        return Response({
            'success': False,
            'error': 'Invalid activity ID'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Get the activity
    try:
        activity = Activity.objects.get(id=activity_id)
    except Activity.DoesNotExist:
        return Response({
            'success': False,
            'error': 'Activity not found'
        }, status=status.HTTP_404_NOT_FOUND)
    
    # Verify QR code matches activity
    if not activity.qr_code or activity.qr_code != qr_code:
        return Response({
            'success': False,
            'error': 'Invalid QR code for this activity'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Check if user is enrolled in this activity
    enrollment = Enrollment.objects.filter(
        user=request.user,
        activity=activity,
        status='enrolled'
    ).first()
    
    if not enrollment:
        return Response({
            'success': False,
            'error': 'You are not enrolled in this activity'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        with transaction.atomic():
            # Check if already marked attendance
            existing_attendance = Attendance.objects.filter(
                user=request.user,
                activity=activity
            ).first()
            
            if existing_attendance:
                return Response({
                    'success': False,
                    'error': 'Attendance already marked for this activity'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Create attendance record
            attendance = Attendance.objects.create(
                user=request.user,
                activity=activity,
                status='present',
                timestamp=timezone.now(),
                qr_code_used=qr_code
            )
            
            # Update enrollment status to completed
            enrollment.status = 'completed'
            enrollment.save()
            enrollment.award_points()
            
            return Response({
                'success': True,
                'message': f'Attendance marked successfully for {activity.title}',
                'attendance_id': attendance.id,
                'checked_in_at': attendance.timestamp,
                'activity': {
                    'id': activity.id,
                    'title': activity.title,
                    'location': activity.location,
                    'start_time': activity.start_time
                }
            }, status=status.HTTP_201_CREATED)
            
    except Exception as e:
        logger.error(f"Attendance marking error: {str(e)}")
        return Response({
            'success': False,
            'error': 'Failed to mark attendance. Please try again.'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_attendance_manual(request, activity_id):
    """Manual attendance marking by instructors/coordinators"""
    # Check permissions
    if request.user.role not in ['instructor', 'coordinator', 'admin']:
        return Response({
            'error': 'Only instructors, coordinators, and admins can mark attendance manually'
        }, status=status.HTTP_403_FORBIDDEN)
    
    activity = get_object_or_404(Activity, id=activity_id)
    student_id = request.data.get('student_id')
    notes = request.data.get('notes', '')
    
    if not student_id:
        return Response({
            'error': 'Student ID is required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        student = User.objects.get(id=student_id, role='student')
    except User.DoesNotExist:
        return Response({
            'error': 'Student not found'
        }, status=status.HTTP_404_NOT_FOUND)
    
    # Check if student is enrolled
    enrollment = Enrollment.objects.filter(
        user=student,
        activity=activity,
        status='enrolled'
    ).first()
    
    if not enrollment:
        return Response({
            'error': 'Student is not enrolled in this activity'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        with transaction.atomic():
            # Check if already attended
            attendance, created = Attendance.objects.get_or_create(
                activity=activity,
                user=student,
                defaults={
                    'status': 'present',
                    'marked_by': request.user,
                    'timestamp': timezone.now(),
                    'notes': notes
                }
            )
            
            if not created:
                return Response({
                    'error': 'Student attendance already marked'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Update enrollment
            enrollment.status = 'completed'
            enrollment.save()
            enrollment.award_points()
            
            return Response({
                'success': True,
                'message': f'Successfully marked attendance for {student.get_full_name() or student.username}',
                'attendance': {
                    'id': attendance.id,
                    'student_name': student.get_full_name() or student.username,
                    'marked_at': attendance.timestamp,
                    'marked_by': request.user.get_full_name() or request.user.username
                }
            }, status=status.HTTP_201_CREATED)
            
    except Exception as e:
        logger.error(f"Manual attendance error: {str(e)}")
        return Response({
            'error': 'Failed to mark attendance'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_activity_attendance(request, activity_id):
    """Get all attendance records for an activity"""
    # Check permissions
    if request.user.role not in ['instructor', 'coordinator', 'admin']:
        return Response({
            'error': 'Only instructors, coordinators, and admins can view attendance'
        }, status=status.HTTP_403_FORBIDDEN)
    
    activity = get_object_or_404(Activity, id=activity_id)
    attendances = Attendance.objects.filter(activity=activity).select_related('user', 'marked_by')
    
    attendance_data = []
    for attendance in attendances:
        attendance_data.append({
            'id': attendance.id,
            'student': {
                'id': attendance.user.id,
                'name': attendance.user.get_full_name() or attendance.user.username,
                'email': attendance.user.email,
                'department': getattr(attendance.user, 'department', 'N/A')
            },
            'status': attendance.status,
            'timestamp': attendance.timestamp,
            'marked_by': attendance.marked_by.get_full_name() if attendance.marked_by else 'QR Code',
            'verification_method': 'QR Code' if attendance.qr_code_used else 'Manual',
            'notes': attendance.notes or ''
        })
    
    # Calculate statistics
    total_enrolled = Enrollment.objects.filter(activity=activity, status__in=['enrolled', 'completed']).count()
    total_attended = attendances.count()
    attendance_rate = (total_attended / total_enrolled * 100) if total_enrolled > 0 else 0
    
    return Response({
        'activity': {
            'id': activity.id,
            'title': activity.title,
            'start_time': activity.start_time,
            'location': activity.location
        },
        'statistics': {
            'total_enrolled': total_enrolled,
            'total_attended': total_attended,
            'attendance_rate': round(attendance_rate, 2),
            'qr_checkins': attendances.filter(qr_code_used__isnull=False).count(),
            'manual_checkins': attendances.filter(marked_by__isnull=False).count()
        },
        'attendances': attendance_data
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_student_attendance(request):
    """Get current user's attendance records"""
    if request.user.role != 'student':
        return Response({
            'error': 'Only students can view their attendance'
        }, status=status.HTTP_403_FORBIDDEN)
    
    attendances = Attendance.objects.filter(user=request.user).select_related('activity')
    
    attendance_data = []
    for attendance in attendances:
        attendance_data.append({
            'id': attendance.id,
            'activity': {
                'id': attendance.activity.id,
                'title': attendance.activity.title,
                'start_time': attendance.activity.start_time,
                'location': attendance.activity.location,
                'is_volunteering': attendance.activity.is_volunteering
            },
            'status': attendance.status,
            'timestamp': attendance.timestamp,
            'verification_method': 'QR Code' if attendance.qr_code_used else 'Manual'
        })
    
    return Response({
        'total_attendances': len(attendance_data),
        'attendances': attendance_data
    })

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def generate_qr_code(request, activity_id):
    """Generate or regenerate QR code for an activity"""
    # Check permissions
    if request.user.role not in ['coordinator', 'admin']:
        return Response({
            'error': 'Only coordinators and admins can generate QR codes'
        }, status=status.HTTP_403_FORBIDDEN)
    
    activity = get_object_or_404(Activity, id=activity_id)
    
    # Check if user can edit this activity
    if not activity.can_edit(request.user):
        return Response({
            'error': 'You do not have permission to edit this activity'
        }, status=status.HTTP_403_FORBIDDEN)
    
    try:
        # Generate new QR code if not exists
        if not activity.qr_code:
            activity.save()  # This will auto-generate QR code
        
        return Response({
            'success': True,
            'message': 'QR code generated successfully',
            'qr_data': activity.generate_qr_code_data(),
            'activity': {
                'id': activity.id,
                'title': activity.title,
                'qr_code': activity.qr_code
            }
        })
        
    except Exception as e:
        logger.error(f"QR code generation error: {str(e)}")
        return Response({
            'error': 'Failed to generate QR code'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_qr_code(request, activity_id):
    """Get QR code for an activity"""
    # Check permissions
    if request.user.role not in ['instructor', 'coordinator', 'admin']:
        return Response({
            'error': 'Permission denied'
        }, status=status.HTTP_403_FORBIDDEN)
    
    activity = get_object_or_404(Activity, id=activity_id)
    
    if not activity.qr_code:
        return Response({
            'error': 'No QR code found for this activity'
        }, status=status.HTTP_404_NOT_FOUND)
    
    return Response({
        'activity_id': activity.id,
        'activity_title': activity.title,
        'qr_code': activity.qr_code,
        'qr_data': activity.generate_qr_code_data()
    })