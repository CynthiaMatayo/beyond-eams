from django.http import JsonResponse

def home(request):
    return JsonResponse({
        "message": "Welcome to Beyond EAMS API",
        "version": "1.0",
        "endpoints": {
            "auth": "/api/auth/",
            "activities": "/api/activities/",
        }
    })