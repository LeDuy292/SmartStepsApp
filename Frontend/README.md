# SmartSteps frontend

Flutter application for the SmartSteps safety lesson game.

## Prerequisites

- Flutter 3.44 or newer on the stable channel
- Dart 3.11 or newer
- Chrome for Web development, or an Android emulator/device

## Setup

```powershell
cd Frontend
flutter pub get
flutter analyze
flutter test
```

Run Web against the local backend. Port `3000` is fixed so it matches the
default backend CORS configuration:

```powershell
flutter run -d chrome --web-port=3000 `
  --dart-define=SMARTSTEPS_API_BASE_URL=http://localhost:8080
```

For an Android emulator, use:

```powershell
flutter run `
  --dart-define=SMARTSTEPS_API_BASE_URL=http://10.0.2.2:8080
```

## Optional Supabase configuration

Avatar uploads use Supabase only when both required values are provided. Never
pass a service-role key to the Flutter client.

```powershell
flutter run -d chrome --web-port=3000 `
  --dart-define=SMARTSTEPS_API_BASE_URL=http://localhost:8080 `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY `
  --dart-define=SUPABASE_AVATAR_BUCKET=avatars
```

## Build Web

```powershell
flutter build web --release
```

The deployable output is written to `build/web`. Vercel uses
`scripts/vercel_build.sh`; `GA_MEASUREMENT_ID` and `VERCEL_BASE_HREF` are
optional deployment environment variables.

## Project data

- Offline lessons: `lib/data/offline_situation_catalog.dart`
- Bundled media: `assets/`
- Local child profile: `child_profile.json` in the app documents directory
- MVP Premium code: `PREMIUM`
