# CycleX - Smart Cycle Sharing App

A comprehensive Flutter application for smart cycle sharing on the KUET campus. CycleX provides an intuitive platform for cycle owners to rent out their cycles and for users to easily find, rent, and pay for cycles through a seamless mobile experience. The system integrates with IoT hardware for real-time GPS tracking and smart lock control.

## 🚀 Features

### 🔐 Authentication & User Management
- **Firebase Authentication**: Secure user registration and login
- **Role-based Access**: Separate interfaces for cycle owners and renters
- **Profile Management**: Complete user profile with photo upload
- **Phone Number Verification**: SMS-based verification system

### 🚲 Cycle Management
- **Add Cycles**: Owners can add cycles with photos and details
- **Cycle Listing**: Browse available cycles with real-time availability
- **Cycle Details**: Comprehensive cycle information and specifications
- **My Cycles**: Owners can manage their cycle inventory

### 📍 Location Services & GPS Tracking
- **Real-time GPS Tracking**: Live location updates from IoT hardware
- **Google Maps Integration**: Real-time cycle location tracking on map
- **Geolocation**: Precise location services using GPS coordinates
- **Route Planning**: Optimal routes between locations
- **Geofencing**: Campus boundary detection and alerts
- **Location History**: Track cycle movement patterns
- **Smart Lock Integration**: Automatic lock/unlock based on rental status

### 🔒 Smart Lock System
- **Automatic Lock Control**: Lock/unlock cycles based on rental status
- **Rental-based Access**: Cycles unlock when rental starts
- **Security Features**: Automatic locking when rental ends
- **Remote Control**: App-based lock management
- **Status Monitoring**: Real-time lock status tracking

### 💳 Payment System
- **SSL Commerz Integration**: Secure payment gateway
- **Multiple Payment Methods**: Credit/debit cards, mobile banking
- **Payment History**: Complete transaction records
- **Receipt Generation**: Digital payment receipts

### 🔍 QR Code Operations
- **QR Code Generation**: Unique QR codes for each cycle
- **QR Scanner**: Built-in camera scanner for quick cycle access
- **Code Validation**: Secure QR code verification system

### 📊 Rental Management
- **Rental Lifecycle**: Complete rental process from start to finish
- **Real-time Tracking**: Live rental status and duration
- **Rental History**: Detailed rental records and analytics
- **Active Rentals**: Monitor ongoing rentals
- **Smart Lock Integration**: Automatic lock/unlock during rental

### 🎨 User Interface
- **Modern Design**: Clean, intuitive Material Design interface
- **Dark/Light Theme**: Customizable theme support
- **Responsive Layout**: Optimized for various screen sizes
- **Smooth Animations**: Enhanced user experience

## 🔧 Hardware Integration

### IoT Hardware Components
- **ESP32 Microcontroller**: Main controller for IoT operations
- **GPS Tracker Module**: Real-time location tracking
- **Smart Auto Lock**: Electromagnetic lock system
- **Relay Module**: Control lock mechanism
- **DC-DC Buck Converter**: Power management
- **Battery Pack**: Portable power supply

### Hardware Features
- **Real-time GPS Tracking**: Continuous location monitoring
- **Firebase Integration**: Direct data transmission to cloud
- **Smart Lock Control**: Automated lock/unlock system
- **Power Management**: Efficient battery usage
- **Wireless Communication**: WiFi/Bluetooth connectivity

### Hardware Workflow
1. **Rental Start**: App sends unlock signal → ESP32 → Relay → Lock opens
2. **GPS Tracking**: GPS module → ESP32 → Firebase → App displays location
3. **Rental End**: App sends lock signal → ESP32 → Relay → Lock closes
4. **Power Management**: Battery → Buck converter → Stable power supply

## 📱 Screenshots

### 🔧 Hardware Integration
![Hardware Setup](assets/images/hardware.png)

### 📱 App Screenshots

#### 🔐 Authentication, Home & History
![Login, Home & History Screens](assets/images/Login_home_history.jpg)

#### 👤 Owner, Renter & Map Views
![Owner, Renter & Map Screens](assets/images/Owner_renter_map.jpg)

#### 💳 Payment System
![Payment Interface](assets/images/payment.jpg)

The app includes the following key screens:
- **Splash Screen**: App introduction and loading
- **Authentication**: Login and registration screens
- **Role Selection**: Choose between owner and renter
- **Dashboard**: Main navigation hub
- **Map View**: Interactive cycle location map with real-time GPS tracking
- **QR Scanner**: Camera-based QR code scanning
- **Payment**: Secure payment processing
- **Profile**: User profile management
- **GPS Tracker**: Real-time location monitoring

