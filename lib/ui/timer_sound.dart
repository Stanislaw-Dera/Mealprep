import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Dźwięk końca minutnika. Plik: assets/sounds/timer_done.wav
/// (placeholder z tools/make_timer_sound.py; podmień plik, żeby zmienić dźwięk).
class TimerSound {
  final _player = AudioPlayer();

  Future<void> play() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/timer_done.wav'));
    } catch (e) {
      // Brak dźwięku nie może zepsuć gotowania; zostaje komunikat na ekranie.
      debugPrint('Nie udało się odtworzyć dźwięku minutnika: $e');
    }
  }

  void dispose() => _player.dispose();
}
