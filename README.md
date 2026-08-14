# CareQA Flutter Application

A comprehensive care management application built with Flutter, Firebase, and Provider for state management. This project includes both admin and staff applications in a monorepo structure.

## Project Structure

```
careqa/
├── admin-app/          # Admin application for managers
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/     # Data models (Carer, ServiceUser, Shift, Visit)
│   │   ├── services/   # Firebase services (AuthService, FirestoreService)
│   │   └── ui/         # User interface screens
│   │       ├── auth/   # Login screen
│   │       ├── dashboard/ # Admin dashboard
│   │       ├── carer/  # Carer management (CRUD)
│   │       ├── service_user/ # Service user management (CRUD)
│   │       ├── shift/  # Shift management (CRUD)
│   │       └── visit/  # Visit viewing (read-only)
│   └── pubspec.yaml
├── staff-app/          # Staff application for carers
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/     # Data models (Shift, Visit)
│   │   ├── services/   # Firebase services (AuthService, FirestoreService)
│   │   └── ui/         # User interface screens
│   │       ├── auth/   # Login screen
│   │       └── dashboard/ # Staff dashboard with check-in/out
│   └── pubspec.yaml
└── pubspec.yaml        # Root monorepo configuration
```

## Features

### Admin Application
- **Authentication**: Email/password login with Firebase Auth
- **Carer Management**: Create, read, update, delete carers
- **Service User Management**: Create, read, update, delete service users
- **Shift Management**: Create, read, update, delete shifts
- **Visit Viewing**: Read-only view of all visits with timestamps

### Staff Application
- **Authentication**: Email/password login with Firebase Auth
- **Shift Dashboard**: View assigned shifts for the current user
- **Check-in/Check-out**: Record visit timestamps with optional notes
- **Visit Status**: View current check-in/check-out status

## Technology Stack

- **Flutter**: Cross-platform mobile development
- **Firebase Authentication**: User authentication
- **Cloud Firestore**: NoSQL database for data storage
- **Provider**: State management
- **Material Design**: UI components

## Firebase Setup

To run this application, you need to set up Firebase:

1. **Create Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project
   - Register both Android and iOS apps

2. **Configure Firebase**:
   - Download `google-services.json` for Android
   - Download `GoogleService-Info.plist` for iOS
   - Place these files in the respective app directories:
     - `admin-app/android/app/google-services.json`
     - `staff-app/android/app/google-services.json`
     - `admin-app/ios/Runner/GoogleService-Info.plist`
     - `staff-app/ios/Runner/GoogleService-Info.plist`

3. **Configure Firestore Rules**:
   - Set up security rules in Firebase Console
   - Enable Firestore in test mode initially for development

4. **Generate Firebase Options**:
   - Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
   - Run: `flutterfire configure`
   - This will generate the `firebase_options.dart` files

## Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd careqa
   ```

2. **Install dependencies**:
   ```bash
   # For admin app
   cd admin-app
   flutter pub get
   
   # For staff app
   cd ../staff-app
   flutter pub get
   ```

3. **Set up Firebase** (as described above)

4. **Run the application**:
   ```bash
   # Run admin app
   cd admin-app
   flutter run
   
   # Run staff app
   cd ../staff-app
   flutter run
   ```

## Database Structure

### Collections

#### `carers`
```javascript
{
  id: string,
  name: string,
  email: string,
  phone: string,
  createdAt: Timestamp
}
```

#### `serviceUsers`
```javascript
{
  id: string,
  name: string,
  address: string,
  notes: string,
  createdAt: Timestamp
}
```

#### `shifts`
```javascript
{
  id: string,
  serviceUserId: string,
  carerId: string | null,
  date: Timestamp,
  startTime: Timestamp,
  endTime: Timestamp,
  status: string
}
```

#### `visits`
```javascript
{
  id: string,
  shiftId: string,
  carerId: string,
  checkInTime: Timestamp | null,
  checkOutTime: Timestamp | null,
  notes: string
}
```

## Development

### Adding New Features

1. **Models**: Add new data models in the `models/` directory
2. **Services**: Extend Firebase services in the `services/` directory
3. **UI**: Create new screens in the appropriate `ui/` subdirectories
4. **State Management**: Use Provider for state management

### Testing

- Unit tests can be added in the `test/` directories
- Widget tests for UI components
- Integration tests for complete user flows

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support and questions:
- Create an issue in the repository
- Check the Flutter documentation
- Refer to Firebase documentation for backend setup