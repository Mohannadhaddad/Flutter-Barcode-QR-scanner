import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class FeedbackService {
  FeedbackService({AudioPlayer? player})
      : _player = player ?? AudioPlayer(playerId: 'scanforge_beep');

  final AudioPlayer _player;
  bool _ready = false;

  Future<void> _ensureReady() async {
    if (_ready) return;
    final ctx = AudioContextConfig(
      route: AudioContextConfigRoute.system,
      respectSilence: false,
      stayAwake: false,
    ).build();
    await AudioPlayer.global.setAudioContext(ctx);
    await _player.setAudioContext(ctx);
    await _player.setPlayerMode(PlayerMode.lowLatency);
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(1.0);
    _ready = true;
  }

  Future<void> playSuccess({
    required bool beep,
    required bool vibrate,
  }) async {
    // Run vibrate and beep together so continuous mode feels instant.
    await Future.wait([
      if (vibrate) _vibrate(),
      if (beep) _beep(),
    ]);
  }

  Future<void> playDuplicateNotice({
    required bool beep,
    required bool vibrate,
  }) async {
    // Softer cue so duplicates are noticeable but distinct from a new scan.
    if (vibrate) {
      try {
        await HapticFeedback.selectionClick();
      } catch (_) {}
    }
    if (beep) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  Future<void> _vibrate() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        await Vibration.vibrate(duration: 120, amplitude: 255);
      }
    } catch (_) {
      try {
        await Vibration.vibrate(duration: 120);
      } catch (_) {}
    }
  }

  Future<void> _beep() async {
    try {
      await _ensureReady();
      await _player.stop();
      await _player.play(AssetSource('sounds/beep.wav'), volume: 1.0);
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {
        try {
          await SystemSound.play(SystemSoundType.click);
        } catch (_) {}
      }
    }
  }
}
