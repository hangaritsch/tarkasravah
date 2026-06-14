# Walkthrough - CMS Audio Deletion & Global Text Scaling Fixes

We have successfully resolved the two remaining bugs in the Sanskrit Reader application and the CMS portal, rebuilt the release artifacts, and pushed them to GitHub.

---

## 📁 Key Changes & Files Modified

### 1. CMS Auto-Delete Audio Fix
- **File**: [cms/index.html](file:///opt/homebrew/var/www/app/tarkasravah/cms/index.html)
- **Modifications**: Fixed a `ReferenceError` where the variable `audioToChange` was referenced but not defined inside the scope of the `deleteSutra` function. We defined it as:
  ```javascript
  const audioToChange = s.audio;
  ```
  This retrieves the filename of the associated audio from the target sutra object before soft-deleting it and triggers the GitHub DELETE API call.

### 2. Global Text Scaling Fix
- **File**: [reader_screen.dart](file:///opt/homebrew/var/www/app/tarkasravah/lib/screens/reader_screen.dart)
- **Modifications**: Converted the raw `RichText` widget used for rendering the Sanskrit sutra text into a `Text.rich` widget:
  ```dart
  // Before
  RichText(
    textAlign: TextAlign.center,
    text: TextSpan(children: ...),
  )

  // After
  Text.rich(
    TextSpan(children: ...),
    textAlign: TextAlign.center,
  )
  ```
  - *Context*: Raw `RichText` widgets in Flutter do not automatically inherit or respect the ambient `textScaler` from `MediaQuery`. By switching to `Text.rich`, the widget automatically responds to the global `textScaler` set in `lib/main.dart`, resolving the bug where font size settings did not scale all texts in the app.

---

## 📦 Packages Rebuilt & Deployed

1. **Android Release APK**: Compiled and staged at [tarkasravah-v1.0.4.apk](file:///opt/homebrew/var/www/app/tarkasravah/tarkasravah-v1.0.4.apk) and `build/releases/tarkasravah.apk`.
2. **iOS Simulator Package**: Built and packaged as `build/releases/tarkasravah-ios.tar.gz`.
3. **GitHub Push**: Committed all fixes and pushed successfully to GitHub repository.
