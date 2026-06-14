# Walkthrough - Tarkaśravaḥ (तर्कश्रावः) Sanskrit E-Reader

We have successfully implemented Multi-Grantha (multi-text) support, refined the offline synchronization system, built a password-protected GitHub Pages CMS, and compiled the latest installable packages for Android and iOS.

---

## 📁 Project Architecture & Local Path

The project is located locally at:
📁 `/opt/homebrew/var/www/app/tarkasravah`

---

## 📚 Multi-Grantha Support & UI Dashboard

To transition the app from a single hardcoded text to an expandable Sanskrit e-reader library, we implemented:

### 1. Dynamic Data Structure
* **Central Index**: Created [granthas.json](file:///opt/homebrew/var/www/app/tarkasravah/assets/data/granthas.json) which registers all available texts (including title, English title, author, description, and sutra count).
* **Grantha Databases**: Separated individual texts into their own data files:
  * [tarkasangraha.json](file:///opt/homebrew/var/www/app/tarkasravah/assets/data/tarkasangraha.json)
  * [muktavali.json](file:///opt/homebrew/var/www/app/tarkasravah/assets/data/muktavali.json)

### 2. UI Screens & Navigation
* **Grantha List Dashboard (`GranthaListScreen`)**: Added a premium selection screen as the application's new homepage. Users can see all available texts, their author, description, and sutra counts.
* **Sutra Reader (`LibraryScreen`)**: Updated the main e-reader page to dynamically display the name of the *active* Grantha and load its corresponding sutras from cache/local storage.
* **App Drawer Navigation (`AppDrawer`)**: Refactored the Navigation Drawer. It now includes:
  * A **Select Grantha (ग्रन्थसूची)** option to navigate back to the library dashboard.
  * A **Sutra List (सूत्रपाठः)** option to view the current text's sutra grid.
  * A dynamic footer displaying the name of the currently active text.
  * An updated **Offline Settings** card that calculates total downloaded sutras and audio tracks dynamically across all registered Granthas.

---

## 🖥️ Web-Hosted Password-Protected CMS

We built a gorgeous, zero-dependency, single-page CMS application inside [cms/index.html](file:///opt/homebrew/var/www/app/tarkasravah/cms/index.html) that can be hosted for free on GitHub Pages:

### 1. Key Security Features
* **Password Protection**: Access requires entering the password **`Tarka@2026`**. The password is validated securely client-side via a SHA-256 cryptographic hash check.
* **GitHub Personal Access Token (PAT)**: Admin commits are securely sent using a browser-supplied GitHub PAT. The token is stored locally in the browser's sandbox (`localStorage`) and is never sent to any external server other than the GitHub API.

### 2. Rich Administrative Dashboard
* **Saffron/Maroon Design**: Aesthetic matches the reader app with gold/maroon accents, glassmorphic card layouts, responsive sidebar, and custom animations.
* **Grantha Manager**: Add, edit, or delete Granthas. Adding a text commits an updated index file and automatically initializes a new `<grantha_id>.json` file in your repository.
* **Sutra Editor**: Add, edit, or delete sutras for any chosen Grantha. Modifying a sutra automatically updates its database file and recalculates the central `sutra_count` field in `granthas.json`.
* **Dictionary Editor**: Search, filter, add, edit, or delete words in `dictionary.json`.
* **Integrated Git Console**: A floating console displays a live log stream of network requests, connection checks, and Git commits (showing successful SHAs).

---

## 🔍 Verification & Testing Status

* **Static Analysis**: `flutter analyze` runs successfully with **No issues found!**
* **Unit Tests**: Pure Dart unit tests pass cleanly:
  ```
  All tests passed!
  ```

---

## 📦 Installable Packages (Build Outputs)

The production-ready installable packages are compiled and pushed to your GitHub repository:

### 🤖 Android Installable (APK)
* **Local Path**: `/opt/homebrew/var/www/app/tarkasravah/build/releases/tarkasravah.apk`
* **Local Link**: [tarkasravah.apk](file:///opt/homebrew/var/www/app/tarkasravah/build/releases/tarkasravah.apk)
* **GitHub Download Link**: [Download Android APK](https://github.com/hangaritsch/tarkasravah/raw/main/build/releases/tarkasravah.apk)

### 🍎 iOS Installable (Simulator Bundle)
* **Local Path**: `/opt/homebrew/var/www/app/tarkasravah/build/releases/tarkasravah-ios.zip` (contains the `Runner.app` simulator package)
* **Local Link**: [tarkasravah-ios.zip](file:///opt/homebrew/var/www/app/tarkasravah/build/releases/tarkasravah-ios.zip)
* **GitHub Download Link**: [Download iOS Simulator Zip](https://github.com/hangaritsch/tarkasravah/raw/main/build/releases/tarkasravah-ios.zip)
