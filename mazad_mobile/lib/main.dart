import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/app.dart';

bool kFirebaseAvailable = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    kFirebaseAvailable = true;
  } catch (_) {
    // Firebase config files not present — push notifications disabled.
  }
  runApp(const MazadApp());
}
