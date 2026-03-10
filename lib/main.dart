import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Import du sélecteur de rôle
import 'screens/role_selector_screen.dart';

void main() async {
  // 1. On s'assure que les widgets sont prêts
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialisation de Supabase
  // Utilise tes vrais identifiants ici
  await Supabase.initialize(
    url: 'https://ltcmjsjkyxwbiszrcayr.supabase.co',
    anonKey: 'sb_publishable_xWAQePu4kNDwO6wumpWb6g_Zw3h75Gg',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResiManager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B4A)),
        useMaterial3: true,
      ),
      // C'est cette page qui sera lancée en premier
      home: RoleSelectorScreen(),
    );
  }
}