import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reader_provider.dart';
import '../screens/about_us_screen.dart';
import '../screens/grantha_list_screen.dart';
import '../screens/library_screen.dart';

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
                  "तर्कश्रवः",
                  style: TextStyle(
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
                // Select Grantha
                ListTile(
                  leading: Icon(Icons.dashboard_outlined, color: accent),
                  title: Text(
                    "Select Grantha (ग्रन्थसूची)",
                    style: TextStyle(color: text, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    final routeName = ModalRoute.of(context)?.settings.name;
                    if (routeName != 'GranthaListScreen') {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          settings: const RouteSettings(name: 'GranthaListScreen'),
                          builder: (context) => const GranthaListScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 4),

                // Library Navigation Link
                ListTile(
                  leading: Icon(Icons.library_books_outlined, color: accent),
                  title: Text(
                    "Sutra List (सूत्रपाठः)",
                    style: TextStyle(color: text, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    final routeName = ModalRoute.of(context)?.settings.name;
                    if (routeName != 'LibraryScreen') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          settings: const RouteSettings(name: 'LibraryScreen'),
                          builder: (context) => const LibraryScreen(),
                        ),
                      );
                    }
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
                      MaterialPageRoute(
                        settings: const RouteSettings(name: 'AboutUsScreen'),
                        builder: (context) => const AboutUsScreen(),
                      ),
                    );
                  },
                ),
                 const SizedBox(height: 16),
                 const Divider(),
                 const SizedBox(height: 16),

                 // Reader Display Options Panel
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 8.0),
                   child: Text(
                     "READER DISPLAY OPTIONS",
                     style: TextStyle(
                       fontSize: 11,
                       fontWeight: FontWeight.bold,
                       color: accent,
                       letterSpacing: 1.1,
                     ),
                   ),
                 ),
                 const SizedBox(height: 12),

                 // Settings Card
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
                         // Font Size Row
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Text(
                               "Font Size",
                               style: TextStyle(
                                 fontSize: 14,
                                 fontWeight: FontWeight.bold,
                                 color: text,
                               ),
                             ),
                             Row(
                               children: [
                                 IconButton(
                                   icon: Icon(Icons.remove_circle_outline, color: accent, size: 20),
                                   onPressed: () {
                                     provider.decreaseFontSize();
                                   },
                                 ),
                                 Text(
                                   provider.fontSize.toInt().toString(),
                                   style: TextStyle(
                                     fontSize: 14,
                                     fontWeight: FontWeight.bold,
                                     color: text,
                                   ),
                                 ),
                                 IconButton(
                                   icon: Icon(Icons.add_circle_outline, color: accent, size: 20),
                                   onPressed: () {
                                     provider.increaseFontSize();
                                   },
                                 ),
                               ],
                             ),
                           ],
                         ),
                         const SizedBox(height: 8),
                         
                         // Sanskrit Font Dropdown Row
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Expanded(
                               child: Text(
                                 "Sanskrit Font",
                                 style: TextStyle(
                                   fontSize: 14,
                                   fontWeight: FontWeight.bold,
                                   color: text,
                                 ),
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ),
                             const SizedBox(width: 8),
                             SizedBox(
                               width: 140,
                               child: DropdownButton<String>(
                                 value: provider.devanagariFont,
                                 dropdownColor: bg,
                                 isExpanded: true,
                                 style: TextStyle(color: text, fontSize: 13),
                                 underline: Container(
                                   height: 1.0,
                                   color: accent.withAlpha(60),
                                 ),
                                 icon: Icon(Icons.arrow_drop_down, color: accent),
                                 onChanged: (String? newFont) {
                                   if (newFont != null) {
                                     provider.setDevanagariFont(newFont);
                                   }
                                 },
                                 items: ReaderProvider.supportedDevanagariFonts
                                     .map((font) => DropdownMenuItem<String>(
                                           value: font,
                                           child: Text(
                                             font,
                                             style: TextStyle(color: text),
                                             overflow: TextOverflow.ellipsis,
                                           ),
                                         ))
                                     .toList(),
                               ),
                             ),
                           ],
                         ),
                         const SizedBox(height: 12),

                         // Theme Options
                         Text(
                           "Theme",
                           style: TextStyle(
                             fontSize: 14,
                             fontWeight: FontWeight.bold,
                             color: text,
                           ),
                         ),
                         const SizedBox(height: 8),
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                           children: ReaderTheme.values.map((themeMode) {
                             final isSelected = provider.theme == themeMode;
                             String themeName = '';
                             Color themeBtnBg = Colors.white;
                             Color themeBtnText = Colors.black;
                             Color borderCol = Colors.transparent;

                             switch (themeMode) {
                               case ReaderTheme.light:
                                 themeName = 'Light';
                                 themeBtnBg = const Color(0xFFFFFFFF);
                                 themeBtnText = const Color(0xFF1E1E1E);
                                 borderCol = Colors.grey.shade300;
                                 break;
                               case ReaderTheme.dark:
                                 themeName = 'Dark';
                                 themeBtnBg = const Color(0xFF1E1E1E);
                                 themeBtnText = const Color(0xFFECECEC);
                                 borderCol = Colors.grey.shade800;
                                 break;
                               case ReaderTheme.sepia:
                                 themeName = 'Sepia';
                                 themeBtnBg = const Color(0xFFFBF0D9);
                                 themeBtnText = const Color(0xFF433422);
                                 borderCol = const Color(0xFFE5D5B3);
                                 break;
                             }

                             return Expanded(
                               child: Padding(
                                 padding: const EdgeInsets.symmetric(horizontal: 2),
                                 child: OutlinedButton(
                                   style: OutlinedButton.styleFrom(
                                     backgroundColor: themeBtnBg,
                                     side: BorderSide(
                                       color: isSelected ? accent : borderCol,
                                       width: isSelected ? 1.5 : 1.0,
                                     ),
                                     padding: const EdgeInsets.symmetric(vertical: 8),
                                     shape: RoundedRectangleBorder(
                                       borderRadius: BorderRadius.circular(8),
                                     ),
                                   ),
                                   onPressed: () {
                                     provider.setTheme(themeMode);
                                   },
                                   child: Text(
                                     themeName,
                                     style: TextStyle(
                                       color: themeBtnText,
                                       fontSize: 12,
                                       fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                     ),
                                   ),
                                 ),
                               ),
                             );
                           }).toList(),
                         ),
                         const SizedBox(height: 12),

                         // Translations Toggle
                         Text(
                           "Translations",
                           style: TextStyle(
                             fontSize: 14,
                             fontWeight: FontWeight.bold,
                             color: text,
                           ),
                         ),
                         SwitchListTile(
                           title: Text("English Meaning", style: TextStyle(color: text, fontSize: 13)),
                           value: provider.showEnglish,
                           activeColor: accent,
                           contentPadding: EdgeInsets.zero,
                           dense: true,
                           onChanged: (val) {
                             provider.toggleEnglishVisibility();
                           },
                         ),
                         SwitchListTile(
                           title: Text("Kannada Meaning (ಕನ್ನಡ)", style: TextStyle(color: text, fontSize: 13)),
                           value: provider.showKannada,
                           activeColor: accent,
                           contentPadding: EdgeInsets.zero,
                           dense: true,
                           onChanged: (val) {
                             provider.toggleKannadaVisibility();
                           },
                         ),
                       ],
                     ),
                   ),
                 ),
                 const SizedBox(height: 20),
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
                              ? "All ${provider.granthas.fold(0, (sum, g) => sum + g.sutraCount)} sutras and audio tracks are saved locally for offline playback."
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "तर्कश्रवः${provider.activeGrantha != null ? ' • ${provider.activeGrantha!.title}' : ''}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secText.withAlpha(150),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Version 1.0.4+5",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secText.withAlpha(120),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
