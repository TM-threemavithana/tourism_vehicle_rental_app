# 🧪 WebSocket Notifications Testing Script
# Tests real-time notification delivery via WebSocket

param(
    [string]$BaseUrl = "http://localhost:3000",
    [string]$TestEmail = "wstest_$(Get-Random)@example.com",
    [string]$TestPassword = "Test123!"
)

Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host   "║    WebSocket Real-Time Notifications Test Suite         ║" -ForegroundColor Cyan
Write-Host   "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "🌐 Server: $BaseUrl" -ForegroundColor Gray
Write-Host "📧 Test Email: $TestEmail`n" -ForegroundColor Gray

# ============================================================================
# Test 1: Register User and Get JWT Token
# ============================================================================
Write-Host "[Test 1] Registering test user..." -ForegroundColor Yellow
try {
    $registerBody = @{
        email = $TestEmail
        password = $TestPassword
        firstName = "WebSocket"
        lastName = "Tester"
        phoneNumber = "+1234567890"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "$BaseUrl/auth/register" `
        -Method Post `
        -ContentType "application/json" `
        -Body $registerBody

    $token = $response.accessToken
    $userId = $response.user.id
    
    Write-Host "✅ Registration successful" -ForegroundColor Green
    Write-Host "   User ID: $userId" -ForegroundColor Gray
    Write-Host "   Token: $($token.Substring(0, 30))..." -ForegroundColor Gray
} catch {
    Write-Host "❌ Registration failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# ============================================================================
# Test 2: Test REST API Notification Endpoints
# ============================================================================
Write-Host "`n[Test 2] Testing REST API notification endpoints..." -ForegroundColor Yellow

# Get current notifications
try {
    $notifications = Invoke-RestMethod -Uri "$BaseUrl/notifications" `
        -Method Get `
        -Headers @{ Authorization = "Bearer $token" }
    
    Write-Host "✅ Retrieved notifications" -ForegroundColor Green
    Write-Host "   Count: $($notifications.Count)" -ForegroundColor Gray
} catch {
    Write-Host "⚠️  Could not retrieve notifications: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Get unread count
try {
    $unreadCount = Invoke-RestMethod -Uri "$BaseUrl/notifications/unread-count" `
        -Method Get `
        -Headers @{ Authorization = "Bearer $token" }
    
    Write-Host "✅ Retrieved unread count" -ForegroundColor Green
    Write-Host "   Unread: $($unreadCount.count)" -ForegroundColor Gray
} catch {
    Write-Host "⚠️  Could not retrieve unread count: $($_.Exception.Message)" -ForegroundColor Yellow
}

# ============================================================================
# Test 3: Create Test Notification
# ============================================================================
Write-Host "`n[Test 3] Creating test notification..." -ForegroundColor Yellow

try {
    $notificationBody = @{
        userId = $userId
        title = "Test Notification"
        message = "This is a test WebSocket notification!"
        type = "INFO"
    } | ConvertTo-Json

    $newNotification = Invoke-RestMethod -Uri "$BaseUrl/notifications" `
        -Method Post `
        -ContentType "application/json" `
        -Headers @{ Authorization = "Bearer $token" } `
        -Body $notificationBody

    Write-Host "✅ Notification created" -ForegroundColor Green
    Write-Host "   ID: $($newNotification.id)" -ForegroundColor Gray
    Write-Host "   Title: $($newNotification.title)" -ForegroundColor Gray
    Write-Host "   Message: $($newNotification.message)" -ForegroundColor Gray
    Write-Host "`n   💡 If WebSocket is connected, client should receive:" -ForegroundColor Cyan
    Write-Host "      Event: 'newNotification'" -ForegroundColor Gray
} catch {
    Write-Host "⚠️  Could not create notification: $($_.Exception.Message)" -ForegroundColor Yellow
}

# ============================================================================
# Generate Test Client HTML
# ============================================================================
$wsUrl = $BaseUrl -replace '^http', 'ws'

$htmlClient = @"
<!DOCTYPE html>
<html><head><title>WebSocket Test</title>
<script src="https://cdn.socket.io/4.5.4/socket.io.min.js"></script>
<style>body{font-family:Arial;max-width:800px;margin:50px auto;padding:20px;background:#f5f5f5;}
.container{background:white;padding:30px;border-radius:10px;}
button{padding:10px 20px;margin:5px;border:none;border-radius:5px;background:#007bff;color:white;cursor:pointer;}
#log{background:#2d2d2d;color:#00ff00;padding:15px;border-radius:5px;height:300px;overflow-y:auto;font-family:monospace;font-size:12px;}
.notification{padding:15px;margin:10px 0;border-left:4px solid #007bff;background:#e7f3ff;}</style></head>
<body><div class="container"><h1>🔌 WebSocket Test</h1>
<div><button onclick="connect()">Connect</button><button onclick="disconnect()">Disconnect</button>
<button onclick="getUnreadCount()">Get Unread Count</button></div>
<h3>Event Log:</h3><div id="log"></div><h3>Notifications:</h3><div id="notifications"></div></div>
<script>
const TOKEN='$token';const WS_URL='$wsUrl/notifications';let socket;
function log(msg){document.getElementById('log').innerHTML+='<div>'+new Date().toLocaleTimeString()+' - '+msg+'</div>';}
function connect(){socket=io(WS_URL,{query:{token:TOKEN},transports:['websocket']});
socket.on('connect',()=>log('✅ Connected: '+socket.id));
socket.on('connected',(d)=>log('🎉 Auth OK: '+d.userId));
socket.on('newNotification',(d)=>{log('📬 NEW: '+JSON.stringify(d.notification));
document.getElementById('notifications').innerHTML+='<div class="notification">'+d.notification.title+'<br>'+d.notification.message+'</div>';});
socket.on('unreadCount',(d)=>log('🔢 Unread: '+d.count));
socket.on('error',(e)=>log('❌ Error: '+JSON.stringify(e)));
socket.on('disconnect',()=>log('🔌 Disconnected'));}
function disconnect(){if(socket)socket.disconnect();}
function getUnreadCount(){if(socket)socket.emit('getUnreadCount');}
</script></body></html>
"@

$htmlClient | Out-File -FilePath "test-websocket-client.html" -Encoding UTF8

Write-Host "`n✅ HTML test client saved: test-websocket-client.html" -ForegroundColor Green
Write-Host "`n🔗 WebSocket URL: $wsUrl/notifications" -ForegroundColor Cyan
Write-Host "🔑 Token: $token`n" -ForegroundColor Cyan
Write-Host "📋 Open 'test-websocket-client.html' in your browser to test!" -ForegroundColor Yellow
Write-Host ""
