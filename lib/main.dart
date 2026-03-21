import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/role_selector_screen.dart';
import 'screens/inter_syndic/tranches_list_screen.dart';
import 'screens/inter_syndic/apartments/apartments_screen.dart';
import 'screens/syndic_general/residence_selection_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/resident/resident_dashboard_screen.dart';
import 'screens/inter_syndic/intersyndic_selection_screen.dart';
import 'screens/syndic_general/dashboard_screen.dart';
import 'screens/super_admin/super_admin_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  runApp(const ResiManagerApp());
}

class ResiManagerApp extends StatelessWidget {
  const ResiManagerApp({super.key});

  static const Color coral = Color(0xFFFF6F4A);
  static const Color beigeBackground = Color(0xFFFCF9F6);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      primaryColor: coral,
      scaffoldBackgroundColor: beigeBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: beigeBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: coral,
        primary: coral,
      ),
    );

    return MaterialApp(
      title: 'ResiManager',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const RoleSelectorScreen(),
      routes: {
        '/home':           (context) => const HomePage(),
        '/apartments':     (context) => const ApartmentsListScreen(),
        '/tranches':       (context) => const TranchesListScreen(),
        '/inter_syndic':   (context) => const InterSyndicSelectionScreen(),
        '/syndic_general': (context) => DashboardScreen(residenceId: 1),
        '/super_admin':    (context) => SuperAdminDashboardScreen(),
      },
      // Route /resident séparée pour passer userId dynamiquement
      onGenerateRoute: (settings) {
        if (settings.name == '/resident') {
          final userId = settings.arguments as int? ?? 3;
          return MaterialPageRoute(
            builder: (_) => ResidentDashboardScreen(userId: userId),
          );
        }
        return null;
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _openResidenceSelection(BuildContext context, {int syndicGeneralId = 1}) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => ResidenceSelectionScreen(syndicGeneralId: syndicGeneralId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ResiManager'), centerTitle: true),
      drawer: const _AppDrawer(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_done, size: 80),
              const SizedBox(height: 20),
              const Text('Supabase connecté avec succès 🎉',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/apartments'),
                icon: const Icon(Icons.apartment),
                label: const Text('Gérer les appartements'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/tranches'),
                icon: const Icon(Icons.layers),
                label: const Text('Gérer les tranches'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _openResidenceSelection(context, syndicGeneralId: 1),
                icon: const Icon(Icons.location_city),
                label: const Text('Sélection de résidence (test id=1)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              ),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Text('ResiManager',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Accueil'),
              onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
            ),
            ListTile(
              leading: const Icon(Icons.apartment),
              title: const Text('Appartements'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/apartments');
              },
            ),
            ListTile(
              leading: const Icon(Icons.layers),
              title: const Text('Tranches'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/tranches');
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_city),
              title: const Text('Sélection résidence'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ResidenceSelectionScreen(syndicGeneralId: 1),
                ));
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('Version debug',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}