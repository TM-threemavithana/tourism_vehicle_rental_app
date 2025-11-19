# 🚀 WebSocket Notifications - Quick Reference Card

## 🔌 Connection

```javascript
import { io } from 'socket.io-client';

const socket = io('http://localhost:3000/notifications', {
  query: { token: 'your-jwt-token' },
  transports: ['websocket']
});
```

## 📡 Events

### Server → Client
```javascript
socket.on('connected', (data) => {
  // { message, userId, timestamp }
});

socket.on('newNotification', (data) => {
  // { notification: {...}, timestamp }
  showNotification(data.notification);
});

socket.on('unreadCount', (data) => {
  // { count: number }
  updateBadge(data.count);
});

socket.on('error', (data) => {
  // { message }
});
```

### Client → Server
```javascript
// Get unread count
socket.emit('getUnreadCount');

// Mark notification as read
socket.emit('markAsRead', { notificationId: 'abc-123' });

// Mark all as read
socket.emit('markAllAsRead');
```

## 🧪 Testing

```powershell
# Run automated test
.\test-websocket-notifications.ps1

# Open browser client
start test-websocket-client.html
```

## 📊 Monitoring

```http
GET /notifications/ws-stats
Authorization: Bearer {token}
```

## 📚 Documentation

1. **Quick Start:** `WEBSOCKET_QUICK_START.md`
2. **Full Guide:** `WEBSOCKET_NOTIFICATIONS_GUIDE.md`
3. **Architecture:** `WEBSOCKET_ARCHITECTURE_VISUAL.md`
4. **Summary:** `WEBSOCKET_FINAL_SUMMARY.md`

## ⚡ Quick Commands

```powershell
# Start server
npm run start:dev

# Test connection
.\test-websocket-notifications.ps1

# Check running processes
Get-Process -Name "node"

# View server logs
# (check terminal where server is running)
```

## 🔐 Security Checklist

- ✅ JWT token required
- ✅ Token blacklist checked
- ✅ CORS configured
- ✅ Room-based isolation
- ✅ Error handling

## 🎯 Common Issues

**Can't connect?**
- Check server is running
- Verify JWT token is valid
- Check CORS settings

**Not receiving notifications?**
- Verify `connected` event received
- Check userId matches
- Listen for `newNotification` event

**Multiple notifications?**
- Normal! Each tab/device = separate connection

---

**Server:** `ws://localhost:3000/notifications`  
**Status:** ✅ Production Ready  
**Docs:** 4 guides, 1,800+ lines
