# ITSM Device Registration System

## User Flow

![User Flow](ScreenShots/user%20flow.png)

A Flutter application for IT Department to register and manage employee device assignments. The app supports device lookup, employee verification, barcode scanning, and assignment updates through a simple mobile workflow.

## Screens

### Login

![Login screen](ScreenShots/1-login%20screen.png)

### Home

![Home screen](ScreenShots/2-home%20screen.png)

### Menu

![Menu screen](ScreenShots/3-menu%20screen.png)

### Device Registration

![Device Registration screen](ScreenShots/4-device%20registration%20screen.png)

### Barcode Scanner

![Barcode Scanner screen](ScreenShots/5-barcode%20screen.png)

## Features

- Login and the device-registration workflow
- Tag Number and Employee ID lookup
- Device and employee details after validation
- Barcode scanning with camera and Google ML Kit
- Add and Remove assignment actions
- English and Arabic localization
- Light and Dark appearance modes
- Persisted language and appearance preferences
- Demo repository for backend-free UI review

## Architecture

The project uses an **MVC-style layered architecture** with the **Repository Pattern**, a **Service Layer**, and **Riverpod** for state management and dependency injection.

```text
Presentation Layer
lib/views/ + lib/shared/widgets/
        ↓
Controller Layer
lib/controllers/device_registration_controller.dart
        ↓
Repository Layer
lib/repositories/device_registration_repository.dart
        ↓
Service Layer
lib/services/device_registration_api_service.dart
        ↓
Transport Layer
Dio client → REST API
```

- **Views:** Build the screens and collect user input. Shared widgets contain reusable UI components.
- **Controllers:** Riverpod controllers manage registration state, validation, loading, errors, and assignment actions.
- **Repositories:** Define the data contract and hide the data source. `DemoDeviceRegistrationRepository` provides in-memory data, while `DioDeviceRegistrationRepository` connects to the REST API.
- **Services:** Build API operations and send requests through the Dio client.
- **Models:** `lib/models/` contains the `Device`, `Employee`, and API response models used between layers.
- **App and preferences:** `ItsmApp` manages routes, themes, and localization. `LocaleController` and `ThemeController` persist settings with Shared Preferences.

`main.dart` injects the demo repository for normal runs.

## Tech Stack

- Flutter and Dart
- Riverpod (`flutter_riverpod`)
- Dio for HTTP transport
- Camera and Google ML Kit Barcode Scanning
- Shared Preferences for persisted settings
- Flutter localization with English and Arabic ARB resources
- Image Picker and Permission Handler for scanner support
- Audio Players for success feedback

## Project Structure

```text
lib/
├── app/             Root app shell, routes, theme, and localization wiring
├── controllers/     Riverpod registration state and preference controllers
├── core/            App constants, theme, configuration, and shared services
├── models/          Device, employee, and API response models
├── repositories/    Repository contract plus demo and Dio implementations
├── services/        API service and Dio client
├── shared/widgets/  Reusable UI components
├── views/           Splash, login, home, registration, scanner, and success screens
├── l10n/            English and Arabic localization resources
├── main.dart        Default demo entry point
└── main_demo.dart   Standalone demo entry point
```

## Getting Started

Requirements: Flutter SDK and Dart SDK.

```bash
flutter pub get
flutter run
```

The default entry point uses the in-memory demo repository and does not require a server or credentials.
