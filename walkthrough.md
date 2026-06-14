# Walkthrough - Android Connectivity Fix & Global Fonts

We have successfully resolved the "No Internet" issue on physical Android release builds, implemented a dynamic global font theme that applies the user's selected Devanagari font throughout the entire app, expanded the font catalog to support all Google Devanagari fonts, and packaged version `v1.0.3+4` for both Android and iOS.

---

## 📁 Key Changes & Files Modified

### 1. Permissions & Android Configuration
- **File**: [AndroidManifest.xml](file:///opt/homebrew/var/www/app/tarkasravah/android/app/src/main/AndroidManifest.xml)
- **Modifications**: Added the required `<uses-permission android:name="android.permission.INTERNET"/>` and `<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>` tags under the `<manifest>` root node. 
  - *Context*: While Flutter debug builds automatically inject the internet permission for Hot Reload/debugging, release builds require explicit declarations. Adding these ensures the compiled release APK has full internet access on physical devices.

### 2. State & Fonts Catalog Expansion
- **File**: [reader_provider.dart](file:///opt/homebrew/var/www/app/tarkasravah/lib/providers/reader_provider.dart)
- **Modifications**:
  - **Version Bump**: Incremented `currentAppVersion` to `1.0.3+4`.
  - **Google Fonts Catalog**: Expanded the `supportedDevanagariFonts` static array to include 47 Google Fonts supporting the Devanagari script (sorted alphabetically from *Amita* to *Yatra One*).
  - **Update Dialog Font**: Removed the hardcoded `fontFamily: 'PragatiNarrow'` override from the update dialog title text style, allowing it to adapt to the active font.

### 3. Dynamic Global Font Application
- **File**: [main.dart](file:///opt/homebrew/var/www/app/tarkasravah/lib/main.dart)
- **Modifications**:
  - Replaced the hardcoded `fontFamily: 'PragatiNarrow'` within `ThemeData`.
  - Configured `ThemeData.textTheme` to build dynamically using `GoogleFonts.getTextTheme` when a Google Font is selected, falling back to local `PragatiNarrow` asset.
  - This dynamically applies the chosen Devanagari font to all titles, lists, drawers, text snippets, and buttons app-wide.

### 4. Code cleanup (Inherited Font Styling)
We removed explicit `fontFamily: 'PragatiNarrow'` overrides from the following files so they dynamically inherit the globally configured font theme:
- **File**: [grantha_list_screen.dart](file:///opt/homebrew/var/www/app/tarkasravah/lib/screens/grantha_list_screen.dart) (AppBar title, selection headers, and card titles)
- **File**: [about_us_screen.dart](file:///opt/homebrew/var/www/app/tarkasravah/lib/screens/about_us_screen.dart) (AppBar title and Sanskrit logo header)
- **File**: [search_screen.dart](file:///opt/homebrew/var/www/app/tarkasravah/lib/screens/search_screen.dart) (Sanskrit search result text snippet)
- **File**: [app_drawer.dart](file:///opt/homebrew/var/www/app/tarkasravah/lib/widgets/app_drawer.dart) (Drawer header title, footer title, and version label bumped to `1.0.3+4`)

### 5. Release Packages & Sharing Page
- **File**: [pubspec.yaml](file:///opt/homebrew/var/www/app/tarkasravah/pubspec.yaml) (Version bumped to `1.0.3+4`)
- **File**: [index.html](file:///opt/homebrew/var/www/app/tarkasravah/index.html) (Version numbers updated to `v1.0.3+4` and APK/iOS links updated)
- **iOS Package compression**: 
  - *Context*: Because debug iOS Simulator binaries (`Runner.app`) contain extensive debug symbol frameworks that push the `.zip` compression format to over 101MB, they exceeded GitHub's 100MB upload limit.
  - *Resolution*: Packaged the simulator build using `tar` and `gzip` into a `tarkasravah-ios.tar.gz` archive (52MB), which achieves a significantly better compression ratio and fits under the GitHub limit. The download link and button in `index.html` were updated to reflect the new extension.

---

## 📦 Packages Rebuilt & Deployed

1. **Android Release APK**: Compiled and deployed at the root as [tarkasravah-v1.0.3.apk](file:///opt/homebrew/var/www/app/tarkasravah/tarkasravah-v1.0.3.apk) (25.5MB).
2. **iOS Simulator Package**: Built and packaged as `build/releases/tarkasravah-ios.tar.gz` (51.6MB).
3. **GitHub Push**: All changes committed and pushed successfully to the `main` branch.

---

## 📱 On-Device Verification

We verified the installation directly on the connected physical Android device (`RZCX62F57AV`):
- Run `adb install -r tarkasravah-v1.0.3.apk` → **Success**.
- The app launches successfully and fully connects to the internet (no offline-mode warning shows on WiFi/cellular startup).
- Selecting any Devanagari font from the reader options immediately updates the font globally across all app bars, lists, cards, and menus.
