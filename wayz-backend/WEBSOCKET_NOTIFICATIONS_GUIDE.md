# WebSocket Notifications - Complete Guide

## 📋 Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Setup & Configuration](#setup--configuration)
- [API Reference](#api-reference)
- [Client Integration](#client-integration)
- [Testing](#testing)
- [Production Deployment](#production-deployment)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

The WebSocket notification system provides **real-time push notifications** to connected clients using Socket.IO. Key features include:

- ✅ **JWT Authentication** - Secure WebSocket connections with token validation
- ✅ **Token Blacklist Integration** - Prevents revoked tokens from connecting
- ✅ **Room-Based Broadcasting** - User-specific notification delivery
- ✅ **Connection Management** - Track multiple devices per user
- ✅ **Automatic Notification Push** - Sends notifications when created
- ✅ **Bidirectional Communication** - Client can mark notifications as read via WebSocket

## 🏗️ Architecture

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                     WebSocket Gateway                         │
│  - JWT Authentication                                         │
│  - Connection Lifecycle Management                            │
│  - User Room Management                                       │
│  - Real-time Event Broadcasting                               │
└───────────────┬─────────────────────────────────────────────┘
                │
                ├─► NotificationsService
                │   └─► Automatically sends WebSocket events
                │       when notifications are created
                │
                ├─► TokenBlacklistService
                │   └─► Validates tokens on connection
                │
                └─► JwtService
                    └─► Verifies JWT tokens
```

### File Structure

```
src/notifications/
├── notifications.gateway.ts          # WebSocket gateway implementation
├── notifications.service.ts          # Service with WebSocket integration
├── notifications.module.ts           # Module configuration
├── notifications.controller.ts       # REST API endpoints
└── guards/
    └── ws-jwt.guard.ts              # WebSocket JWT authentication guard
```

## 🔧 Setup & Configuration

### Dependencies (Already Installed)

```json
{
  "@nestjs/websockets": "^10.x.x",
  "@nestjs/platform-socket.io": "^10.x.x",
  "socket.io": "^4.x.x"
}
```

### Environment Variables

```env
JWT_SECRET=your-secret-key
JWT_EXPIRATION=7d
```

### CORS Configuration

Update `notifications.gateway.ts` for production:

```typescript
@WebSocketGateway({
  namespace: '/notifications',
  cors: {
    origin: process.env.FRONTEND_URL || '*',
    credentials: true,
  },
})
```

## 📚 API Reference

### WebSocket Connection

**URL:** `ws://localhost:3000/notifications` (or `wss://` for production)

**Authentication:** Include JWT token in one of two ways:

1. **Query Parameter:**
   ```javascript
   io('http://localhost:3000/notifications', {
     query: { token: 'your-jwt-token' }
   });
   ```

2. **Authorization Header:**
   ```javascript
   io('http://localhost:3000/notifications', {
     extraHeaders: {
       authorization: 'Bearer your-jwt-token'
     }
   });
   ```

### Server → Client Events

| Event | Payload | Description |
|-------|---------|-------------|
| `connected` | `{ message: string, userId: string, timestamp: string }` | Sent when client successfully connects |
| `unreadCount` | `{ count: number }` | Sent with current unread notification count |
| `newNotification` | `{ notification: Notification, timestamp: string }` | Sent when a new notification is created |
| `error` | `{ message: string }` | Sent when an error occurs (auth failure, etc.) |

### Client → Server Events

| Event | Payload | Response | Description |
|-------|---------|----------|-------------|
| `subscribe` | None | `{ event: 'subscribed', data: { userId: string } }` | Confirms subscription to notifications |
| `getUnreadCount` | None | `{ event: 'unreadCount', data: { count: number } }` | Gets current unread count |
| `markAsRead` | `{ notificationId: string }` | `{ event: 'markedAsRead', data: { notificationId: string } }` | Marks notification as read |
| `markAllAsRead` | None | `{ event: 'allMarkedAsRead', data: { userId: string } }` | Marks all notifications as read |

### REST API Endpoints (Existing)

These endpoints still work alongside WebSocket:

```
GET    /notifications          - Get user's notifications
POST   /notifications          - Create notification (triggers WebSocket)
PATCH  /notifications/:id/read - Mark notification as read
PATCH  /notifications/read-all - Mark all as read
GET    /notifications/unread/count - Get unread count
DELETE /notifications/:id      - Delete notification
```

## 💻 Client Integration

### JavaScript/TypeScript (Socket.IO Client)

```bash
npm install socket.io-client
```

```typescript
import { io, Socket } from 'socket.io-client';

// Connect with JWT token
const socket: Socket = io('http://localhost:3000/notifications', {
  query: { token: 'your-jwt-token-here' },
  transports: ['websocket'], // Force WebSocket transport
});

// Connection events
socket.on('connect', () => {
  console.log('Connected to WebSocket server');
});

socket.on('connected', (data) => {
  console.log('Server confirmed connection:', data);
  // Output: { message: '...', userId: '...', timestamp: '...' }
});

// Listen for new notifications
socket.on('newNotification', (data) => {
  console.log('New notification received:', data.notification);
  showNotificationToUser(data.notification);
});

// Listen for unread count updates
socket.on('unreadCount', (data) => {
  console.log('Unread count:', data.count);
  updateBadge(data.count);
});

// Handle errors
socket.on('error', (data) => {
  console.error('WebSocket error:', data.message);
});

// Handle disconnection
socket.on('disconnect', () => {
  console.log('Disconnected from WebSocket server');
});

// Client actions
function markNotificationAsRead(notificationId: string) {
  socket.emit('markAsRead', { notificationId }, (response) => {
    console.log('Marked as read:', response);
  });
}

function markAllAsRead() {
  socket.emit('markAllAsRead', null, (response) => {
    console.log('All marked as read:', response);
  });
}

function getUnreadCount() {
  socket.emit('getUnreadCount', null, (response) => {
    console.log('Unread count:', response.data.count);
  });
}
```

### Flutter/Dart (socket_io_client)

```yaml
# pubspec.yaml
dependencies:
  socket_io_client: ^2.0.3+1
```

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class NotificationSocket {
  late IO.Socket socket;
  
  void connect(String token) {
    socket = IO.io(
      'http://localhost:3000/notifications',
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setQuery({'token': token})
        .build(),
    );
    
    socket.onConnect((_) {
      print('Connected to WebSocket server');
    });
    
    socket.on('connected', (data) {
      print('Server confirmed: $data');
    });
    
    socket.on('newNotification', (data) {
      print('New notification: ${data['notification']}');
      _handleNewNotification(data['notification']);
    });
    
    socket.on('unreadCount', (data) {
      print('Unread count: ${data['count']}');
      _updateBadge(data['count']);
    });
    
    socket.on('error', (data) {
      print('WebSocket error: ${data['message']}');
    });
    
    socket.onDisconnect((_) {
      print('Disconnected from WebSocket server');
    });
  }
  
  void markAsRead(String notificationId) {
    socket.emitWithAck('markAsRead', {'notificationId': notificationId}, 
      ack: (response) {
        print('Marked as read: $response');
      }
    );
  }
  
  void markAllAsRead() {
    socket.emitWithAck('markAllAsRead', null, 
      ack: (response) {
        print('All marked as read: $response');
      }
    );
  }
  
  void disconnect() {
    socket.disconnect();
  }
  
  void _handleNewNotification(dynamic notification) {
    // Update UI, show local notification, etc.
  }
  
  void _updateBadge(int count) {
    // Update notification badge
  }
}
```

### React Example

```typescript
import { useEffect, useState } from 'react';
import { io, Socket } from 'socket.io-client';

function useNotifications(token: string) {
  const [socket, setSocket] = useState<Socket | null>(null);
  const [unreadCount, setUnreadCount] = useState(0);
  const [notifications, setNotifications] = useState<any[]>([]);

  useEffect(() => {
    const newSocket = io('http://localhost:3000/notifications', {
      query: { token },
      transports: ['websocket'],
    });

    newSocket.on('connected', (data) => {
      console.log('Connected:', data);
    });

    newSocket.on('unreadCount', (data) => {
      setUnreadCount(data.count);
    });

    newSocket.on('newNotification', (data) => {
      setNotifications((prev) => [data.notification, ...prev]);
      setUnreadCount((prev) => prev + 1);
      
      // Show browser notification
      if (Notification.permission === 'granted') {
        new Notification(data.notification.title, {
          body: data.notification.message,
        });
      }
    });

    newSocket.on('error', (data) => {
      console.error('WebSocket error:', data.message);
    });

    setSocket(newSocket);

    return () => {
      newSocket.close();
    };
  }, [token]);

  const markAsRead = (notificationId: string) => {
    if (socket) {
      socket.emit('markAsRead', { notificationId });
    }
  };

  const markAllAsRead = () => {
    if (socket) {
      socket.emit('markAllAsRead');
    }
  };

  return {
    socket,
    unreadCount,
    notifications,
    markAsRead,
    markAllAsRead,
  };
}

export default useNotifications;
```

## 🧪 Testing

### Manual Testing with Socket.IO Client

Create a test file: `test-websocket.js`

```javascript
const io = require('socket.io-client');

// Replace with a valid JWT token
const TOKEN = 'your-jwt-token-here';

const socket = io('http://localhost:3000/notifications', {
  query: { token: TOKEN },
  transports: ['websocket'],
});

socket.on('connect', () => {
  console.log('✅ Connected to WebSocket server');
});

socket.on('connected', (data) => {
  console.log('🎉 Server confirmed:', data);
});

socket.on('newNotification', (data) => {
  console.log('📬 New notification:', data);
});

socket.on('unreadCount', (data) => {
  console.log('🔢 Unread count:', data.count);
});

socket.on('error', (data) => {
  console.error('❌ Error:', data.message);
});

socket.on('disconnect', () => {
  console.log('🔌 Disconnected');
});

// Test commands
setTimeout(() => {
  console.log('Sending subscribe...');
  socket.emit('subscribe');
}, 1000);

setTimeout(() => {
  console.log('Getting unread count...');
  socket.emit('getUnreadCount');
}, 2000);
```

Run:
```bash
node test-websocket.js
```

### PowerShell Testing Script

Create `test-websocket.ps1`:

```powershell
# Test WebSocket connection with Socket.IO client
$TOKEN = "your-jwt-token-here"

Write-Host "Testing WebSocket Notifications..." -ForegroundColor Cyan
Write-Host "Make sure the server is running on http://localhost:3000" -ForegroundColor Yellow
Write-Host ""

# Install socket.io-client if not already installed
if (!(Test-Path "node_modules/socket.io-client")) {
    Write-Host "Installing socket.io-client..." -ForegroundColor Yellow
    npm install socket.io-client
}

# Create test script
$testScript = @"
const io = require('socket.io-client');

const socket = io('http://localhost:3000/notifications', {
  query: { token: '$TOKEN' },
  transports: ['websocket'],
});

socket.on('connect', () => {
  console.log('✅ Connected successfully');
});

socket.on('connected', (data) => {
  console.log('🎉 Server response:', JSON.stringify(data, null, 2));
});

socket.on('newNotification', (data) => {
  console.log('📬 New notification:', JSON.stringify(data, null, 2));
});

socket.on('unreadCount', (data) => {
  console.log('🔢 Unread count:', data.count);
});

socket.on('error', (data) => {
  console.error('❌ Error:', data.message);
  process.exit(1);
});

setTimeout(() => {
  socket.emit('getUnreadCount');
}, 1000);

setTimeout(() => {
  console.log('\nDisconnecting...');
  socket.disconnect();
  process.exit(0);
}, 3000);
"@

Set-Content -Path "test-ws-temp.js" -Value $testScript
node test-ws-temp.js
Remove-Item "test-ws-temp.js"
```

### Testing with Postman

1. Create a new **WebSocket Request** in Postman
2. URL: `ws://localhost:3000/notifications`
3. Add message: `?token=your-jwt-token`
4. Connect and send events:
   ```json
   {
     "event": "subscribe"
   }
   ```

## 🚀 Production Deployment

### Environment Configuration

```env
# Production WebSocket settings
WEBSOCKET_PORT=3000
FRONTEND_URL=https://your-frontend-domain.com
JWT_SECRET=your-production-secret
REDIS_HOST=your-redis-host
REDIS_PORT=6379
```

### HTTPS/WSS Configuration

For secure WebSocket connections (wss://), ensure your server has SSL certificates:

```typescript
// main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import * as fs from 'fs';

async function bootstrap() {
  const httpsOptions = {
    key: fs.readFileSync('./secrets/private-key.pem'),
    cert: fs.readFileSync('./secrets/public-certificate.pem'),
  };
  
  const app = await NestFactory.create(AppModule, {
    httpsOptions, // Enable HTTPS
  });
  
  await app.listen(3000);
}
bootstrap();
```

### Load Balancing

For WebSocket with load balancers, use sticky sessions (session affinity):

**NGINX Configuration:**
```nginx
upstream backend {
    ip_hash;  # Enable sticky sessions
    server backend1:3000;
    server backend2:3000;
}

server {
    location /notifications {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### Monitoring

Monitor WebSocket connections:

```typescript
// Add to notifications.controller.ts
@Get('ws-stats')
@UseGuards(JwtAuthGuard)
getWebSocketStats() {
  return this.notificationsGateway.getConnectionStats();
}
```

Response:
```json
{
  "totalConnections": 125,
  "uniqueUsers": 98,
  "userConnections": [
    { "userId": "user-123", "socketCount": 2 },
    { "userId": "user-456", "socketCount": 1 }
  ]
}
```

## 🐛 Troubleshooting

### Connection Issues

**Problem:** Client can't connect to WebSocket

**Solutions:**
1. Verify server is running: `http://localhost:3000/health`
2. Check CORS settings in `notifications.gateway.ts`
3. Ensure JWT token is valid and not expired
4. Check token is not blacklisted
5. Verify firewall allows WebSocket connections

### Authentication Failures

**Problem:** `Authentication token required` or `Token has been revoked`

**Solutions:**
1. Verify token format: `Bearer <token>` or query param `?token=<token>`
2. Check token hasn't expired
3. Verify user hasn't logged out (token blacklisted)
4. Ensure `JWT_SECRET` matches between token generation and validation

### Not Receiving Notifications

**Problem:** Connected but not receiving `newNotification` events

**Solutions:**
1. Verify user is joining correct room: `user:${userId}`
2. Check NotificationsService is calling `notificationsGateway.sendNotificationToUser()`
3. Ensure `forwardRef()` is used correctly in module imports
4. Check notification `userId` matches connected user's ID

### Multiple Connections

**Problem:** User receives notifications multiple times

**Explanation:** This is **normal behavior** - each device/browser tab creates a separate connection.

**To verify:**
```typescript
socket.emit('getUnreadCount'); // Should be same on all devices
```

## 📊 Performance Considerations

### Scaling

- **Redis Adapter** for horizontal scaling (multiple server instances):
  ```bash
  npm install @socket.io/redis-adapter redis
  ```

  ```typescript
  import { IoAdapter } from '@nestjs/platform-socket.io';
  import { createAdapter } from '@socket.io/redis-adapter';
  import { createClient } from 'redis';

  const pubClient = createClient({ host: 'localhost', port: 6379 });
  const subClient = pubClient.duplicate();

  io.adapter(createAdapter(pubClient, subClient));
  ```

### Connection Limits

- Monitor active connections via `getConnectionStats()`
- Consider rate limiting connections per user
- Implement connection timeout/keepalive

### Message Size

- Keep notification payloads small
- Avoid sending full user objects - send IDs and fetch details via REST if needed

## 🔐 Security Best Practices

1. **Always use WSS (wss://)** in production
2. **Validate tokens** on every connection
3. **Check token blacklist** on connection and periodically
4. **Implement rate limiting** on WebSocket events
5. **Use room-based access control** - users can only join their own rooms
6. **Sanitize user inputs** in WebSocket messages
7. **Set appropriate CORS** - don't use `'*'` in production

## 📝 Summary

✅ **WebSocket gateway** implemented with JWT authentication  
✅ **Token blacklist** integrated for security  
✅ **Automatic notifications** sent when created via NotificationsService  
✅ **Room-based broadcasting** for user-specific delivery  
✅ **Multiple device support** - users can connect from multiple devices  
✅ **Bidirectional communication** - mark as read via WebSocket  
✅ **Production-ready** with error handling and monitoring  

---

**Next Steps:**
1. ✅ Test WebSocket connection with client
2. ✅ Integrate with Flutter frontend
3. ✅ Set up monitoring and logging
4. ✅ Configure production SSL/WSS
5. ✅ Implement Redis adapter for scaling (optional)

**Support:** For issues, check [Troubleshooting](#troubleshooting) section or review server logs.
