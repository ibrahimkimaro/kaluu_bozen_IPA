# Backend Integration for Push Notifications

## Django Backend Example

### 1. Install Firebase Admin SDK
```bash
pip install firebase-admin
```

### 2. Get Service Account Key
1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key"
3. Save the JSON file securely on your server

### 3. Django Models (add to your User model)
```python
from django.db import models

class User(AbstractUser):
    # ... existing fields ...
    fcm_token = models.CharField(max_length=255, blank=True, null=True)
```

### 4. Create Notification Service
```python
# notifications/firebase_service.py
import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings

class FirebaseService:
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
            firebase_admin.initialize_app(cred)
        return cls._instance
    
    def send_shipment_update(self, fcm_token, tracking_code, route_stage, customer_name):
        """Send notification when shipment route_progress changes"""
        if not fcm_token:
            return None
            
        message = messaging.Message(
            notification=messaging.Notification(
                title='📦 Shipment Update',
                body=f'Your shipment {tracking_code} has reached {route_stage}',
            ),
            data={
                'tracking_code': tracking_code,
                'route_stage': route_stage,
                'type': 'shipment_update',
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
            token=fcm_token,
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    icon='ic_launcher',
                    color='#0EA5E9',
                ),
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        sound='default',
                        badge=1,
                    ),
                ),
            ),
        )
        
        try:
            response = messaging.send(message)
            return response
        except Exception as e:
            print(f"Error sending notification: {e}")
            return None
```

### 5. Update Shipment Signal
```python
# shipping/signals.py
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Shipment
from notifications.firebase_service import FirebaseService

@receiver(post_save, sender=Shipment)
def notify_shipment_update(sender, instance, created, **kwargs):
    """Send notification when route_progress changes"""
    if not created:
        # Check if route_progress changed
        old_instance = Shipment.objects.filter(pk=instance.pk).first()
        if old_instance and old_instance.route_progress != instance.route_progress:
            # Get user's FCM token
            user = instance.customer  # Adjust based on your model
            if user and user.fcm_token:
                firebase_service = FirebaseService()
                firebase_service.send_shipment_update(
                    fcm_token=user.fcm_token,
                    tracking_code=instance.tracking_code,
                    route_stage=instance.current_route_stage_display,
                    customer_name=instance.customer_full_name,
                )
```

### 6. API Endpoint to Update FCM Token
```python
# auths/views.py
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_fcm_token(request):
    """Update user's FCM token"""
    fcm_token = request.data.get('fcm_token')
    if fcm_token:
        request.user.fcm_token = fcm_token
        request.user.save()
        return Response({'status': 'success'})
    return Response({'error': 'fcm_token required'}, status=400)
```

### 7. URL Configuration
```python
# urls.py
urlpatterns = [
    # ... other patterns ...
    path('api/auth/update-fcm-token/', update_fcm_token, name='update_fcm_token'),
]
```

### 8. Settings Configuration
```python
# settings.py
FIREBASE_CREDENTIALS_PATH = os.path.join(BASE_DIR, 'serviceAccountKey.json')
```

## Testing from Django Admin

You can also send test notifications from Django admin:

```python
# shipping/admin.py
from django.contrib import admin
from .models import Shipment
from notifications.firebase_service import FirebaseService

@admin.register(Shipment)
class ShipmentAdmin(admin.ModelAdmin):
    actions = ['send_test_notification']
    
    def send_test_notification(self, request, queryset):
        firebase_service = FirebaseService()
        for shipment in queryset:
            user = shipment.customer
            if user and user.fcm_token:
                firebase_service.send_shipment_update(
                    fcm_token=user.fcm_token,
                    tracking_code=shipment.tracking_code,
                    route_stage=shipment.current_route_stage_display,
                    customer_name=shipment.customer_full_name,
                )
        self.message_user(request, f"Sent notifications for {queryset.count()} shipments")
    
    send_test_notification.short_description = "Send notification to selected shipments"
```

## Important Notes

1. **Error Handling**: Always handle FCM token errors (expired, invalid, etc.)
2. **Token Refresh**: Implement token refresh logic on the Flutter side
3. **Batch Sending**: For multiple users, use `messaging.send_multicast()`
4. **Testing**: Use Firebase Console to send test messages first

## Security

- Keep `serviceAccountKey.json` secure
- Add it to `.gitignore`
- Use environment variables in production
- Validate FCM tokens before saving
