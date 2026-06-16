import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playAlarm(double volume) async {
    await _player.setVolume(volume / 100);
    await _player.play(AssetSource('audio/waring.mp3'));
  }

  static Future<void> stopAlarm() async {
    await _player.stop();
  }
}