# ITSM Device Registration System

A Flutter mobile application developed for the Sultan Qaboos University (SQU) IT Department to register, update, and manage employee device assignments.

## Overview

The application simplifies the process of assigning IT assets to employees by allowing staff to search for devices, scan barcodes, and register ownership information through a modern mobile interface.

## Features

- User authentication (Login)
- Device registration
- Barcode scanning
- Employee ID verification
- Arabic & English localization
- Responsive UI
- Light & Dark theme support
- Session persistence

## Technologies

- Flutter
- Dart
- Riverpod
- Dio
- Google ML Kit (Barcode Scanning)
- Shared Preferences

## Project Structure

```text
lib/
├── app/
├── controllers/
├── core/
├── models/
├── repositories/
├── services/
├── shared/
├── views/
├── l10n/
└── main.dart
```

## Screens

- Splash Screen
- Login
- Home
- Device Registration
- Barcode Scanner
- Registration Result

## Getting Started

Clone the repository:

```bash
git clone https://github.com/azher-devs/itsm-device-registration-system.git
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

## UI Demo Mode

The current application uses an in-memory repository. It does not call a real
server and does not require a base URL, credentials, or internet access. Demo
assignments reset when the application restarts.

Run the application with the Fake API:

```bash
flutter run
```

The separate UI demo entry point remains available:

```bash
flutter run -t lib/main_demo.dart
```

Run the demo on a specific device:

```bash
flutter run -d <device-id> -t lib/main_demo.dart
```

Available Device Registration values:

- `TAG-UNASSIGNED` - unassigned Dell laptop
- `TAG-ASSIGNED` - assigned HP desktop
- `TAG-SECOND` - second unassigned Lenovo tablet
- `TAG-ADD-FAIL` - simulates an Add failure
- `TAG-REMOVE-FAIL` - simulates a Remove failure
- `TAG-TIMEOUT` - simulates a three-second lookup timeout
- `TAG-NOT-FOUND` - simulates a missing device
- `EMP-10045` - valid employee
- `EMP-NOT-FOUND` - simulates a missing employee

Add and Remove failures return the Fake API messages shown by the application.
Automated tests also cover successful assignment, removal, rename payloads, and
the documented iTop response mapping.

## iTop API Preparation

The Dio architecture follows the supplied iTop REST/JSON specification while
remaining disconnected from the real server. Requests use multipart form data
with `auth_user`, `auth_pwd`, and serialized `json_data` fields.

Real-server values are centralized in:

```text
lib/config/itop_config.dart
```

The demo remains available through `lib/main.dart` and `lib/main_demo.dart`.
For authorized real-server testing, edit only these three constants:

```dart
static const baseUrl = 'https://your-itop-server';
static const username = 'your_username';
static const password = 'your_password';
```

Then run the dedicated real API entry point:

```bash
flutter run -t lib/main_itop.dart
```

No JSON configuration file or `--dart-define` argument is required. Do not
commit real credentials; restore the placeholder values before committing or
sharing the project. Repositories, controllers, models, providers, and UI code
do not need to change.

## Requirements

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code

## Disclaimer

This project was developed as part of an On-the-Job Training (OJT) program at Sultan Qaboos University.

## Author

**Al Azher Al Kindi**

Software Engineering Student

University of Technology and Applied Sciences (UTAS), Oman

GitHub: https://github.com/azher-devs
