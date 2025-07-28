from django.core.management.base import BaseCommand
from accounts.models import User


class Command(BaseCommand):
    help = 'Create an admin user'

    def add_arguments(self, parser):
        parser.add_argument('--username', type=str, help='Username for the admin user')
        parser.add_argument('--email', type=str, help='Email for the admin user')
        parser.add_argument('--password', type=str, help='Password for the admin user')
        parser.add_argument('--first_name', type=str, help='First name for the admin user')
        parser.add_argument('--last_name', type=str, help='Last name for the admin user')

    def handle(self, *args, **options):
        # Set default values if not provided
        username = options.get('username') or 'admin.cynthia'
        email = options.get('email') or 'admin.cynthia@ueab.ac.ke'
        password = options.get('password') or 'admin123'
        first_name = options.get('first_name') or 'Cynthia'
        last_name = options.get('last_name') or 'Admin'

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
            self.stdout.write(
                self.style.SUCCESS(f'✅ Created admin user: {user.username}')
            )
        else:
            # Update password and ensure admin privileges
            user.set_password(password)
            user.role = 'admin'
            user.is_staff = True
            user.is_superuser = True
            user.save()
            self.stdout.write(
                self.style.WARNING(f'ℹ️ Updated existing user: {user.username}')
            )

        self.stdout.write(f'📧 Email: {user.email}')
        self.stdout.write(f'🔑 Password: {password}')
        self.stdout.write(f'👤 Role: {user.role}')
        self.stdout.write(f'🏢 Department: {user.department}')
        self.stdout.write(
            self.style.SUCCESS('Admin user is ready to use!')
        )
