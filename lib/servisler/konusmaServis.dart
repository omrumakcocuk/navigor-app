import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart';

class KonusmaServis {
  final SpeechToText _speech = SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();


  final String _pythonSunucuAdresi = 'http://127.0.0.1:5000/ses-uret';


  String sonKelimeler = '';

  // Bu fonksiyon artık bir iş yapmıyor ama uyumluluk için duruyor.
  Future<void> metinOkuyucuHazirla() async {
    // Gelecekte ses çalar için başlangıç ayarları buraya eklenebilir.
  }


  Future<bool> konusmaTaniyiciHazirla(
      void Function(String) onStatus, void Function(String) onError) async {
    return await _speech.initialize(
      onStatus: onStatus,
      onError: (dynamic error) {
        onError(error.toString());
      },
    );
  }


  void dinlemeyiBaslat(void Function(String) onResult) {
    sonKelimeler = '';
    _speech.listen(
      localeId: 'tr-TR',
      onResult: (result) {
        sonKelimeler = result.recognizedWords;
        onResult(sonKelimeler);
      },
      cancelOnError: false,
      listenFor: const Duration(minutes: 10),
    );
  }


  void dinlemeyiDurdur() {
    _speech.stop();
  }

  bool get isListening => _speech.isListening;


  Future<void> konus(String metin) async {
    // Eğer ses çalar meşgulse, önce onu durduruyoruz.
    if (_audioPlayer.state == PlayerState.playing) {
      await _audioPlayer.stop();
    }

    try {
      print("Python sunucusuna istek gönderiliyor: '$metin'");
      // 1. Konuşulacak metni Python sunucusuna POST isteği ile gönderiyoruz.
      final response = await http.post(
        Uri.parse(_pythonSunucuAdresi),
        body: {'metin': metin},
      );

      if (response.statusCode == 200) {
        // 2. Sunucudan cevap olarak gelen ses verisini alıyoruz.
        final sesVerisi = response.bodyBytes;
        print("Ses verisi başarıyla alındı, çalınıyor...");
        // 3. Gelen ses dosyasını anında çalıyoruz.
        await _audioPlayer.play(BytesSource(sesVerisi));
      } else {
        // Eğer sunucu bir hata dönerse (404, 500 vb.) konsola yazdırıyoruz.
        print("Sunucudan hata kodu geldi: ${response.statusCode}");
      }
    } catch (e) {
      // Eğer sunucuya hiç bağlanamazsak (IP yanlış, Wi-Fi kapalı vb.) hatayı yazdırıyoruz.
      print("Python sunucusuna bağlanırken bir hata oluştu: $e");
    }
  }
}

