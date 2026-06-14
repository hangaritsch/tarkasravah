import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/sutra.dart';
import '../models/grantha.dart';

enum ReaderTheme { light, dark, sepia }

class ReaderProvider extends ChangeNotifier {
  List<Grantha> _granthas = [];
  Grantha? _activeGrantha;
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

  // Track latest commit SHA from GitHub to bypass jsDelivr CDN caching
  String _commitSha = 'main';

  // Audio Playback
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingSutraId;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Getters
  List<Grantha> get granthas => _granthas;
  Grantha? get activeGrantha => _activeGrantha;
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

  // Set the active text and load its sutras dynamically
  Future<void> setActiveGrantha(Grantha grantha) async {
    _activeGrantha = grantha;
    notifyListeners();
    await loadSutrasForActiveGrantha();
  }

  // Load local JSON assets & handle cache / background CDN sync
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final directory = await getApplicationDocumentsDirectory();
      final granthasCacheFile = File('${directory.path}/granthas_cache.json');
      final dictCacheFile = File('${directory.path}/dictionary_cache.json');

      // 1. Load Granthas list (from cache or bundle assets)
      if (await granthasCacheFile.exists()) {
        try {
          final content = await granthasCacheFile.readAsString();
          final List<dynamic> jsonList = json.decode(content);
          _granthas = jsonList.map((j) => Grantha.fromJson(j)).toList();
          debugPrint("Loaded granthas index from local document cache.");
        } catch (e) {
          debugPrint("Error loading granthas from cache: $e");
          _granthas = await _loadGranthasFromAsset();
        }
      } else {
        _granthas = await _loadGranthasFromAsset();
      }

      // Set active grantha (defaults to the first one)
      if (_granthas.isNotEmpty && _activeGrantha == null) {
        _activeGrantha = _granthas.first;
      }

      // 2. Load Dictionary
      if (await dictCacheFile.exists()) {
        try {
          final content = await dictCacheFile.readAsString();
          _dictionary = json.decode(content);
          debugPrint("Loaded dictionary from local document cache.");
        } catch (e) {
          _dictionary = await _loadDictionaryFromAsset();
        }
      } else {
        _dictionary = await _loadDictionaryFromAsset();
      }

      // 3. Load active Grantha's sutras
      await loadSutrasForActiveGrantha();

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

  Future<List<Grantha>> _loadGranthasFromAsset() async {
    final String content = await rootBundle.loadString('assets/data/granthas.json');
    final List<dynamic> jsonList = json.decode(content);
    return jsonList.map((j) => Grantha.fromJson(j)).toList();
  }

  Future<Map<String, dynamic>> _loadDictionaryFromAsset() async {
    final String content = await rootBundle.loadString('assets/data/dictionary.json');
    return json.decode(content);
  }

