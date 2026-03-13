// lib/widgets/resident_mobile_drawer.dart

import 'package:flutter/material.dart';
import '../screens/resident/resident_dashboard_screen.dart';
import '../screens/resident/resident_charges_screen.dart';
import '../screens/resident/resident_annonces_screen.dart';
import '../screens/resident/resident_reunions_screen.dart';
import '../screens/resident/historique_paiements_screen.dart';

class ResidentMobileDrawer extends StatelessWidget {
  final int currentIndex;

  const ResidentMobileDrawer({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF2D2D2D),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.home_work, color: Color(0xFFFF6B4A), size: 40),
                SizedBox(height: 10),
                Text(
                  "ResiManager",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Espace Résident",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            index: 0,
            icon: Icons.home_outlined,
            label: "Accueil",
            destination: const ResidentDashboardScreen(),
          ),
          _buildDrawerItem(
            context,
            index: 1,
            icon: Icons.receipt_long_outlined,
            label: "Dépenses",
            destination: const ResidentChargesScreen(),
          ),
          _buildDrawerItem(
            context,
            index: 2,
            icon: Icons.payment_outlined,
            label: "Paiements",
            destination: const HistoriquePaiementsScreen(),
          ),
          _buildDrawerItem(
            context,
            index: 3,
            icon: Icons.article_outlined,
            label: "Annonces",
            destination: ResidentAnnoncesScreen(),  // ← SANS const
          ),
          _buildDrawerItem(
            context,
            index: 4,
            icon: Icons.calendar_today_outlined,
            label: "Réunions",
            destination: const ResidentReunionsScreen(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Retour Admin"),
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, {
        required int index,
        required IconData icon,
        required String label,
        required Widget destination,
      }) {
    final isActive = currentIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? const Color(0xFFFF6B4A) : null,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? const Color(0xFFFF6B4A) : null,
        ),
      ),
      selected: isActive,
      onTap: () {
        Navigator.pop(context);
        if (!isActive) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        }
      },
    );
  }
}