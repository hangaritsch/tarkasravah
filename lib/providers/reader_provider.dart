import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/sutra.dart';

enum ReaderTheme { light, dark, sepia }

class ReaderProvider extends ChangeNotifier {
  List<Sutra> _sutras = [];
  Map<String, dynamic> _dictionary = {};
  bool _isLoading = true;
  String? _error;

  // Kindle UI customisation
  double _fontSize = 20.0;
  ReaderTheme _theme = ReaderTheme.light;
  bool _showEnglish = true;
  bool _showKannada = true;

  // Proactive Offline Cache manager
  bool _isDownloadingAll = false;
  double _downloadProgress = 0.0;
  bool _isFullyOfflineReady = false;

  // Audio Playback
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingSutraId;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Getters
  List<Sutra> get sutras => _sutras;
  Map<String, dynamic> get dictionary => _dictionary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get fontSize => _fontSize;
  ReaderTheme get theme => _theme;
  bool get showEnglish => _showEnglish;
  bool get showKannada => _showKannada;
  bool get isDownloadingAll => _isDownloadingAll;
  double get downloadProgress => _downloadProgress;
  bool get isFullyOfflineReady => _isFullyOfflineReady;
  int? get playingSutraId => _playingSutraId;
  PlayerState get playerState => _playerState;
  Duration get duration => _duration;
  Duration get position => _position;

  // Constructor
  ReaderProvider() {
    _initAudioListeners();
    loadData();
  }

