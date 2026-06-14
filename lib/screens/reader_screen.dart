import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/reader_provider.dart';
import '../models/sutra.dart';
import '../widgets/shabda_span.dart';
import '../widgets/dictionary_bottom_sheet.dart';
import '../widgets/app_drawer.dart';

class ReaderScreen extends StatefulWidget {
  final int initialSutraId;

  const ReaderScreen({super.key, required this.initialSutraId});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ReaderProvider>(context, listen: false);
    final initialIndex = provider.sutras.indexWhere((s) => s.id == widget.initialSutraId);
    _currentPageIndex = initialIndex != -1 ? initialIndex : 0;
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }



  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReaderProvider>(context);

    if (provider.isLoading) {
      return Scaffold(
        backgroundColor: provider.backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bg = provider.backgroundColor;
    final text = provider.textColor;
    final accent = provider.accentColor;
    final cardBg = provider.cardBackgroundColor;
    final secText = provider.secondaryTextColor;

    final sutrasCount = provider.sutras.length;
    final activeSutra = provider.sutras[_currentPageIndex];

    return Scaffold(
      backgroundColor: bg,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Sutra ${activeSutra.sutraNumber} of $sutrasCount",
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.format_size, color: accent),
              tooltip: 'Text Display Settings',
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(
            height: 1.0,
            thickness: 1.0,
            color: accent.withAlpha(30),
          ),
        ),
      ),
      body: Column(
        children: [
          // Reader content (Swipeable PageView)
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: sutrasCount,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
                // Auto-stop previous audio if playing when page changes (optional, keeps UI clean)
                if (provider.playingSutraId != null && provider.playingSutraId != provider.sutras[index].id) {
                  provider.stopAudio();
                }
              },
              itemBuilder: (context, index) {
                final sutra = provider.sutras[index];
                final isPlayingAudio = provider.playingSutraId == sutra.id;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Subtitle / Section title
                      Center(
                        child: Text(
                          sutra.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Sanskrit Card (Pragati Narrow font)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isPlayingAudio ? accent : accent.withAlpha(20),
                            width: isPlayingAudio ? 2.0 : 1.0,
                          ),
                          boxShadow: isPlayingAudio
                              ? [
                                  BoxShadow(
                                    color: accent.withAlpha(30),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text.rich(
                            TextSpan(
                              children: ShabdaSpanBuilder.buildSpans(
                                context: context,
                                text: sutra.sanskrit,
                                fontSize: 22.0, // base font size for Sanskrit
                                textColor: text,
                                onWordTap: (word) {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => DictionaryBottomSheet(word: word),
                                  );
                                },
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          "ℹ️ Tap on any Sanskrit word to see grammatical analysis and meanings.",
                          style: TextStyle(fontSize: 11, color: secText, fontStyle: FontStyle.italic),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // English Translation
                      if (provider.showEnglish) ...[
                        Text(
                          "English Translation",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: accent,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          sutra.englishMeaning,
                          style: TextStyle(
                            fontSize: 17.0,
                            color: text,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Kannada Translation
                      if (provider.showKannada) ...[
                        Text(
                          "ಕನ್ನಡ ಅನುವಾದ (Kannada)",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: accent,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          sutra.kannadaMeaning,
                          style: TextStyle(
                            fontSize: 17.0,
                            color: text,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Audio Player Controls Panel (fixed at the bottom)
          _buildAudioControlsPanel(provider, activeSutra, bg, text, accent, cardBg, secText),
        ],
      ),
    );
  }

  Widget _buildAudioControlsPanel(
    ReaderProvider provider,
    Sutra activeSutra,
    Color bg,
    Color text,
    Color accent,
    Color cardBg,
    Color secText,
  ) {
    final isPlayingSutra = provider.playingSutraId == activeSutra.id;
    final isAudioPlaying = isPlayingSutra && provider.playerState == PlayerState.playing;

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 32),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(
          top: BorderSide(
            color: accent.withAlpha(30),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Audio progress row
          Row(
            children: [
              Text(
                _formatDuration(isPlayingSutra ? provider.position : Duration.zero),
                style: TextStyle(color: secText, fontSize: 12),
              ),
              Expanded(
                child: Slider(
                  activeColor: accent,
                  inactiveColor: accent.withAlpha(40),
                  value: (isPlayingSutra && provider.duration.inMilliseconds > 0)
                      ? (provider.position.inMilliseconds / provider.duration.inMilliseconds).clamp(0.0, 1.0)
                      : 0.0,
                  onChanged: (val) {
                    if (isPlayingSutra && provider.duration.inMilliseconds > 0) {
                      final newMillis = (val * provider.duration.inMilliseconds).toInt();
                      provider.seekAudio(Duration(milliseconds: newMillis));
                    }
                  },
                ),
              ),
              Text(
                _formatDuration(isPlayingSutra ? provider.duration : Duration.zero),
                style: TextStyle(color: secText, fontSize: 12),
              ),
            ],
          ),
          
          // Audio control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Page Navigation - Previous
              IconButton(
                icon: Icon(Icons.skip_previous, color: _currentPageIndex > 0 ? accent : secText.withAlpha(60), size: 30),
                onPressed: _currentPageIndex > 0
                    ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
              const SizedBox(width: 20),

              // Main Play/Pause Button
              GestureDetector(
                onTap: () => provider.playAudio(activeSutra),
                child: Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withAlpha(60),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Icon(
                    isAudioPlaying ? Icons.pause : Icons.play_arrow,
                    color: bg,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Page Navigation - Next
              IconButton(
                icon: Icon(Icons.skip_next, color: _currentPageIndex < provider.sutras.length - 1 ? accent : secText.withAlpha(60), size: 30),
                onPressed: _currentPageIndex < provider.sutras.length - 1
                    ? () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
