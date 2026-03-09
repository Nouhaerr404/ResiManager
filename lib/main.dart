import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Importe ton fichier de configuration
// (Vérifie juste le nom exact de ton fichier dans le dossier config, par exemple config.dart)
import 'config/supabase_config.dart'; // <-- À adapter selon le nom de ton fichier

// 2. Importe ton écran Dashboard
import 'screens/syndic_general/dashboard_screen.dart';

void main() async {
  // Obligatoire avant d'initialiser des plugins natifs comme Supabase
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Initialisation avec TA classe de configuration
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const ResiManagerApp());
}

class ResiManagerApp extends StatelessWidget {
  const ResiManagerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResiManager - Syndic Général',
      debugShowCheckedModeBanner: false, // Enlève le bandeau rouge "DEBUG"
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // On met le fond gris clair par défaut pour toute l'app
        scaffoldBackgroundColor: const Color(0xFFF4F7FA),
      ),
      // On affiche ton Dashboard en lui passant l'ID 1 pour tester
      home: const DashboardScreen(residenceId: 1),
    );
  }
}