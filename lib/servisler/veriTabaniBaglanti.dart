import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class VeriTabaniBaglanti {
  Future<dynamic> hastanedeArama(String aramaKelimesi) async {
    try {
      final data = await supabase
          .from('hastane')
          .select('doktor_ad')
          .ilike('doktor_ad', '%$aramaKelimesi%')
          .maybeSingle();

      return data;
    } catch (e) {
      rethrow;
    }
  }
}
