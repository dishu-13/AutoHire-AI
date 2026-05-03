# Firebase Setup

## Target Project

Use this Firebase project:

```text
autohire-ai-8f5f6
```

Android package name:

```text
com.daksh.smartjobassistant
```

## Free Products To Enable

Enable only these free-tier products:

- Authentication: Email/Password provider.
- Authentication: Google provider if you want the Google login button live.
- Cloud Firestore.

Do not enable or deploy Cloud Functions for the no-cost version.

## Android App Config Needed

The Flutter app now has the Android Firebase app values embedded in:

```text
lib/firebase_options.dart
```

Current values:

```text
apiKey: embedded
appId: 1:556007849704:android:3f47af55e98439efdc135d
messagingSenderId: 556007849704
projectId: autohire-ai-8f5f6
storageBucket: autohire-ai-8f5f6.firebasestorage.app
```

For Google sign-in on Android, add the SHA-1 and SHA-256 certificate
fingerprints for the APK signing key in Firebase Project settings > Android app.
The current release APK uses the debug signing config until a Play Store release
key is added.

If the Android app is ever recreated in Firebase Console, update
`lib/firebase_options.dart` from the new `google-services.json`:

1. Open Project settings.
2. In Your apps, choose Android.
3. Use package name `com.daksh.smartjobassistant`.
4. Download `google-services.json`.
5. Copy the values into `lib/firebase_options.dart`.

No private secret is included in `google-services.json`; Firebase app config is public client config.

Do not use a Firebase Admin SDK service account JSON in the Flutter app. Files
named like `firebase-adminsdk-...json` contain private server credentials and
must never be bundled into an APK.

## Firestore Rules

Deploy only rules and indexes:

```powershell
firebase deploy --only firestore:rules,firestore:indexes
```

The current rules are scoped to user-owned data:

```text
users/{uid}
users/{uid}/savedJobs/{jobId}
users/{uid}/applications/{applicationId}
users/{uid}/resumeResults/{resultId}
```

## Checks

Run checks without creating an APK:

```powershell
.\scripts\check_project.ps1
```
