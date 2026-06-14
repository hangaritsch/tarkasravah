import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/reader_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/offline_warning_banner.dart';
import 'reader_screen.dart';
import 'search_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReaderProvider>(context);

    final bg = provider.backgroundColor;
    final text = provider.textColor;
    final accent = provider.accentColor;
    final cardBg = provider.cardBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: accent),
        title: Text(
          provider.activeGrantha?.title ?? "Library",
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.bold,
            fontFamily: 'PragatiNarrow',
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: accent),
            tooltip: 'Search Sutras',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
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
      body: provider.isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            )
          : provider.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: accent),
                        const SizedBox(height: 16),
                        Text(
                          provider.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: text, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadData(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: bg,
                          ),
                          child: const Text("Retry"),
                        )
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    const OfflineWarningBanner(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: provider.sutras.length,
                        itemBuilder: (context, index) {
                          final sutra = provider.sutras[index];
                          final isPlaying = provider.playingSutraId == sutra.id;
                          final isAudioPlaying = isPlaying && provider.playerState == PlayerState.playing;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: cardBg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isPlaying ? accent : accent.withAlpha(20),
                                width: isPlaying ? 2.0 : 1.0,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReaderScreen(initialSutraId: sutra.id),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Sutra Number Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: accent.withAlpha(25),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "Sutra ${sutra.sutraNumber}",
                                            style: TextStyle(
                                              color: accent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        // Audio Play / Pause Button
                                        IconButton(
                                          icon: Icon(
                                            isAudioPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                            color: accent,
                                            size: 32,
                                          ),
                                          onPressed: () => provider.playAudio(sutra),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Title
                                    Text(
                                      sutra.title,
                                      style: TextStyle(
                                        color: text,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // First line of Sanskrit
                                    Text(
                                      sutra.sanskrit,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'PragatiNarrow',
                                        fontSize: 18,
                                        color: text.withAlpha(220),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
