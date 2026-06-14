import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reader_provider.dart';

class ShabdaSpanBuilder {
  static List<InlineSpan> buildSpans({
    required BuildContext context,
    required String text,
    required double fontSize,
    required Color textColor,
    required void Function(String word) onWordTap,
  }) {
    final provider = Provider.of<ReaderProvider>(context, listen: false);
    final List<InlineSpan> spans = [];
    final List<String> tokens = text.split(RegExp(r'\s+'));

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.isEmpty) continue;

      // Handle pure punctuation tokens
      if (token == '।' || token == '॥') {
        spans.add(TextSpan(
          text: token,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontFamily: 'PragatiNarrow',
          ),
        ));
      } else {
        // Strip trailing punctuation if attached to word (e.g., "तर्कसङ्ग्रहः॥" -> "तर्कसङ्ग्रहः" + "॥")
        String cleanWord = token;
        String trailingPunctuation = '';

        if (token.endsWith('॥')) {
          cleanWord = token.substring(0, token.length - 1);
          trailingPunctuation = '॥';
        } else if (token.endsWith('।')) {
          cleanWord = token.substring(0, token.length - 1);
          trailingPunctuation = '।';
        }

        // Add the word span (interactive)
        spans.add(TextSpan(
          text: cleanWord,
          style: TextStyle(
            color: provider.accentColor,
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
            fontFamily: 'PragatiNarrow',
            decoration: TextDecoration.underline,
            decorationColor: provider.accentColor.withAlpha(80),
            decorationStyle: TextDecorationStyle.dashed,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              onWordTap(cleanWord);
            },
        ));

        // Add the trailing punctuation
        if (trailingPunctuation.isNotEmpty) {
          spans.add(TextSpan(
            text: trailingPunctuation,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontFamily: 'PragatiNarrow',
            ),
          ));
        }
      }

      // Append space between tokens
      if (i < tokens.length - 1) {
        spans.add(TextSpan(
          text: ' ',
          style: TextStyle(fontSize: fontSize),
        ));
      }
    }

    return spans;
  }
}
