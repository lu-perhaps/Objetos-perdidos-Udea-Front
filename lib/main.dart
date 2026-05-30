import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'Screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qzqvvdnjizhaewbizoit.supabase.co',
    anonKey: 'sb_publishable_rVPrlTvyfgle9vzme_E1mw_rW7juGyK',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Objetos Perdidos UdeA',
      home: AuthGate(),

      locale: Locale('es', 'CO'),

      supportedLocales: [
        Locale('es', 'CO'),
        Locale('en', 'US'),
      ],

      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}