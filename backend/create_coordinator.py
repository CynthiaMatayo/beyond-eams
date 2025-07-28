import os
import django

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'beyond_eams.settings')
django.setup()

from accounts.models import User

def create_coordinator():
    """Create a coordinator user"""
    
    # Coordinator details
    coordinator_data = {
        'username': 'coord.wilson',
        'email': 'coord.wilson@ueab.ac.ke',
        'first_name': 'Mark',
        'last_name': 'Wilson',
        'role': 'coordinator',
        'department': 'Student Affairs'
    }
    
    # Create or get the coordinator
    coordinator, created = User.objects.get_or_create(
        username=coordinator_data['username'],
        defaults=coordinator_data
    )
    
    if created:
        coordinator.set_password('coordinator123')
        coordinator.save()
        print(f'✅ Created coordinator: {coordinator.username}')
    else:
        # Update the existing coordinator
        for key, value in coordinator_data.items():
            if key != 'username':
                setattr(coordinator, key, value)
        coordinator.set_password('coordinator123')
        coordinator.save()
        print(f'ℹ️ Updated coordinator: {coordinator.username}')
    
    print(f'📧 Email: {coordinator.email}')
    print(f'🔑 Password: coordinator123')
    print(f'👤 Role: {coordinator.role}')
    print(f'🏢 Department: {coordinator.department}')
    
    return coordinator

if __name__ == '__main__':
    print("👥 Creating Coordinator...")
    print("=" * 50)
    
    # Create coordinator
    coordinator = create_coordinator()
    
    print(f"\n📊 Summary:")
    print(f"✅ Coordinator created/updated successfully!")
    
    # Display all coordinators in system
    all_coordinators = User.objects.filter(role='coordinator')
    print(f"\n👥 All Coordinators in System:")
    print("=" * 50)
    for coord in all_coordinators:
        print(f"👤 {coord.get_full_name()} ({coord.username})")
        print(f"   📧 {coord.email}")
        print(f"   🏢 {coord.department}")
        print(f"   🔑 Password: coordinator123")
        print()
