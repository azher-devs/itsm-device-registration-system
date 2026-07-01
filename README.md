# ITSM Device Registration System

Flutter UI for the ITSM Device Registration System used by Sultan Qaboos University IT Department to register and update employee devices.

## Current Phase

Week 3 focuses on UI, responsive layout, theme, localization, and navigation only. Backend API integration, Riverpod state management, Dio requests, and real barcode scanning are intentionally not implemented yet.

## Project Structure

The project uses a top-level MVC-style organization because the current app is UI-first and each feature is still lightweight:

- `lib/app/`: Root application shell, routing, theme wiring, and localization wiring.
- `lib/models/`: Data objects and placeholder data used by the UI-only flow.
- `lib/views/`: Screen-level UI grouped by feature area.
- `lib/controllers/`: App state controllers such as locale and theme persistence.
- `lib/shared/widgets/`: Reusable UI components.
- `lib/core/`: Shared constants and theme definitions.
- `lib/l10n/`: English and Arabic localization resources and generated localizations.

## Validation

Run these checks after UI or structure changes:

```bash
flutter analyze
flutter test
flutter build web
```
