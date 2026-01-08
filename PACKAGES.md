# Packages Used in Daily Reading Register App

This app uses the following packages:

## Dependencies

1. **hive** (^2.2.3)

   - Lightweight, fast NoSQL database for Flutter
   - Used for local data storage

2. **hive_flutter** (^1.1.0)

   - Flutter integration for Hive database
   - Provides Flutter-specific initialization

3. **intl** (^0.19.0)

   - Internationalization and localization package
   - Used for date formatting (DateFormat)

4. **cupertino_icons** (^1.0.8)

   - iOS-style icons for Flutter apps

5. **animations** (^2.0.11)

   - Flutter's official animations package
   - Used for smooth page transitions

6. **flutter_animate** (^4.5.0)

   - Modern declarative animations package
   - Used for fade-in, slide animations on widgets

7. **shimmer** (^3.0.0)

   - Shimmer loading effect package
   - Used for loading placeholders

8. **toastification** (^1.1.0)
   - Modern toast notification package
   - Used for displaying success/error messages

## Dev Dependencies

1. **hive_generator** (^2.0.1)

   - Code generator for Hive adapters
   - Generates type adapters for Hive models

2. **build_runner** (^2.4.8)
   - Build system for Dart code generation
   - Used to generate Hive adapter files

## Installation

All packages are already installed. To reinstall:

```bash
flutter pub get
```

## Code Generation

To regenerate Hive adapters after model changes:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
