import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ValueNotifier<Locale?> {
  LocaleController() : super(null);

  static const _key = 'app_locale';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    value = switch (saved) {
      'en' => const Locale('en'),
      'fr' => const Locale('fr'),
      'ar' => const Locale('ar'),
      _ => null,
    };
  }

  Future<void> setLocale(Locale? locale) async {
    value = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
  }
}

class LocaleControllerProvider extends InheritedNotifier<LocaleController> {
  const LocaleControllerProvider({
    super.key,
    required super.notifier,
    required super.child,
  });

  static LocaleController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocaleControllerProvider>()!
          .notifier!;
}
