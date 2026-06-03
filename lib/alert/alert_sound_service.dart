// lib/services/alert_sound_service.dart
//
// Plays a beep / alert sound when a price alert fires.
// Uses the `audioplayers` package — add to pubspec.yaml:
//
//   audioplayers: ^6.0.0
//
// Place your alert sound file at:  assets/sounds/alert.mp3
// And register it in pubspec.yaml:
//   flutter:
//     assets:
//       - assets/sounds/alert.mp3

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:parvexglobal/alert/AlertDirection.dart';
import 'package:parvexglobal/alert/PriceAlert.dart';

class AlertSoundService {
  AlertSoundService._();
  static final AlertSoundService instance = AlertSoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _isSoundEnabled = true;

  bool get isSoundEnabled => _isSoundEnabled;

  void toggleSound(bool value) => _isSoundEnabled = value;

  /// Call this when an alert fires.
  Future<void> playAlert(PriceAlert alert) async {
    if (!_isSoundEnabled) return;
    try {
      // Stop any current playback first so rapid alerts don't queue up.
      await _player.stop();
      await _player.play(alert.alertType == AlertType.Target ? AssetSource('sounds/target.wav') : AssetSource('sounds/alert.wav'));
    } catch (e) {
      debugPrint('[AlertSoundService] Could not play sound: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
