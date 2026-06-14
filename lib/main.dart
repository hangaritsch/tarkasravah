import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/reader_provider.dart';
import 'screens/library_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ReaderProvider(),
      child: const TarkaSravahApp(),
    ),
  );
}

class TarkaSravahApp extends StatelessWidget {
  const TarkaSravahApp({super.key});

  @override
  Widget build(BuildContext context) {
    // We dynamically apply custom colors/themes from ReaderProvider
    final provider = Provider.of<ReaderProvider>(context);

    // Dynamic color scheme matching saffron/maroon accents and Kindle themes
    final MaterialColor primaryColorSeed = Colors.orange;

    return MaterialApp(
      title: 'Tarkaśravaḥ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColorSeed,
          brightness: provider.theme == ReaderTheme.dark ? Brightness.dark : Brightness.light,
        ),
        scaffoldBackgroundColor: provider.backgroundColor,
        cardTheme: CardTheme(
          color: provider.cardBackgroundColor,
        ),
        fontFamily: 'PragatiNarrow',
      ),
      home: const LibraryScreen(),
    );
  }
}
