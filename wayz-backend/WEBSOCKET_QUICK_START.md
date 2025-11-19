# 🚀 WebSocket Notifications - Quick Start Guide

## ✅ Setup Complete!

Your WebSocket notification system is now **fully configured** and ready to use. This guide will help you test it quickly.

---

## 📦 What's Already Done

✅ **WebSocket Gateway** - Implemented with JWT authentication  
✅ **Notifications Service** - Integrated with real-time push  
✅ **Token Blacklist** - Security integrated  
✅ **Multi-device Support** - Users can connect from multiple devices  
✅ **Room-based Broadcasting** - User-specific notification delivery  

---

## 🎯 Quick Test (3 Steps)

### Step 1: Start the Server

```powershell
# The server should already be running. If not:
npm run start:dev
```

Wait for: `🚀 WebSocket Gateway initialized for notifications`

### Step 2: Run the Test Script

```powershell
# This will register a user, get a token, and test WebSocket connection
.\test-websocket-notifications.ps1
```

**Expected Output:**
```
✅ Registration successful
✅ Retrieved notifications
✅ Notification created
💡 If WebSocket is connected, client should receive: Event: 'newNotification'
✅ HTML test client saved: test-websocket-client.html
```

### Step 3: Test with Browser Client

1. Open `test-websocket-client.html` in your browser
2. Click **"Connect"** button
3. Watch the Event Log for:
   - ✅ Connected
   - 🎉 Auth OK
   - 🔢 Unread count

---

## 🧪 Manual Testing

### Test 1: Connect to WebSocket

```javascript
const io = require('socket.io-client');

// Get a valid JWT token first (register or login)
const TOKEN = 'your-jwt-token-here';

const socket = io('http://localhost:3000/notifications', {
  query: { token: TOKEN },
  transports: ['websocket'],
});

socket.on('connect', () => {
  console.log('✅ Connected!');
});

socket.on('connected', (data) => {
  console.log('🎉 Server confirmed:', data);
});

socket.on('newNotification', (data) => {
  console.log('📬 New notification:', data);
});
```

### Test 2: Create a Notification (Triggers WebSocket)

```powershell
# First, get a JWT token
$TOKEN = "your-jwt-token"

# Create a notification
$body = @{
    userId = "user-id-here"
    title = "Test Notification"
    message = "This is a test!"
    type = "INFO"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3000/notifications" `
    -Method Post `
    -ContentType "application/json" `
    -Headers @{ Authorization = "Bearer $TOKEN" } `
    -Body $body
```

**Result:** Any connected WebSocket client for that user will immediately receive the notification!

---

## 📱 Flutter Integration

Add to your `pubspec.yaml`:
```yaml
dependencies:
  socket_io_client: ^2.0.3+1
```

Quick implementation:

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class NotificationService {
  late IO.Socket socket;
  
  void connect(String jwtToken) {
    socket = IO.io(
      'http://localhost:3000/notifications',
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setQuery({'token': jwtToken})
        .build(),
    );
    
    socket.onConnect((_) {
      print('✅ Connected to notifications');
    });
    
    socket.on('newNotification', (data) {
      print('📬 New notification: ${data['notification']}');
      // Show notification to user
      _showNotification(data['notification']);
    });
    
    socket.on('unreadCount', (data) {
      print('🔢 Unread: ${data['count']}');
      // Update badge
      _updateBadge(data['count']);
    });
  }
  
  void markAsRead(String notificationId) {
    socket.emit('markAsRead', {'notificationId': notificationId});
  }
  
  void disconnect() {
    socket.disconnect();
  }
}
```

---

## 🔌 WebSocket Events Reference

### Server → Client Events

| Event | When Sent | Payload |
|-------|-----------|---------|
| `connected` | After successful auth | `{ message, userId, timestamp }` |
| `unreadCount` | On connect & after reads | `{ count: number }` |
| `newNotification` | When notification created | `{ notification, timestamp }` |
| `error` | On auth failure | `{ message }` |

### Client → Server Events

| Event | Purpose | Payload |
|-------|---------|---------|
| `subscribe` | Confirm subscription | None |
| `getUnreadCount` | Request unread count | None |
| `markAsRead` | Mark notification as read | `{ notificationId }` |
| `markAllAsRead` | Mark all as read | None |

---

## 🐛 Troubleshooting

### ❌ "Authentication token required"
**Solution:** Include token in connection:
```javascript
io('http://localhost:3000/notifications', {
  query: { token: 'your-jwt-token' }
});
```

### ❌ "Token has been revoked"
**Solution:** Get a fresh token (user logged out or token was blacklisted)

### ❌ Not receiving notifications
**Checklist:**
1. ✅ Server running?
2. ✅ WebSocket connected? (check `connected` event)
3. ✅ Creating notification for correct `userId`?
4. ✅ Listening to `newNotification` event?

### ❌ CORS issues
**Solution:** Update gateway CORS settings:
```typescript
// src/notifications/notifications.gateway.ts
@WebSocketGateway({
  namespace: '/notifications',
  cors: {
    origin: 'http://localhost:3000', // Your frontend URL
    credentials: true,
  },
})
```

---

## 📊 Monitor Connections

Check active WebSocket connections:

```powershell
$TOKEN = "your-jwt-token"

Invoke-RestMethod -Uri "http://localhost:3000/notifications/ws-stats" `
    -Method Get `
    -Headers @{ Authorization = "Bearer $TOKEN" }
```

**Response:**
```json
{
  "totalConnections": 5,
  "uniqueUsers": 3,
  "userConnections": [
    { "userId": "user-1", "socketCount": 2 },
    { "userId": "user-2", "socketCount": 1 }
  ]
}
```

---

## 🎓 What Happens When...

### User Logs In
1. Get JWT token from `/auth/login`
2. Connect to WebSocket with token
3. Receive `connected` event
4. Receive current `unreadCount`

### Notification Created
1. Backend calls `NotificationsService.create()`
2. Notification saved to database
3. **WebSocket automatically sends to user** via `sendNotificationToUser()`
4. Client receives `newNotification` event

### User Marks as Read
1. Client sends `markAsRead` event
2. Database updated
3. All user's devices receive updated `unreadCount`

### User Logs Out
1. Token gets blacklisted
2. WebSocket connection rejected if reconnect attempted
3. Must login again to get new token

---

## 📚 Full Documentation

For detailed documentation, see:
- **[WEBSOCKET_NOTIFICATIONS_GUIDE.md](./WEBSOCKET_NOTIFICATIONS_GUIDE.md)** - Complete guide with examples
- **[WEBSOCKET_NOTIFICATIONS_COMPLETE.md](./WEBSOCKET_NOTIFICATIONS_COMPLETE.md)** - Implementation summary

---

## ✨ Next Steps

1. ✅ **Test the setup** - Run `test-websocket-notifications.ps1`
2. ✅ **Open HTML client** - Test in browser
3. ✅ **Integrate with Flutter** - Use the code example above
4. ✅ **Test multi-device** - Open multiple browser tabs
5. ✅ **Monitor connections** - Check `/notifications/ws-stats`

---

## 🎉 You're Ready!

Your WebSocket notification system is production-ready with:
- 🔐 JWT authentication
- 🚫 Token blacklist security
- 📱 Multi-device support
- 🎯 User-specific delivery
- 📊 Connection monitoring
- ⚡ Real-time push notifications

**Happy coding!** 🚀