## 🛠️ Prerequisites

- **Flutter SDK**: Version 3.5.4 or higher
- **Dart SDK**: Compatible with Flutter version
- **Android Studio / VS Code**: For development
- **Firebase Project**: For authentication and database
- **Google Maps API Key**: For location services
- **SSL Commerz Account**: For payment processing
- **IoT Hardware**: ESP32, GPS tracker, smart lock, relay module
- **Arduino IDE**: For ESP32 programming

## 🚀 Installation

### 1. **Clone the Repository**
```bash
git clone <repository-url>
cd CycleX
```

### 2. **Install Dependencies**
```bash
flutter pub get
```

### 3. **Environment Setup**

#### Firebase Configuration
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android and iOS apps to your Firebase project
3. Download and add the configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS

#### Google Maps API Key
1. Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Geocoding API

#### SSL Commerz Configuration
1. Create an SSL Commerz merchant account
2. Get your store ID and password
3. Configure sandbox/production environment

### 4. **Platform-specific Setup**

#### Android Setup
1. Update `android/app/build.gradle` with your package name
2. Add Google Maps API key to `android/app/src/main/AndroidManifest.xml`
3. Configure Firebase in `android/app/google-services.json`

#### iOS Setup
1. Update bundle identifier in Xcode
2. Add Google Maps API key to `ios/Runner/AppDelegate.swift`
3. Configure Firebase in `ios/Runner/GoogleService-Info.plist`

### 5. **Run the App**
```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Build APK
flutter build apk

# Build iOS
flutter build ios
```

## 📁 Project Structure

```
CycleX/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── authentication/           # Auth screens
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── user_details_screen.dart
│   ├── view/                    # UI screens
│   │   ├── SplashScreen.dart
│   │   ├── RoleSelectionScreen.dart
│   │   ├── HomeScreen.dart
│   │   ├── MapView.dart
│   │   ├── QRScannerScreen.dart
│   │   ├── PaymentScreen.dart
│   │   ├── ProfileScreen.dart
│   │   ├── GPS Tracker/         # GPS tracking screens
│   │   │   ├── GPSTrackerScreen.dart
│   │   │   └── GPSTrackerDetailsScreen.dart
│   │   ├── owner/               # Owner-specific screens
│   │   │   ├── AddCycleScreen.dart
│   │   │   ├── MyCyclesScreen.dart
│   │   │   └── RentalHistoryScreen.dart
│   │   └── renter/              # Renter-specific screens
│   │       ├── RentCycle.dart
│   │       └── RentInProgressScreen.dart
│   ├── models/                  # Data models
│   │   ├── cycle.dart
│   │   ├── rental.dart
│   │   └── gps_tracker.dart     # GPS tracking model
│   ├── services/                # API and external services
│   │   ├── api_service.dart
│   │   ├── user_service.dart
│   │   ├── ssl_commerz_service.dart
│   │   ├── gps_tracker_service.dart    # GPS tracking service
│   │   ├── firebase_database_service.dart
│   │   └── timezone_service.dart
│   ├── Config/                  # App configuration
│   │   ├── Allcolors.dart
│   │   ├── AllDimensions.dart
│   │   ├── AllImages.dart
│   │   ├── AllTitles.dart
│   │   └── routes/
│   │       ├── PageConstants.dart
│   │       └── OneGenerateRoute.dart
│   ├── constants/               # App constants
│   │   └── colors.dart
│   ├── global/                  # Global utilities
│   │   └── global.dart
│   └── themeprovider/           # Theme management
│       └── themeprovider.dart
├── assets/                      # App assets
│   └── images/
│       ├── logo.png
│       ├── icon.svg
│       ├── kuet_logo.png
│       ├── cycle_marker.png
│       ├── marker.png
│       ├── marker1.png
│       └── profile.png
├── android/                     # Android-specific files
├── ios/                         # iOS-specific files
└── pubspec.yaml                 # Dependencies
```

## 🔧 Key Dependencies

### Core Dependencies
- **flutter**: Core Flutter framework
- **firebase_core**: Firebase initialization
- **firebase_auth**: User authentication
- **firebase_database**: Real-time database
- **firebase_storage**: File storage
- **cloud_firestore**: Cloud Firestore database

### UI & Navigation
- **flutter_svg**: SVG image support
- **animated_text_kit**: Text animations
- **cupertino_icons**: iOS-style icons

