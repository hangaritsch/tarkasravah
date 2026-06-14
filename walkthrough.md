# Walkthrough - Sidebar settings, iOS versioning, and CMS filtering

We have successfully migrated the Reader display settings to the AppDrawer sidebar, confirmed iOS versioning compliance with `pubspec.yaml`, implemented a natural numeric sorting and searching interface for Sutras in the CMS, and packaged version `v1.0.4+5` for release.

---

## 📁 Key Changes & Files Modified

### 1. Reader Display Options Migrated to Sidebar
- **File**: [app_drawer.dart](file:///opt/homebrew/var/www/app/tarkasravah/lib/widgets/app_drawer.dart)
  - **Modifications**: Added the complete "Reader Display Options" control card directly inside the drawer's scrollable list. It includes:
    - **Font Size adjustment**: Interactive `+` / `-` buttons to scale the Sanskrit text.
    - **Sanskrit Font dropdown**: Access to the full alphabetized catalog of 47 Devanagari Google Fonts.
    - **Theme selection**: Clean OutlinedButtons representing Light, Dark, and Sepia modes.
    - **Translations toggles**: SwitchListTiles to show/hide English and Kannada translation panes.
  - **Modifications**: Bumped displayed footer version to `Version 1.0.4+5`.
- **File**: [reader_screen.dart](file:///opt/homebrew/var/www/app/tarkasravah/lib/screens/reader_screen.dart)
  - **Modifications**:
    - Deleted the local settings modal bottom sheet (`_showSettingsBottomSheet()`) completely to avoid duplicate UI.
    - Hooked the drawer directly to the reader Scaffold (`drawer: const AppDrawer()`).
    - Configured the AppBar settings icon button to open the sidebar dynamically using a `Builder` context calling `Scaffold.of(context).openDrawer()`.

### 2. iOS Versioning Alignment
- **Verification**: Verified that both `CFBundleShortVersionString` and `CFBundleVersion` in `ios/Runner/Info.plist` are mapped to `$(FLUTTER_BUILD_NAME)` and `$(FLUTTER_BUILD_NUMBER)` respectively. This ensures the iOS simulator build automatically inherits version `1.0.4` and build number `5` from `pubspec.yaml` on compilation.

### 3. CMS Search and Sort Features
- **File**: [cms/index.html](file:///opt/homebrew/var/www/app/tarkasravah/cms/index.html)
  - **Sutras Filters UI**: Added a responsive filter row in the Sutras tab displaying a text search input and a sort dropdown (Ascending Num, Descending Num, A-Z Title, Z-A Title).
  - **Default Sorting**: Integrated a natural numeric sorting comparison function (`compareSutraNumbers()`) that parses multi-dotted strings (like `1.1`, `1.2`, `1.10`, `2.1`) and sorts them numerically rather than alphabetically. It now translates Devanagari numerals (e.g. `१`, `१०`) to standard digits before parsing, correcting sorting issues for Sanskrit-numbered sutras. The CMS list is now sorted by `Num (Ascending)` by default.
  - **Natural Search**: Enhanced search matching to translate Devanagari numerals to standard digits, allowing seamless lookups using either digit style.
  - **Dynamic Re-rendering**: Programmed input and change event listeners to dynamically re-filter and sort the active sutras array in memory on keyup/change and refresh the table rows instantly.
  - **Database Natural Order**: Sorted the sutras list naturally *before* saving updates to GitHub. This ensures the JSON database files themselves stay naturally sorted, making the mobile app display them in the correct sequence.

---

## 📦 Packages Rebuilt & Deployed

1. **Android Release APK**: Compiled and copied to the root as [tarkasravah-v1.0.4.apk](file:///opt/homebrew/var/www/app/tarkasravah/tarkasravah-v1.0.4.apk) (25.5MB).
2. **iOS Simulator Package**: Built and packaged as `build/releases/tarkasravah-ios.tar.gz` (51.6MB).
3. **Download Landing Page**: Updated [index.html](file:///opt/homebrew/var/www/app/tarkasravah/index.html) download links and labels to version `1.0.4+5`.
4. **GitHub Push**: Committed and pushed all changes successfully.