  // Load the sutras for the selected text
  Future<void> loadSutrasForActiveGrantha() async {
    if (_activeGrantha == null) return;
    
    final granthaId = _activeGrantha!.id;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final sutrasCacheFile = File('${directory.path}/${granthaId}_cache.json');

      if (await sutrasCacheFile.exists()) {
        try {
          final content = await sutrasCacheFile.readAsString();
          final List<dynamic> jsonList = json.decode(content);
          _sutras = jsonList.map((j) => Sutra.fromJson(j)).toList();
          debugPrint("Loaded sutras for $granthaId from local cache.");
        } catch (e) {
          _sutras = await _loadSutrasFromAsset(granthaId);
        }
      } else {
        _sutras = await _loadSutrasFromAsset(granthaId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading sutras for $granthaId: $e");
      _sutras = [];
      notifyListeners();
    }
  }

  Future<List<Sutra>> _loadSutrasFromAsset(String granthaId) async {
    try {
      final String content = await rootBundle.loadString('assets/data/$granthaId.json');
      final List<dynamic> jsonList = json.decode(content);
      return jsonList.map((j) => Sutra.fromJson(j)).toList();
    } catch (e) {
      debugPrint("Asset assets/data/$granthaId.json not found, returning empty: $e");
      return [];
    }
  }

  // Fetch the latest commit SHA from the GitHub API to bypass CDN caching
  Future<void> fetchLatestCommitSha() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/hangaritsch/tarkasravah/commits/main'),
        headers: {'User-Agent': 'Tarkasravah-App'},
      ).timeout(const Duration(seconds: 4));
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded.containsKey('sha')) {
          _commitSha = decoded['sha'] as String;
          debugPrint("Fetched latest commit SHA: $_commitSha");
        }
      }
    } catch (e) {
      debugPrint("Could not fetch latest commit SHA: $e");
    }
  }

  // Check if a remote audio file has changed (different size)
  Future<bool> _shouldUpdateAudioFile(String cdnAudioUrl, File localAudioFile) async {
    if (!await localAudioFile.exists()) return true;
    try {
      final response = await http.head(Uri.parse(cdnAudioUrl)).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final remoteLength = int.tryParse(response.headers['content-length'] ?? '');
        final localLength = await localAudioFile.length();
        if (remoteLength != null && remoteLength != localLength) {
          debugPrint("Audio file length mismatch: Remote $remoteLength, Local $localLength. Needs update.");
          return true;
        }
      }
    } catch (e) {
      debugPrint("Error checking remote audio file HEAD: $e");
    }
    return false;
  }

  // Background CDN sync
  Future<void> syncFromRemote() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      
      // Load cached SHA if available
      final shaFile = File('${directory.path}/commit_sha.txt');
      String cachedSha = '';
      if (await shaFile.exists()) {
        cachedSha = (await shaFile.readAsString()).trim();
      }

      await fetchLatestCommitSha();

      // If SHA hasn't changed and we already have cached files, skip sync!
      if (_commitSha != 'main' && cachedSha == _commitSha) {
        debugPrint("No remote changes. Already synced at commit: $_commitSha");
        return;
      }

      final granthasCacheFile = File('${directory.path}/granthas_cache.json');
      final dictCacheFile = File('${directory.path}/dictionary_cache.json');

      final cdnUrlPrefix = 'https://cdn.jsdelivr.net/gh/hangaritsch/tarkasravah@$_commitSha/assets/data';
      final cdnAudioPrefix = 'https://cdn.jsdelivr.net/gh/hangaritsch/tarkasravah@$_commitSha/assets/audio';

      debugPrint("Attempting background CDN sync at commit $_commitSha...");

      bool granthasUpdated = false;
      bool activeSutrasUpdated = false;

      // 1. Sync Granthas index
      final granthasResponse = await http.get(Uri.parse('$cdnUrlPrefix/granthas.json')).timeout(const Duration(seconds: 8));
      if (granthasResponse.statusCode == 200) {
        final decoded = json.decode(granthasResponse.body);
        if (decoded is List) {
          await granthasCacheFile.writeAsString(granthasResponse.body);
          _granthas = decoded.map((j) => Grantha.fromJson(j)).toList();
          granthasUpdated = true;
          debugPrint("Granthas index successfully synced from CDN and cached.");
        }
      }

      // Set active grantha if it became null
      if (_granthas.isNotEmpty && _activeGrantha == null) {
        _activeGrantha = _granthas.first;
      }

      // 2. Sync Dictionary
      final dictResponse = await http.get(Uri.parse('$cdnUrlPrefix/dictionary.json')).timeout(const Duration(seconds: 8));
      if (dictResponse.statusCode == 200) {
        final decoded = json.decode(dictResponse.body);
        if (decoded is Map) {
          await dictCacheFile.writeAsString(dictResponse.body);
          _dictionary = decoded.cast<String, dynamic>();
          debugPrint("Dictionary successfully synced from CDN and cached.");
        }
      }

      // 3. Sync Active Grantha's Sutras
      if (_activeGrantha != null) {
        final activeId = _activeGrantha!.id;
        final activeCacheFile = File('${directory.path}/${activeId}_cache.json');
        final activeResponse = await http.get(Uri.parse('$cdnUrlPrefix/$activeId.json')).timeout(const Duration(seconds: 8));
        if (activeResponse.statusCode == 200) {
          final decoded = json.decode(activeResponse.body);
          if (decoded is List) {
            await activeCacheFile.writeAsString(activeResponse.body);
            _sutras = decoded.map((j) => Sutra.fromJson(j)).toList();
            activeSutrasUpdated = true;
            debugPrint("Active sutras ($activeId) successfully synced from CDN and cached.");
          }
        }
      }

      // Save the newly synced commit SHA
      if (_commitSha != 'main') {
        await shaFile.writeAsString(_commitSha);
      }

      // If user had previously enabled "Offline Mode", proactively download 
      // all files (including new Granthas and their audios) in the background.
      if ((granthasUpdated || activeSutrasUpdated) && _isFullyOfflineReady) {
        debugPrint("Automatic offline sync checking for new Granthas and audio files...");
        for (var grantha in _granthas) {
          final gFile = File('${directory.path}/${grantha.id}_cache.json');
          List<Sutra> gSutras = [];
          if (!await gFile.exists()) {
            final gResp = await http.get(Uri.parse('$cdnUrlPrefix/${grantha.id}.json')).timeout(const Duration(seconds: 8));
            if (gResp.statusCode == 200) {
              await gFile.writeAsString(gResp.body);
              final decoded = json.decode(gResp.body);
              if (decoded is List) {
                gSutras = decoded.map((j) => Sutra.fromJson(j)).toList();
              }
            }
          } else {
            final content = await gFile.readAsString();
            final decoded = json.decode(content);
            if (decoded is List) {
              gSutras = decoded.map((j) => Sutra.fromJson(j)).toList();
            }
          }

          for (var sutra in gSutras) {
            if (sutra.audio.isEmpty) continue;
            final localAudioFile = File('${directory.path}/${sutra.audio}');
            final cdnAudioUrl = '$cdnAudioPrefix/${sutra.audio}';
            
            if (await _shouldUpdateAudioFile(cdnAudioUrl, localAudioFile)) {
              await _downloadAndCacheAudio(cdnAudioUrl, localAudioFile);
            }
          }
        }
      }

      await checkOfflineStatus();
      notifyListeners();
    } catch (e) {
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
        final cdnAudioUrl = 'https://cdn.jsdelivr.net/gh/hangaritsch/tarkasravah@$_commitSha/assets/audio/${sutra.audio}';
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
      
      final granthasCacheFile = File('${directory.path}/granthas_cache.json');
      final dictCacheFile = File('${directory.path}/dictionary_cache.json');
      
      if (!await granthasCacheFile.exists() || !await dictCacheFile.exists()) {
        _isFullyOfflineReady = false;
        notifyListeners();
        return;
      }

      if (_granthas.isEmpty) {
        _isFullyOfflineReady = false;
        notifyListeners();
        return;
      }

      bool everythingCached = true;
      for (var grantha in _granthas) {
        final gCacheFile = File('${directory.path}/${grantha.id}_cache.json');
        if (!await gCacheFile.exists()) {
          everythingCached = false;
          break;
        }

        final content = await gCacheFile.readAsString();
        final List<dynamic> decodedList = json.decode(content);
        final listSutras = decodedList.map((j) => Sutra.fromJson(j)).toList();

        for (var sutra in listSutras) {
          final localAudioFile = File('${directory.path}/${sutra.audio}');
          if (!await localAudioFile.exists()) {
            everythingCached = false;
            break;
          }
        }
        if (!everythingCached) break;
      }

      _isFullyOfflineReady = everythingCached;
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
      await fetchLatestCommitSha();
      final directory = await getApplicationDocumentsDirectory();
      
      final cdnUrlPrefix = 'https://cdn.jsdelivr.net/gh/hangaritsch/tarkasravah@$_commitSha/assets/data';
      final cdnAudioPrefix = 'https://cdn.jsdelivr.net/gh/hangaritsch/tarkasravah@$_commitSha/assets/audio';

      final granthasCacheFile = File('${directory.path}/granthas_cache.json');
      final dictCacheFile = File('${directory.path}/dictionary_cache.json');

      // 1. Fetch latest Granthas index
      final granthasResponse = await http.get(Uri.parse('$cdnUrlPrefix/granthas.json')).timeout(const Duration(seconds: 8));
      if (granthasResponse.statusCode == 200) {
        await granthasCacheFile.writeAsString(granthasResponse.body);
        final decoded = json.decode(granthasResponse.body);
        if (decoded is List) {
          _granthas = decoded.map((j) => Grantha.fromJson(j)).toList();
        }
      }
      _downloadProgress = 0.05;
      notifyListeners();

      // 2. Fetch latest Dictionary
      final dictResponse = await http.get(Uri.parse('$cdnUrlPrefix/dictionary.json')).timeout(const Duration(seconds: 8));
      if (dictResponse.statusCode == 200) {
        await dictCacheFile.writeAsString(dictResponse.body);
        final decoded = json.decode(dictResponse.body);
        if (decoded is Map) {
          _dictionary = decoded.cast<String, dynamic>();
        }
      }
      _downloadProgress = 0.1;
      notifyListeners();

      // 3. Fetch all Granthas' JSONs and audio files
      if (_granthas.isNotEmpty) {
        double step = 0.9 / _granthas.length;

        for (int i = 0; i < _granthas.length; i++) {
          final grantha = _granthas[i];
          final gFile = File('${directory.path}/${grantha.id}_cache.json');
          List<Sutra> gSutras = [];

          // Download Grantha JSON
          final gResp = await http.get(Uri.parse('$cdnUrlPrefix/${grantha.id}.json')).timeout(const Duration(seconds: 8));
          if (gResp.statusCode == 200) {
            await gFile.writeAsString(gResp.body);
            final decoded = json.decode(gResp.body);
            if (decoded is List) {
              gSutras = decoded.map((j) => Sutra.fromJson(j)).toList();
            }
          }

          if (gSutras.isNotEmpty) {
            double audioStep = step / gSutras.length;
            for (int j = 0; j < gSutras.length; j++) {
              final sutra = gSutras[j];
              if (sutra.audio.isEmpty) continue;
              final localAudioFile = File('${directory.path}/${sutra.audio}');
              final cdnAudioUrl = '$cdnAudioPrefix/${sutra.audio}';

              if (await _shouldUpdateAudioFile(cdnAudioUrl, localAudioFile)) {
                final response = await http.get(Uri.parse(cdnAudioUrl)).timeout(const Duration(seconds: 30));
                if (response.statusCode == 200) {
                  await localAudioFile.writeAsBytes(response.bodyBytes);
                }
              }

              _downloadProgress = 0.1 + (step * i) + (audioStep * (j + 1));
              notifyListeners();
            }
          } else {
            _downloadProgress = 0.1 + (step * (i + 1));
            notifyListeners();
          }
        }
      }

      // Save synced commit SHA
      if (_commitSha != 'main') {
        final shaFile = File('${directory.path}/commit_sha.txt');
        await shaFile.writeAsString(_commitSha);
      }

      _downloadProgress = 1.0;
      _isDownloadingAll = false;
      _isFullyOfflineReady = true;
      await checkOfflineStatus();
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
      
      final granthasCacheFile = File('${directory.path}/granthas_cache.json');
      final dictCacheFile = File('${directory.path}/dictionary_cache.json');

      if (await granthasCacheFile.exists()) await granthasCacheFile.delete();
      if (await dictCacheFile.exists()) await dictCacheFile.delete();

      for (var grantha in _granthas) {
        final gCacheFile = File('${directory.path}/${grantha.id}_cache.json');
        if (await gCacheFile.exists()) {
          try {
            final content = await gCacheFile.readAsString();
            final List<dynamic> decodedList = json.decode(content);
            final listSutras = decodedList.map((j) => Sutra.fromJson(j)).toList();
            for (var sutra in listSutras) {
              final localAudioFile = File('${directory.path}/${sutra.audio}');
              if (await localAudioFile.exists()) {
                await localAudioFile.delete();
              }
            }
          } catch (_) {}
          await gCacheFile.delete();
        }
      }

      _isFullyOfflineReady = false;
      _activeGrantha = null;
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
    final cleaned = rawWord
        .replaceAll('।', '')
        .replaceAll('॥', '')
        .replaceAll(',', '')
        .replaceAll('.', '')
        .replaceAll(' ', '')
        .trim();

    if (cleaned.isEmpty) return null;

    if (_dictionary.containsKey(cleaned)) {
      return _dictionary[cleaned];
    }

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
    switch (_theme) {
      case ReaderTheme.light:
        return const Color(0xFFD35400); // Saffron
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