### Location & Maps
- **google_maps_flutter**: Google Maps integration
- **geolocator**: GPS location services
- **geocoder2**: Address geocoding
- **flutter_geofire**: Geofire for location queries
- **flutter_polyline_points**: Route planning

### GPS Tracking & IoT
- **firebase_database**: Real-time GPS data reception
- **stream**: Real-time data streaming
- **timer**: Periodic GPS updates

### QR Code & Camera
- **qr_flutter**: QR code generation
- **mobile_scanner**: QR code scanning
- **image_picker**: Image selection

### Payment & Web
- **webview_flutter**: Web view for payment
- **url_launcher**: External URL handling

### Utilities
- **http**: HTTP requests
- **shared_preferences**: Local storage
- **intl**: Internationalization
- **permission_handler**: App permissions

## 🎨 UI/UX Features

### Design System
- **Material Design**: Modern, clean interface
- **Custom Colors**: Brand-specific color scheme
- **Responsive Layout**: Adapts to different screen sizes
- **Smooth Animations**: Enhanced user experience

### Navigation
- **Bottom Navigation**: Easy access to main features
- **Drawer Menu**: Additional navigation options
- **Tab Navigation**: Organized content sections

### User Experience
- **Loading States**: Clear feedback during operations
- **Error Handling**: User-friendly error messages
- **Offline Support**: Basic offline functionality
- **Push Notifications**: Real-time updates

## 🔒 Security Features

- **Firebase Authentication**: Secure user authentication
- **JWT Tokens**: Secure API communication
- **SSL/TLS**: Encrypted data transmission
- **Input Validation**: Client-side data validation
- **Permission Management**: Granular app permissions

## 📊 Data Models

### User Model
```dart
class User {
  String id;
  String name;
  String email;
  String phone;
  String role; // 'owner' or 'renter'
  String profileImage;
  DateTime createdAt;
}
```

### Cycle Model
```dart
class Cycle {
  String id;
  String ownerId;
  String name;
  String description;
  String imageUrl;
  double pricePerHour;
  GeoPoint location;
  bool isAvailable;
  bool isLocked; // Smart lock status
  String gpsDeviceId; // Associated GPS device
}
```

### Rental Model
```dart
class Rental {
  String id;
  String userId;
  String cycleId;
  DateTime startTime;
  DateTime? endTime;
  double totalAmount;
  String status; // 'active', 'completed', 'cancelled'
  bool isLocked; // Lock status during rental
  List<GeoPoint> routeHistory; // GPS tracking history
}
```

### GPS Tracker Model
```dart
class GPSTracker {
  String deviceId;
  String cycleId;
  GeoPoint currentLocation;
  DateTime lastUpdate;
  bool isActive;
  double batteryLevel;
  String lockStatus; // 'locked', 'unlocked'
}
```

## 🚀 Deployment

### Android Deployment
1. **Build Release APK**
   ```bash
   flutter build apk --release
   ```

2. **Sign the APK**
   ```bash
   flutter build apk --release --split-per-abi
   ```

3. **Upload to Google Play Store**
   - Create developer account
   - Upload APK/AAB
   - Configure store listing

### iOS Deployment
1. **Build iOS App**
   ```bash
   flutter build ios --release
   ```

2. **Archive in Xcode**
   - Open `ios/Runner.xcworkspace`
   - Archive the project
   - Upload to App Store Connect

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart

# Run widget tests
flutter test test/widget_test.dart
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For support and questions:
- Email: nahid7ar@gmail.com
- Phone: +880-1727-892717

## 📄 License

This project is licensed under the MIT License.

## 🔄 Version History

- **v2.0.0** - GPS Tracking & Smart Lock Integration
  - Real-time GPS tracking with IoT hardware
  - Smart lock system integration
  - ESP32 microcontroller support
  - Automatic lock/unlock based on rental status
  - Enhanced location services
  - Hardware component integration

- **v1.0.0** - Initial release
  - Complete authentication system
  - Cycle rental functionality
  - Payment integration
  - QR code operations
  - Real-time location tracking
  - Modern UI/UX design

## 🙏 Acknowledgments

- **KUET**: For providing the platform and support
- **Firebase**: For backend services and real-time database
- **Google Maps**: For location services
- **SSL Commerz**: For payment processing
- **Flutter Team**: For the amazing framework
- **ESP32 Community**: For IoT development support
- **Arduino**: For microcontroller programming
