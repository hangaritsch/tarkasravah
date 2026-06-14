import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reader_provider.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReaderProvider>(context);

    final bg = provider.backgroundColor;
    final text = provider.textColor;
    final accent = provider.accentColor;
    final cardBg = provider.cardBackgroundColor;
    final secText = provider.secondaryTextColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "About Tarkaśravaḥ",
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(
            height: 1.0,
            thickness: 1.0,
            color: accent.withAlpha(30),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Emblem / Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: accent.withAlpha(45),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "तर्कश्रवः",
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: accent,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Tarkaśravaḥ",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: text,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Version 1.0.0 (Offline-First CDN)",
                    style: TextStyle(
                      fontSize: 12,
                      color: secText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Mission Statement
            Text(
              "Our Mission",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "तर्कश्रवः is a premium digital E-Reader dedicated to the study of Nyaya-Vaisheshika philosophy (Shastras). Our mission is to bridge ancient Sanskrit wisdom with modern interactive technology, making traditional texts accessible, interactive, and easily comprehensible for students and enthusiasts alike.",
              style: TextStyle(
                fontSize: 15,
                color: text,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Features Card Grid
            Text(
              "Key Features",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureRow(
              icon: Icons.translate,
              title: "Trilingual Translations",
              description: "Read each sutra with accurate Sanskrit Devanagari text coupled with fluent English and Kannada translations.",
              color: accent,
              textCol: text,
              secCol: secText,
            ),
            _buildFeatureRow(
              icon: Icons.ads_click,
              title: "Interactive 'Shabda' Meanings",
              description: "Tap any Sanskrit word (shabda) to instantly trigger a bottom sheet revealing its grammatical case and precise translation.",
              color: accent,
              textCol: text,
              secCol: secText,
            ),
            _buildFeatureRow(
              icon: Icons.cloud_download,
              title: "Offline Sync & Audio Streaming",
              description: "Stream high-quality audio files from GitHub or toggle the Offline Mode to download all media to local storage for offline use.",
              color: accent,
              textCol: text,
              secCol: secText,
            ),
            _buildFeatureRow(
              icon: Icons.chrome_reader_mode,
              title: "Kindle-Like Customization",
              description: "Adjust text sizes and dynamically switch themes between Light, Dark, and warm Sepia modes to fit your preferred reading environments.",
              color: accent,
              textCol: text,
              secCol: secText,
            ),
            const SizedBox(height: 28),

            // Credits/Acknowledgments
            Text(
              "Credits & Acknowledgments",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "We thank the traditional Sanskrit scholars and educators who have preserved Annambhatta's classic primer, the *Tarkasangraha*, for generations. All texts, translations, and lexical maps have been compiled locally to operate without third-party servers.",
              style: TextStyle(
                fontSize: 14,
                color: secText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),

            // Footer
            Center(
              child: Text(
                "© 2026 Tarkaśravaḥ Open-Source Project",
                style: TextStyle(
                  fontSize: 12,
                  color: secText.withAlpha(120),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Color textCol,
    required Color secCol,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textCol,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: secCol,
                    height: 1.3,
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
