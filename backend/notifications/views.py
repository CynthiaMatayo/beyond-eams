from django.shortcuts import render
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import get_user_model
from .models import Notification, NotificationTemplate, EmailLog
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
import logging

User = get_user_model()
logger = logging.getLogger(__name__)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_notifications(request):
    """Get notifications for the current user"""
    try:
        user = request.user
        notifications = Notification.objects.filter(recipient=user)
        
        # Mark notifications as read if requested
        mark_read = request.GET.get('mark_read', 'false').lower() == 'true'
        if mark_read:
            notifications.filter(is_read=False).update(is_read=True)
        
        notifications_data = []
        for notification in notifications:
            notifications_data.append({
                'id': notification.id,
                'title': notification.title,
                'message': notification.message,
                'type': notification.notification_type,
                'priority': notification.priority,
                'is_read': notification.is_read,
                'created_at': notification.created_at.isoformat(),
                'related_activity_id': notification.related_activity.id if notification.related_activity else None,
            })
        
        return Response({
            'success': True,
            'notifications': notifications_data,
            'unread_count': notifications.filter(is_read=False).count(),
        })
        
    except Exception as e:
        logger.error(f"Error getting user notifications: {str(e)}")
        return Response({
            'success': False,
            'error': f'Failed to get notifications: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_notification_read(request, notification_id):
    """Mark a specific notification as read"""
    try:
        notification = Notification.objects.get(
            id=notification_id, 
            recipient=request.user
        )
        notification.mark_as_read()
        
        return Response({
            'success': True,
            'message': 'Notification marked as read'
        })
        
    except Notification.DoesNotExist:
        return Response({
            'success': False,
            'error': 'Notification not found'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_notification(request):
    """Send notification to users (admin only for now)"""
    try:
        # Check if user is admin/coordinator
        if not (request.user.is_staff or getattr(request.user, 'role', '') in ['admin', 'coordinator']):
            return Response({
                'success': False,
                'error': 'Permission denied'
            }, status=status.HTTP_403_FORBIDDEN)
        
        title = request.data.get('title')
        message = request.data.get('message')
        notification_type = request.data.get('type', 'general')
        priority = request.data.get('priority', 'normal')
        recipient_ids = request.data.get('recipient_ids', [])
        send_email = request.data.get('send_email', True)
        
        if not title or not message:
            return Response({
                'success': False,
                'error': 'Title and message are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # If no specific recipients, send to all users
        if not recipient_ids:
            recipients = User.objects.filter(is_active=True)
        else:
            recipients = User.objects.filter(id__in=recipient_ids, is_active=True)
        
        notifications_created = 0
        emails_sent = 0
        
        for recipient in recipients:
            # Create notification
            notification = Notification.objects.create(
                recipient=recipient,
                title=title,
                message=message,
                notification_type=notification_type,
                priority=priority,
            )
            notifications_created += 1
            
            # Send email if requested
            if send_email and notification.send_email():
                emails_sent += 1
        
        return Response({
            'success': True,
            'message': f'Notifications sent successfully',
            'notifications_created': notifications_created,
            'emails_sent': emails_sent,
        })
        
    except Exception as e:
        logger.error(f"Error sending notifications: {str(e)}")
        return Response({
            'success': False,
            'error': f'Failed to send notifications: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_activity_notification(request):
    """Send notification about activity to enrolled users"""
    try:
        from activities.models import Activity, ActivityEnrollment
        
        activity_id = request.data.get('activity_id')
        title = request.data.get('title')
        message = request.data.get('message')
        send_email = request.data.get('send_email', True)
        
        if not activity_id or not title or not message:
            return Response({
                'success': False,
                'error': 'Activity ID, title and message are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            activity = Activity.objects.get(id=activity_id)
        except Activity.DoesNotExist:
            return Response({
                'success': False,
                'error': 'Activity not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Get enrolled users
        enrollments = ActivityEnrollment.objects.filter(activity=activity)
        
        notifications_created = 0
        emails_sent = 0
        
        for enrollment in enrollments:
            # Create notification
            notification = Notification.objects.create(
                recipient=enrollment.user,
                title=title,
                message=message,
                notification_type='activity',
                related_activity=activity,
            )
            notifications_created += 1
            
            # Send email if requested
            if send_email and notification.send_email():
                emails_sent += 1
        
        return Response({
            'success': True,
            'message': f'Activity notifications sent successfully',
            'notifications_created': notifications_created,
            'emails_sent': emails_sent,
        })
        
    except Exception as e:
        logger.error(f"Error sending activity notifications: {str(e)}")
        return Response({
            'success': False,
            'error': f'Failed to send activity notifications: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_notification_count(request):
    """Get unread notification count for the current user"""
    try:
        unread_count = Notification.objects.filter(
            recipient=request.user,
            is_read=False
        ).count()
        
        return Response({
            'success': True,
            'unread_count': unread_count,
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def test_email(request):
    """Test email functionality (admin only)"""
    try:
        if not request.user.is_staff:
            return Response({
                'success': False,
                'error': 'Permission denied'
            }, status=status.HTTP_403_FORBIDDEN)
        
        recipient_email = request.data.get('email', request.user.email)
        
        subject = "Beyond EAMS Email Test"
        message = f"""
Hello {request.user.get_full_name() or request.user.username},

This is a test email from Beyond EAMS to verify that email functionality is working correctly.

Sent at: {timezone.now().strftime('%Y-%m-%d %H:%M:%S')}

Best regards,
Beyond EAMS Team
        """
        
        success = send_mail(
            subject=subject,
            message=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[recipient_email],
            fail_silently=False,
        )
        
        # Log the email attempt
        EmailLog.objects.create(
            recipient_email=recipient_email,
            subject=subject,
            message=message,
            sent_successfully=success,
        )
        
        if success:
            return Response({
                'success': True,
                'message': f'Test email sent successfully to {recipient_email}',
            })
        else:
            return Response({
                'success': False,
                'error': 'Failed to send test email',
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
    except Exception as e:
        logger.error(f"Error sending test email: {str(e)}")
        
        # Log the failed attempt
        EmailLog.objects.create(
            recipient_email=request.data.get('email', request.user.email),
            subject="Beyond EAMS Email Test",
            message="Test email",
            sent_successfully=False,
            error_message=str(e),
        )
        
        return Response({
            'success': False,
            'error': f'Failed to send test email: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
