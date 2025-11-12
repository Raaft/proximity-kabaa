# Mecca Proximity

A Flutter application that calculates distance and bearing to the Kaaba using Clean Architecture principles.

## Overview

This app demonstrates Clean Architecture implementation in Flutter, featuring location tracking with adaptive power management and GPS smoothing algorithms.

## Features

- Real GPS Mode: Fetches actual device location using Geolocator
- Static Test Locations: Three predefined test points
  - Inside Haram (within 500m)
  - Inside Mataf (within 150m)
  - Outside Haram (beyond 500m)
- Distance Calculation: Computes distance in meters using Haversine formula
- Bearing Calculation: Computes direction in degrees (0-360) toward Kaaba
- Adaptive Power Policy: Automatically adjusts update interval and accuracy based on distance
- GPS Smoothing: Applies moving median filter over last 5 readings
- Mini Log: Displays last 10 location readings with timestamp and accuracy

## Architecture

The project follows Clean Architecture with three main layers:

- Domain Layer: Contains entities, use cases, and repository interfaces
- Data Layer: Implements data sources, models, and repository implementations
- Presentation Layer: Handles UI and state management using BLoC pattern

### Use Cases

- GetCurrentLocation: Retrieves current location from GPS or simulation
- ComputeDistanceToKaaba: Calculates distance using Haversine formula
- ComputeBearingToKaaba: Calculates bearing angle to Kaaba

## Getting Started

### Prerequisites

- Flutter SDK 3.8.0 or higher
- Dart SDK 3.8.0 or higher

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

## Dependencies

- geolocator: Location services for GPS access
- flutter_bloc: State management using BLoC pattern
- get_it: Dependency injection container

## Permissions

### Android

Add to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS

Add to `Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to calculate distance to Kaaba</string>
```

## Constants

- Kaaba Coordinates: 21.422487°N, 39.826206°E
- Mataf Radius: 150 meters
- Haram Radius: 500 meters
- Moving Median Window: 5 readings
- Stillness Threshold: 15 meters

## Project Structure

```
lib/
├── core/
│   ├── constants.dart
│   ├── di/injection_container.dart
│   └── utils/location_utils.dart
└── features/
    └── mecca_proximity/
        ├── data/
        │   ├── datasources/
        │   ├── models/
        │   └── repositories/
        ├── domain/
        │   ├── entities/
        │   ├── enums/
        │   ├── repositories/
        │   └── use_cases/
        └── presentation/
            ├── cubit/
            └── pages/
```

## Notes

- The app uses foreground location tracking only
- All calculations are performed offline
- Simulation modes are for testing purposes
- The app requests only necessary location permissions
