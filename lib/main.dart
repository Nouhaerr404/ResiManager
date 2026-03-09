import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/syndic_general/residence_selection_screen.dart';

// LA FONCTION MANQUANTE : C'est le point d'entrée de l'app
void main() async {
  // Obligatoire pour initialiser les plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Supabase avec ta classe de config
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
      debugShowCheckedModeBanner: false,

      // CONFIGURATION DE TA NOUVELLE PALETTE DE COULEURS
      theme: ThemeData(
        primaryColor: const Color(0xFFFF6F4A), // Orange Corail
        scaffoldBackgroundColor: const Color(0xFFFCF9F6), // Fond Beige clair

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFCF9F6),
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold
          ),
        ),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6F4A),
          primary: const Color(0xFFFF6F4A),
        ),
      ),

      // L'application démarre sur la sélection de résidence (ID 1 pour test)
      home: const ResidenceSelectionScreen(syndicGeneralId: 1),
    );
  }
}