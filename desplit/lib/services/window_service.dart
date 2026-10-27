import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WindowService {
  WindowService._();
  static final WindowService instance = WindowService._();

  static const MethodChannel _channel = MethodChannel('desplit/window');

  double _opacity = 0.93;
  double get currentOpacity => _opacity;

  /// Sets window opacity (0.1 to 1.0) on Windows desktop .exe
  Future<void> setOpacity(double opacity) async {
    _opacity = opacity.clamp(0.2, 1.0);
    if (!kIsWeb && Platform.isWindows) {
      try {
        await _channel.invokeMethod('setOpacity', _opacity);
      } catch (e) {
        debugPrint('WindowService setOpacity error: $e');
      }
    }
  }
}
