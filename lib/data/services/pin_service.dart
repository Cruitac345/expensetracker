import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinService extends ChangeNotifier {
  PinService({required this.onWipe});

  final Future<void> Function() onWipe;

  static const String _pinKey = 'pin';
  static const String _attemptsKey = 'attempts';
  static const int maxAttempts = 3;

  String? _pin;
  bool _unlocked = false;
  int _attempts = 0;

  bool get hasPin => _pin != null;
  bool get isUnlocked => _unlocked;
  int get attemptsLeft => maxAttempts - _attempts;

  Future<void> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _pin = prefs.getString(_pinKey);
    _attempts = prefs.getInt(_attemptsKey) ?? 0;
    _unlocked = false;
    notifyListeners();
  }

  Future<String?> setPin(String pin) async {
    if (pin.length != 4) return 'PIN должен быть 4 цифры';
    if (_isEasy(pin)) return 'Такой PIN слишком простой';
    if (pin != _pin && _pin != null) {
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    await prefs.setInt(_attemptsKey, 0);
    _pin = pin;
    _attempts = 0;
    _unlocked = true;
    notifyListeners();
    return null;
  }

  Future<String> check(String pin) async {
    if (_pin == null) return 'ok';
    if (pin == _pin) {
      await _saveAttempts(0);
      _attempts = 0;
      _unlocked = true;
      notifyListeners();
      return 'ok';
    }

    _attempts++;
    await _saveAttempts(_attempts);

    if (_attempts >= maxAttempts) {
      await resetAll();
      return 'wiped';
    }

    notifyListeners();
    return 'wrong:$attemptsLeft';
  }

  Future<void> resetAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.setInt(_attemptsKey, 0);
    _pin = null;
    _attempts = 0;
    _unlocked = false;
    try {
      await onWipe();
    } on Exception catch (error) {
      debugPrint('wipe error: $error');
    }
    notifyListeners();
  }

  Future<void> _saveAttempts(int n) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_attemptsKey, n);
  }

  bool _isEasy(String pin) {
    if (pin.split('').toSet().length == 1) return true;

    const List<String> bad = <String>[
      '1234', '4321', '0123', '3210',
      '2345', '5432', '3456', '6543',
      '4567', '7654', '5678', '8765',
      '6789', '9876',
    ];
    if (bad.contains(pin)) return true;
    if (pin.substring(0, 2) == pin.substring(2, 4)) return true;

    return false;
  }
}