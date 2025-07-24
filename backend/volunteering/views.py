# backend/volunteering/views.py 
from rest_framework.views import APIView
from django.http import JsonResponse
from django.utils import timezone
from django.shortcuts import get_object_or_404
from activities.models import Activity, Enrollment
from accounts.models import User

class VolunteerTaskListView(APIView):
    """List all volunteer activities from the Activity table"""
    
    def get(self, request, *args, **kwargs):
        """Return actual volunteer activities from database"""
        try:
            # Query actual volunteer activities from Activity table
            volunteer_activities = Activity.objects.filter(
                is_volunteering=True
            ).order_by('-start_time')
            
            activities_data = []
            for activity in volunteer_activities:
                # Get enrollment count for this activity
                enrolled_count = Enrollment.objects.filter(
                    activity=activity,
                    status='enrolled'
                ).count()
                
                # Check if user has applied (if user_id is provided)
                user_id = request.GET.get('user_id')
                is_applied = False
                application_status = None
                
                if user_id:
                    try:
                        user = User.objects.get(id=user_id)
                        enrollment = Enrollment.objects.filter(
                            user=user,
                            activity=activity
                        ).first()
                        if enrollment:
                            is_applied = True
                            application_status = enrollment.status
                    except User.DoesNotExist:
                        pass
                
                # Calculate status based on dates
                now = timezone.now()
                if activity.start_time > now:
                    activity_status = 'open'
                elif activity.start_time <= now <= activity.end_time:
                    activity_status = 'ongoing'
                else:
                    activity_status = 'completed'
                
                activity_data = {
                    'id': activity.id,
                    'title': activity.title,
                    'description': activity.description,
                    'activity_title': activity.title,  # For compatibility
                    'activity_id': activity.id,
                    'location': activity.location,
                    'start_time': activity.start_time.isoformat(),
                    'end_time': activity.end_time.isoformat(),
                    'required_volunteers': getattr(activity, 'max_participants', 20),
                    'applied_volunteers': enrolled_count,
                    'enrolled_count': enrolled_count,
                    'hours_commitment': 4.0,  # Default or calculate from activity duration
                    'due_date': activity.start_time.isoformat(),
                    'posted_by': activity.created_by.get_full_name() if activity.created_by else 'Coordinator',
                    'created_by_name': activity.created_by.get_full_name() if activity.created_by else 'Coordinator',
                    'status': activity_status,
                    'is_applied': is_applied,
                    'application_status': application_status,
                    'is_volunteering': True,  # All these are volunteer activities
                    'created_at': activity.created_at.isoformat(),
                }
                activities_data.append(activity_data)
            
            print(f"🔍 VOLUNTEERING DEBUG: Returning {len(activities_data)} volunteer activities")
            for i, activity in enumerate(activities_data):
                print(f"Volunteer Activity {i}: {activity['title']}")
            
            return JsonResponse(activities_data, safe=False)
            
        except Exception as e:
            print(f"❌ Error in volunteer activities: {e}")
            return JsonResponse({
                'success': False,
                'error': str(e)
            }, status=500)

class VolunteerTaskDetailView(APIView):
    """Get details of a specific volunteer activity"""
    
    def get(self, request, pk, *args, **kwargs):
        """Get specific volunteer activity details"""
        try:
            # Get actual activity from Activity table
            activity = get_object_or_404(Activity, id=pk, is_volunteering=True)
            
            enrolled_count = Enrollment.objects.filter(
                activity=activity,
                status='enrolled'
            ).count()
            
            # Check if user has applied
            user_id = request.GET.get('user_id')
            is_applied = False
            if user_id:
                try:
                    user = User.objects.get(id=user_id)
                    enrollment = Enrollment.objects.filter(
                        user=user,
                        activity=activity
                    ).exists()
                    is_applied = enrollment
                except User.DoesNotExist:
                    pass
            
            activity_data = {
                'id': activity.id,
                'title': activity.title,
                'description': activity.description,
                'activity_title': activity.title,
                'activity_id': activity.id,
                'location': activity.location,
                'start_time': activity.start_time.isoformat(),
                'end_time': activity.end_time.isoformat(),
                'required_volunteers': getattr(activity, 'max_participants', 20),
                'applied_volunteers': enrolled_count,
                'hours_commitment': 4.0,
                'posted_by': activity.created_by.get_full_name() if activity.created_by else 'Coordinator',
                'status': 'open',
                'is_applied': is_applied,
                'is_volunteering': True,
            }
            
            return JsonResponse(activity_data)
            
        except Exception as e:
            return JsonResponse({
                'success': False,
                'error': str(e)
            }, status=500)

