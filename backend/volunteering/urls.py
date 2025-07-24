# backend/volunteering/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('', views.VolunteerTaskListView.as_view(), name='volunteer-task-list'),
    path('<int:pk>/', views.VolunteerTaskDetailView.as_view(), name='volunteer-task-detail'),
    path('<int:task_id>/apply/', views.VolunteerApplicationView.as_view(), name='volunteer-apply'),
    path('my-applications/', views.MyVolunteerApplicationsView.as_view(), name='my-volunteer-applications'),
]