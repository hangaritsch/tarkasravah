import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reader_provider.dart';

class OfflineWarningBanner extends StatelessWidget {
  const OfflineWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReaderProvider>(context);
    if (provider.networkStatusMessage == null) return const SizedBox.shrink();

    final accent = provider.accentColor;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withAlpha(80), width: 1.0),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              provider.networkStatusMessage!,
              style: TextStyle(
                color: provider.textColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
