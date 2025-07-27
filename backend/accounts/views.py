# backend/accounts/views.py
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import authenticate
from django.db.models import Count, Q
from django.utils import timezone
from datetime import datetime, timedelta
from .models import User
from rest_framework_simplejwt.tokens import RefreshToken
import logging

logger = logging.getLogger(__name__)

# Custom permission for admin users
def admin_required(view_func):
    """Decorator to require admin role"""
    def wrapper(request, *args, **kwargs):
        if not request.user.is_authenticated:
            return Response({"error": "Authentication required"}, status=401)
        if request.user.role != 'admin':
            return Response({"error": "Admin access required"}, status=403)
        return view_func(request, *args, **kwargs)
    return wrapper

@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    """Register a new user"""
    try:
        data = request.data
        print(f"Registration data received: {data}")  # Debug print
        
        # Get basic required fields
        username = data.get('username')
        email = data.get('email')
        password = data.get('password')
        first_name = data.get('first_name', '')
        last_name = data.get('last_name', '')
        
        # Basic validation
        if not username:
            return Response({"error": "Username is required"}, status=400)
        if not email:
            return Response({"error": "Email is required"}, status=400)
        if not password:
            return Response({"error": "Password is required"}, status=400)
        
        # Check if username already exists
        if User.objects.filter(username=username).exists():
            return Response({"error": "Username already exists"}, status=400)
        
        # Check if email already exists
        if User.objects.filter(email=email).exists():
            return Response({"error": "Email already exists"}, status=400)
        
        print(f"Creating user with username: {username}, email: {email}")  # Debug print
        
        # Create user with minimal required fields
        user = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            first_name=first_name,
            last_name=last_name,
            role='student'  # Default role
        )
        
        print(f"User created successfully: {user.id}, {user.username}")  # Debug print
        
        return Response({
            "message": "User registered successfully",
            "user": {
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "role": user.role
            }
        }, status=201)
        
    except Exception as e:
        print(f"Registration error: {str(e)}")  # Debug print
        import traceback
        traceback.print_exc()  # Print full traceback
        return Response(
            {"error": f"Registration failed: {str(e)}"}, 
            status=500
        )

@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    """Login user with username or email and password"""
    try:
        data = request.data
        username = data.get('username')
        email = data.get('email')
        password = data.get('password')
        
        # Accept either username or email
        login_field = username or email
        
        print(f"Login attempt for: {login_field}")  # Debug print
        
        if not login_field or not password:
            return Response(
                {"error": "Username/email and password are required"}, 
                status=400
            )
        
        # Try to authenticate
        user = None
        if username:
            user = authenticate(username=username, password=password)
        elif email:
            # If email provided, find user by email and authenticate with username
            try:
                user_obj = User.objects.get(email=email)
                user = authenticate(username=user_obj.username, password=password)
            except User.DoesNotExist:
                pass
        
        if user is not None:
            # Generate JWT tokens
            refresh = RefreshToken.for_user(user)
            
            print(f"Login successful for user: {user.username}")  # Debug print
            
            return Response({
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "user": {
                    "id": user.id,
                    "username": user.username,
                    "email": user.email,
                    "first_name": user.first_name,
                    "last_name": user.last_name,
                    "role": user.role,
                }
            }, status=200)
        else:
            print(f"Login failed for: {login_field}")  # Debug print
            return Response(
                {"error": "Invalid credentials"}, 
                status=401
            )
            
    except Exception as e:
        print(f"Login error: {str(e)}")  # Debug print
        import traceback
        traceback.print_exc()
        return Response(
            {"error": f"Login failed: {str(e)}"}, 
            status=500
        )

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_current_user(request):
    """Get current user profile"""
    user = request.user
    return Response({
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "first_name": user.first_name,
        "last_name": user.last_name,
        "role": user.role,
        "date_joined": user.date_joined,
    })

@api_view(['POST'])
@permission_classes([AllowAny])
def reset_password(request):
    """Reset password for a user (for testing purposes)"""
    try:
        username = request.data.get('username')
        new_password = request.data.get('new_password', 'password123')
        
        if not username:
            return Response({"error": "Username is required"}, status=400)
        
        try:
            user = User.objects.get(username=username)
            user.set_password(new_password)
            user.save()
            
            return Response({
                "message": f"Password reset for {username}",
                "new_password": new_password
            }, status=200)
            
        except User.DoesNotExist:
            return Response({"error": "User not found"}, status=404)
            
    except Exception as e:
        return Response({"error": str(e)}, status=500)

@api_view(['GET'])
@permission_classes([AllowAny])  # Remove this in production
def list_users(request):
    """List all users (for testing purposes - remove in production)"""
    try:
        users = User.objects.all()
        users_data = []
        
        for user in users:
            users_data.append({
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "role": user.role,
                "is_active": user.is_active,
            })
        
        return Response({
            "count": len(users_data),
            "users": users_data
        }, status=200)
        
    except Exception as e:
        return Response({"error": str(e)}, status=500)

