# MapView Functionality Documentation

## Overview
The MapView screen displays active cycles on a Google Map and allows users to rent cycles by tapping on their markers. It integrates with the backend API to fetch real-time cycle locations and status.

## Features

### 1. Real-time Cycle Display
- Fetches all active cycles from the database (`/cycles/nearby` endpoint)
- Filters cycles by `isActive: true` and `isRented: false`
- Displays cycle locations as markers on Google Maps
- Shows cycle count in the search bar overlay

### 2. Location Services
- Requests location permissions from the user
- Gets current user location using Geolocator
- Centers the map on user's current location
- Provides a floating action button to re-center the map

### 3. Cycle Markers
- Custom cycle marker icons (falls back to default green marker)
- Info windows showing cycle brand, model, and hourly rate
- Tap functionality to navigate to RentCycle screen

### 4. Navigation to RentCycle
- When a cycle marker is tapped, navigates to `RentCycle.dart`
- Passes the cycle ID to the RentCycle screen
- RentCycle screen fetches full cycle details from backend

## Backend Integration

### API Endpoints Used

#### 1. Get Nearby Cycles
```
GET /cycles/nearby?lat={latitude}&lng={longitude}
```
**Response:**
```json
{
  "cycles": [
    {
      "_id": "cycle_id",
      "brand": "Brand Name",
      "model": "Model Name", 
      "hourlyRate": 50.0,
      "isActive": true,
      "isRented": false,
      "coordinates": {
        "latitude": 22.8999,
        "longitude": 89.5020
      },
      "location": "Address string",
      "condition": "Good",
      "description": "Cycle description",
      "images": ["image1.jpg", "image2.jpg"]
    }
  ]
}
```

#### 2. Get Cycle by ID (used by RentCycle)
```
GET /cycles/{cycleId}
```
**Response:**
```json
{
  "cycle": {
    "_id": "cycle_id",
    "brand": "Brand Name",
    "model": "Model Name",
    "hourlyRate": 50.0,
    "isActive": true,
    "isRented": false,
    "coordinates": {
      "latitude": 22.8999,
      "longitude": 89.5020
    },
    "location": "Address string",
    "condition": "Good",
    "description": "Cycle description",
    "images": ["image1.jpg", "image2.jpg"]
  }
}
```

## Data Models

### Cycle Model (Flutter)
```dart
class Cycle {
  final String id;
  final String owner;
  final String brand;
  final String model;
  final String condition;
  final double hourlyRate;
  final String description;
  final String location;
  final bool isRented;
  final bool isActive;
  final CycleLocation? coordinates;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### CycleLocation Model
```dart
class CycleLocation {
  final double latitude;
  final double longitude;
}
```

## UI Components

### 1. Search Bar Overlay
- Shows count of active cycles nearby
- Displays refresh indicator when loading
- Positioned at the top of the map

### 2. Bottom Info Card
- Shows "Active Cycles" with count
- Displays instruction to tap markers
- Positioned at the bottom of the map

### 3. Map Controls
- My location button (floating action button)
- Refresh button in app bar
- Compass enabled
- Zoom controls disabled for cleaner UI

## Error Handling

### 1. Location Services
- Checks if location services are enabled
- Requests location permissions
- Handles permanently denied permissions
- Shows error dialogs for location issues

### 2. API Errors
- Network connectivity issues
- Server errors
- Invalid response formats
- Graceful fallback to empty state

### 3. Marker Loading
- Falls back to default marker if custom marker fails to load
- Handles missing coordinate data
- Validates coordinate values before creating markers

## State Management

### Loading States
- `_isLoading`: Initial map loading
- `_isRefreshing`: Refreshing cycle data
- Shows appropriate loading indicators

### Data States
- `_currentPosition`: User's current location
- `_activeCycles`: List of active cycles from API
- `_markers`: Set of map markers

## Dependencies

### Required Packages
```yaml
dependencies:
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  http: ^1.1.0
  firebase_auth: ^4.15.0
```

### Assets
- `assets/images/cycle_marker.png` - Custom cycle marker icon

## Testing

### Test File: `test_map_view.dart`
- Tests initial loading state
- Tests API response handling
- Tests cycle data parsing
- Tests active cycle filtering

## Usage Flow

1. **User opens MapView**
   - Shows loading screen
   - Requests location permissions
   - Gets current location

2. **Map loads with cycles**
   - Fetches active cycles from API
   - Creates markers for each cycle
   - Centers map on user location

3. **User taps cycle marker**
   - Navigates to RentCycle screen
   - Passes cycle ID to RentCycle
   - RentCycle fetches full cycle details

4. **User rents cycle**
   - RentCycle handles rental process
   - Updates cycle status in backend
   - Returns to map or rental progress screen

## Performance Considerations

### 1. Marker Optimization
- Only creates markers for active, available cycles
- Validates coordinates before creating markers
- Uses efficient marker management

### 2. API Calls
- Implements retry logic for network issues
- Caches cycle data to reduce API calls
- Handles errors gracefully

### 3. Location Updates
- Only updates location when necessary
- Implements proper permission handling
- Provides fallback for location issues

## Future Enhancements

### 1. Real-time Updates
- WebSocket integration for live cycle updates
- Push notifications for new cycles
- Real-time status changes

### 2. Advanced Filtering
- Filter by price range
- Filter by cycle condition
- Filter by distance

### 3. Enhanced UI
- Custom marker clustering
- Cycle details preview on marker hover
- Route planning to cycle location

### 4. Analytics
- Track popular cycle locations
- Monitor rental patterns
- User behavior analytics 