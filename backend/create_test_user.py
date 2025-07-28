from accounts.models import User

# Create test user
user, created = User.objects.get_or_create(
    username='john.student',
    defaults={
        'email': 'john.student@ueab.ac.ke',
        'first_name': 'John',
        'last_name': 'Student',
        'role': 'student',
        'department': 'Information Systems and Computing'
    }
)

if created:
    user.set_password('password123')
    user.save()
    print(f'✅ Created test user: {user.username}')
else:
    # Update password in case it exists
    user.set_password('password123')
    user.save()
    print(f'ℹ️ Updated test user: {user.username}')

print(f'📧 Email: {user.email}')
print(f'🔑 Password: password123')
print(f'👤 Role: {user.role}')
