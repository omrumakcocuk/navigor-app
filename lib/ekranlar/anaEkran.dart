import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Dokunsal geri bildirim için
import '../servisler/konusmaServis.dart';
import '../servisler/veriTabaniBaglanti.dart';

enum KonusmaDurumu {
  bosta,
  hedefBekleniyor,
  onayBekleniyor,
}

class AnaEkran extends StatefulWidget {
  const AnaEkran({Key? key}) : super(key: key);

  @override
  State<AnaEkran> createState() => _AnaEkranDurumu();
}

class _AnaEkranDurumu extends State<AnaEkran> with TickerProviderStateMixin {
  final KonusmaServis _konusmaServis = KonusmaServis();
  final VeriTabaniBaglanti _veriTabani = VeriTabaniBaglanti();

  bool _dinliyorMu = false;
  String _gosterilenMetin = 'NaviGör Başlatılıyor...';
  String _sonTanimlananKelimeler = '';
  String? _gidilecekYer;
  KonusmaDurumu _mevcutDurum = KonusmaDurumu.bosta;
  bool _butonBasiliMi = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _baslatVeKonus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _baslatVeKonus() async {
    await _konusmaServis.metinOkuyucuHazirla();
    await _konusmaServis.konusmaTaniyiciHazirla(_statusListener, _errorListener);
    await Future.delayed(const Duration(milliseconds: 500));
    _karsilamaMesajiniOynat();
  }

  void _statusListener(String status) {
    if (status == 'notListening' && _dinliyorMu) {
      setState(() {
        _dinliyorMu = false;
        _animationController.stop();
        _animationController.reset();
      });
      _sesliKomutuIsle(_sonTanimlananKelimeler);
    }
  }

  void _errorListener(String hata) {
    print('Konuşma hatası: $hata');
  }

  void _karsilamaMesajiniOynat() async {
    await _konusmaServis.konus("Na vigör uygulamasına hoş geldiniz.");
    _hedefiSor();
  }

  void _hedefiSor() async {
    _mevcutDurum = KonusmaDurumu.hedefBekleniyor;
    await _konusmaServis.konus("Nereye gitmek istersiniz?");
  }

  void _dinlemeyiBaslat() {
    if (!_dinliyorMu && !_konusmaServis.isListening) {
      HapticFeedback.lightImpact();
      _sonTanimlananKelimeler = '';
      setState(() {
        _gosterilenMetin = "Dinliyorum...";
        _dinliyorMu = true;
        _animationController.repeat(reverse: true);
      });
      _konusmaServis.dinlemeyiBaslat((sonuc) {
        if (sonuc.isNotEmpty) {
          _sonTanimlananKelimeler = sonuc;
          setState(() {
            _gosterilenMetin = sonuc;
          });
        }
      });
    }
  }

  void _dinlemeyiDurdur() {
    if (_dinliyorMu) {
      HapticFeedback.lightImpact();
      _konusmaServis.dinlemeyiDurdur();
    }
  }

  Future<void> _hedefiDogrulaVeAyarla(String hedef) async {
    try {
      final data = await _veriTabani.hastanedeArama(hedef);

      if (data != null) {
        _mevcutDurum = KonusmaDurumu.bosta;
        await _konusmaServis.konus("Harika! Rota, $hedef olarak ayarlanıyor.");
      } else {
        await _konusmaServis.konus(
            "Aradığınız '$hedef' isminde bir kayıt bulunamadı. Lütfen başka bir yer söyleyin.");
        _hedefiSor();
      }
    } catch (e) {
      print('Veritabanı hatası: $e');
      await _konusmaServis.konus(
          "Veritabanına bağlanırken bir sorun oluştu. Lütfen daha sonra tekrar deneyin.");
      _mevcutDurum = KonusmaDurumu.bosta;
    }
  }

  void _sesliKomutuIsle(String komut) async {
    if (komut.isEmpty) {
      await _konusmaServis.konus(
          "Sizi anlayamadım. Lütfen tekrar denemek için butona dokunun.");
      _mevcutDurum = KonusmaDurumu.hedefBekleniyor;
      return;
    }

    final kucukHarfKomut = komut.toLowerCase();
    switch (_mevcutDurum) {
      case KonusmaDurumu.hedefBekleniyor:
        _gidilecekYer = komut;
        _mevcutDurum = KonusmaDurumu.onayBekleniyor;
        await _konusmaServis.konus("Anladığım kadarıyla '$komut' dediniz. Onaylıyor musunuz?");
        break;
      case KonusmaDurumu.onayBekleniyor:
        if (kucukHarfKomut.contains("evet") || kucukHarfKomut.contains("onaylıyorum")) {
          if (_gidilecekYer != null) {
            await _hedefiDogrulaVeAyarla(_gidilecekYer!);
          }
        } else if (kucukHarfKomut.contains("hayır") || kucukHarfKomut.contains("iptal")) {
          _hedefiSor();
        } else {
          await _konusmaServis.konus("Anlayamadım. Lütfen 'evet' veya 'hayır' diyerek cevap verin.");
        }
        break;
      case KonusmaDurumu.bosta:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ekranGenisligi = MediaQuery.of(context).size.width;
    final butonBoyutu = ekranGenisligi * 0.35;

    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      body: SafeArea(
        child: Column(
          children: [
            // Başlık
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'NaviGör',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: const Color(0xFF00897B),
                    letterSpacing: 1.2),
              ),
            ),
            // Harita Alanı
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    'https://www.fragmanlar.com/images/blog/google-haritalar-a-yeni-ozellik.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade400, // Hata durumu için arkaplan
                        child: Center(
                          child: Icon(Icons.map_outlined, color: Colors.grey.shade600, size: 60),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Kontrol Paneli
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    // Gölge biraz daha belirgin
                    BoxShadow(
                      color: const Color.fromARGB(31, 0, 0, 0),
                      blurRadius: 25,
                      spreadRadius: -5,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Metin Alanı
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _gosterilenMetin,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800),
                        ),
                      ),
                    ),
                    // Buton Alanı
                    GestureDetector(
                      onTapDown: (_) => setState(() => _butonBasiliMi = true),
                      onTapUp: (_) => setState(() => _butonBasiliMi = false),
                      onTapCancel: () => setState(() => _butonBasiliMi = false),
                      onTap: () {
                        _dinliyorMu ? _dinlemeyiDurdur() : _dinlemeyiBaslat();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        transform: Matrix4.identity()..scale(_butonBasiliMi ? 0.95 : 1.0),
                        transformAlignment: Alignment.center,
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            final glowSize = _dinliyorMu
                                ? Tween<double>(begin: 0, end: 20)
                                .animate(_animationController)
                                .value
                                : 0.0;
                            return Container(
                              width: butonBoyutu,
                              height: butonBoyutu,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00BFA5),
                                borderRadius:
                                BorderRadius.circular(butonBoyutu / 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(179, 0, 191, 165),
                                    blurRadius: glowSize,
                                    spreadRadius: glowSize / 2,
                                  ),
                                ],
                              ),
                              child: child,
                            );
                          },
                          child: Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: butonBoyutu * 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

