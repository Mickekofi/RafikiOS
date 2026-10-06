Place your app launcher icon image here as `assets/icon.png`.

Requirements and recommendations:
- File name: `icon.png`
- Preferred size: 1024x1024 PNG (square, no rounded corners)
- Transparent background is allowed; adaptive icons will use `adaptive_icon_background` color from `pubspec.yaml`.

After placing your icon, run:

```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
```

This will generate platform launcher icons for Android and iOS automatically.