class VolunteerApplicationView(APIView):
    """Handle volunteer applications"""
    
    def post(self, request, task_id):
        """Apply for a volunteer task"""
        try:
            # Get the volunteer activity
            activity = get_object_or_404(Activity, id=task_id, is_volunteering=True)
            user_id = request.data.get('user_id') or request.GET.get('user_id')
            
            if not user_id:
                return JsonResponse({
                    'success': False,
                    'error': 'User ID required'
                }, status=400)
            
            user = get_object_or_404(User, id=user_id)
            
            # Check if already enrolled
            existing_enrollment = Enrollment.objects.filter(
                user=user,
                activity=activity
            ).first()
            
            if existing_enrollment:
                return JsonResponse({
                    'success': False,
                    'error': 'Already applied for this volunteer activity'
                }, status=400)
            
            # Create enrollment
            enrollment = Enrollment.objects.create(
                user=user,
                activity=activity,
                status='enrolled',
                enrollment_date=timezone.now()
            )
            
            return JsonResponse({
                'success': True,
                'message': 'Successfully applied for volunteer task!',
                'application_id': enrollment.id,
                'status': 'enrolled'
            })
            
        except Exception as e:
            return JsonResponse({
                'success': False,
                'error': f'Failed to apply: {str(e)}'
            }, status=400)
    
    def delete(self, request, task_id):
        """Withdraw application"""
        try:
            user_id = request.data.get('user_id') or request.GET.get('user_id')
            
            if not user_id:
                return JsonResponse({
                    'success': False,
                    'error': 'User ID required'
                }, status=400)
            
            user = get_object_or_404(User, id=user_id)
            activity = get_object_or_404(Activity, id=task_id, is_volunteering=True)
            
            # Delete enrollment
            enrollment = Enrollment.objects.filter(
                user=user,
                activity=activity
            ).first()
            
            if enrollment:
                enrollment.delete()
                return JsonResponse({
                    'success': True,
                    'message': 'Successfully withdrew volunteer application'
                })
            else:
                return JsonResponse({
                    'success': False,
                    'error': 'No application found to withdraw'
                }, status=404)
                
        except Exception as e:
            return JsonResponse({
                'success': False,
                'error': str(e)
            }, status=500)

class MyVolunteerApplicationsView(APIView):
    """Get user's volunteer applications"""
    
    def get(self, request):
        """Get user's volunteer applications"""
        try:
            user_id = request.GET.get('user_id')
            
            if not user_id:
                return JsonResponse({
                    'success': False,
                    'error': 'User ID required'
                }, status=400)
            
            user = get_object_or_404(User, id=user_id)
            
            # Get actual enrollments for volunteer activities
            volunteer_enrollments = Enrollment.objects.filter(
                user=user,
                activity__is_volunteering=True
            ).select_related('activity').order_by('-enrollment_date')
            
            applications_data = []
            for enrollment in volunteer_enrollments:
                activity = enrollment.activity
                application_data = {
                    'id': enrollment.id,
                    'task_title': activity.title,
                    'activity_title': activity.title,
                    'activity_id': activity.id,
                    'status': enrollment.status,
                    'applied_at': enrollment.enrollment_date.isoformat(),
                    'hours_commitment': 4.0,  # Calculate from activity duration
                    'message': f'Applied for {activity.title}',
                    'location': activity.location,
                    'start_time': activity.start_time.isoformat(),
                    'end_time': activity.end_time.isoformat(),
                }
                applications_data.append(application_data)
            
            print(f"🔍 USER APPLICATIONS DEBUG: User {user_id} has {len(applications_data)} volunteer applications")
            
            return JsonResponse(applications_data, safe=False)
            
        except Exception as e:
            return JsonResponse({
                'success': False,
                'error': str(e)
            }, status=500)