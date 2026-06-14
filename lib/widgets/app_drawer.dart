import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reader_provider.dart';
import '../screens/about_us_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReaderProvider>(context);

    final bg = provider.backgroundColor;
    final text = provider.textColor;
    final accent = provider.accentColor;
    final cardBg = provider.cardBackgroundColor;
    final secText = provider.secondaryTextColor;

    return Drawer(
      backgroundColor: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: BoxDecoration(
              color: accent.withAlpha(20),
              border: Border(
                bottom: BorderSide(
                  color: accent.withAlpha(50),
                  width: 1.0,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "तर्कश्रावः",
                  style: TextStyle(
                    fontFamily: 'PragatiNarrow',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Tarkaśravaḥ Sanskrit Reader",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: text.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),

          // Menu Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                // Library Navigation Link
                ListTile(
                  leading: Icon(Icons.library_books, color: accent),
                  title: Text(
                    "Library Home",
                    style: TextStyle(color: text, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                  },
                ),
                const SizedBox(height: 4),

                // About Us Navigation Link
                ListTile(
                  leading: Icon(Icons.info_outline, color: accent),
                  title: Text(
                    "About Us",
                    style: TextStyle(color: text, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutUsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Offline Mode Panel
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "OFFLINE MODE SETTINGS",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accent,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Status Card
                Card(
                  color: cardBg,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: accent.withAlpha(20),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Status details
                        Row(
                          children: [
                            Icon(
                              provider.isFullyOfflineReady
                                  ? Icons.check_circle
                                  : provider.isDownloadingAll
                                      ? Icons.downloading
                                      : Icons.cloud_done_outlined,
                              color: provider.isFullyOfflineReady
                                  ? Colors.green
                                  : provider.isDownloadingAll
                                      ? accent
                                      : Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                provider.isFullyOfflineReady
                                    ? "100% Offline Ready"
                                    : provider.isDownloadingAll
                                        ? "Downloading Media..."
                                        : "Local Assets Only",
                                style: TextStyle(
                                  color: text,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.isFullyOfflineReady
                              ? "All 6 sutras and audio tracks are saved locally for offline playback."
                              : provider.isDownloadingAll
                                  ? "Fetching all audio files and indices from remote GitHub CDN..."
                                  : "Audio tracks stream online by default. Download them for offline playback.",
                          style: TextStyle(
                            color: secText,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Progress bar if downloading
                        if (provider.isDownloadingAll) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: provider.downloadProgress,
                                    color: accent,
                                    backgroundColor: accent.withAlpha(40),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "${(provider.downloadProgress * 100).toInt()}%",
                                style: TextStyle(
                                  color: text,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Actions button
                        if (provider.isDownloadingAll)
                          OutlinedButton(
                            onPressed: null, // Disabled during download
                            style: OutlinedButton.styleFrom(
                              disabledForegroundColor: secText.withAlpha(80),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text("Downloading..."),
                          )
                        else if (provider.isFullyOfflineReady)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text("Remove Offline Cache"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50.withAlpha(30),
                              foregroundColor: Colors.redAccent,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: Colors.redAccent, width: 1.0),
                              ),
                            ),
                            onPressed: () {
                              provider.clearOfflineCache();
                            },
                          )
                        else
                          ElevatedButton.icon(
                            icon: const Icon(Icons.cloud_download, size: 18),
                            label: const Text("Download All for Offline"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: bg,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              provider.downloadAllForOffline();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    "🔄 Note: When offline mode is active, the app automatically checks for cloud updates when online and syncs changes in the background.",
                    style: TextStyle(
                      fontSize: 11,
                      color: secText,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: accent.withAlpha(30),
                  width: 1.0,
                ),
              ),
            ),
            child: Text(
              "तर्कश्रावः • तर्कसंग्रहः",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PragatiNarrow',
                color: secText.withAlpha(150),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