# =============================================================================
# ADMIN DASHBOARD ENDPOINTS
# =============================================================================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
@admin_required
def admin_dashboard_stats(request):
    """Get admin dashboard statistics with REAL recent activities"""
    try:
        # Calculate time ranges
        now = timezone.now()
        this_month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        
        # Get user statistics
        total_users = User.objects.count()
        new_users_this_month = User.objects.filter(
            date_joined__gte=this_month_start
        ).count()
        
        # Get activity statistics
        try:
            from activities.models import Activity, Enrollment
            active_activities = Activity.objects.filter(
                start_time__lte=now,
                end_time__gte=now
            ).count()
            upcoming_activities = Activity.objects.filter(
                start_time__gt=now
            ).count()
        except ImportError:
            active_activities = 0
            upcoming_activities = 0
        
        # 🔧 GET REAL RECENT ACTIVITIES FROM DATABASE
        recent_activities = []
        
        # Get recent user registrations
        recent_users = User.objects.filter(
            date_joined__gte=now - timedelta(days=7)
        ).order_by('-date_joined')[:3]
        
        for user in recent_users:
            recent_activities.append({
                'id': f'user_{user.id}',
                'type': 'user_created',
                'description': f'New user registered: {user.first_name} {user.last_name}' if user.first_name else f'New user: {user.username}',
                'timestamp': user.date_joined.isoformat(),
                'user_id': str(user.id),
                'user_name': f'{user.first_name} {user.last_name}' if user.first_name else user.username,
            })
        
        # Get recent activities created
        try:
            recent_created_activities = Activity.objects.filter(
                created_at__gte=now - timedelta(days=7)
            ).order_by('-created_at')[:3]
            
            for activity in recent_created_activities:
                recent_activities.append({
                    'id': f'activity_{activity.id}',
                    'type': 'activity_created',
                    'description': f'New activity created: {activity.title}',
                    'timestamp': activity.created_at.isoformat(),
                    'user_id': str(activity.created_by.id) if activity.created_by else None,
                    'user_name': activity.created_by.get_full_name() if activity.created_by else 'System',
                })
        except:
            pass
        
        # Get recent enrollments
        try:
            recent_enrollments = Enrollment.objects.filter(
                enrolled_at__gte=now - timedelta(days=7)
            ).select_related('user', 'activity').order_by('-enrolled_at')[:2]
            
            for enrollment in recent_enrollments:
                recent_activities.append({
                    'id': f'enrollment_{enrollment.id}',
                    'type': 'user_enrolled',
                    'description': f'{enrollment.user.get_full_name() or enrollment.user.username} enrolled in {enrollment.activity.title}',
                    'timestamp': enrollment.enrolled_at.isoformat(),
                    'user_id': str(enrollment.user.id),
                    'user_name': enrollment.user.get_full_name() or enrollment.user.username,
                })
        except:
            pass
        
        # Add system events if no real activities
        if not recent_activities:
            recent_activities.append({
                'id': 'system_1',
                'type': 'system_event',
                'description': 'System running smoothly - no recent activities',
                'timestamp': now.isoformat(),
                'user_id': None,
                'user_name': 'System',
            })
        
        # Sort by timestamp (most recent first)
        recent_activities.sort(key=lambda x: x['timestamp'], reverse=True)
        recent_activities = recent_activities[:5]  # Keep only 5 most recent
        
        # Simple system health calculation
        system_health = 98  # Can be made dynamic based on various factors
        pending_issues = 0  # Calculate real pending issues if needed
        
        return Response({
            'total_users': total_users,
            'new_users_this_month': new_users_this_month,
            'active_activities': active_activities,
            'upcoming_activities': upcoming_activities,
            'system_health': system_health,
            'pending_issues': pending_issues,
            'recent_activities': recent_activities
        }, status=200)
        
    except Exception as e:
        import traceback
        print(f"Dashboard stats error: {str(e)}")
        print(traceback.format_exc())
        return Response(
            {'error': f'Failed to load dashboard stats: {str(e)}'},
            status=500
        )

