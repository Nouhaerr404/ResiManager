// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/inter_syndic/tranches_list_screen.dart';
import 'screens/inter_syndic/apartments/apartments.dart';
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
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ResiManager"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_done,
                size: 80,
              ),

              const SizedBox(height: 20),

              const Text(
                "Supabase connecté avec succès 🎉",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ApartmentsListScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.apartment),
                label: const Text("Gérer les appartements"),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TranchesListScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.layers),
                label: const Text("Gérer les tranches"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}