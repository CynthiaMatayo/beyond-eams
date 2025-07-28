import os
import django

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'beyond_eams.settings')
django.setup()

from accounts.models import User

def create_instructor():
    """Create an instructor user"""
    
    # Instructor details
    instructor_data = {
        'username': 'dr.smith',
        'email': 'dr.smith@ueab.ac.ke',
        'first_name': 'Dr. Sarah',
        'last_name': 'Smith',
        'role': 'instructor',
        'department': 'Information Systems and Computing'
    }
    
    # Create or get the instructor
    instructor, created = User.objects.get_or_create(
        username=instructor_data['username'],
        defaults=instructor_data
    )
    
    if created:
        instructor.set_password('instructor123')
        instructor.save()
        print(f'✅ Created instructor: {instructor.username}')
    else:
        # Update the existing instructor
        for key, value in instructor_data.items():
            if key != 'username':
                setattr(instructor, key, value)
        instructor.set_password('instructor123')
        instructor.save()
        print(f'ℹ️ Updated instructor: {instructor.username}')
    
    print(f'📧 Email: {instructor.email}')
    print(f'🔑 Password: instructor123')
    print(f'👤 Role: {instructor.role}')
    print(f'🏢 Department: {instructor.department}')
    
    return instructor

def create_multiple_instructors():
    """Create multiple instructors for different departments"""
    
    instructors_data = [
        {
            'username': 'prof.johnson',
            'email': 'prof.johnson@ueab.ac.ke',
            'first_name': 'Prof. Michael',
            'last_name': 'Johnson',
            'role': 'instructor',
            'department': 'Education'
        },
        {
            'username': 'dr.williams',
            'email': 'dr.williams@ueab.ac.ke',
            'first_name': 'Dr. Lisa',
            'last_name': 'Williams',
            'role': 'instructor',
            'department': 'Nursing'
        },
        {
            'username': 'prof.brown',
            'email': 'prof.brown@ueab.ac.ke',
            'first_name': 'Prof. David',
            'last_name': 'Brown',
            'role': 'instructor',
            'department': 'Biological Sciences and Agriculture'
        },
        {
            'username': 'dr.davis',
            'email': 'dr.davis@ueab.ac.ke',
            'first_name': 'Dr. Emily',
            'last_name': 'Davis',
            'role': 'instructor',
            'department': 'Mathematics, Chemistry and Physics'
        }
    ]
    
    created_instructors = []
    
    for instructor_data in instructors_data:
        instructor, created = User.objects.get_or_create(
            username=instructor_data['username'],
            defaults=instructor_data
        )
        
        if created:
            instructor.set_password('instructor123')
            instructor.save()
            print(f'✅ Created instructor: {instructor.username} - {instructor.department}')
        else:
            # Update existing instructor
            for key, value in instructor_data.items():
                if key != 'username':
                    setattr(instructor, key, value)
            instructor.set_password('instructor123')
            instructor.save()
            print(f'ℹ️ Updated instructor: {instructor.username} - {instructor.department}')
        
        created_instructors.append(instructor)
    
    return created_instructors

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

def create_multiple_coordinators():
    """Create multiple coordinators for different departments"""
    
    coordinators_data = [
        {
            'username': 'coord.thompson',
            'email': 'coord.thompson@ueab.ac.ke',
            'first_name': 'Jessica',
            'last_name': 'Thompson',
            'role': 'coordinator',
            'department': 'Academic Affairs'
        },
        {
            'username': 'coord.garcia',
            'email': 'coord.garcia@ueab.ac.ke',
            'first_name': 'Carlos',
            'last_name': 'Garcia',
            'role': 'coordinator',
            'department': 'Student Activities'
        },
        {
            'username': 'coord.lee',
            'email': 'coord.lee@ueab.ac.ke',
            'first_name': 'Amanda',
            'last_name': 'Lee',
            'role': 'coordinator',
            'department': 'Community Outreach'
        }
    ]
    
    created_coordinators = []
    
    for coordinator_data in coordinators_data:
        coordinator, created = User.objects.get_or_create(
            username=coordinator_data['username'],
            defaults=coordinator_data
        )
        
        if created:
            coordinator.set_password('coordinator123')
            coordinator.save()
            print(f'✅ Created coordinator: {coordinator.username} - {coordinator.department}')
        else:
            # Update existing coordinator
            for key, value in coordinator_data.items():
                if key != 'username':
                    setattr(coordinator, key, value)
            coordinator.set_password('coordinator123')
            coordinator.save()
            print(f'ℹ️ Updated coordinator: {coordinator.username} - {coordinator.department}')
        
        created_coordinators.append(coordinator)
    
    return created_coordinators

if __name__ == '__main__':
    print("🎓 Creating Instructors...")
    print("=" * 50)
    
    # Create primary instructor
    primary_instructor = create_instructor()
    
    print("\n🎓 Creating Additional Instructors...")
    print("=" * 50)
    
    # Create multiple instructors
    instructors = create_multiple_instructors()
    
    print("\n👥 Creating Coordinators...")
    print("=" * 50)
    
    # Create primary coordinator
    primary_coordinator = create_coordinator()
    
    print("\n👥 Creating Additional Coordinators...")
    print("=" * 50)
    
    # Create multiple coordinators
    coordinators = create_multiple_coordinators()
    
    print(f"\n📊 Summary:")
    print(f"✅ Total instructors created/updated: {len(instructors) + 1}")
    print(f"✅ Total coordinators created/updated: {len(coordinators) + 1}")
    
    # Display all instructors
    all_instructors = User.objects.filter(role='instructor')
    print(f"\n👩‍🏫 All Instructors in System:")
    print("=" * 50)
    for instructor in all_instructors:
        print(f"👤 {instructor.get_full_name()} ({instructor.username})")
        print(f"   📧 {instructor.email}")
        print(f"   🏢 {instructor.department}")
        print(f"   🔑 Password: instructor123")
        print()
    
    # Display all coordinators
    all_coordinators = User.objects.filter(role='coordinator')
    print(f"\n👥 All Coordinators in System:")
    print("=" * 50)
    for coordinator in all_coordinators:
        print(f"👤 {coordinator.get_full_name()} ({coordinator.username})")
        print(f"   📧 {coordinator.email}")
        print(f"   🏢 {coordinator.department}")
        print(f"   🔑 Password: coordinator123")
        print()
