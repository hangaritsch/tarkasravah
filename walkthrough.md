# Walkthrough - Per-Grantha Caching, Landings, and Offline Fallbacks

We have successfully implemented per-Grantha asset caching, built a responsive Sanskrit-themed landing page with client-side OS-detection, resolved remote CDN sync delays, and added inline warning alerts for offline operations.

---

## 📁 Key Files & Modifications

### 1. Reusable Offline Banner Widget
* **File**: [offline_warning_banner.dart](file:///opt/homebrew/var/www/app/tarkasravah/lib/widgets/offline_warning_banner.dart)
* **Description**: A responsive inline banner that automatically appears when network connectivity is lost (or when a CDN sync / download request throws an exception). It matches the user's active reading theme (light, dark, or sepia) and utilizes the saffron accent color.

### 2. State & Caching updates
* **File**: [reader_provider.dart](file:///opt/homebrew/var/www/app/tarkasravah/lib/providers/reader_provider.dart)
* **Modifications**:
  * **Per-Grantha Caching States**: Added tracking maps (`_granthaDownloadProgress`, `_isGranthaDownloading`, `_isGranthaOfflineReady`) and getters to keep track of individual texts.
  * **Grantha Downloader**: Implemented `downloadGranthaForOffline(Grantha grantha)` which downloads only the selected Grantha's JSON and its corresponding audio files, reporting progress incrementally.
  * **Instant CDN Sync Fix**: Replaced jsDelivr CDN paths with raw GitHub URLs (`raw.githubusercontent.com`) and appended a cache-bypassing timestamp query parameter (`?t=timestamp`) to force immediate fetches of modified files on the `main` branch.
  * **Graceful Network Handling**: Wrapped background sync and downloading in `try-catch` blocks to capture `SocketException` or timeout errors, gracefully falling back to local files and displaying a `"No internet connection. Operating in Offline Mode."` message.
  * **Selection-based Syncing**: Updated `setActiveGrantha` to immediately trigger a background sync for the active text on selection.

### 3. Grantha Selection & Reading Screens
* **File**: [grantha_list_screen.dart](file:///opt/homebrew/var/www/app/tarkasravah/lib/screens/grantha_list_screen.dart)
* **Modifications**:
  * Added the shared `OfflineWarningBanner` at the top of the body.
  * Integrated a download button and animated progress tracker directly inside each Grantha card. Cards show:
    * `Download Offline` button if files aren't cached yet.
    * `Downloading X%` circular indicator during download.
    * `Offline Ready` green icon once fully cached.
* **File**: [library_screen.dart](file:///opt/homebrew/var/www/app/tarkasravah/lib/screens/library_screen.dart)
* **Modifications**:
  * Wrapped the body in a `Column` and placed the `OfflineWarningBanner` at the top of the screen.

### 4. Sharing & Download Landing Page
* **File**: [index.html](file:///opt/homebrew/var/www/app/tarkasravah/index.html)
* **Description**: A premium, responsive Sanskrit landing page hosted at the repository root:
  * **Device Detection**: Detects Android and iOS/macOS via user-agent sniffing to highlight the recommended download package with a linear gradient border and badge.
  * **Version Detail**: Prominently shows the current app version `v1.0.1+2`.
  * **Saffron/Maroon Accent styling**: Matching the app design, using glassmorphic cards and glowing hover effects.
  * **Quick Links**: Offers manual selection buttons to download the APK (Android) or Simulator ZIP (iOS), as well as a link to open the CMS administrative console.

### 5. CMS Real-time Update & Caching Fixes
* **File**: [cms/index.html](file:///opt/homebrew/var/www/app/tarkasravah/cms/index.html)
* **Modifications**:
  * **API Cache Busting**: Appended timestamp query parameters (`&t=timestamp`) to all GitHub API GET requests for repository contents, including JSON databases (`granthas.json`, `dictionary.json`, and active sutras lists) and audio file directories, ensuring the browser always queries live data without caching.
  * **Real-time Propagation**: Introduced a 1.5-second propagation delay using `setTimeout` for background audio list fetches following deletes or uploads. This gives the GitHub API enough time to process changes, preventing the local list from being overwritten with stale API data.

---

## 📦 Packages Rebuilt & Pushed

We have re-compiled the release outputs, committed all changes, and pushed them to `origin/main` on GitHub:
* **Android APK**: `build/releases/tarkasravah.apk` (Compiled in release mode, version `1.0.1+2`)
* **iOS Simulator Zip**: `build/releases/tarkasravah-ios.zip` (Runner.app simulator binary, packaged and zipped)
* **Commits**: Pushed successfully to [GitHub Repo](https://github.com/hangaritsch/tarkasravah.git).

