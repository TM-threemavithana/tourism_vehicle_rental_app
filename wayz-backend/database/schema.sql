-- Tourism Vehicle Rental Database Schema
-- Day 3: Initial database structure for cloud PostgreSQL

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable PostGIS for geospatial data (if needed for location features)
-- CREATE EXTENSION IF NOT EXISTS postgis;

-- Users table (migrated from Firebase Auth)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  firebase_uid VARCHAR(255) UNIQUE, -- For migration dual-write
  email VARCHAR(255) UNIQUE NOT NULL,
  email_verified BOOLEAN DEFAULT false,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  phone_number VARCHAR(20),
  profile_image_url TEXT,
  date_of_birth DATE,
  license_number VARCHAR(50),
  license_expiry DATE,
  address TEXT,
  city VARCHAR(100),
  country VARCHAR(100),
  is_active BOOLEAN DEFAULT true,
  last_login_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Vehicle categories
CREATE TABLE vehicle_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  icon_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Vehicles table
CREATE TABLE vehicles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  firebase_doc_id VARCHAR(255), -- For migration dual-write
  category_id UUID REFERENCES vehicle_categories(id),
  owner_id UUID REFERENCES users(id),
  
  -- Basic vehicle info
  make VARCHAR(50) NOT NULL,
  model VARCHAR(100) NOT NULL,
  year INTEGER NOT NULL,
  color VARCHAR(50),
  license_plate VARCHAR(20),
  vin VARCHAR(50),
  
  -- Rental info
  daily_rate DECIMAL(10,2) NOT NULL,
  security_deposit DECIMAL(10,2),
  fuel_type VARCHAR(20), -- petrol, diesel, electric, hybrid
  transmission VARCHAR(20), -- manual, automatic
  seats INTEGER,
  
  -- Location
  location_lat DECIMAL(10, 8),
  location_lng DECIMAL(11, 8),
  location_address TEXT,
  location_city VARCHAR(100),
  
  -- Features & conditions
  features JSONB, -- AC, GPS, Bluetooth, etc.
  description TEXT,
  rules TEXT,
  
  -- Images
  images JSONB, -- Array of image URLs
  
  -- Availability
  is_available BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Bookings table
CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  firebase_doc_id VARCHAR(255), -- For migration dual-write
  user_id UUID REFERENCES users(id) NOT NULL,
  vehicle_id UUID REFERENCES vehicles(id) NOT NULL,
  
  -- Booking dates
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  
  -- Pricing
  daily_rate DECIMAL(10,2) NOT NULL,
  total_days INTEGER NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL,
  tax_amount DECIMAL(10,2) DEFAULT 0,
  discount_amount DECIMAL(10,2) DEFAULT 0,
  total_amount DECIMAL(10,2) NOT NULL,
  security_deposit DECIMAL(10,2),
  
  -- Status
  status VARCHAR(20) DEFAULT 'pending', -- pending, confirmed, active, completed, cancelled
  payment_status VARCHAR(20) DEFAULT 'pending', -- pending, paid, refunded
  
  -- Additional info
  pickup_location TEXT,
  dropoff_location TEXT,
  special_requests TEXT,
  
  -- Timestamps
  booking_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Favorites table
CREATE TABLE favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) NOT NULL,
  vehicle_id UUID REFERENCES vehicles(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, vehicle_id)
);

-- Reviews table
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  firebase_doc_id VARCHAR(255), -- For migration dual-write
  user_id UUID REFERENCES users(id) NOT NULL,
  vehicle_id UUID REFERENCES vehicles(id) NOT NULL,
  booking_id UUID REFERENCES bookings(id),
  
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  title VARCHAR(200),
  comment TEXT,
  
  -- Review responses
  owner_response TEXT,
  owner_response_date TIMESTAMP WITH TIME ZONE,
  
  is_verified BOOLEAN DEFAULT false,
  is_featured BOOLEAN DEFAULT false,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Notifications table
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) NOT NULL,
  title VARCHAR(200) NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(50), -- booking, payment, reminder, promotion
  reference_id UUID, -- ID of related booking, payment, etc.
  
  is_read BOOLEAN DEFAULT false,
  is_push_sent BOOLEAN DEFAULT false,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Payment transactions table
CREATE TABLE payment_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id UUID REFERENCES bookings(id) NOT NULL,
  user_id UUID REFERENCES users(id) NOT NULL,
  
  amount DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  transaction_type VARCHAR(20), -- payment, refund, deposit
  
  -- Payment gateway info
  gateway_name VARCHAR(50), -- stripe, razorpay, etc.
  gateway_transaction_id VARCHAR(255),
  gateway_response JSONB,
  
  status VARCHAR(20) DEFAULT 'pending', -- pending, success, failed, cancelled
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_users_active ON users(is_active);

CREATE INDEX idx_vehicles_category ON vehicles(category_id);
CREATE INDEX idx_vehicles_owner ON vehicles(owner_id);
CREATE INDEX idx_vehicles_location ON vehicles(location_lat, location_lng);
CREATE INDEX idx_vehicles_available ON vehicles(is_available, is_active);
CREATE INDEX idx_vehicles_firebase_doc_id ON vehicles(firebase_doc_id);

CREATE INDEX idx_bookings_user ON bookings(user_id);
CREATE INDEX idx_bookings_vehicle ON bookings(vehicle_id);
CREATE INDEX idx_bookings_dates ON bookings(start_date, end_date);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_firebase_doc_id ON bookings(firebase_doc_id);

CREATE INDEX idx_favorites_user ON favorites(user_id);
CREATE INDEX idx_favorites_vehicle ON favorites(vehicle_id);

CREATE INDEX idx_reviews_user ON reviews(user_id);
CREATE INDEX idx_reviews_vehicle ON reviews(vehicle_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);
CREATE INDEX idx_reviews_firebase_doc_id ON reviews(firebase_doc_id);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_notifications_type ON notifications(type);

CREATE INDEX idx_payment_transactions_booking ON payment_transactions(booking_id);
CREATE INDEX idx_payment_transactions_user ON payment_transactions(user_id);
CREATE INDEX idx_payment_transactions_status ON payment_transactions(status);

-- Insert sample vehicle categories
INSERT INTO vehicle_categories (name, description) VALUES
('Economy Cars', 'Budget-friendly cars for city travel'),
('SUV', 'Sport Utility Vehicles for family trips'),
('Luxury Cars', 'Premium vehicles for special occasions'),
('Motorcycles', 'Two-wheelers for quick city rides'),
('Electric Vehicles', 'Eco-friendly electric cars');

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vehicles_updated_at BEFORE UPDATE ON vehicles 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON reviews 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_transactions_updated_at BEFORE UPDATE ON payment_transactions 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Success message
SELECT 'Tourism Vehicle Rental Database Schema Created Successfully!' as status;
