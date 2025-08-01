# Generated by Django 5.2.1 on 2025-06-25 06:57

import django.db.models.deletion
import uuid
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('activities', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='ActivityQRCode',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('code', models.UUIDField(default=uuid.uuid4, editable=False, unique=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('expires_at', models.DateTimeField(blank=True, null=True)),
                ('is_active', models.BooleanField(default=True)),
                ('activity', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='qr_code', to='activities.activity')),
            ],
        ),
        migrations.CreateModel(
            name='Attendance',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('checked_in_at', models.DateTimeField(auto_now_add=True)),
                ('verification_method', models.CharField(choices=[('qr_code', 'QR Code'), ('manual', 'Manual Entry')], default='qr_code', max_length=20)),
                ('activity', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='attendances', to='activities.activity')),
                ('student', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='attendances', to=settings.AUTH_USER_MODEL)),
                ('verified_by', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='verified_attendances', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-checked_in_at'],
                'unique_together': {('activity', 'student')},
            },
        ),
    ]
