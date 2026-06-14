import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // Per-Grantha Caching States
  final Map<String, double> _granthaDownloadProgress = {};
  final Map<String, bool> _isGranthaDownloading = {};
  final Map<String, bool> _isGranthaOfflineReady = {};
  String? _networkStatusMessage;

  // Track latest commit SHA from GitHub to bypass jsDelivr CDN caching
  String _commitSha = 'main';

  // App Version & Update Check
  static const String currentAppVersion = "1.0.3+4";
  bool _hasCheckedForUpdates = false;
  bool get hasCheckedForUpdates => _hasCheckedForUpdates;

  // Selected Devanagari Font
  String _devanagariFont = 'Pragati Narrow';
  String get devanagariFont => _devanagariFont;
  
  static const List<String> supportedDevanagariFonts = [
    'Amita',
    'Anek Devanagari',
    'Asar',
    'Baloo 2',
    'Biryani',
    'Cambay',
    'Dekko',
    'Eczar',
    'Farsan',
    'Gajraj One',
    'Gotu',
    'Halant',
    'Hind',
    'IBM Plex Sans Devanagari',
    'Jaldi',
    'Kadwa',
    'Kalam',
    'Karma',
    'Khand',
    'Kurale',
    'Laila',
    'Martel',
    'Martel Sans',
    'Modak',
    'Mukta',
    'Noto Sans Devanagari',
    'Noto Serif Devanagari',
    'Palanquin',
    'Palanquin Dark',
    'Playpen Sans',
    'Poppins',
    'Pragati Narrow',
    'Rajdhani',
    'Ranga',
    'Rhodium Libre',
    'Rozha One',
    'Sahitya',
    'Sarpanch',
    'Shrikhand',
    'Sura',
    'Teko',
    'Tiro Devanagari Hindi',
    'Tiro Devanagari Marathi',
    'Tiro Devanagari Sanskrit',
    'Vesper Libre',
    'Yantramanav',
    'Yatra One',
  ];

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
  Map<String, double> get granthaDownloadProgress => _granthaDownloadProgress;
  Map<String, bool> get isGranthaDownloading => _isGranthaDownloading;
  Map<String, bool> get isGranthaOfflineReady => _isGranthaOfflineReady;
  String? get networkStatusMessage => _networkStatusMessage;
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
    syncFromRemote();
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

      // 1. Try fetching index from GitHub API first on startup if online (real-time)
      try {
        final content = await _fetchRepoFileRealtime('assets/data/granthas.json');
        final decoded = json.decode(content);
        if (decoded is List) {
          await granthasCacheFile.writeAsString(content);
          _granthas = decoded.map((j) => Grantha.fromJson(j)).toList();
          debugPrint("Successfully loaded latest granthas index on startup.");
        }
      } catch (e) {
        debugPrint("Real-time fetch for granthas list failed on startup: $e");
      }

      // Fallback: load index from cache or assets
      if (_granthas.isEmpty) {
        if (await granthasCacheFile.exists()) {
          try {
            final content = await granthasCacheFile.readAsString();
            final List<dynamic> jsonList = json.decode(content);
            _granthas = jsonList.map((j) => Grantha.fromJson(j)).toList();
            debugPrint("Loaded granthas index from local cache.");
          } catch (_) {
            _granthas = await _loadGranthasFromAsset();
          }
        } else {
          _granthas = await _loadGranthasFromAsset();
        }
      }

      // Set active grantha (defaults to the first one)
      if (_granthas.isNotEmpty && _activeGrantha == null) {
        _activeGrantha = _granthas.first;
      }

      // Update the offline maps before loading active sutras
      await checkOfflineStatus();

      // 2. Try fetching dictionary from GitHub API on startup if online (real-time)
      try {
        final content = await _fetchRepoFileRealtime('assets/data/dictionary.json');
        final decoded = json.decode(content);
        if (decoded is Map) {
          await dictCacheFile.writeAsString(content);
          _dictionary = decoded.cast<String, dynamic>();
          debugPrint("Successfully loaded latest dictionary on startup.");
        }
      } catch (e) {
        debugPrint("Real-time fetch for dictionary failed on startup: $e");
      }

      // Fallback: load dictionary from cache or assets
      if (_dictionary.isEmpty) {
        if (await dictCacheFile.exists()) {
          try {
            final content = await dictCacheFile.readAsString();
            _dictionary = json.decode(content);
            debugPrint("Loaded dictionary from local cache.");
          } catch (_) {
            _dictionary = await _loadDictionaryFromAsset();
          }
        } else {
          _dictionary = await _loadDictionaryFromAsset();
        }
      }

      // 3. Load active Grantha's sutras
      await loadSutrasForActiveGrantha();

      _isLoading = false;
      notifyListeners();

      // Trigger background sync with a short delay to let network stack initialize
      Future.delayed(const Duration(seconds: 2), () {
        syncFromRemote();
      });
    } catch (e) {
      _isLoading = false;
      _error = "Error loading data: $e";
      notifyListeners();
    }
  }

  void setDevanagariFont(String font) {
    _devanagariFont = font;
    notifyListeners();
  }

  TextStyle getDevanagariStyle({required double fontSize, Color? color, FontWeight? fontWeight}) {
    if (_devanagariFont == 'Pragati Narrow' || _devanagariFont == 'PragatiNarrow') {
      return TextStyle(
        fontFamily: 'PragatiNarrow',
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
      );
    } else {
      try {
        return GoogleFonts.getFont(
          _devanagariFont,
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        );
      } catch (e) {
        // Fallback to local default PragatiNarrow
        return TextStyle(
          fontFamily: 'PragatiNarrow',
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        );
      }
    }
  }

  // Version check helpers
  bool _isNewerVersion(String local, String remote) {
    try {
      final localParts = local.split('+');
      final remoteParts = remote.split('+');
      
      final localSemVer = localParts[0].split('.');
      final remoteSemVer = remoteParts[0].split('.');
      
      for (int i = 0; i < 3; i++) {
        final localVal = int.parse(localSemVer[i]);
        final remoteVal = int.parse(remoteSemVer[i]);
        if (remoteVal > localVal) return true;
        if (remoteVal < localVal) return false;
      }
      
      if (remoteParts.length > 1 && localParts.length > 1) {
        final localBuild = int.parse(localParts[1]);
        final remoteBuild = int.parse(remoteParts[1]);
        return remoteBuild > localBuild;
      }
    } catch (_) {}
    return false;
  }

  // Triggers checking for remote updates
  Future<void> checkForUpdates(BuildContext context) async {
    if (_hasCheckedForUpdates) return;
    _hasCheckedForUpdates = true;
    try {
      final pubspecContent = await _fetchRepoFileRealtime('pubspec.yaml');
      final regExp = RegExp(r'^version:\s*(\d+\.\d+\.\d+\+\d+)', multiLine: true);
      final match = regExp.firstMatch(pubspecContent);
      if (match != null) {
        final remoteVersion = match.group(1)!;
        debugPrint("Current version: $currentAppVersion, Remote version: $remoteVersion");
        if (_isNewerVersion(currentAppVersion, remoteVersion)) {
          if (context.mounted) {
            _showUpdateDialog(context, remoteVersion);
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking for updates: $e");
    }
  }

  void _showUpdateDialog(BuildContext context, String newVersion) {
    final bg = backgroundColor;
    final text = textColor;
    final accent = accentColor;
    final secText = secondaryTextColor;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: bg,
          title: Text(
            "तर्कश्रवः - Update Available",
            style: TextStyle(color: accent, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "A newer version of Tarkaśravaḥ (v$newVersion) is available for download.",
                style: TextStyle(color: text),
              ),
              const SizedBox(height: 12),
              Text(
                "Would you like to visit the website to download the latest updates?",
                style: TextStyle(color: secText),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Later", style: TextStyle(color: secText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: bg),
              onPressed: () async {
                Navigator.pop(dialogContext);
                final url = Uri.parse('https://hangaritsch.github.io/tarkasravah/');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text("Download Now"),
            ),
          ],
        );
      },
    );
  }

  // Real-time file fetch helper to completely bypass CDN caching
  Future<String> _fetchRepoFileRealtime(String path) async {
    final apiUri = Uri.parse('https://api.github.com/repos/hangaritsch/tarkasravah/contents/$path');
    final rawUri = Uri.parse('https://raw.githubusercontent.com/hangaritsch/tarkasravah/main/$path?t=${DateTime.now().millisecondsSinceEpoch}');
    
    // 1. Try fetching via GitHub API contents endpoint for real-time data
    try {
      final response = await http.get(apiUri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded.containsKey('content')) {
          final cleanBase64 = decoded['content'].toString().replaceAll('\n', '').replaceAll('\r', '');
          final decodedBytes = base64.decode(cleanBase64);
          final content = utf8.decode(decodedBytes);
          debugPrint("Successfully fetched latest $path from GitHub API.");
          return content;
        }
      }
    } catch (e) {
      debugPrint("GitHub API fetch for $path failed: $e. Falling back to raw URL.");
    }

    // 2. Fallback to raw usercontent URL
    final response = await http.get(rawUri).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      debugPrint("Fetched $path from raw usercontent fallback.");
      return response.body;
    }
    
    throw Exception("Failed to fetch $path (status code: ${response.statusCode})");
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
    final isOfflineReady = _isGranthaOfflineReady[granthaId] == true;

    if (!isOfflineReady) {
      // Online first loading: fetch from CDN directly if not downloaded
      try {
        final rawUrlPrefix = 'https://raw.githubusercontent.com/hangaritsch/tarkasravah/main/assets/data';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final response = await http.get(Uri.parse('$rawUrlPrefix/$granthaId.json?t=$timestamp')).timeout(const Duration(seconds: 6));
        
        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded is List) {
            _sutras = decoded.map((j) => Sutra.fromJson(j)).toList();
            // Silently cache it locally
            final directory = await getApplicationDocumentsDirectory();
            final sutrasCacheFile = File('${directory.path}/${granthaId}_cache.json');
            await sutrasCacheFile.writeAsString(response.body);
            debugPrint("Loaded sutras for $granthaId directly from CDN.");
            notifyListeners();
            return;
          }
        }
      } catch (e) {
        debugPrint("CDN fetch failed for $granthaId (falling back to cache/assets): $e");
      }
    }

    // Fallback/Offline loading
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

  // Background remote sync
  Future<void> syncFromRemote() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      
      final rawUrlPrefix = 'https://raw.githubusercontent.com/hangaritsch/tarkasravah/main/assets/data';
      final rawAudioPrefix = 'https://raw.githubusercontent.com/hangaritsch/tarkasravah/main/assets/audio';
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      debugPrint("Attempting background sync from GitHub repository...");

      bool granthasUpdated = false;
      bool activeSutrasUpdated = false;

      // 1. Sync Granthas index
      final granthasResponse = await http.get(Uri.parse('$rawUrlPrefix/granthas.json?t=$timestamp')).timeout(const Duration(seconds: 8));
      if (granthasResponse.statusCode == 200) {
        final decoded = json.decode(granthasResponse.body);
        if (decoded is List) {
          final granthasCacheFile = File('${directory.path}/granthas_cache.json');
          await granthasCacheFile.writeAsString(granthasResponse.body);
          _granthas = decoded.map((j) => Grantha.fromJson(j)).toList();
          granthasUpdated = true;
          debugPrint("Granthas index successfully synced from GitHub.");
        }
      }

      // Set active grantha if it became null
      if (_granthas.isNotEmpty && _activeGrantha == null) {
        _activeGrantha = _granthas.first;
      }

      // 2. Sync Dictionary
      final dictResponse = await http.get(Uri.parse('$rawUrlPrefix/dictionary.json?t=$timestamp')).timeout(const Duration(seconds: 8));
      if (dictResponse.statusCode == 200) {
        final decoded = json.decode(dictResponse.body);
        if (decoded is Map) {
          final dictCacheFile = File('${directory.path}/dictionary_cache.json');
          await dictCacheFile.writeAsString(dictResponse.body);
          _dictionary = decoded.cast<String, dynamic>();
          debugPrint("Dictionary successfully synced from GitHub.");
        }
      }

      // 3. Sync Active Grantha's Sutras
      if (_activeGrantha != null) {
        final activeId = _activeGrantha!.id;
        final activeResponse = await http.get(Uri.parse('$rawUrlPrefix/$activeId.json?t=$timestamp')).timeout(const Duration(seconds: 8));
        if (activeResponse.statusCode == 200) {
          final decoded = json.decode(activeResponse.body);
          if (decoded is List) {
            final activeCacheFile = File('${directory.path}/${activeId}_cache.json');
            await activeCacheFile.writeAsString(activeResponse.body);
            _sutras = decoded.map((j) => Sutra.fromJson(j)).toList();
            activeSutrasUpdated = true;
            debugPrint("Active sutras ($activeId) successfully synced from GitHub.");
          }
        }
      }

      // If sync was successful, clear any network warnings
      _networkStatusMessage = null;

      // If user had previously enabled "Offline Mode", proactively download 
      // all files (including new Granthas and their audios) in the background.
      if ((granthasUpdated || activeSutrasUpdated) && _isFullyOfflineReady) {
        debugPrint("Automatic offline sync checking for new Granthas and audio files...");
        for (var grantha in _granthas) {
          final gFile = File('${directory.path}/${grantha.id}_cache.json');
          List<Sutra> gSutras = [];
          if (!await gFile.exists()) {
            final gResp = await http.get(Uri.parse('$rawUrlPrefix/${grantha.id}.json?t=$timestamp')).timeout(const Duration(seconds: 8));
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
            final rawAudioUrl = '$rawAudioPrefix/${sutra.audio}';
            
            if (await _shouldUpdateAudioFile(rawAudioUrl, localAudioFile)) {
              await _downloadAndCacheAudio(rawAudioUrl, localAudioFile);
            }
          }
        }
      }

      await checkOfflineStatus();
      notifyListeners();
    } catch (e) {
      debugPrint("Background GitHub sync failed: $e");
      try {
        final result = await InternetAddress.lookup('github.com').timeout(const Duration(seconds: 3));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          _networkStatusMessage = null;
        } else {
          _networkStatusMessage = "No internet connection. Operating in Offline Mode.";
        }
      } catch (_) {
        _networkStatusMessage = "No internet connection. Operating in Offline Mode.";
      }
      notifyListeners();
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
        final rawAudioUrl = 'https://raw.githubusercontent.com/hangaritsch/tarkasravah/main/assets/audio/${sutra.audio}';
        debugPrint("Streaming audio online from GitHub: $rawAudioUrl");
        await _audioPlayer.play(UrlSource(rawAudioUrl));

        // Start background download for caching
        _downloadAndCacheAudio(rawAudioUrl, localAudioFile);
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
      
      bool globalReady = true;
      if (!await granthasCacheFile.exists() || !await dictCacheFile.exists() || _granthas.isEmpty) {
        globalReady = false;
      }

      // Check per-Grantha offline status
      for (var grantha in _granthas) {
        final gCacheFile = File('${directory.path}/${grantha.id}_cache.json');
        if (!await gCacheFile.exists()) {
          _isGranthaOfflineReady[grantha.id] = false;
          globalReady = false;
          continue;
        }

        try {
          final content = await gCacheFile.readAsString();
          final List<dynamic> decodedList = json.decode(content);
          final listSutras = decodedList.map((j) => Sutra.fromJson(j)).toList();

          bool allAudiosExist = true;
          for (var sutra in listSutras) {
            if (sutra.audio.isEmpty) continue;
            final localAudioFile = File('${directory.path}/${sutra.audio}');
            if (!await localAudioFile.exists()) {
              allAudiosExist = false;
              break;
            }
          }
          _isGranthaOfflineReady[grantha.id] = allAudiosExist;
          if (!allAudiosExist) {
            globalReady = false;
          }
        } catch (e) {
          _isGranthaOfflineReady[grantha.id] = false;
          globalReady = false;
        }
      }

      _isFullyOfflineReady = globalReady;
      notifyListeners();
    } catch (e) {
      debugPrint("Error checking offline status: $e");
      _isFullyOfflineReady = false;
      notifyListeners();
    }
  }

  // Download and cache files for a specific Grantha
  Future<void> downloadGranthaForOffline(Grantha grantha) async {
    final granthaId = grantha.id;
    if (_isGranthaDownloading[granthaId] == true) return;

    _isGranthaDownloading[granthaId] = true;
    _granthaDownloadProgress[granthaId] = 0.0;
    _networkStatusMessage = null;
    notifyListeners();

    try {
      final directory = await getApplicationDocumentsDirectory();
      
      final rawUrlPrefix = 'https://raw.githubusercontent.com/hangaritsch/tarkasravah/main/assets/data';
      final rawAudioPrefix = 'https://raw.githubusercontent.com/hangaritsch/tarkasravah/main/assets/audio';
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final gFile = File('${directory.path}/${granthaId}_cache.json');
      List<Sutra> gSutras = [];

      // Step 1: Download Grantha JSON (approx 10% of progress)
      final gResp = await http.get(Uri.parse('$rawUrlPrefix/$granthaId.json?t=$timestamp')).timeout(const Duration(seconds: 10));
      if (gResp.statusCode == 200) {
        await gFile.writeAsString(gResp.body);
        final decoded = json.decode(gResp.body);
        if (decoded is List) {
          gSutras = decoded.map((j) => Sutra.fromJson(j)).toList();
        }
      } else {
        throw HttpException("Failed to download grantha data. Status: ${gResp.statusCode}");
      }

      _granthaDownloadProgress[granthaId] = 0.1;
      notifyListeners();

      // Step 2: Download all audio files for this Grantha (remaining 90%)
      if (gSutras.isNotEmpty) {
        double step = 0.9 / gSutras.length;
        for (int i = 0; i < gSutras.length; i++) {
          final sutra = gSutras[i];
          if (sutra.audio.isNotEmpty) {
            final localAudioFile = File('${directory.path}/${sutra.audio}');
            final rawAudioUrl = '$rawAudioPrefix/${sutra.audio}';

            if (await _shouldUpdateAudioFile(rawAudioUrl, localAudioFile)) {
              final response = await http.get(Uri.parse(rawAudioUrl)).timeout(const Duration(seconds: 45));
              if (response.statusCode == 200) {
                await localAudioFile.writeAsBytes(response.bodyBytes);
              } else {
                throw HttpException("Failed to download audio file ${sutra.audio}");
              }
            }
          }
          _granthaDownloadProgress[granthaId] = 0.1 + (step * (i + 1));
          notifyListeners();
        }
      }

      _isGranthaDownloading[granthaId] = false;
      _isGranthaOfflineReady[granthaId] = true;
      _granthaDownloadProgress[granthaId] = 1.0;
      await checkOfflineStatus();
      notifyListeners();
    } catch (e) {
      _isGranthaDownloading[granthaId] = false;
      _granthaDownloadProgress[granthaId] = 0.0;
      _networkStatusMessage = "No internet connection. Operating in Offline Mode.";
      debugPrint("Error downloading grantha offline files: $e");
      notifyListeners();
    }
  }

  // Deletes cached offline files for a specific Grantha
  Future<void> deleteGranthaOfflineCache(Grantha grantha) async {
    final granthaId = grantha.id;
    try {
      final directory = await getApplicationDocumentsDirectory();
      
      // Load sutras to find audio filenames
      final gCacheFile = File('${directory.path}/${granthaId}_cache.json');
      List<Sutra> gSutras = [];
      
      if (await gCacheFile.exists()) {
        try {
          final content = await gCacheFile.readAsString();
          final List<dynamic> decodedList = json.decode(content);
          gSutras = decodedList.map((j) => Sutra.fromJson(j)).toList();
        } catch (_) {}
        await gCacheFile.delete();
        debugPrint("Deleted cached JSON database for $granthaId");
      }

      // If we couldn't load from cache, fallback to asset to get list of audios to delete
      if (gSutras.isEmpty) {
        gSutras = await _loadSutrasFromAsset(granthaId);
      }

      // Delete audio files
      for (var sutra in gSutras) {
        if (sutra.audio.isNotEmpty) {
          final localAudioFile = File('${directory.path}/${sutra.audio}');
          if (await localAudioFile.exists()) {
            await localAudioFile.delete();
            debugPrint("Deleted cached audio: ${sutra.audio}");
          }
        }
      }

      _isGranthaOfflineReady[granthaId] = false;
      _granthaDownloadProgress[granthaId] = 0.0;
      _isGranthaDownloading[granthaId] = false;
      
      await checkOfflineStatus();
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting cached files for $granthaId: $e");
    }
  }

  // Proactive download manager - fetches all data for 100% offline usage
  Future<void> downloadAllForOffline() async {
    if (_isDownloadingAll) return;
    _isDownloadingAll = true;
    _downloadProgress = 0.0;
    _networkStatusMessage = null;
    notifyListeners();

    try {
      final directory = await getApplicationDocumentsDirectory();
      
      final rawUrlPrefix = 'https://raw.githubusercontent.com/hangaritsch/tarkasravah/main/assets/data';
      final rawAudioPrefix = 'https://raw.githubusercontent.com/hangaritsch/tarkasravah/main/assets/audio';
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final granthasCacheFile = File('${directory.path}/granthas_cache.json');
      final dictCacheFile = File('${directory.path}/dictionary_cache.json');

      // 1. Fetch latest Granthas index
      final granthasResponse = await http.get(Uri.parse('$rawUrlPrefix/granthas.json?t=$timestamp')).timeout(const Duration(seconds: 10));
      if (granthasResponse.statusCode == 200) {
        await granthasCacheFile.writeAsString(granthasResponse.body);
        final decoded = json.decode(granthasResponse.body);
        if (decoded is List) {
          _granthas = decoded.map((j) => Grantha.fromJson(j)).toList();
        }
      } else {
        throw HttpException("Failed to download granthas list");
      }
      _downloadProgress = 0.05;
      notifyListeners();

      // 2. Fetch latest Dictionary
      final dictResponse = await http.get(Uri.parse('$rawUrlPrefix/dictionary.json?t=$timestamp')).timeout(const Duration(seconds: 10));
      if (dictResponse.statusCode == 200) {
        await dictCacheFile.writeAsString(dictResponse.body);
        final decoded = json.decode(dictResponse.body);
        if (decoded is Map) {
          _dictionary = decoded.cast<String, dynamic>();
        }
      } else {
        throw HttpException("Failed to download dictionary");
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
          final gResp = await http.get(Uri.parse('$rawUrlPrefix/${grantha.id}.json?t=$timestamp')).timeout(const Duration(seconds: 10));
          if (gResp.statusCode == 200) {
            await gFile.writeAsString(gResp.body);
            final decoded = json.decode(gResp.body);
            if (decoded is List) {
              gSutras = decoded.map((j) => Sutra.fromJson(j)).toList();
            }
          } else {
            throw HttpException("Failed to download data for ${grantha.title}");
          }

          if (gSutras.isNotEmpty) {
            double audioStep = step / gSutras.length;
            for (int j = 0; j < gSutras.length; j++) {
              final sutra = gSutras[j];
              if (sutra.audio.isEmpty) continue;
              final localAudioFile = File('${directory.path}/${sutra.audio}');
              final rawAudioUrl = '$rawAudioPrefix/${sutra.audio}';

              if (await _shouldUpdateAudioFile(rawAudioUrl, localAudioFile)) {
                final response = await http.get(Uri.parse(rawAudioUrl)).timeout(const Duration(seconds: 45));
                if (response.statusCode == 200) {
                  await localAudioFile.writeAsBytes(response.bodyBytes);
                } else {
                  throw HttpException("Failed to download audio ${sutra.audio}");
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

      _downloadProgress = 1.0;
      _isDownloadingAll = false;
      _isFullyOfflineReady = true;
      _networkStatusMessage = null;
      await checkOfflineStatus();
      notifyListeners();
    } catch (e) {
      _isDownloadingAll = false;
      _networkStatusMessage = "No internet connection. Operating in Offline Mode.";
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

      _isGranthaOfflineReady.clear();
      _granthaDownloadProgress.clear();
      _isGranthaDownloading.clear();
      _isFullyOfflineReady = false;
      _activeGrantha = null;
      _networkStatusMessage = null;
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
