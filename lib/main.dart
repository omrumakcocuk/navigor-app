import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ekranlar/anaEkran.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ynbyrilkovvhywtzvrkg.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InluYnlyaWxrb3Z2aHl3dHp2cmtnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3Mjk3MDIsImV4cCI6MjA2OTMwNTcwMn0.MCeYyBqVTzU9i7pIF6q0M3dniCqhVrbsYzyKaTrLJzI',
  );

  runApp(const Uygulamam());
}

class Uygulamam extends StatelessWidget {
  const Uygulamam({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NaviGör',
      home: AnaEkran(),
    );
  }
}
