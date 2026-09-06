# ITSM Device Registration System

## Supervisor Run and Test Guide

This guide explains how to run the application in Demo Mode or connect it to
an authorized iTop test server.

## 1. Prerequisites

Install and configure:

- Flutter SDK
- Android Studio for Android testing
- Xcode for iPhone testing (macOS only)
- A connected physical device or configured emulator
- Network or VPN access to the iTop server

From the project root, confirm that Flutter can see the development environment:

```bash
flutter doctor
flutter devices
flutter pub get
```

Camera and gallery barcode scanning should be tested on a physical Android or
iOS device.

## 2. Demo Mode

Demo Mode uses local Fake API data and never connects to iTop.

Run:

```bash
flutter run -t lib/main_demo.dart
```

Available test values:

| Scenario | Tag Number | Employee ID |
|---|---|---|
| Unassigned device | `TAG-UNASSIGNED` | `EMP-10045` |
| Assigned device | `TAG-ASSIGNED` | Loaded automatically |
| Device not found | `TAG-NOT-FOUND` | Not required |
| Employee not found | `TAG-UNASSIGNED` | `EMP-NOT-FOUND` |
| Add failure | `TAG-ADD-FAIL` | `EMP-10045` |
| Remove failure | `TAG-REMOVE-FAIL` | Loaded automatically |
| Timeout | `TAG-TIMEOUT` | Not required |

Use Demo Mode to review the UI, localization, themes, dialogs, Snackbars, and
assignment state changes without server access.

## 3. Real API Configuration

Real API Mode uses the existing Dio, service, repository, controller, and
Riverpod architecture.

Open:

```text
lib/config/itop_config.dart
```

Replace only these three placeholder values:

```dart
static const baseUrl = 'https://your-itop-server';
static const username = 'your_username';
static const password = 'your_password';
```

Configuration rules:

- `baseUrl` must contain the iTop server address only.
- Do not append `/webservices/rest.php?version=1.0`.
- Use an HTTPS address whenever the server supports it.
- Use an account authorized for the documented read and assignment operations.
- Do not commit or share the file while it contains real credentials.

## 4. Run Real API Mode

From the project root, run:

```bash
flutter run -t lib/main_itop.dart
```

No JSON configuration file or `--dart-define` argument is required.

The Login screen is currently UI-only. Its fields do not authenticate against
iTop. Tap Login to continue; API credentials are read from
`lib/config/itop_config.dart`.

## 5. Real Server Test Checklist

Use dedicated test records rather than production records.

### Search Device

1. Open Device Registration.
2. Enter a known device Tag Number.
3. Tap the Tag Number search button.
4. Confirm that Tag Number matches the iTop `PhysicalDevice.name` field.
5. Confirm that Serial Number, Brand, Device Type, and assignment state appear.

### Search Employee

1. Search an unassigned device.
2. Enter a known Employee ID.
3. Tap the Employee ID search button.
4. Confirm that the value matches the iTop `Person.employee_number` field.
5. Confirm that Employee ID, Employee Name, and Organization appear.

### Add Assignment

1. Search an unassigned device and a valid employee.
2. Tap Add.
3. Verify the Tag Number and Employee ID in the confirmation dialog.
4. Tap Yes.
5. Confirm that the success Snackbar appears.
6. Confirm that the button changes from Add to Remove.
7. Verify the new `lnkContactToFunctionalCI` relationship in iTop.

### Remove Assignment

1. Search a known assigned device.
2. Confirm that its employee profile loads from `contacts_list`.
3. Tap Remove and then Yes.
4. Confirm that the success Snackbar appears.
5. Confirm that employee information is cleared while device information stays.
6. Verify that the relationship was removed from iTop.

### Barcode Scanner

1. Create or use a barcode containing a real device `name`.
2. Scan it with the camera.
3. Confirm that Tag Number is filled and searched automatically.
4. Repeat using Scan from Gallery.
5. Confirm that manual entry remains available.

### Error Handling

Verify the behavior for:

- Unknown Tag Number
- Unknown Employee ID
- Invalid API credentials
- Unavailable server or VPN
- Request timeout
- Insufficient iTop permissions

The application should display the message returned by iTop when one is
available. Failed Add or Remove operations must not change the current state.

## 6. Rename Support

Rename Device is implemented in the API service, repository, and Riverpod
controller. The current UI does not expose a Rename action, so it is validated
through automated contract tests rather than the Device Registration screen.

## 7. Automated Validation

Before real-server testing, run:

```bash
flutter analyze
flutter test
```

Both commands should complete without errors.

## 8. Troubleshooting

### No device appears in `flutter devices`

- Unlock the device.
- Enable USB debugging on Android.
- Trust the computer on iOS.
- Reconnect the USB cable and run `flutter devices` again.

### API requests cannot reach the server

- Confirm the server URL.
- Confirm VPN or university network access.
- Confirm that the server uses HTTPS correctly.
- Do not disable SSL certificate verification in the application.

### `Found: 0`

- Confirm that Tag Number matches `PhysicalDevice.name`.
- Confirm that Employee ID matches `Person.employee_number`.
- Confirm there are no additional spaces in the test values.

### Invalid credentials or permission errors

- Confirm the username and password.
- Confirm that the account can read `PhysicalDevice` and `Person`.
- Confirm that it can create and delete `lnkContactToFunctionalCI`.
- Confirm that it can update the applicable device class for Rename testing.

### Camera does not open

- Test on Android or iOS.
- Grant camera permission.
- Check the operating-system application permission settings.

## 9. After Testing

Stop the running application with `Ctrl+C`.

Restore the placeholders in `lib/config/itop_config.dart` before committing,
uploading, or sharing the project:

```dart
static const baseUrl = 'https://your-itop-server';
static const username = 'your_username';
static const password = 'your_password';
```

