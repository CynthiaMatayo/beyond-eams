#!/usr/bin/env python
"""
Create sample activities for testing
"""
import os
import django
from datetime import datetime, timedelta
from django.utils import timezone

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'beyond_eams.settings')
django.setup()

from activities.models import Activity, ActivityCategory
from accounts.models import User

def create_sample_activities():
    """Create sample activities for testing"""
    
    # Create categories first
    categories = [
        {'name': 'Academic', 'description': 'Academic events and seminars', 'color': '#007bff'},
        {'name': 'Sports', 'description': 'Sports and fitness activities', 'color': '#28a745'},
        {'name': 'Cultural', 'description': 'Cultural events and performances', 'color': '#ffc107'},
        {'name': 'Tech', 'description': 'Technology workshops and hackathons', 'color': '#6f42c1'},
        {'name': 'Community Service', 'description': 'Community service and volunteering', 'color': '#fd7e14'},
    ]
    
    created_categories = []
    for cat_data in categories:
        category, created = ActivityCategory.objects.get_or_create(
            name=cat_data['name'],
            defaults=cat_data
        )
        created_categories.append(category)
        if created:
            print(f"✅ Created category: {category.name}")
        else:
            print(f"ℹ️ Category exists: {category.name}")
    
    # Get or create a coordinator user
    coordinator, created = User.objects.get_or_create(
        username='coordinator1',
        defaults={
            'email': 'coordinator@ueab.ac.ke',
            'first_name': 'John',
            'last_name': 'Coordinator',
            'role': 'coordinator',
            'department': 'Management'
        }
    )
    if created:
        coordinator.set_password('password123')
        coordinator.save()
        print(f"✅ Created coordinator: {coordinator.username}")
    
    # Sample activities data
    now = timezone.now()
    
    activities_data = [
        {
            'title': 'Python Programming Workshop',
            'description': 'Learn Python programming from scratch. Perfect for beginners!',
            'location': 'Computer Lab 1',
            'start_time': now + timedelta(days=3),
            'end_time': now + timedelta(days=3, hours=3),
            'category': created_categories[3],  # Tech
            'status': 'upcoming',
            'is_volunteering': False,
            'max_participants': 30,
        },
        {
            'title': 'Campus Cleanup Drive',
            'description': 'Join us in making our campus clean and green!',
            'location': 'Main Campus',
            'start_time': now + timedelta(days=7),
            'end_time': now + timedelta(days=7, hours=4),
            'category': created_categories[4],  # Community Service
            'status': 'upcoming',
            'is_volunteering': True,
            'max_participants': 50,
        },
        {
            'title': 'Football Tournament',
            'description': 'Inter-department football championship. Come support your team!',
            'location': 'Sports Ground',
            'start_time': now + timedelta(days=14),
            'end_time': now + timedelta(days=14, hours=6),
            'category': created_categories[1],  # Sports
            'status': 'upcoming',
            'is_volunteering': False,
            'max_participants': 100,
        },
        {
            'title': 'Cultural Night',
            'description': 'Showcase of different cultures through music, dance, and food.',
            'location': 'Main Auditorium',
            'start_time': now + timedelta(days=21),
            'end_time': now + timedelta(days=21, hours=5),
            'category': created_categories[2],  # Cultural
            'status': 'upcoming',
            'is_volunteering': False,
            'max_participants': 200,
        },
        {
            'title': 'Guest Lecture: AI in Healthcare',
            'description': 'Renowned expert will discuss the future of AI in healthcare.',
            'location': 'Lecture Hall A',
            'start_time': now + timedelta(days=10),
            'end_time': now + timedelta(days=10, hours=2),
            'category': created_categories[0],  # Academic
            'status': 'upcoming',
            'is_volunteering': False,
            'max_participants': 80,
        },
        {
            'title': 'Library Volunteer Program',
            'description': 'Help organize books and assist students in the library.',
            'location': 'University Library',
            'start_time': now + timedelta(days=5),
            'end_time': now + timedelta(days=5, hours=4),
            'category': created_categories[4],  # Community Service
            'status': 'upcoming',
            'is_volunteering': True,
            'max_participants': 15,
        },
    ]
    
    created_activities = []
    for activity_data in activities_data:
        activity, created = Activity.objects.get_or_create(
            title=activity_data['title'],
            defaults={
                **activity_data,
                'created_by': coordinator,
            }
        )
        created_activities.append(activity)
        if created:
            print(f"✅ Created activity: {activity.title}")
        else:
            print(f"ℹ️ Activity exists: {activity.title}")
    
    print(f"\n📊 Summary:")
    print(f"📁 Categories: {ActivityCategory.objects.count()}")
    print(f"🎯 Activities: {Activity.objects.count()}")
    print(f"👥 Users: {User.objects.count()}")
    
    # Show some stats
    volunteer_activities = Activity.objects.filter(is_volunteering=True).count()
    regular_activities = Activity.objects.filter(is_volunteering=False).count()
    print(f"🤝 Volunteer activities: {volunteer_activities}")
    print(f"📅 Regular activities: {regular_activities}")

if __name__ == '__main__':
    create_sample_activities()
