# backend/accounts/management/commands/seed_departments.py
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
import random

User = get_user_model()

class Command(BaseCommand):
    help = 'Seed student accounts with diverse departments'

    def handle(self, *args, **options):
        # UEAB Official Departments
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

        # Get all student users
        students = User.objects.filter(role='student')
        
        if not students.exists():
            self.stdout.write(
                self.style.WARNING('No student users found. Create some students first.')
            )
            return

        updated_count = 0
        
        for student in students:
            # Randomly assign department
            student.department = random.choice(departments)
            student.save()
            updated_count += 1

        self.stdout.write(
            self.style.SUCCESS(
                f'Successfully updated {updated_count} student departments from {len(departments)} available departments'
            )
        )
        
        # Show distribution
        dept_counts = {}
        for dept in departments:
            count = User.objects.filter(role='student', department=dept).count()
            if count > 0:
                dept_counts[dept] = count
        
        self.stdout.write('\nDepartment Distribution:')
        for dept, count in sorted(dept_counts.items()):
            self.stdout.write(f'  {dept}: {count} students')