  // Initialize Audio Listeners
  void _initAudioListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _playerState = state;
      if (state == PlayerState.completed) {
        _playingSutraId = null;
        _position = Duration.zero;
      }
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });
  }

  // Load local JSON assets & handle cache / background CDN sync
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final directory = await getApplicationDocumentsDirectory();
      final sutraCacheFile = File('${directory.path}/tarkasangraha_cache.json');
      final dictCacheFile = File('${directory.path}/dictionary_cache.json');

      // 1. Load Sutras from local document cache, fallback to bundled assets
      if (await sutraCacheFile.exists()) {
        try {
          final content = await sutraCacheFile.readAsString();
          final List<dynamic> sutraJsonList = json.decode(content);
          _sutras = sutraJsonList.map((json) => Sutra.fromJson(json)).toList();
          debugPrint("Loaded sutras from local document cache.");
        } catch (cacheErr) {
          debugPrint("Failed to load sutras from cache, loading from assets: $cacheErr");
          final String sutraJsonString = await rootBundle.loadString('assets/data/tarkasangraha.json');
          final List<dynamic> sutraJsonList = json.decode(sutraJsonString);
          _sutras = sutraJsonList.map((json) => Sutra.fromJson(json)).toList();
        }
      } else {
        final String sutraJsonString = await rootBundle.loadString('assets/data/tarkasangraha.json');
        final List<dynamic> sutraJsonList = json.decode(sutraJsonString);
        _sutras = sutraJsonList.map((json) => Sutra.fromJson(json)).toList();
        debugPrint("Loaded sutras from bundle assets.");
      }

      // 2. Load Dictionary from local document cache, fallback to bundled assets
      if (await dictCacheFile.exists()) {
        try {
          final content = await dictCacheFile.readAsString();
          _dictionary = json.decode(content);
          debugPrint("Loaded dictionary from local document cache.");
        } catch (cacheErr) {
          debugPrint("Failed to load dictionary from cache, loading from assets: $cacheErr");
          final String dictJsonString = await rootBundle.loadString('assets/data/dictionary.json');
          _dictionary = json.decode(dictJsonString);
        }
      } else {
        final String dictJsonString = await rootBundle.loadString('assets/data/dictionary.json');
        _dictionary = json.decode(dictJsonString);
        debugPrint("Loaded dictionary from bundle assets.");
      }

      _isLoading = false;
      await checkOfflineStatus();
      notifyListeners();

      // Trigger background sync from remote GitHub CDN (jsDelivr)
      syncFromRemote();
    } catch (e) {
      _isLoading = false;
      _error = "Error loading data: $e";
      notifyListeners();
    }
  }

  // Background CDN sync
  Future<void> syncFromRemote() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final sutraCacheFile = File('${directory.path}/tarkasangraha_cache.json');
      final dictCacheFile = File('${directory.path}/dictionary_cache.json');

      const cdnSutraUrl = 'https://cdn.jsdelivr.net/gh/hangaritsch/tarkasravah@main/assets/data/tarkasangraha.json';
      const cdnDictUrl = 'https://cdn.jsdelivr.net/gh/hangaritsch/tarkasravah@main/assets/data/dictionary.json';

      debugPrint("Attempting background CDN sync...");

      bool sutraUpdated = false;

      // Fetch Sutras
      final sutraResponse = await http.get(Uri.parse(cdnSutraUrl)).timeout(const Duration(seconds: 8));
      if (sutraResponse.statusCode == 200) {
        final decoded = json.decode(sutraResponse.body);
        if (decoded is List) {
          await sutraCacheFile.writeAsString(sutraResponse.body);
          _sutras = decoded.map((json) => Sutra.fromJson(json)).toList();
          sutraUpdated = true;
          debugPrint("Sutras successfully synced from CDN and cached.");
        }
      }

      // Fetch Dictionary
      final dictResponse = await http.get(Uri.parse(cdnDictUrl)).timeout(const Duration(seconds: 8));
      if (dictResponse.statusCode == 200) {
        final decoded = json.decode(dictResponse.body);
        if (decoded is Map) {
          await dictCacheFile.writeAsString(dictResponse.body);
          _dictionary = decoded.cast<String, dynamic>();
          debugPrint("Dictionary successfully synced from CDN and cached.");
        }
      }

      // If user had previously downloaded everything for offline mode,
      // proactively fetch any new files automatically.
      if (sutraUpdated && _isFullyOfflineReady) {
        debugPrint("Automatic offline sync checking for new audio files...");
        for (var sutra in _sutras) {
          final localAudioFile = File('${directory.path}/${sutra.audio}');
          if (!await localAudioFile.exists()) {
            final cdnAudioUrl = 'https://cdn.jsdelivr.net/gh/hangaritsch/tarkasravah@main/assets/audio/${sutra.audio}';
            await _downloadAndCacheAudio(cdnAudioUrl, localAudioFile);
          }
        }
      }

      await checkOfflineStatus();
      notifyListeners();
    } catch (e) {
      // Silent error logging to not interrupt offline experience
      debugPrint("Background CDN sync failed: $e");
    }
  }

  // Font Size Settings
  void increaseFontSize() {
    if (_fontSize < 36.0) {
      _fontSize += 2.0;
      notifyListeners();
    }
  }

  void decreaseFontSize() {
    if (_fontSize > 14.0) {
      _fontSize -= 2.0;
      notifyListeners();
    }
  }

  void setFontSize(double size) {
    _fontSize = size.clamp(14.0, 36.0);
    notifyListeners();
  }

  // Theme Settings
  void setTheme(ReaderTheme newTheme) {
    _theme = newTheme;
    notifyListeners();
  }

  // Translations Visibility Settings
  void toggleEnglishVisibility() {
    _showEnglish = !_showEnglish;
    notifyListeners();
  }

  void toggleKannadaVisibility() {
    _showKannada = !_showKannada;
    notifyListeners();
  }

  // Audio playback controls (Hybrid streaming and caching)
  Future<void> playAudio(Sutra sutra) async {
    try {
      if (_playingSutraId == sutra.id) {
        if (_playerState == PlayerState.playing) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.resume();
        }
        notifyListeners();
        return;
      }

      await _audioPlayer.stop();
      _playingSutraId = sutra.id;
      _position = Duration.zero;
      notifyListeners();

      final directory = await getApplicationDocumentsDirectory();
      final localAudioFile = File('${directory.path}/${sutra.audio}');

      if (await localAudioFile.exists()) {
        debugPrint("Playing audio offline from cache: ${localAudioFile.path}");
        await _audioPlayer.play(DeviceFileSource(localAudioFile.path));
      } else {
        final cdnAudioUrl = 'https://cdn.jsdelivr.net/gh/hangaritsch/tarkasravah@main/assets/audio/${sutra.audio}';
        debugPrint("Streaming audio online from CDN: $cdnAudioUrl");
        await _audioPlayer.play(UrlSource(cdnAudioUrl));

        // Start background download for caching
        _downloadAndCacheAudio(cdnAudioUrl, localAudioFile);
      }
    } catch (e) {
      debugPrint("Audio Playback Error: $e");
    }
  }

  // Download and cache audio file in the background
  Future<void> _downloadAndCacheAudio(String url, File targetFile) async {
    try {
      debugPrint("Downloading audio file to cache: $url");
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        await targetFile.writeAsBytes(response.bodyBytes);
        debugPrint("Audio file successfully downloaded and cached at: ${targetFile.path}");
      }
    } catch (e) {
      debugPrint("Failed to download and cache audio: $e");
    }
  }

  // Check if all app data (sutras and audios) is cached locally
  Future<void> checkOfflineStatus() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      
      final sutraCacheFile = File('${directory.path}/tarkasangraha_cache.json');
      final dictCacheFile = File('${directory.path}/dictionary_cache.json');
      
      bool jsonsCached = await sutraCacheFile.exists() && await dictCacheFile.exists();
      if (!jsonsCached) {
        _isFullyOfflineReady = false;
        notifyListeners();
        return;
      }

      if (_sutras.isEmpty) {
        _isFullyOfflineReady = false;
        notifyListeners();
        return;
      }

      bool allAudiosCached = true;
      for (var sutra in _sutras) {
        final localAudioFile = File('${directory.path}/${sutra.audio}');
        if (!await localAudioFile.exists()) {
          allAudiosCached = false;
          break;
        }
      }

      _isFullyOfflineReady = allAudiosCached;
      notifyListeners();
    } catch (e) {
      debugPrint("Error checking offline status: $e");
      _isFullyOfflineReady = false;
      notifyListeners();
    }
  }

  // Proactive download manager - fetches all data for 100% offline usage
  Future<void> downloadAllForOffline() async {
    if (_isDownloadingAll) return;
    _isDownloadingAll = true;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      final directory = await getApplicationDocumentsDirectory();

      // 1. Fetch latest JSON databases from CDN
      const cdnSutraUrl = 'https://cdn.jsdelivr.net/gh/hangaritsch/tarkasravah@main/assets/data/tarkasangraha.json';
      const cdnDictUrl = 'https://cdn.jsdelivr.net/gh/hangaritsch/tarkasravah@main/assets/data/dictionary.json';

      final sutraCacheFile = File('${directory.path}/tarkasangraha_cache.json');
      final dictCacheFile = File('${directory.path}/dictionary_cache.json');

      final sutraResponse = await http.get(Uri.parse(cdnSutraUrl)).timeout(const Duration(seconds: 8));
      if (sutraResponse.statusCode == 200) {
        final decoded = json.decode(sutraResponse.body);
        if (decoded is List) {
          await sutraCacheFile.writeAsString(sutraResponse.body);
          _sutras = decoded.map((json) => Sutra.fromJson(json)).toList();
        }
      }
      _downloadProgress = 0.1;
      notifyListeners();

      final dictResponse = await http.get(Uri.parse(cdnDictUrl)).timeout(const Duration(seconds: 8));
      if (dictResponse.statusCode == 200) {
        final decoded = json.decode(dictResponse.body);
        if (decoded is Map) {
          await dictCacheFile.writeAsString(dictResponse.body);
          _dictionary = decoded.cast<String, dynamic>();
        }
      }
      _downloadProgress = 0.2;
      notifyListeners();

      // 2. Fetch all missing audio files
      if (_sutras.isNotEmpty) {
        double audioStep = 0.8 / _sutras.length;
        for (int i = 0; i < _sutras.length; i++) {
          final sutra = _sutras[i];
          final localAudioFile = File('${directory.path}/${sutra.audio}');

          if (!await localAudioFile.exists()) {
            final cdnAudioUrl = 'https://cdn.jsdelivr.net/gh/hangaritsch/tarkasravah@main/assets/audio/${sutra.audio}';
            final response = await http.get(Uri.parse(cdnAudioUrl)).timeout(const Duration(seconds: 30));
            if (response.statusCode == 200) {
              await localAudioFile.writeAsBytes(response.bodyBytes);
            }
          }

          _downloadProgress = 0.2 + (audioStep * (i + 1));
          notifyListeners();
        }
      }

      _downloadProgress = 1.0;
      _isDownloadingAll = false;
      _isFullyOfflineReady = true;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));
      notifyListeners();
    } catch (e) {
      _isDownloadingAll = false;
      debugPrint("Error downloading all files for offline mode: $e");
      notifyListeners();
    }
  }

  // Deletes cached offline files and reloads bundle defaults
  Future<void> clearOfflineCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      
      final sutraCacheFile = File('${directory.path}/tarkasangraha_cache.json');
      final dictCacheFile = File('${directory.path}/dictionary_cache.json');

      if (await sutraCacheFile.exists()) await sutraCacheFile.delete();
      if (await dictCacheFile.exists()) await dictCacheFile.delete();

      for (var sutra in _sutras) {
        final localAudioFile = File('${directory.path}/${sutra.audio}');
        if (await localAudioFile.exists()) {
          await localAudioFile.delete();
        }
      }

      _isFullyOfflineReady = false;
      notifyListeners();

      // Reload default bundled assets
      await loadData();
    } catch (e) {
      debugPrint("Error clearing local cache: $e");
    }
  }

  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
    notifyListeners();
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    _playingSutraId = null;
    _position = Duration.zero;
    notifyListeners();
  }

  Future<void> seekAudio(Duration position) async {
    await _audioPlayer.seek(position);
    notifyListeners();
  }

  // Global search method
  List<Sutra> search(String query) {
    if (query.trim().isEmpty) return _sutras;
    final lowerQuery = query.toLowerCase();

    return _sutras.where((sutra) {
      final inSanskrit = sutra.sanskrit.toLowerCase().contains(lowerQuery);
      final inEnglish = sutra.englishMeaning.toLowerCase().contains(lowerQuery);
      final inKannada = sutra.kannadaMeaning.toLowerCase().contains(lowerQuery);
      final inTitle = sutra.title.toLowerCase().contains(lowerQuery);
      final inNumber = sutra.sutraNumber.toLowerCase().contains(lowerQuery);
      return inSanskrit || inEnglish || inKannada || inTitle || inNumber;
    }).toList();
  }

  // Dictionary Lookup Helper
  Map<String, dynamic>? lookupWord(String rawWord) {
    // Remove Sanskrit punctuations like । (danda) and ॥ (double danda), spaces, and standard commas/dots
    final cleaned = rawWord
        .replaceAll('।', '')
        .replaceAll('॥', '')
        .replaceAll(',', '')
        .replaceAll('.', '')
        .replaceAll(' ', '')
        .trim();

    if (cleaned.isEmpty) return null;

    // Direct match
    if (_dictionary.containsKey(cleaned)) {
      return _dictionary[cleaned];
    }

    // Try a case-insensitive check or partial matching if needed, 
    // but strict direct match is preferred for Sanskrit exact inflections.
    // However, if the word has virama/anusvara differences, we can try to resolve them.
    // For now, let's look for keys that match or are substrings to be slightly flexible.
    for (var key in _dictionary.keys) {
      if (key == cleaned) return _dictionary[key];
    }

    return null;
  }

  // Color helper methods for Theme Support
  Color get backgroundColor {
    switch (_theme) {
      case ReaderTheme.light:
        return const Color(0xFFFFFFFF);
      case ReaderTheme.dark:
        return const Color(0xFF121212);
      case ReaderTheme.sepia:
        return const Color(0xFFFBF0D9);
    }
  }

  Color get textColor {
    switch (_theme) {
      case ReaderTheme.light:
        return const Color(0xFF1E1E1E);
      case ReaderTheme.dark:
        return const Color(0xFFECECEC);
      case ReaderTheme.sepia:
        return const Color(0xFF433422);
    }
  }

  Color get cardBackgroundColor {
    switch (_theme) {
      case ReaderTheme.light:
        return const Color(0xFFF7F7F7);
      case ReaderTheme.dark:
        return const Color(0xFF1E1E1E);
      case ReaderTheme.sepia:
        return const Color(0xFFF3E7C4);
    }
  }

  Color get accentColor {
    // Elegant Saffron / Maroon Accent
    switch (_theme) {
      case ReaderTheme.light:
        return const Color(0xFFD35400); // Saffron / Orange-brown
      case ReaderTheme.dark:
        return const Color(0xFFE59866); // Light Saffron
      case ReaderTheme.sepia:
        return const Color(0xFF8B0000); // Deep Maroon
    }
  }

  Color get secondaryTextColor {
    switch (_theme) {
      case ReaderTheme.light:
        return const Color(0xFF555555);
      case ReaderTheme.dark:
        return const Color(0xFFAAAAAA);
      case ReaderTheme.sepia:
        return const Color(0xFF6E563B);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
