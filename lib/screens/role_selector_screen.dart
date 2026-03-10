import 'package:flutter/material.dart';
import 'super_admin/super_admin_dashboard_screen.dart';
import 'resident/resident_dashboard_screen.dart';

class RoleSelectorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Bienvenue sur ResiManager",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Choisissez un espace pour la démo :",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 50),

            // BOUTON SUPER ADMIN
            _roleButton(
                context,
                "Espace Super Admin",
                Icons.admin_panel_settings,
                Colors.blue.shade700,
                SuperAdminDashboardScreen()
            ),

            const SizedBox(height: 20),

            // BOUTON RÉSIDENT
            _roleButton(
                context,
                "Espace Résident (Ahmed)",
                Icons.home,
                const Color(0xFFFF6B4A),
                ResidentDashboardScreen()
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleButton(BuildContext context, String title, IconData icon, Color color, Widget nextScreen) {
    return SizedBox(
      width: 300,
      height: 70,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => nextScreen)),
        icon: Icon(icon, color: Colors.white),
        label: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}