@api_view(['GET'])
@permission_classes([IsAuthenticated])
@admin_required
def admin_get_users(request):
    """Get all users with filtering and pagination"""
    try:
        # Get query parameters
        page = int(request.GET.get('page', 1))
        page_size = int(request.GET.get('page_size', 20))
        search_query = request.GET.get('search', '')
        role_filter = request.GET.get('role', '')
        
        # Build queryset
        queryset = User.objects.all()
        
        # Apply search filter
        if search_query:
            queryset = queryset.filter(
                Q(first_name__icontains=search_query) |
                Q(last_name__icontains=search_query) |
                Q(email__icontains=search_query) |
                Q(username__icontains=search_query)
            )
        
        # Apply role filter
        if role_filter:
            queryset = queryset.filter(role=role_filter)
        
        # Get total count
        total_count = queryset.count()
        
        # Apply pagination
        start = (page - 1) * page_size
        end = start + page_size
        users = queryset[start:end]
        
        # Serialize data
        users_data = []
        for user in users:
            users_data.append({
                'id': user.id,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'email': user.email,
                'username': user.username,
                'role': user.role,
                'is_active': user.is_active,
                'date_joined': user.date_joined.isoformat(),
                'last_login': user.last_login.isoformat() if user.last_login else None,
            })
        
        return Response({
            'users': users_data,
            'total_count': total_count,
            'page': page,
            'page_size': page_size,
            'total_pages': (total_count + page_size - 1) // page_size
        }, status=200)
        
    except Exception as e:
        return Response(
            {'error': f'Failed to load users: {str(e)}'},
            status=500
        )

@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
@admin_required
def admin_update_user_role(request, user_id):
    """Update user role"""
    try:
        user = User.objects.get(id=user_id)
        new_role = request.data.get('role')
        
        valid_roles = ['student', 'instructor', 'coordinator', 'admin']
        if new_role not in valid_roles:
            return Response(
                {'error': 'Invalid role'},
                status=400
            )
        
        old_role = user.role
        user.role = new_role
        user.save()
        
        return Response({
            'message': f'User role updated from {old_role} to {new_role}',
            'user': {
                'id': user.id,
                'username': user.username,
                'role': user.role
            }
        }, status=200)
        
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=404)
    except Exception as e:
        return Response(
            {'error': f'Failed to update user role: {str(e)}'},
            status=500
        )

@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
@admin_required
def admin_toggle_user_status(request, user_id):
    """Toggle user active status"""
    try:
        user = User.objects.get(id=user_id)
        is_active = request.data.get('is_active')
        
        if is_active is None:
            return Response(
                {'error': 'is_active field is required'},
                status=400
            )
        
        user.is_active = is_active
        user.save()
        
        status_text = 'activated' if is_active else 'deactivated'
        return Response({
            'message': f'User {status_text} successfully',
            'user': {
                'id': user.id,
                'username': user.username,
                'is_active': user.is_active
            }
        }, status=200)
        
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=404)
    except Exception as e:
        return Response(
            {'error': f'Failed to update user status: {str(e)}'},
            status=500
        )

@api_view(['GET'])
@permission_classes([IsAuthenticated])
@admin_required
def admin_get_analytics(request):
    """Get system analytics"""
    try:
        start_date = request.GET.get('start_date')
        end_date = request.GET.get('end_date')
        
        # User analytics
        total_users = User.objects.count()
        user_roles = User.objects.values('role').annotate(count=Count('role'))
        
        by_role = {}
        for role_data in user_roles:
            by_role[role_data['role']] = role_data['count']
        
        # Activity analytics (mock data for now)
        activity_data = {
            'upcoming': 5,
            'ongoing': 3,
            'completed': 25,
            'total_enrollments': 156,
            'avg_enrollment_rate': 78.5
        }
        
        return Response({
            'overview': {
                'total_users': total_users,
                'total_activities': 33,
                'active_sessions': 12,
                'uptime': '99.9%'
            },
            'users': {
                'total_users': total_users,
                'by_role': by_role
            },
            'activities': activity_data
        }, status=200)
        
    except Exception as e:
        return Response(
            {'error': f'Failed to load analytics: {str(e)}'},
            status=500
        )

@api_view(['GET'])
@permission_classes([IsAuthenticated])
@admin_required
def admin_export_data(request, data_type):
    """Export data"""
    try:
        format_type = request.GET.get('format', 'csv')
        
        # Mock export URL for now
        download_url = f'http://localhost:8000/api/admin/exports/{data_type}_{timezone.now().strftime("%Y%m%d_%H%M%S")}.{format_type}'
        
        return Response({
            'download_url': download_url,
            'message': f'{data_type.title()} data export ready'
        }, status=200)
        
    except Exception as e:
        return Response(
            {'error': f'Failed to export data: {str(e)}'},
            status=500
        )

@api_view(['GET'])
@permission_classes([IsAuthenticated])
@admin_required
def admin_get_settings(request):
    """Get system settings"""
    try:
        settings_data = {
            'app_name': 'Beyond EAMS',
            'app_version': '1.0.0',
            'max_activities_per_user': 10,
            'enable_notifications': True,
            'enable_registration': True,
            'maintenance_mode': False,
            'database_type': 'SQLite',
            'environment': 'Development',
            'last_backup': 'Never',
            'total_users': User.objects.count(),
            'total_activities': 0  # Will be updated when activities are integrated
        }
        
        return Response(settings_data, status=200)
        
    except Exception as e:
        return Response(
            {'error': f'Failed to load settings: {str(e)}'},
            status=500
        )

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
@admin_required
def admin_update_settings(request):
    """Update system settings"""
    try:
        # For now, just return success - would normally save to database
        settings = request.data
        
        return Response({
            'message': 'Settings updated successfully',
            'settings': settings
        }, status=200)
        
    except Exception as e:
        return Response(
            {'error': f'Failed to update settings: {str(e)}'},
            status=500
        )

