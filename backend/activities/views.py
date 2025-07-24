# backend/activities/views.py - COMPLETE FIXED VERSION WITH ALL MISSING FUNCTIONS
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.permissions import AllowAny
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response
from rest_framework import status
from django.http import JsonResponse
from django.shortcuts import get_object_or_404
from django.db.models import Count, Sum, Avg, Q
from datetime import datetime, timedelta
from django.utils import timezone
from django.core.exceptions import ValidationError
from django.contrib.auth import get_user_model
import json
from .models import (
    Activity, Enrollment, Attendance, VolunteerApplication, 
    VolunteerOpportunity, Notification, ActivityCategory
)

# Get the User model
User = get_user_model()

# Health check endpoint
@api_view(['GET'])
@permission_classes([AllowAny])
def health_check(request):
    """Simple health check endpoint"""
    return Response({'status': 'healthy', 'message': 'Activities API is running'})

# =======================================
# STUDENT DASHBOARD ENDPOINTS - FIXED FOR PERSISTENCE
# =======================================

@api_view(['GET'])
@permission_classes([AllowAny])
def get_student_enrolled_activities(request):
    """Get user's enrolled activities - FIXED FOR PERSISTENCE"""
    try:
        user_id = request.GET.get('user_id')
        
        if not user_id:
            return Response({'error': 'User ID required'}, status=status.HTTP_400_BAD_REQUEST)
        
        user = get_object_or_404(User, id=user_id)
        
        # Get ALL enrollments for this user that are still active
        enrollments = Enrollment.objects.filter(
            user=user,
            status__in=['enrolled', 'completed']  # Include both enrolled and completed
        ).select_related('activity').order_by('-enrolled_at')
        
        enrolled_activities = []
        for enrollment in enrollments:
            activity = enrollment.activity
            
            # Check if user is currently enrolled
            is_enrolled = enrollment.status == 'enrolled'
            
            activity_data = {
                'id': activity.id,
                'title': activity.title,
                'description': activity.description,
                'location': activity.location,
                'start_time': activity.start_time.isoformat(),
                'end_time': activity.end_time.isoformat(),
                'is_volunteering': activity.is_volunteering,
                'status': activity.status,
                'enrollment_status': enrollment.status,
                'enrolled_at': enrollment.enrolled_at.isoformat(),
                'is_enrolled': is_enrolled,
                'can_withdraw': is_enrolled and activity.start_time > timezone.now(),
                'is_past': activity.end_time < timezone.now(),
            }
            enrolled_activities.append(activity_data)
        
        return Response({
            'enrolled_activities': enrolled_activities,
            'total_count': len(enrolled_activities)
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_student_recent_activities(request):
    """Get user's recent activities (past activities they were enrolled in) - FIXED"""
    try:
        user_id = request.GET.get('user_id')
        
        if not user_id:
            return Response({'error': 'User ID required'}, status=status.HTTP_400_BAD_REQUEST)
        
        user = get_object_or_404(User, id=user_id)
        
        # Get activities that have ended and user was enrolled in
        now = timezone.now()
        recent_enrollments = Enrollment.objects.filter(
            user=user,
            activity__end_time__lt=now,  # Activity has ended
            status__in=['enrolled', 'completed']
        ).select_related('activity').order_by('-activity__end_time')[:10]
        
        recent_activities = []
        for enrollment in recent_enrollments:
            activity = enrollment.activity
            
            # Check if user attended
            attendance = Attendance.objects.filter(
                user=user,
                activity=activity
            ).first()
            
            activity_data = {
                'id': activity.id,
                'title': activity.title,
                'description': activity.description,
                'location': activity.location,
                'start_time': activity.start_time.isoformat(),
                'end_time': activity.end_time.isoformat(),
                'is_volunteering': activity.is_volunteering,
                'status': 'completed',
                'enrollment_status': enrollment.status,
                'enrolled_at': enrollment.enrolled_at.isoformat(),
                'attendance_status': attendance.status if attendance else 'not_marked',
                'was_present': attendance.status == 'present' if attendance else False,
            }
            recent_activities.append(activity_data)
        
        return Response({
            'recent_activities': recent_activities,
            'total_count': len(recent_activities)
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_student_volunteer_applications(request):
    """Get user's volunteer applications - FIXED FOR PERSISTENCE"""
    try:
        user_id = request.GET.get('user_id')
        
        if not user_id:
            return Response({'error': 'User ID required'}, status=status.HTTP_400_BAD_REQUEST)
        
        user = get_object_or_404(User, id=user_id)
        
        # Get ALL volunteer applications for this user
        applications = VolunteerApplication.objects.filter(
            user=user
        ).select_related('opportunity').order_by('-submitted_at')
        
        applications_data = []
        for app in applications:
            app_data = {
                'id': app.id,
                'opportunity_title': app.opportunity.title,
                'opportunity_description': app.opportunity.description,
                'status': app.status,
                'hours_completed': float(app.hours_completed),
                'submitted_at': app.submitted_at.isoformat(),
                'approved_by': app.approved_by.get_full_name() if app.approved_by else None,
                'coordinator_name': app.opportunity.coordinator.get_full_name() if app.opportunity.coordinator else 'Unknown',
                'time_commitment': app.opportunity.time_commitment,
                'start_date': app.opportunity.start_date.isoformat(),
                'end_date': app.opportunity.end_date.isoformat() if app.opportunity.end_date else None,
            }
            applications_data.append(app_data)
        
        return Response({
            'volunteer_applications': applications_data,
            'total_count': len(applications_data)
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_activities_with_enrollment_status(request):
    """Get all activities with user's enrollment status - FIXED VOLUNTEERING"""
    try:
        user_id = request.GET.get('user_id')
        
        # Get ALL activities
        activities = Activity.objects.all().order_by('-start_time')
        
        activities_data = []
        for activity in activities:
            # Calculate actual enrollment count
            enrollment_count = Enrollment.objects.filter(
                activity=activity,
                status='enrolled'
            ).count()
            
            # Check if specific user is enrolled (if user_id provided)
            is_enrolled = False
            enrollment_status = None
            if user_id:
                try:
                    user = User.objects.get(id=user_id)
                    enrollment = Enrollment.objects.filter(
                        user=user,
                        activity=activity,
                        status__in=['enrolled', 'completed']
                    ).first()
                    
                    if enrollment:
                        is_enrolled = True
                        enrollment_status = enrollment.status
                except User.DoesNotExist:
                    pass
            
            # Calculate dynamic status based on current time
            now = timezone.now()
            if activity.start_time > now:
                dynamic_status = 'upcoming'
            elif activity.start_time <= now <= activity.end_time:
                dynamic_status = 'ongoing'
            else:
                dynamic_status = 'completed'
            
            # FIXED: Ensure is_volunteering is properly sent
            activity_data = {
                'id': activity.id,
                'title': activity.title,
                'description': activity.description,
                'location': activity.location,
                'start_time': activity.start_time.isoformat(),
                'end_time': activity.end_time.isoformat(),
                'created_by': activity.created_by.id if activity.created_by else None,
                'created_by_name': activity.created_by.get_full_name() if activity.created_by else 'Coordinator',
                'created_at': activity.created_at.isoformat(),
                
                # CRITICAL: Make sure is_volunteering is explicitly sent as boolean
                'is_volunteering': bool(activity.is_volunteering),  # Ensure it's a boolean
                
                'status': dynamic_status,
                'enrolled_count': enrollment_count,
                'enrollment_count': enrollment_count,  # For compatibility
                'is_enrolled': is_enrolled,
                'enrollment_status': enrollment_status,
                'can_enroll': not is_enrolled and activity.start_time > now,
                'is_past': activity.start_time < now,
                'max_participants': getattr(activity, 'max_participants', 50),
                'available_spots': getattr(activity, 'max_participants', 50) - enrollment_count,
            }
            activities_data.append(activity_data)
        
        # DEBUG: Print sample activities to check volunteering status
        print(f"🔍 BACKEND DEBUG: Returning {len(activities_data)} activities")
        for i, activity in enumerate(activities_data[:3]):
            print(f"Activity {i}: {activity['title']}")
            print(f"  - is_volunteering: {activity['is_volunteering']} (type: {type(activity['is_volunteering'])})")
        
        return Response({
            'success': True,
            'data': activities_data,
            'total_count': len(activities_data)
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
@api_view(['GET'])
@permission_classes([AllowAny])
def get_student_dashboard_data(request):
    """Get complete student dashboard data in one call - FIXED FOR PERSISTENCE"""
    try:
        user_id = request.GET.get('user_id')
        
        if not user_id:
            return Response({'error': 'User ID required'}, status=status.HTTP_400_BAD_REQUEST)
        
        user = get_object_or_404(User, id=user_id)
        
        # Get enrolled activities
        enrolled_enrollments = Enrollment.objects.filter(
            user=user,
            status__in=['enrolled', 'completed']
        ).select_related('activity')
        
        enrolled_activities = []
        for enrollment in enrolled_enrollments:
            activity = enrollment.activity
            enrolled_activities.append({
                'id': activity.id,
                'title': activity.title,
                'start_time': activity.start_time.isoformat(),
                'status': activity.status,
                'enrollment_status': enrollment.status,
                'is_past': activity.end_time < timezone.now(),
            })
        
        # Get recent activities (past activities user was enrolled in)
        now = timezone.now()
        recent_enrollments = Enrollment.objects.filter(
            user=user,
            activity__end_time__lt=now,
            status__in=['enrolled', 'completed']
        ).select_related('activity').order_by('-activity__end_time')[:5]
        
        recent_activities = []
        for enrollment in recent_enrollments:
            activity = enrollment.activity
            recent_activities.append({
                'id': activity.id,
                'title': activity.title,
                'end_time': activity.end_time.isoformat(),
                'enrollment_status': enrollment.status,
            })
        
        # Get volunteer applications
        volunteer_applications = VolunteerApplication.objects.filter(
            user=user
        ).select_related('opportunity')[:5]
        
        applications_data = []
        for app in volunteer_applications:
            applications_data.append({
                'id': app.id,
                'opportunity_title': app.opportunity.title,
                'status': app.status,
                'hours_completed': float(app.hours_completed),
                'submitted_at': app.submitted_at.isoformat(),
            })
        
        # Calculate statistics
        total_enrollments = enrolled_enrollments.count()
        completed_activities = enrolled_enrollments.filter(status='completed').count()
        volunteer_hours = volunteer_applications.aggregate(
            total=Sum('hours_completed')
        )['total'] or 0.0
        
        dashboard_data = {
            'user_info': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'role': user.role,
                'department': user.department,
            },
            'statistics': {
                'activities_joined': total_enrollments,
                'completed_activities': completed_activities,
                'volunteer_hours': float(volunteer_hours),
                'volunteer_applications': volunteer_applications.count(),
            },
            'enrolled_activities': enrolled_activities,
            'recent_activities': recent_activities,
            'volunteer_applications': applications_data,
        }
        
        return Response(dashboard_data)
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# =======================================
# FIXED ENROLLMENT ENDPOINT
# =======================================

@api_view(['POST', 'DELETE'])
@permission_classes([AllowAny])
def enroll_in_activity_fixed(request, activity_id):
    """FIXED enrollment endpoint with proper persistence"""
    try:
        activity = get_object_or_404(Activity, id=activity_id)
        user_id = request.data.get('user_id')
        
        if not user_id:
            return Response({'error': 'User ID required'}, status=status.HTTP_400_BAD_REQUEST)
            
        user = get_object_or_404(User, id=user_id)
        
        if request.method == 'POST':
            # Check if activity is in the past
            if activity.start_time < timezone.now():
                return Response({
                    'success': False,
                    'error': 'Cannot enroll in past activity'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Check if already enrolled
            existing_enrollment = Enrollment.objects.filter(
                user=user,
                activity=activity,
                status__in=['enrolled', 'completed']
            ).first()
            
            if existing_enrollment:
                return Response({
                    'success': False,
                    'error': 'Already enrolled in this activity',
                    'enrollment_id': existing_enrollment.id,
                    'enrollment_status': existing_enrollment.status
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Create new enrollment
            enrollment = Enrollment.objects.create(
                user=user,
                activity=activity,
                status='enrolled'
            )
            
            # Create notification
            Notification.objects.create(
                user=user,
                title="Activity Enrollment Confirmed",
                message=f"You have successfully enrolled in '{activity.title}'",
                notification_type='activity',
                related_activity=activity
            )
            
            # Get updated count
            updated_count = Enrollment.objects.filter(
                activity=activity, 
                status='enrolled'
            ).count()
            
            return Response({
                'success': True,
                'message': f'Successfully enrolled in {activity.title}',
                'enrollment_id': enrollment.id,
                'enrollment_count': updated_count,
                'activity_id': activity.id,
                'user_enrolled': True
            })
                
        elif request.method == 'DELETE':
            # Find enrollment
            enrollment = Enrollment.objects.filter(
                user=user, 
                activity=activity, 
                status='enrolled'  # Only withdraw from currently enrolled
            ).first()
            
            if enrollment:
                enrollment.status = 'withdrawn'
                enrollment.save()
                
                # Get updated count
                updated_count = Enrollment.objects.filter(
                    activity=activity, 
                    status='enrolled'
                ).count()
                
                return Response({
                    'success': True,
                    'message': f'Successfully withdrew from {activity.title}',
                    'enrollment_count': updated_count,
                    'activity_id': activity.id,
                    'user_enrolled': False
                })
            else:
                return Response({
                    'success': False,
                    'error': 'Not currently enrolled in this activity'
                }, status=status.HTTP_400_BAD_REQUEST)
                
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# Replace ONLY the coordinator section in your backend/activities/views.py

# =======================================
# COORDINATOR ENDPOINTS - FINAL VERSION
# =======================================

@api_view(['GET'])
@permission_classes([AllowAny])
def get_coordinator_stats(request):
    """Get coordinator dashboard statistics from database"""
    try:
        coordinator_id = request.GET.get('coordinator_id')
        
        if coordinator_id:
            coordinator = get_object_or_404(User, id=coordinator_id)
            activities_filter = Q(created_by=coordinator)
        else:
            activities_filter = Q()
        
        now = timezone.now()
        start_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        
        my_activities = Activity.objects.filter(activities_filter).count()
        
        total_enrollments = Enrollment.objects.filter(
            activity__in=Activity.objects.filter(activities_filter),
            status__in=['enrolled', 'completed']
        ).count()
        
        this_month_activities = Activity.objects.filter(
            activities_filter,
            created_at__gte=start_of_month
        ).count()
        
        active_volunteers = VolunteerApplication.objects.filter(
            opportunity__activity__in=Activity.objects.filter(activities_filter, is_volunteering=True),
            status__in=['active', 'approved']
        ).count()
        
        pending_activities = Activity.objects.filter(activities_filter, status='draft').count()
        
        stats = {
            'my_activities': my_activities,
            'total_enrollments': total_enrollments,
            'this_month_activities': this_month_activities,
            'active_volunteers': active_volunteers,
            'pending_activities': pending_activities,
        }
        return Response(stats)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_coordinator_activities(request):
    """🔧 FINAL: Get all activities created by coordinator from database"""
    try:
        coordinator_id = request.GET.get('coordinator_id')
        
        if coordinator_id:
            coordinator = get_object_or_404(User, id=coordinator_id)
            activities = Activity.objects.filter(created_by=coordinator)
        else:
            activities = Activity.objects.all()
        
        # 🔧 FINAL FIX: Use different field name to avoid property conflict
        activities = activities.annotate(
            enrolled_participants=Count('activity_enrollments', filter=Q(activity_enrollments__status='enrolled'))
        ).order_by('-created_at')
        
        activities_data = []
        for activity in activities:
            # Calculate dynamic status
            now = timezone.now()
            if activity.start_time > now:
                dynamic_status = 'upcoming'
            elif activity.start_time <= now <= activity.end_time:
                dynamic_status = 'ongoing'
            else:
                dynamic_status = 'completed'
            
            activity_data = {
                'id': activity.id,
                'title': activity.title,
                'description': activity.description,
                'location': activity.location,
                'start_time': activity.start_time.isoformat(),
                'end_time': activity.end_time.isoformat(),
                'created_by': activity.created_by.id if activity.created_by else None,
                'created_by_name': activity.created_by.get_full_name() if activity.created_by else 'Unknown',
                'created_at': activity.created_at.isoformat(),
                'is_volunteering': activity.is_volunteering,
                'status': dynamic_status,
                'enrolled_count': activity.enrolled_participants,
                'enrollment_count': activity.enrolled_participants,  # For compatibility
            }
            activities_data.append(activity_data)
        
        return Response(activities_data)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_activity_reports(request):
    """Get comprehensive activity reports from database"""
    try:
        coordinator_id = request.GET.get('coordinator_id')
        
        if coordinator_id:
            activities = Activity.objects.filter(created_by_id=coordinator_id)
        else:
            activities = Activity.objects.all()
        
        total_activities = activities.count()
        total_participants = Enrollment.objects.filter(
            activity__in=activities,
            status__in=['enrolled', 'completed']
        ).count()
        
        # Calculate status breakdown with dynamic status
        now = timezone.now()
        upcoming_count = activities.filter(start_time__gt=now).count()
        ongoing_count = activities.filter(start_time__lte=now, end_time__gte=now).count()
        completed_count = activities.filter(end_time__lt=now).count()
        
        status_breakdown = [
            {'status': 'upcoming', 'count': upcoming_count},
            {'status': 'ongoing', 'count': ongoing_count},
            {'status': 'completed', 'count': completed_count},
        ]
        
        months_data = []
        for i in range(6):
            month_start = (now.replace(day=1) - timedelta(days=32*i)).replace(day=1)
            month_end = (month_start + timedelta(days=32)).replace(day=1) - timedelta(days=1)
            
            month_activities = activities.filter(
                created_at__gte=month_start,
                created_at__lte=month_end
            ).count()
            
            months_data.append({
                'month': month_start.strftime('%Y-%m'),
                'activities': month_activities
            })
        
        reports = {
            'overview': {
                'total_activities': total_activities,
                'total_participants': total_participants,
                'average_participants': total_participants / total_activities if total_activities > 0 else 0,
            },
            'status_breakdown': status_breakdown,
            'monthly_trend': list(reversed(months_data)),
        }
        
        return Response(reports)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([AllowAny])
def create_activity(request):
    """Create a new activity"""
    try:
        data = request.data
        
        activity = Activity.objects.create(
            title=data.get('title', ''),
            description=data.get('description', ''),
            location=data.get('location', ''),
            start_time=datetime.fromisoformat(data.get('start_time').replace('Z', '+00:00')),
            end_time=datetime.fromisoformat(data.get('end_time').replace('Z', '+00:00')),
            is_volunteering=data.get('is_volunteering', False),
            status='draft',
            created_by=request.user if hasattr(request, 'user') and request.user.is_authenticated else None,
        )
        
        return Response({
            'success': True,
            'message': 'Activity created successfully',
            'activity_id': activity.id
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT'])
@permission_classes([AllowAny])
def update_activity(request, activity_id):
    """Update an existing activity"""
    try:
        activity = get_object_or_404(Activity, id=activity_id)
        data = request.data
        
        if 'title' in data:
            activity.title = data['title']
        if 'description' in data:
            activity.description = data['description']
        if 'location' in data:
            activity.location = data['location']
        
        activity.save()
        
        return Response({
            'success': True,
            'message': 'Activity updated successfully'
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['DELETE'])
@permission_classes([AllowAny])
def delete_activity(request, activity_id):
    """Delete an activity"""
    try:
        activity = get_object_or_404(Activity, id=activity_id)
        
        enrollment_count = Enrollment.objects.filter(activity=activity, status='enrolled').count()
        if enrollment_count > 0:
            return Response({
                'error': f'Cannot delete activity with {enrollment_count} enrolled participants'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        activity_title = activity.title
        activity.delete()
        
        return Response({
            'success': True,
            'message': f'Activity "{activity_title}" deleted successfully'
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([AllowAny])
def publish_activity(request, activity_id):
    """Publish a draft activity"""
    try:
        activity = get_object_or_404(Activity, id=activity_id)
        
        if activity.status != 'draft':
            return Response({
                'error': 'Only draft activities can be published'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        activity.status = 'upcoming'
        activity.save()
        
        return Response({
            'success': True,
            'message': f'Activity "{activity.title}" published successfully'
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_activity_categories(request):
    """Get all activity categories from database"""
    try:
        categories = ActivityCategory.objects.all().order_by('name')
        categories_data = []
        
        for category in categories:
            categories_data.append({
                'id': category.id,
                'name': category.name,
                'description': category.description,
                'activity_count': Activity.objects.filter(category=category).count(),
            })
        
        return Response(categories_data)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# =======================================
# VOLUNTEERING ENDPOINTS
# =======================================

# REPLACE your get_volunteering_opportunities function in backend/activities/views.py

@api_view(['GET'])
@permission_classes([AllowAny])
def get_volunteering_opportunities(request):
    """
    Get volunteering opportunities with full activity details - ENHANCED VERSION
    """
    try:
        opportunities = VolunteerOpportunity.objects.filter(
            is_active=True
        ).select_related('activity', 'coordinator').order_by('-created_at')
        
        data = []
        for opp in opportunities:
            # Get linked activity details
            activity = opp.activity
            
            opportunity_data = {
                # Opportunity info
                'opportunity_id': opp.id,
                'title': opp.title,
                'description': opp.description,
                'requirements': opp.requirements,
                'time_commitment': opp.time_commitment,
                'start_date': opp.start_date.isoformat(),
                'end_date': opp.end_date.isoformat() if opp.end_date else None,
                'coordinator_name': opp.coordinator.get_full_name() if opp.coordinator else 'Unknown',
                'max_volunteers': opp.max_volunteers,
                'application_count': opp.application_count,
                
                # Activity details (for full context)
                'activity_details': {
                    'activity_id': activity.id if activity else None,
                    'location': activity.location if activity else 'TBD',
                    'start_time': activity.start_time.isoformat() if activity else None,
                    'end_time': activity.end_time.isoformat() if activity else None,
                    'status': activity.status if activity else 'unknown',
                    'created_by_name': activity.created_by_name if activity else 'Unknown',
                    'is_volunteering': activity.is_volunteering if activity else True,
                    'points_reward': getattr(activity, 'points_reward', 10) if activity else 10,
                } if activity else None,
                
                # Quick access fields (for compatibility)
                'activity_id': activity.id if activity else None,
                'location': activity.location if activity else 'TBD',
                'start_time': activity.start_time.isoformat() if activity else None,
                'end_time': activity.end_time.isoformat() if activity else None,
            }
            data.append(opportunity_data)
        
        return Response(data)
        
    except Exception as e:
        return Response({
            'error': f'Failed to load volunteer opportunities: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ALSO ADD this helper endpoint for frontend
@api_view(['GET'])
@permission_classes([AllowAny])
def get_opportunity_by_activity(request, activity_id):
    """
    Get volunteer opportunity for a specific activity ID
    Useful when student clicks "Volunteer" on an activity
    """
    try:
        opportunity = VolunteerOpportunity.objects.select_related('activity', 'coordinator').get(
            activity_id=activity_id,
            is_active=True
        )
        
        data = {
            'opportunity_id': opportunity.id,
            'activity_id': activity_id,
            'title': opportunity.title,
            'description': opportunity.description,
            'requirements': opportunity.requirements,
            'max_volunteers': opportunity.max_volunteers,
            'application_count': opportunity.application_count,
            'coordinator_name': opportunity.coordinator.get_full_name() if opportunity.coordinator else 'Unknown',
            'can_apply': opportunity.application_count < opportunity.max_volunteers,
        }
        
        return Response(data)
        
    except VolunteerOpportunity.DoesNotExist:
        return Response({
            'error': f'No volunteer opportunity found for activity {activity_id}'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'error': f'Error finding volunteer opportunity: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_volunteering_stats(request):
    """Get volunteering statistics from database"""
    try:
        user_id = request.GET.get('user_id')
        if user_id:
            total_hours = VolunteerApplication.objects.filter(
                user_id=user_id, status__in=['active', 'completed']
            ).aggregate(total=Sum('hours_completed'))['total'] or 0.0
            
            completed_tasks = VolunteerApplication.objects.filter(
                user_id=user_id, status='completed'
            ).count()
            
            pending_applications = VolunteerApplication.objects.filter(
                user_id=user_id, status='pending'
            ).count()
        else:
            total_hours = 0.0
            completed_tasks = 0
            pending_applications = 0
        
        return Response({
            'total_volunteer_hours': float(total_hours),
            'completed_volunteer_tasks': completed_tasks,
            'pending_applications': pending_applications
        })
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_my_volunteer_applications(request):
    """Get user's volunteer applications from database"""
    try:
        user_id = request.GET.get('user_id')
        if user_id:
            apps = VolunteerApplication.objects.filter(user_id=user_id).select_related('opportunity').order_by('-submitted_at')
            data = []
            for app in apps:
                data.append({
                    'id': app.id,
                    'task_title': app.opportunity.title,
                    'status': app.status,
                    'hours_completed': float(app.hours_completed),
                    'submitted_at': app.submitted_at.isoformat(),
                    'coordinator_name': app.opportunity.coordinator.get_full_name() if app.opportunity.coordinator else 'Unknown',
                })
            return Response(data)
        return Response([])
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# =======================================
# INSTRUCTOR ENDPOINTS
# =======================================

# Continuation of backend/activities/views.py - Part 2

@api_view(['GET'])
@permission_classes([AllowAny])
def get_instructor_stats(request):
    """Get instructor statistics from database"""
    try:
        return Response({
            'activities_monitored': Activity.objects.filter(status__in=['upcoming', 'ongoing']).count(),
            'students_tracked': Enrollment.objects.values('user').distinct().count(),
            'pending_verifications': VolunteerApplication.objects.filter(status='pending').count(),
            'total_hours_verified': float(VolunteerApplication.objects.filter(
                status__in=['completed', 'active']
            ).aggregate(total=Sum('hours_completed'))['total'] or 0.0),
        })
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_instructor_activities(request):
    """Get instructor activities from database"""
    try:
        activities = Activity.objects.annotate(
            enrollment_count=Count('activity_enrollments', filter=Q(activity_enrollments__status='enrolled'))
        ).order_by('-created_at')[:10]
        
        data = []
        for activity in activities:
            data.append({
                'id': activity.id,
                'title': activity.title,
                'description': activity.description,
                'location': activity.location,
                'start_time': activity.start_time.isoformat(),
                'status': activity.status,
                'enrolled_count': activity.enrollment_count,
                'attendance_marked': Attendance.objects.filter(activity=activity).exists(),
            })
        return Response(data)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_instructor_students(request):
    """Get only actual students (not coordinators/instructors/admins)"""
    try:
        # FIXED: Only get actual students based on role field or is_staff status
        if hasattr(User.objects.first(), 'role'):
            # If User model has role field, filter by it
            students = User.objects.filter(role='student')[:20]
        else:
            # Fallback: filter by is_staff and is_superuser
            students = User.objects.filter(
                is_active=True,
                is_staff=False,  # Exclude staff (instructors/coordinators)
                is_superuser=False  # Exclude admins
            )[:20]
        
        departments = [
            'Accounting',
            'Biological Sciences and Agriculture',
            'Education',
            'Foods, Nutrition and Dietetics',
            'Humanities and Social Sciences',
            'Information Systems and Computing',
            'Management',
            'Mathematics, Chemistry and Physics',
            'Medical Laboratory Science',
            'Nursing',
            'Public Health',
            'Technology and Applied Sciences',
            'Theology and Religious Studies'
        ]
        
        data = []
        
        for student in students:
            # Auto-generate registration number: REG + zero-padded ID
            reg_number = f"REG{str(student.id).zfill(4)}"
            
            # Auto-assign department based on student ID (cyclical assignment)
            department = departments[student.id % len(departments)]
            
            # Calculate student statistics
            total_enrollments = Enrollment.objects.filter(user=student).count()
            completed_activities = Enrollment.objects.filter(user=student, status='completed').count()
            volunteer_hours = VolunteerApplication.objects.filter(
                user=student, status__in=['active', 'completed', 'approved']
            ).aggregate(total=Sum('hours_completed'))['total'] or 0.0
            
            # Build full name
            full_name = f"{student.first_name} {student.last_name}".strip()
            if not full_name:
                full_name = student.username or f"Student {student.id}"
            
            # Determine role
            role = getattr(student, 'role', 'student')
            
            data.append({
                'id': student.id,
                'username': student.username,
                'email': student.email,
                'first_name': student.first_name,
                'last_name': student.last_name,
                'role': role,
                
                # Generated fields
                'full_name': full_name,
                'registration_number': reg_number,
                'department': department,
                'date_joined': student.date_joined.isoformat() if student.date_joined else None,
                'created_at': student.date_joined.isoformat() if student.date_joined else None,
                
                # Statistics
                'total_enrollments': total_enrollments,
                'completed_activities': completed_activities,
                'volunteer_hours': float(volunteer_hours),
                'participation_rate': (completed_activities / total_enrollments * 100) if total_enrollments > 0 else 0.0,
            })
            
        print(f"✅ BACKEND: Returning {len(data)} actual students (filtered from all users)")
        return Response(data)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_pending_verifications(request):
    """
    FIXED: Get pending volunteer verifications with correct student names
    """
    try:
        apps = VolunteerApplication.objects.filter(status='pending').select_related('user', 'opportunity').order_by('-submitted_at')
        data = []
        for app in apps:
            # FIX: Use same naming logic
            student = app.user
            
            student_name = f"{student.first_name} {student.last_name}".strip()
            
            if not student_name or student_name == " ":
                app_name = f"{app.first_name} {app.last_name}".strip()
                if app_name and app_name != " ":
                    student_name = app_name
                else:
                    student_name = student.email.split('@')[0] if student.email else f"Student {student.id}"
            
            data.append({
                'id': app.id,
                'student_name': student_name,  # Fixed name
                'student_email': app.email if app.email else student.email,
                'activity_title': app.opportunity.title,
                'volunteer_hours': float(app.hours_completed) if app.hours_completed > 0 else 5.0,
                'submission_date': app.submitted_at.isoformat(),
                'status': app.status,
                'student_id': app.user.id,
            })
        return Response(data)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([AllowAny])
def mark_attendance(request, activity_id):
    """Mark attendance for activity"""
    try:
        activity = get_object_or_404(Activity, id=activity_id)
        attendance_data = request.data.get('attendance', [])
        
        marked_count = 0
        for attendance_record in attendance_data:
            student_id = attendance_record.get('student_id')
            status_value = attendance_record.get('status', 'absent')
            
            try:
                student = User.objects.get(id=student_id)
                attendance, created = Attendance.objects.update_or_create(
                    user=student,
                    activity=activity,
                    defaults={
                        'status': status_value,
                        'marked_by': request.user if hasattr(request, 'user') and request.user.is_authenticated else None,
                    }
                )
                marked_count += 1
            except User.DoesNotExist:
                continue
        
        return Response({
            'success': True,
            'message': f'Attendance marked for {marked_count} students',
        })
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([AllowAny])
def approve_volunteer_hours(request, verification_id):
    """Approve volunteer hours"""
    try:
        hours = request.data.get('hours', 0)
        application = get_object_or_404(VolunteerApplication, id=verification_id)
        
        application.status = 'approved'
        application.hours_completed = hours
        application.approved_by = request.user if hasattr(request, 'user') and request.user.is_authenticated else None
        application.save()
        
        return Response({
            'success': True,
            'message': 'Volunteer hours approved successfully',
        })
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([AllowAny])
def reject_volunteer_hours(request, verification_id):
    """Reject volunteer hours"""
    try:
        application = get_object_or_404(VolunteerApplication, id=verification_id)
        
        application.status = 'rejected'
        application.approved_by = request.user if hasattr(request, 'user') and request.user.is_authenticated else None
        application.save()
        
        return Response({
            'success': True,
            'message': 'Volunteer hours rejected successfully',
        })
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_student_participation(request, student_id):
    """Get student participation data"""
    try:
        student = get_object_or_404(User, id=student_id)
        
        total_enrollments = Enrollment.objects.filter(user=student).count()
        completed_enrollments = Enrollment.objects.filter(user=student, status='completed').count()
        volunteer_hours = VolunteerApplication.objects.filter(
            user=student, status__in=['active', 'completed']
        ).aggregate(total=Sum('hours_completed'))['total'] or 0.0
        
        total_attendance = Attendance.objects.filter(user=student).count()
        present_count = Attendance.objects.filter(user=student, status='present').count()
        participation_rate = (present_count / total_attendance * 100) if total_attendance > 0 else 0
        
        recent_activities = []
        recent_enrollments = Enrollment.objects.filter(
            user=student
        ).select_related('activity').order_by('-enrolled_at')[:5]
        
        for enrollment in recent_enrollments:
            activity = enrollment.activity
            attendance = Attendance.objects.filter(user=student, activity=activity).first()
            
            activity_data = {
                'id': activity.id,
                'title': activity.title,
                'date': activity.start_time.isoformat(),
                'attendance': attendance.status if attendance else 'not_marked',
            }
            recent_activities.append(activity_data)
        
        participation_data = {
            'student_id': student_id,
            'total_activities': total_enrollments,
            'completed_activities': completed_enrollments,
            'volunteer_hours': float(volunteer_hours),
            'participation_rate': round(participation_rate, 1),
            'recent_activities': recent_activities,
        }
        return Response(participation_data)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_student_report(request, student_id):
    """Get student report (alias for participation)"""
    return get_student_participation(request, student_id)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_monthly_report(request):
    """Get monthly report data"""
    try:
        now = timezone.now()
        start_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        
        monthly_data = {
            'month': now.strftime('%Y-%m'),
            'activities_created': Activity.objects.filter(created_at__gte=start_of_month).count(),
            'total_enrollments': Enrollment.objects.filter(enrolled_at__gte=start_of_month).count(),
            'volunteer_applications': VolunteerApplication.objects.filter(submitted_at__gte=start_of_month).count(),
        }
        
        return Response({'monthly_data': monthly_data})
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_activity_participants(request, activity_id):
    """Get participants for specific activity"""
    try:
        activity = get_object_or_404(Activity, id=activity_id)
        
        enrollments = Enrollment.objects.filter(
            activity=activity,
            status='enrolled'
        ).select_related('user')
        
        participants = []
        for enrollment in enrollments:
            student = enrollment.user
            attendance = Attendance.objects.filter(user=student, activity=activity).first()
            
            participant_data = {
                'student_id': student.id,
                'first_name': student.first_name,
                'last_name': student.last_name,
                'email': student.email,
                'enrollment_date': enrollment.enrolled_at.isoformat(),
                'attendance_status': attendance.status if attendance else None,
            }
            participants.append(participant_data)
        
        return Response({'participants': participants})
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
@api_view(['GET'])
@permission_classes([AllowAny])
def get_pending_volunteer_applications(request):
    """
    FIXED: Get all pending volunteer applications with correct student names
    """
    try:
        # Get all pending volunteer applications from database
        pending_applications = VolunteerApplication.objects.filter(
            status='pending'
        ).select_related('user', 'opportunity').order_by('-submitted_at')
        
        applications_data = []
        for app in pending_applications:
            # FIX: Get student name from User model, not VolunteerApplication fields
            student = app.user
            
            # Build full name from User model first
            student_name = f"{student.first_name} {student.last_name}".strip()
            
            # If User model names are empty, fallback to VolunteerApplication fields
            if not student_name or student_name == " ":
                app_name = f"{app.first_name} {app.last_name}".strip()
                if app_name and app_name != " ":
                    student_name = app_name
                else:
                    # Last fallback - use email username part
                    student_name = student.email.split('@')[0] if student.email else f"Student {student.id}"
            
            applications_data.append({
                'id': str(app.id),
                'student_id': app.user.id,
                'student_name': student_name,  # This is the key fix
                'student_email': app.email if app.email else student.email,
                'student_username': app.user.username,
                'opportunity_id': app.opportunity.id,
                'opportunity_title': app.opportunity.title,
                'activity_id': app.opportunity.activity.id if app.opportunity.activity else None,
                'activity_title': app.opportunity.activity.title if app.opportunity.activity else app.opportunity.title,
                'application_date': app.submitted_at.isoformat(),
                'status': app.status,
                'description': app.interest_reason,
                'skills_experience': app.skills_experience,
                'availability': app.availability,
                'estimated_hours': 0.0,
                'department': app.department,
                'registration_number': app.student_id,
                'phone': app.phone_primary,
                'academic_year': app.academic_year,
            })
        
        return Response(applications_data, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': f'Failed to load pending applications: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([AllowAny])  # Using AllowAny to match your existing pattern
def get_pending_volunteer_count(request):
    """
    ISSUE #1 FIX: Get count of pending volunteer applications for instructor dashboard
    """
    try:
        # Count pending applications from database
        pending_count = VolunteerApplication.objects.filter(status='pending').count()
        
        return Response({'count': pending_count}, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': f'Failed to get pending count: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([AllowAny])  # Using AllowAny to match your existing pattern
def approve_volunteer_application(request, application_id):
    """
    BONUS: Approve volunteer application (for instructor approvals screen)
    """
    try:
        app = get_object_or_404(VolunteerApplication, id=application_id)
        
        app.status = 'approved'
        app.approved_by = request.user if hasattr(request, 'user') and request.user.is_authenticated else None
        app.save()
        
        return Response({
            'success': True,
            'message': f'Application for {app.opportunity.title} approved successfully'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': f'Failed to approve application: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([AllowAny])  # Using AllowAny to match your existing pattern  
def reject_volunteer_application(request, application_id):
    """
    BONUS: Reject volunteer application (for instructor approvals screen)
    """
    try:
        app = get_object_or_404(VolunteerApplication, id=application_id)
        reason = request.data.get('reason', 'No reason provided')
        
        app.status = 'rejected'
        app.approved_by = request.user if hasattr(request, 'user') and request.user.is_authenticated else None
        app.save()
        
        return Response({
            'success': True,
            'message': f'Application for {app.opportunity.title} rejected: {reason}'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': f'Failed to reject application: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

# ADD THIS SINGLE FUNCTION TO THE END OF YOUR backend/activities/views.py

@api_view(['POST'])
@permission_classes([AllowAny])
def submit_volunteer_application(request):
    """
    Submit a volunteer application to the database
    """
    try:
        data = request.data
        
        user_id = data.get('user_id')
        opportunity_id = data.get('opportunity_id')
        
        if not user_id or not opportunity_id:
            return Response({
                'success': False,
                'error': 'User ID and opportunity ID are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        user = get_object_or_404(User, id=user_id)
        opportunity = get_object_or_404(VolunteerOpportunity, id=opportunity_id)
        
        # Check if already applied
        existing_app = VolunteerApplication.objects.filter(
            user=user,
            opportunity=opportunity
        ).first()
        
        if existing_app:
            return Response({
                'success': False,
                'error': 'You have already applied for this opportunity'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Create application
        application = VolunteerApplication.objects.create(
            user=user,
            opportunity=opportunity,
            first_name=data.get('first_name', user.first_name),
            last_name=data.get('last_name', user.last_name),
            email=data.get('email', user.email),
            student_id=data.get('student_id', str(user.id)),
            phone_primary=data.get('phone_primary', ''),
            phone_secondary=data.get('phone_secondary', ''),
            department=data.get('department', getattr(user, 'department', '')),
            academic_year=data.get('academic_year', '2025'),
            interest_reason=data.get('interest_reason', 'I am interested in volunteering'),
            skills_experience=data.get('skills_experience', 'Willing to learn'),
            availability=data.get('availability', 'Flexible schedule'),
            status='pending'
        )
        
        return Response({
            'success': True,
            'message': f'Successfully applied for {opportunity.title}',
            'application_id': application.id,
            'application_status': application.status
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({
            'success': False,
            'error': f'Failed to submit application: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
# REPLACE your create_volunteer_opportunities_from_activities function with this:

@api_view(['GET', 'POST'])
@permission_classes([AllowAny])
def create_volunteer_opportunities_from_activities(request):
    """
    Create VolunteerOpportunity for each volunteering Activity (improved version)
    """
    try:
        # Get ACTUAL coordinators first, not just any user
        coordinator = User.objects.filter(role='coordinator').first()
        if not coordinator:
            # Fallback to instructor, then admin
            coordinator = User.objects.filter(role='instructor').first()
        if not coordinator:
            coordinator = User.objects.filter(role='admin').first()
        if not coordinator:
            # Last resort - use first user but warn
            coordinator = User.objects.first()
            
        if not coordinator:
            return Response({'error': 'No users found in database'}, status=400)
        
        # Get volunteering activities
        volunteering_activities = Activity.objects.filter(is_volunteering=True)
        created_count = 0
        updated_count = 0
        opportunities_info = []
        
        for activity in volunteering_activities:
            # Use activity's original creator if they're a coordinator
            activity_coordinator = coordinator  # default
            if activity.created_by and hasattr(activity.created_by, 'role'):
                if activity.created_by.role in ['coordinator', 'instructor', 'admin']:
                    activity_coordinator = activity.created_by
            
            # Create/update opportunity with activity-specific data
            opportunity, created = VolunteerOpportunity.objects.get_or_create(
                activity=activity,
                defaults={
                    'title': activity.title,  # Use original title, not "Volunteer for..."
                    'description': activity.description,
                    'requirements': 'Interest in volunteering and helping the community',
                    'time_commitment': f"{activity.duration_hours:.0f} hours" if hasattr(activity, 'duration_hours') else '3-5 hours',
                    'start_date': activity.start_time.date(),
                    'end_date': activity.end_time.date() if activity.end_time else activity.start_time.date(),
                    'max_volunteers': getattr(activity, 'max_participants', 15) or 15,  # Use activity's limit
                    'coordinator': activity_coordinator,
                    'is_active': True
                }
            )
            
            if created:
                created_count += 1
            else:
                # Update existing opportunity with fresh data
                opportunity.title = activity.title
                opportunity.description = activity.description
                opportunity.start_date = activity.start_time.date()
                opportunity.end_date = activity.end_time.date() if activity.end_time else activity.start_time.date()
                opportunity.max_volunteers = getattr(activity, 'max_participants', 15) or 15
                opportunity.coordinator = activity_coordinator
                opportunity.save()
                updated_count += 1
                
            opportunities_info.append({
                'opportunity_id': opportunity.id,
                'activity_id': activity.id,
                'title': opportunity.title,
                'coordinator': opportunity.coordinator.get_full_name() if opportunity.coordinator else 'Unknown',
                'max_volunteers': opportunity.max_volunteers,
            })
        
        return Response({
            'success': True,
            'message': f'Created {created_count} new opportunities, updated {updated_count} existing ones',
            'coordinator_used': f"{coordinator.get_full_name()} ({coordinator.role})" if hasattr(coordinator, 'role') else coordinator.get_full_name(),
            'opportunities': opportunities_info,
            'total_opportunities': VolunteerOpportunity.objects.count()
        })
        
    except Exception as e:
        import traceback
        return Response({
            'error': str(e),
            'traceback': traceback.format_exc()
        }, status=500)
    
@api_view(['GET'])
@permission_classes([AllowAny])
def get_all_volunteer_applications(request):
    """
    FIXED: Get ALL volunteer applications with correct student names
    """
    try:
        applications = VolunteerApplication.objects.filter(
            # Don't filter by status - get all
        ).select_related('user', 'opportunity').order_by('-submitted_at')
        
        applications_data = []
        for app in applications:
            # FIX: Same logic - get name from User model first
            student = app.user
            
            student_name = f"{student.first_name} {student.last_name}".strip()
            
            if not student_name or student_name == " ":
                app_name = f"{app.first_name} {app.last_name}".strip()
                if app_name and app_name != " ":
                    student_name = app_name
                else:
                    student_name = student.email.split('@')[0] if student.email else f"Student {student.id}"
            
            applications_data.append({
                'id': app.id,
                'student_name': student_name,  # Fixed name logic
                'student_email': app.email if app.email else student.email,
                'activity_title': app.opportunity.title,
                'volunteer_hours': float(app.hours_completed) if app.hours_completed > 0 else 5.0,
                'submission_date': app.submitted_at.isoformat(),
                'status': app.status,
                'student_id': app.user.id,
            })
        
        return Response(applications_data)
    except Exception as e:
        return Response({'error': str(e)}, status=500)

# =======================================
# LEGACY COMPATIBILITY ALIASES
# =======================================

# Map old function names to new ones for backward compatibility
get_activities = get_activities_with_enrollment_status
get_recent_activities = get_student_recent_activities
enroll_in_activity = enroll_in_activity_fixed