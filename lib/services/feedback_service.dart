import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class FeedbackService {
  FeedbackService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  bool _audioReady = false;

  Future<void> _ensureAudio() async {
    if (_audioReady) return;
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(1.0);
    _audioReady = true;
  }

  Future<void> playSuccess({
    required bool beep,
    required bool vibrate,
  }) async {
    if (vibrate) {
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          await Vibration.vibrate(duration: 80, amplitude: 180);
        } else {
          await HapticFeedback.heavyImpact();
        }
      } catch (_) {
        await HapticFeedback.heavyImpact();
      }
    }

    if (beep) {
      try {
        await _ensureAudio();
        await _player.stop();
        await _player.play(AssetSource('sounds/beep.wav'));
      } catch (_) {
        await SystemSound.play(SystemSoundType.click);
      }
    }
  }
}
