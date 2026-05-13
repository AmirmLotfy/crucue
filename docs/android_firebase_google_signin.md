# Android release signing → Firebase & Google Sign-In

Release APKs are signed with **`android/crucue-upload-key.jks`** (see `android/key.properties`, gitignored). Google Sign-In and Firebase Auth on Android need the **upload key’s fingerprints** registered in Firebase.

## Fingerprints (upload keystore, alias `crucue-key`)

| Type | Fingerprint |
|------|----------------|
| **SHA-1** | `A4:B6:1C:0F:35:E3:BF:46:84:4E:5E:9D:B2:77:A6:40:AD:96:86:DB` |
| **SHA-256** | `A4:FD:D3:38:C4:DD:60:66:8C:4E:7D:CA:0E:FE:D7:C0:45:7D:38:5A:19:E2:55:C0:81:97:C2:A1:E3:43:C1:F7` |

Recompute locally (no passwords in docs):

```bash
keytool -list -v -keystore android/crucue-upload-key.jks -alias crucue-key
```

## Where to register

1. [Firebase Console](https://console.firebase.google.com/) → your project → **Project settings** → **Your apps** → Android app `com.crucue.app`.
2. Under **SHA certificate fingerprints**, add **both** SHA-1 and SHA-256 above (if not already present).
3. Download a fresh **`google-services.json`** into `android/app/` only if Firebase prompted a config change (usually not required for SHA-only updates).
4. In **Authentication** → **Sign-in method**, ensure **Google** is enabled.

If Google Sign-In still fails after sideloading a new APK, wait a few minutes for Firebase to propagate, then reinstall the app.
