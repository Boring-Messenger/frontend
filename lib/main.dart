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
  return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
  // Use Hepta Slab as the default app font via Google Fonts
  textTheme: GoogleFonts.heptaSlabTextTheme(),
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
