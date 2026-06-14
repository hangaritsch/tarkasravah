import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reader_provider.dart';
import '../widgets/app_drawer.dart';
import 'library_screen.dart';

class GranthaListScreen extends StatelessWidget {
  const GranthaListScreen({super.key});

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
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: accent),
        title: Text(
          "Tarkaśravaḥ (तर्कश्रावः)",
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.bold,
            fontFamily: 'PragatiNarrow',
            fontSize: 24,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Select Grantha / ग्रन्थचयनम्",
                            style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              fontFamily: 'PragatiNarrow',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Choose a text to read, listen, and explore",
                            style: TextStyle(
                              color: secText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: provider.granthas.length,
                        itemBuilder: (context, index) {
                          final grantha = provider.granthas[index];
                          final isActive = provider.activeGrantha?.id == grantha.id;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: cardBg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isActive ? accent : accent.withAlpha(20),
                                width: isActive ? 2.0 : 1.0,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                await provider.setActiveGrantha(grantha);
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LibraryScreen(),
                                    ),
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Sanskrit Title
                                              Text(
                                                grantha.title,
                                                style: TextStyle(
                                                  fontFamily: 'PragatiNarrow',
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: accent,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              // English Title
                                              Text(
                                                grantha.englishTitle,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: text,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: accent.withAlpha(25),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "${grantha.sutraCount} Sutras",
                                            style: TextStyle(
                                              color: accent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Author
                                    Row(
                                      children: [
                                        Icon(Icons.person_outline, size: 16, color: secText),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Author: ${grantha.author}",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: secText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Description
                                    Text(
                                      grantha.description,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: text.withAlpha(180),
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (isActive) ...[
                                          Icon(Icons.check_circle, color: Colors.green, size: 18),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Currently Selected",
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        Text(
                                          "Open Reader →",
                                          style: TextStyle(
                                            color: accent,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
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
