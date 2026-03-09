import 'package:flutter/material.dart';
import '../screens/syndic_general/dashboard_screen.dart';
import '../screens/syndic_general/tranches_management_screen.dart';

class SyndicSidebar extends StatelessWidget {
  const SyndicSidebar({Key? key}) : super(key: key);

  // Les couleurs de ta nouvelle maquette
  final Color primaryOrange = const Color(0xFFFF6F4A);
  final Color darkGrey = const Color(0xFF2C2C2C);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du menu (Logo Orange)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ResiManager', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text('Admin Général', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Les liens du menu
          _buildMenuItem(context, Icons.dashboard_outlined, 'Tableau de bord', true, () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen(residenceId: 1)));
          }),
          _buildMenuItem(context, Icons.people_outline, 'Syndics', false, () {}),
          _buildMenuItem(context, Icons.domain, 'Tranches', false, () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TranchesManagementScreen(residenceId: 1)));
          }),
          _buildMenuItem(context, Icons.apartment, 'Immeubles', false, () {}),
          _buildMenuItem(context, Icons.local_parking, 'Parkings', false, () {}),

          const Spacer(),

          // Bouton Noir "Espace Syndic"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.business_center, color: Colors.white, size: 20),
              label: const Text('Espace Syndic', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGrey,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),

          const Divider(height: 1),
          // Section Profil
          ListTile(
            leading: CircleAvatar(backgroundColor: darkGrey, child: const Text('AD', style: TextStyle(color: Colors.white))),
            title: const Text('Administrateur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('admin@residence.ma', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // Petit widget pour générer les lignes du menu proprement
  Widget _buildMenuItem(BuildContext context, IconData icon, String title, bool isSelected, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? primaryOrange : Colors.grey.shade700),
      title: Text(title, style: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? primaryOrange : Colors.black87,
      )),
      selected: isSelected,
      onTap: onTap,
    );
  }
}