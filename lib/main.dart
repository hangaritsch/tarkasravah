import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/reader_provider.dart';
import 'screens/grantha_list_screen.dart';

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

    final baseTextTheme = provider.theme == ReaderTheme.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    TextTheme textTheme;
    if (provider.devanagariFont == 'Pragati Narrow' || provider.devanagariFont == 'PragatiNarrow') {
      textTheme = baseTextTheme.apply(fontFamily: 'PragatiNarrow');
    } else {
      try {
        textTheme = GoogleFonts.getTextTheme(provider.devanagariFont, baseTextTheme);
      } catch (_) {
        textTheme = baseTextTheme.apply(fontFamily: 'PragatiNarrow');
      }
    }

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
        textTheme: textTheme,
      ),
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        final double scaleFactor = provider.fontSize / 20.0;
        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: TextScaler.linear(scaleFactor),
          ),
          child: child!,
        );
      },
      home: const GranthaListScreen(),
    );
  }
}
