import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebaselearning/authSetup/login.dart';
import 'package:firebaselearning/l10n/app_localizations.dart';
import 'package:firebaselearning/main_nav_shell.dart';
import 'package:firebaselearning/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options:
          kIsWeb
              ? const FirebaseOptions(
                apiKey: 'AIzaSyCITkWQse8FKyz9Kimk519rDKQ4lZN2n4I',
                appId: '1:388318558178:android:a7adad294fd29db4fbebbb',
                messagingSenderId: '388318558178',
                projectId: 'tareq-546c1',
                authDomain: 'tareq-546c1.firebaseapp.com',
                storageBucket: 'tareq-546c1.firebasestorage.app',
              )
              : null,
    );
  }
  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.dark(),

      debugShowCheckedModeBanner: false,
      home:
          FirebaseAuth.instance.currentUser != null &&
                  FirebaseAuth.instance.currentUser!.emailVerified
              ? const MainNavShell()
              : Login(),
    );
  }
}
