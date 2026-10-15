import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Firebase initialization (Phase 2)
// Uncomment after adding google-services.json and running `flutterfire configure`
// ─────────────────────────────────────────────────────────────────────────────
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase init (Phase 2) ─────────────────────────────────────────────
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  runApp(
    // Riverpod provider scope — wraps the entire app
    const ProviderScope(
      child: FindersKeepersApp(),
    ),
  );
}
