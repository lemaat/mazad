import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart' show kFirebaseAvailable;
import 'config/app_config.dart';
import 'locale/locale_controller.dart';
import 'network/token_storage.dart';
import 'presentation/splash_screen.dart';
import 'theme/theme.dart';
import 'theme/theme_controller.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/listings/data/listing_repository.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import 'presentation/nav_shell.dart';

// Foreground notification channel (Android).
const _androidChannel = AndroidNotificationChannel(
  'mazad_default',
  'Mazad Notifications',
  importance: Importance.high,
);

final _localNotifications = FlutterLocalNotificationsPlugin();

Future<void> _initLocalNotifications() async {
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await _localNotifications.initialize(initSettings);
  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_androidChannel);
}

class MazadApp extends StatefulWidget {
  const MazadApp({super.key});

  @override
  State<MazadApp> createState() => _MazadAppState();
}

class _MazadAppState extends State<MazadApp> {
  final _themeController = ThemeController();
  final _localeController = LocaleController();
  late final AuthController _authController;
  late final ListingRepository _listingRepository;
  bool _showSplash = true;
  bool _showOnboarding = false;
  String? _previousToken;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(
      repository: const AuthRepository(host: AppConfig.host),
      tokenStorage: TokenStorage(),
    );
    _listingRepository = const ListingRepository(host: AppConfig.host);
    _themeController.load();
    _localeController.load();

    if (kFirebaseAvailable) {
      _initLocalNotifications();
      _setupFcm();
    }

    _authController.addListener(_onAuthChanged);
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final seen = await hasSeenOnboarding();
    if (mounted && !seen) setState(() => _showOnboarding = true);
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthChanged);
    _authController.dispose();
    _themeController.dispose();
    _localeController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (_authController.isLoggedIn && kFirebaseAvailable) {
      _registerFcmToken();
    } else if (!_authController.isLoggedIn && _previousToken != null) {
      _unregisterFcmToken(_previousToken!);
      _previousToken = null;
    }
  }

  Future<void> _setupFcm() async {
    // Permission is requested from the onboarding screen on first launch.
    // On subsequent launches (onboarding already seen) we request it here.
    // requestPermission() is cross-platform: covers iOS and Android 13+,
    // and is a no-op on Android < 13 or when already granted.
    if (await hasSeenOnboarding()) {
      await FirebaseMessaging.instance.requestPermission();
    }

    // Foreground messages — show as local notification.
    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n == null) return;
      _localNotifications.show(
        msg.hashCode,
        n.title,
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            importance: _androidChannel.importance,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    });

    // Background tap — app was in background.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Terminated-state tap.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleMessageTap(initial);
  }

  void _handleMessageTap(RemoteMessage msg) {
    // Deep-linking from a push tap — currently just surfaces the alerts tab.
    // Route based on msg.data['notification_type'] in a future iteration.
  }

  Future<void> _registerFcmToken() async {
    final token = _authController.token;
    if (token == null) return;
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;
      _previousToken = fcmToken;
      final platform = Platform.isIOS ? 'ios' : 'android';
      await NotificationRepository(host: AppConfig.host, token: token)
          .registerDevice(fcmToken, platform);
    } catch (_) {
      // best-effort
    }
  }

  Future<void> _unregisterFcmToken(String fcmToken) async {
    // Use the last known auth token — called right before it is cleared.
    final token = _authController.token;
    if (token == null) return;
    try {
      await NotificationRepository(host: AppConfig.host, token: token)
          .unregisterDevice(fcmToken);
    } catch (_) {
      // best-effort
    }
  }

  void _onSplashComplete() {
    if (mounted) setState(() => _showSplash = false);
  }

  void _onOnboardingDone() {
    if (mounted) setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    return LocaleControllerProvider(
      notifier: _localeController,
      child: ThemeControllerProvider(
        notifier: _themeController,
        child: ValueListenableBuilder<Locale?>(
          valueListenable: _localeController,
          builder: (_, locale, _) => ValueListenableBuilder<ThemeMode>(
            valueListenable: _themeController,
            builder: (_, mode, _) => MaterialApp(
              title: 'Mazad',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: mode,
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: _showSplash
                  ? SplashScreen(onComplete: _onSplashComplete)
                  : _showOnboarding
                      ? OnboardingScreen(onDone: _onOnboardingDone)
                      : NavShell(
                          authController: _authController,
                          listingRepository: _listingRepository,
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
