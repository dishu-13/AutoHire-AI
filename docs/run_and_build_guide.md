# Run and Build Guide

## Requirements

- Flutter SDK 3.41 or newer.
- Android Studio with Android SDK.
- JDK 17.
- Android emulator or physical Android device.

On this machine, Flutter was found at:

```text
C:\Users\dishu\Downloads\flutter_windows_3.41.8-stable\flutter
```

If `flutter` is not on PATH, run commands with:

```powershell
& "C:\Users\dishu\Downloads\flutter_windows_3.41.8-stable\flutter\bin\flutter.bat" doctor
```

## Install Dependencies

```powershell
& "C:\Users\dishu\Downloads\flutter_windows_3.41.8-stable\flutter\bin\flutter.bat" pub get
```

## Run On Android

Start an Android Studio emulator or connect your phone with USB debugging, then run:

```powershell
& "C:\Users\dishu\Downloads\flutter_windows_3.41.8-stable\flutter\bin\flutter.bat" run -d android
```

The app is Android-only right now. Web, Windows, and iOS projects are not configured.

## Build APK

Only run this when you explicitly want an installable APK.

Debug APK:

```powershell
& "C:\Users\dishu\Downloads\flutter_windows_3.41.8-stable\flutter\bin\flutter.bat" build apk --debug
```

Release APK:

```powershell
& "C:\Users\dishu\Downloads\flutter_windows_3.41.8-stable\flutter\bin\flutter.bat" build apk --release
```

The APK will be created under:

```text
build/app/outputs/flutter-apk/
```

## Common Errors

`No connected devices`

Start an emulator from Android Studio or connect a phone with USB debugging enabled.

`Firebase app is not configured`

Add the Android Firebase app config for project `autohire-ai-8f5f6` in `lib/firebase_options.dart`.

`Sign in fails`

Enable Authentication > Sign-in method > Email/Password in Firebase Console.

`Firestore permission denied`

Deploy the Firestore rules and indexes, then make sure you are signed in.
