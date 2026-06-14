import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reader_provider.dart';

class DictionaryBottomSheet extends StatelessWidget {
  final String word;

  const DictionaryBottomSheet({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReaderProvider>(context);
    final entry = provider.lookupWord(word);

    final bg = provider.backgroundColor;
    final text = provider.textColor;
    final accent = provider.accentColor;
    final cardBg = provider.cardBackgroundColor;
    final secText = provider.secondaryTextColor;

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: accent.withAlpha(40),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: secText.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          if (entry != null) ...[
            // Word Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    entry['word'] ?? word,
                    style: TextStyle(
                      fontFamily: 'PragatiNarrow',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: secText),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            
            // Grammar tag
            if (entry['grammar'] != null) ...[
              const SizedBox(height: 4),
              Text(
                entry['grammar'],
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: secText,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // English Meaning Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accent.withAlpha(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.g_translate, size: 16, color: accent),
                      const SizedBox(width: 8),
                      Text(
                        "ENGLISH",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accent,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry['english'] ?? 'Meaning not available.',
                    style: TextStyle(
                      fontSize: 16,
                      color: text,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Kannada Meaning Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accent.withAlpha(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.translate, size: 16, color: accent),
                      const SizedBox(width: 8),
                      Text(
                        "ಕನ್ನಡ (KANNADA)",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accent,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry['kannada'] ?? 'ಅರ್ಥ ಲಭ್ಯವಿಲ್ಲ.',
                    style: TextStyle(
                      fontSize: 16,
                      color: text,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Word not found - Dictionary coming soon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  word,
                  style: TextStyle(
                    fontFamily: 'PragatiNarrow',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: text,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: secText),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.auto_stories,
                    size: 64,
                    color: accent.withAlpha(120),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Dictionary coming soon",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "The dictionary entry for '$word' is under preparation. We are constantly expanding Tarkaśravaḥ.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: secText,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
