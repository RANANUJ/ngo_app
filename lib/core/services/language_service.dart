import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  LanguageService() {
    _loadLanguage();
  }

  final _secureStorage = const FlutterSecureStorage();

  Future<void> _loadLanguage() async {
    final languageCode = await _secureStorage.read(key: _languageKey) ?? 'en';
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    if (_currentLocale.languageCode == languageCode) return;
    _currentLocale = Locale(languageCode);
    notifyListeners();
    await _secureStorage.write(key: _languageKey, value: languageCode);
  }

  bool get isHindi => _currentLocale.languageCode == 'hi';
  bool get isEnglish => _currentLocale.languageCode == 'en';
}
