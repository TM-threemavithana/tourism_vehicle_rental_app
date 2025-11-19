# 📚 Wayz Backend API Reference - Day 4

## 🚀 Base URL
```
http://localhost:3000
```

## 📋 API Endpoints Summary (47 Total)

### 👥 Users API - `/api/v1/users`
- `POST /api/v1/users` - Create user
- `GET /api/v1/users` - List all users
- `GET /api/v1/users/:id` - Get user by ID  
- `PATCH /api/v1/users/:id` - Update user
- `PATCH /api/v1/users/:id/verify-email` - Verify email
- `DELETE /api/v1/users/:id` - Soft delete user
- `GET /api/v1/users/stats` - User statistics

### 🚗 Vehicles API - `/api/v1/vehicles`
- `POST /api/v1/vehicles` - Create vehicle
- `GET /api/v1/vehicles` - List/search vehicles
- `GET /api/v1/vehicles/:id` - Get vehicle by ID
- `PATCH /api/v1/vehicles/:id` - Update vehicle
- `DELETE /api/v1/vehicles/:id` - Delete vehicle
- `GET /api/v1/vehicles/owner/:ownerId` - Get vehicles by owner
- `GET /api/v1/vehicles/category/:categoryId` - Get vehicles by category
- `GET /api/v1/vehicles/stats` - Vehicle statistics

### 📅 Bookings API - `/api/v1/bookings`
- `POST /api/v1/bookings` - Create booking
- `GET /api/v1/bookings?userId=&vehicleId=` - List bookings with filters
- `GET /api/v1/bookings/:id` - Get booking by ID
- `PATCH /api/v1/bookings/:id` - Update booking
- `DELETE /api/v1/bookings/:id` - Cancel booking
- `GET /api/v1/bookings/user/:userId` - Get user bookings
- `GET /api/v1/bookings/vehicle/:vehicleId` - Get vehicle bookings
- `GET /api/v1/bookings/stats` - Booking statistics

### ⭐ Reviews API - `/api/v1/reviews`
- `POST /api/v1/reviews/:userId` - Create review
- `GET /api/v1/reviews?vehicleId=` - List reviews with filters
- `GET /api/v1/reviews/:id` - Get review by ID
- `PATCH /api/v1/reviews/:id/user/:userId` - Update review
- `DELETE /api/v1/reviews/:id/user/:userId` - Delete review
- `GET /api/v1/reviews/user/:userId` - Get user reviews
- `GET /api/v1/reviews/vehicle/:vehicleId` - Get vehicle reviews
- `GET /api/v1/reviews/vehicle/:vehicleId/rating` - Get average rating
- `GET /api/v1/reviews/stats` - Review statistics

### ❤️ Favorites API - `/api/v1/favorites`
- `POST /api/v1/favorites/:userId` - Add to favorites
- `GET /api/v1/favorites/user/:userId` - Get user favorites
- `GET /api/v1/favorites/:userId/check/:vehicleId` - Check favorite status
- `DELETE /api/v1/favorites/:userId/:vehicleId` - Remove from favorites

### 🔔 Notifications API - `/api/v1/notifications`
- `POST /api/v1/notifications` - Create notification
- `GET /api/v1/notifications/user/:userId` - Get user notifications
- `GET /api/v1/notifications/user/:userId/unread-count` - Get unread count
- `PATCH /api/v1/notifications/:id/read` - Mark as read
- `PATCH /api/v1/notifications/user/:userId/read-all` - Mark all as read
- `DELETE /api/v1/notifications/:id` - Delete notification

### 🏷️ Vehicle Categories API - `/api/v1/vehicle-categories`
- `POST /api/v1/vehicle-categories` - Create category
- `GET /api/v1/vehicle-categories` - List categories
- `GET /api/v1/vehicle-categories/with-stats` - Categories with stats
- `GET /api/v1/vehicle-categories/:id` - Get category by ID
- `PATCH /api/v1/vehicle-categories/:id` - Update category
- `DELETE /api/v1/vehicle-categories/:id` - Delete category

### 🔧 System Endpoints
- `GET /` - Health check
- `GET /health` - Detailed health status
- `GET /api-docs` - Swagger API Documentation

---

## 📝 Sample API Requests

### Create User
```bash
POST /api/v1/users
Content-Type: application/json

{
  "email": "john.doe@example.com",
  "firstName": "John", 
  "lastName": "Doe",
  "phoneNumber": "+94771234567",
  "role": "customer"
}
```

### Create Vehicle
```bash
POST /api/v1/vehicles
Content-Type: application/json

{
  "name": "Toyota Camry 2023",
  "brand": "Toyota",
  "model": "Camry", 
  "year": 2023,
  "categoryId": "category-uuid-here",
  "ownerId": "owner-uuid-here",
  "pricePerDay": 75.00,
  "description": "Comfortable sedan for city and highway driving"
}
```

### Create Booking
```bash
POST /api/v1/bookings
Content-Type: application/json

{
  "vehicleId": "vehicle-uuid-here",
  "userId": "user-uuid-here",
  "startDate": "2024-01-15T09:00:00.000Z",
  "endDate": "2024-01-17T18:00:00.000Z",
  "totalCost": 150.00,
  "pickupLocation": "Colombo Airport"
}
```

### Create Review  
```bash
POST /api/v1/reviews/user-uuid-here
Content-Type: application/json

{
  "vehicleId": "vehicle-uuid-here",
  "rating": 4.5,
  "comment": "Excellent vehicle! Clean and comfortable. Highly recommend."
}
```

### Add to Favorites
```bash
POST /api/v1/favorites/user-uuid-here
Content-Type: application/json

{
  "vehicleId": "vehicle-uuid-here"
}
```

---

## 🎯 Testing the API

### 1. Using Swagger UI
Navigate to `http://localhost:3000/api-docs` for interactive API documentation

### 2. Using curl
```bash
# Health check
curl http://localhost:3000/health

# Get all users
curl http://localhost:3000/api/v1/users

# Get all vehicles  
curl http://localhost:3000/api/v1/vehicles
```

### 3. Using Postman
Import the API endpoints and test with sample data

---

## 🔑 Important Notes

### UUIDs Required
- All IDs are UUIDs (e.g., `550e8400-e29b-41d4-a716-446655440000`)
- Use proper UUID format for all ID parameters

### Date Formats
- Use ISO 8601 format: `2024-01-15T09:00:00.000Z`
- Dates are validated for logical constraints (end > start, no past dates)

### Validation
- All inputs are validated using class-validator
- Detailed error messages returned for validation failures
- HTTP status codes follow REST conventions

### Relationships
- Users can own multiple vehicles
- Users can make multiple bookings  
- Users can favorite multiple vehicles
- Users can review vehicles they've booked
- Vehicles belong to categories

---

## 🚀 Next Steps

1. **Start the server**: `npm run start:dev`
2. **Access Swagger docs**: `http://localhost:3000/api-docs` 
3. **Test endpoints**: Use Swagger UI or Postman
4. **Day 5**: Implement authentication and authorization

---

## 📊 Day 4 Complete: 47 API Endpoints Ready! ✨
