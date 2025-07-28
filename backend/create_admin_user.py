#!/usr/bin/env python
"""
Simple script to create admin user admin.cynthia
Run this from the backend directory with: python create_admin_user.py
"""

import os
import sys
import django

# Add the current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Set up Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'beyond_eams.settings')
django.setup()

from accounts.models import User

def create_admin_user():
    """Create admin.cynthia user"""
    
    username = 'admin.cynthia'
    email = 'admin.cynthia@ueab.ac.ke'
    password = 'admin123'
    first_name = 'Cynthia'
    last_name = 'Admin'
    
    print("🔨 Creating admin user...")
    print(f"👤 Username: {username}")
    print(f"📧 Email: {email}")
    
    # Create or update admin user
    user, created = User.objects.get_or_create(
        username=username,
        defaults={
            'email': email,
            'first_name': first_name,
            'last_name': last_name,
            'role': 'admin',
            'department': 'Information Systems and Computing',
            'is_staff': True,
            'is_superuser': True,
        }
    )

    if created:
        user.set_password(password)
        user.save()
        print('✅ Successfully created admin user!')
    else:
        # Update password and ensure admin privileges
        user.set_password(password)
        user.role = 'admin'
        user.is_staff = True
        user.is_superuser = True
        user.email = email
        user.first_name = first_name
        user.last_name = last_name
        user.save()
        print('ℹ️ Updated existing user with admin privileges!')

    print(f'📧 Email: {user.email}')
    print(f'🔑 Password: {password}')
    print(f'👤 Role: {user.role}')
    print(f'🏢 Department: {user.department}')
    print(f'🛡️ Staff: {user.is_staff}')
    print(f'🔐 Superuser: {user.is_superuser}')
    print('🎉 Admin user is ready to use!')

if __name__ == '__main__':
    try:
        create_admin_user()
    except Exception as e:
        print(f'❌ Error creating admin user: {e}')
        sys.exit(1)
