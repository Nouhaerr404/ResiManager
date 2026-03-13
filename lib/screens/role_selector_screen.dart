import 'package:flutter/material.dart';
import 'super_admin/super_admin_dashboard_screen.dart';
import 'resident/resident_dashboard_screen.dart';
import 'syndic_general/dashboard_screen.dart';
import 'inter_syndic/tranche_dashboard_screen.dart';
import 'inter_syndic/apartments/apartments_screen.dart';
import 'inter_syndic/tranches_list_screen.dart';
import 'inter_syndic/inter_syndic_selection_screen.dart';
import '../models/tranche_model.dart';


class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F6),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.rocket_launch, size: 60, color: Color(0xFFFF6B4A)),
              const SizedBox(height: 20),
              const Text("ResiManager Demo Launchpad",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Accès rapide à tous les espaces et fonctionnalités",
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
              
              const SizedBox(height: 50),
              
              _sectionHeader("ESPACES UTILISATEURS"),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _roleButton(
                    context,
                    "Super Admin",
                    Icons.admin_panel_settings,
                    Colors.blue.shade700,
                    SuperAdminDashboardScreen(),
                  ),
                  _roleButton(
                    context,
                    "Syndic Général",
                    Icons.business_center,
                    Colors.indigo,
                    DashboardScreen(residenceId: 1),
                  ),
                  _roleButton(
                    context,
                    "Inter-Syndic",
                    Icons.dashboard_customize,
                    const Color(0xFF4CAF82), // Mint
                    const InterSyndicSelectionScreen(),
                  ),

                  _roleButton(
                    context,
                    "Résident (Ahmed)",
                    Icons.home,
                    const Color(0xFFFF6B4A), // Coral
                    ResidentDashboardScreen(),
                  ),
                ],
              ),

              const SizedBox(height: 50),
              
              _sectionHeader("GESTION & MODULES"),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _roleButton(
                    context,
                    "Appartements",
                    Icons.apartment,
                    Colors.grey.shade800,
                    ApartmentsListScreen(),
                  ),
                  _roleButton(
                    context,
                    "Tranches",
                    Icons.layers,
                    Colors.grey.shade800,
                    TranchesListScreen(),
                  ),
                ],
              ),
              
              const SizedBox(height: 100),
              const Text("Version 1.0.0 - Mode Debug", 
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(title, 
            style: const TextStyle(
              color: Colors.grey, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 1.2,
              fontSize: 12
            )),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _roleButton(BuildContext context, String title, IconData icon, Color color, Widget nextScreen) {
    return SizedBox(
      width: 250,
      height: 80,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => nextScreen)),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        label: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 4,
          shadowColor: color.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}