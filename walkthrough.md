# Walkthrough - Tarkaśravaḥ (तर्कश्रावः) Sanskrit E-Reader

We have successfully implemented the trilingual, offline-first **Tarkaśravaḥ** (तर्कश्रावः) Sanskrit E-Reader app.

---

## 📁 Project Architecture & Local Path

The project is fully initialized and configured inside:
📁 `/opt/homebrew/var/www/app/tarkasravah`

---

## ☁️ GitHub Backup & jsDelivr CDN Integration

To support seamless updates and open-source lifetime free file hosting, we implemented a hybrid online/offline sync mechanism:

### 1. Trilingual Database Sync
* **Location**: `assets/data/tarkasangraha.json` and `assets/data/dictionary.json`.
* **CDN URL**: [jsDelivr CDN](https://cdn.jsdelivr.net/gh/hangaritsch/tarkasravah@main/assets/data/tarkasangraha.json) fetches files from the public repository.
* **Sync Flow**:
  1. **Instant Start**: The app immediately loads the cached JSON from the device's local application documents directory (`tarkasangraha_cache.json`). If no cache is found (e.g. first launch), it falls back to the bundled offline asset.
  2. **Background Update**: Once loaded, it executes a background HTTP request to the jsDelivr CDN URL. If a newer JSON exists, it updates the screen data in real-time and caches the new file locally for subsequent offline launches.

### 2. Intelligent Audio Streaming & Caching
* **Offline-First Playback**:
  1. When playing a sutra's audio, the app checks if the file (e.g., `audio_0.mp3`) already exists locally in the device's application documents directory.
  2. If the file is cached, it plays **instantly and offline** via `DeviceFileSource`.
  3. If it is not cached, it streams it on-the-fly from the CDN using `UrlSource`. In the background, it downloads and caches the file so that subsequent plays of that sutra work **100% offline**.

---

## 🖥️ Local Git Repository & Cloud Backup Ready

* **Local Repository**: Git has been initialized inside the folder, and all code/asset modifications have been committed locally.
* **GitHub remote**: Configured remote origin pointing to:
  `https://github.com/hangaritsch/tarkasravah.git`
* **GitHub Push Script**: Created [push_to_github.sh](file:///opt/homebrew/var/www/app/tarkasravah/push_to_github.sh) inside the project directory to assist in backing up your code to GitHub.

---

## 🔍 Verification & Lint Status

* **Static Analysis**: `flutter analyze` runs successfully with **No issues found!**
* **Unit Tests**: Pure Dart unit tests pass cleanly:
  ```
  00:00 +2: All tests passed!
  ```