@api_view(['POST'])
@permission_classes([IsAuthenticated])
@admin_required
def admin_send_notification(request):
    """Send system notification"""
    try:
        title = request.data.get('title')
        message = request.data.get('message')
        user_ids = request.data.get('user_ids', [])
        roles = request.data.get('roles', [])
        
        if not title or not message:
            return Response(
                {'error': 'Title and message are required'},
                status=400
            )
        
        # Mock notification sending for now
        return Response({
            'message': 'Notification sent successfully',
            'recipients': len(user_ids) if user_ids else User.objects.count()
        }, status=200)
        
    except Exception as e:
        return Response(
            {'error': f'Failed to send notification: {str(e)}'},
            status=500
        )

@api_view(['POST'])
@permission_classes([IsAuthenticated])
@admin_required
def admin_create_backup(request):
    """Create system backup"""
    try:
        # Mock backup creation
        backup_url = f'http://localhost:8000/api/admin/backups/backup_{timezone.now().strftime("%Y%m%d_%H%M%S")}.zip'
        
        return Response({
            'backup_url': backup_url,
            'message': 'System backup created successfully'
        }, status=200)
        
    except Exception as e:
        return Response(
            {'error': f'Failed to create backup: {str(e)}'},
            status=500
        )
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
@admin_required
def admin_get_role_requests(request):
    """Get pending role requests"""
    try:
        # Mock role requests for now - replace with actual model later
        role_requests = [
            {
                'id': '1',
                'user_id': '2',
                'user_name': 'John Doe',
                'user_email': 'john@example.com',
                'current_role': 'student',
                'requested_role': 'coordinator',
                'reason': 'I want to organize activities for my department',
                'request_date': timezone.now().isoformat(),
                'status': 'pending'
            }
        ]
        
        return Response({
            'requests': role_requests
        }, status=200)
        
    except Exception as e:
        return Response(
            {'error': f'Failed to load role requests: {str(e)}'},
            status=500
        )
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
@admin_required
def admin_get_role_requests(request):
    """Get pending role requests"""
    try:
        # Mock role requests for now
        role_requests = [
            {
                'id': 1,
                'user_id': 2,
                'user_name': 'John Doe',
                'user_email': 'john@example.com',
                'current_role': 'student',
                'requested_role': 'coordinator',
                'reason': 'I want to organize activities',
                'request_date': timezone.now().isoformat(),
                'status': 'pending'
            }
        ]
        
        return Response({'requests': role_requests}, status=200)
        
    except Exception as e:
        return Response(
            {'error': f'Failed to load role requests: {str(e)}'},
            status=500
        )
    
# ADD TO backend/accounts/views.py

@api_view(['GET'])
@permission_classes([IsAuthenticated])
@admin_required
def admin_get_system_reports(request):
    """Get comprehensive system reports"""
    try:
        # Get basic stats
        total_users = User.objects.count()
        this_month_start = timezone.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        new_users_this_month = User.objects.filter(date_joined__gte=this_month_start).count()
        
        # Try to get activity stats
        try:
            from activities.models import Activity, Enrollment
            total_activities = Activity.objects.count()
            active_activities = Activity.objects.filter(
                start_time__lte=timezone.now(),
                end_time__gte=timezone.now()
            ).count()
        except ImportError:
            total_activities = 0
            active_activities = 0
        
        # System performance metrics (mock for now)
        system_report = {
            'total_users': total_users,
            'new_users_this_month': new_users_this_month,
            'total_activities': total_activities,
            'active_activities': active_activities,
            'system_health': 98,
            'pending_issues': 0,
            'system_uptime': 99.9,
            'storage_used': 12.4,
            'storage_total': 50.0,
            'cpu_usage': 23,
            'memory_usage': 67,
            'network_status': 95,
            'response_time': 145,
            'db_queries': 342,
            'error_rate': 0.1,
            'active_sessions': 127,
            'recent_activities': [
                {
                    'id': '1',
                    'type': 'user_created',
                    'description': 'New user registered',
                    'timestamp': timezone.now().isoformat(),
                    'user_id': None,
                    'user_name': 'System',
                }
            ]
        }
        
        return Response(system_report, status=200)
        
    except Exception as e:
        return Response(
            {'error': f'Failed to load system reports: {str(e)}'},
            status=500
        )
    
