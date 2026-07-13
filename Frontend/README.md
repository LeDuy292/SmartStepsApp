# smartsteps

A new Flutter project.

## Offline lesson catalog

The app currently ships with a hard-coded offline lesson catalog so it can be
tested without the ASP.NET backend. Lesson data lives in
`lib/data/offline_situation_catalog.dart`, and video/voice files are bundled
from `assets/videos/*` and `assets/voices/*`.

To add a quick pilot lesson, add the media files under `assets/`, register the
folder in `pubspec.yaml` when needed, then add the matching
`SituationDetail` entry to the offline catalog.

## Local profile and Premium

The first-login survey is stored as `child_profile.json` in the app documents
directory. For the MVP Premium flow, users can enter the code `PREMIUM`; the app
updates the same local profile file and displays the Premium plan in-app.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
