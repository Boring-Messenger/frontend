import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/new_chat_screen.dart';
import 'screens/qr_code_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/settings_screen.dart';
import 'services/profile_service.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    Future<void> tryInit(Future<void> Function() init) async {
      try {
        await init();
      } on FirebaseException catch (e) {
        // Ignore duplicate-app on hot restart or if native already initialized
        if (e.code != 'duplicate-app') rethrow;
      } on PlatformException catch (e) {
        if (e.code != 'duplicate-app') rethrow;
      } catch (e) {
        final msg = e.toString();
        if (!msg.contains('duplicate-app')) rethrow;
      }
    }

    try {
      await tryInit(() => Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ));
    } on UnsupportedError {
      // Fallback for platforms without configured options (e.g., linux)
      await tryInit(() => Firebase.initializeApp());
    }
  }
  // Decide start screen based on presence of local profile
  final hasProfile = await ProfileService().loadLocalProfile() != null;
  runApp(MyApp(startOnProfileSetup: !hasProfile));
}

class MyApp extends StatelessWidget {
  final bool startOnProfileSetup;
  const MyApp({super.key, this.startOnProfileSetup = false});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final darkBg = const Color(0xFF0A0F1A); // very blackish dark blue
    final darkCard = const Color(0xFF0E1624);
    final primary = const Color(0xFF90CAF9); // light blue accent
    final secondary = const Color(0xFF64B5F6);
    final scheme = ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      background: darkBg,
      surface: darkCard,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onBackground: Colors.white,
      onSurface: Colors.white,
    );

    final radius32 = BorderRadius.circular(32);
    final shape32 = RoundedRectangleBorder(borderRadius: radius32);

    return MaterialApp(
      title: 'Messager',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: darkBg,
        textTheme: GoogleFonts.heptaSlabTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: darkCard,
          foregroundColor: scheme.onSurface,
          elevation: 0,
          centerTitle: true,
        ),
  cardTheme: CardThemeData(
          color: darkCard,
          elevation: 0,
          shape: shape32,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        ),
  dialogTheme: DialogThemeData(
          backgroundColor: darkCard,
          shape: shape32,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: darkCard,
          shape: shape32,
        ),
        listTileTheme: ListTileThemeData(
          shape: shape32,
          iconColor: scheme.onSurface,
          textColor: scheme.onSurface,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkBg,
          border: OutlineInputBorder(borderRadius: radius32),
          enabledBorder: OutlineInputBorder(
            borderRadius: radius32,
            borderSide: BorderSide(color: scheme.outline.withOpacity(0.4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: radius32,
            borderSide: BorderSide(color: primary, width: 1.4),
          ),
          labelStyle: TextStyle(color: scheme.onSurface.withOpacity(0.8)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: shape32,
            backgroundColor: primary,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: shape32,
            backgroundColor: primary,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: shape32,
            side: BorderSide(color: primary),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            foregroundColor: primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: shape32,
            foregroundColor: primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.black,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: darkCard,
          contentTextStyle: TextStyle(color: scheme.onSurface),
          behavior: SnackBarBehavior.floating,
          shape: shape32,
        ),
        dividerTheme: DividerThemeData(color: scheme.outline.withOpacity(0.2)),
      ),
      home: startOnProfileSetup ? const ProfileSetupScreen() : const HomeScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
        '/new_chat': (context) => const NewChatScreen(),
        '/qr_code': (context) => const QRCodeScreen(),
        '/qr_scanner': (context) => const QRScannerScreen(),
        '/profile_setup': (context) => const ProfileSetupScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

// ...existing code...
