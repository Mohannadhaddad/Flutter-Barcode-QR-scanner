import 'package:flutter/services.dart';

class FeedbackService {
  Future<void> playSuccess({
    required bool beep,
    required bool vibrate,
  }) async {
    if (vibrate) {
      await HapticFeedback.mediumImpact();
    }
    if (beep) {
      await SystemSound.play(SystemSoundType.click);
    }
  }
}
