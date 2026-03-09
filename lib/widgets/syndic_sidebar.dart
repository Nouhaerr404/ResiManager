import 'package:flutter/material.dart';
import '../screens/syndic_general/tranches_management_screen.dart';
class SyndicSidebar extends StatelessWidget {
  const SyndicSidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du menu (Logo + Nom)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ResiManager', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Admin Général', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),
          const Divider(),
          // Les liens
          ListTile(
            leading: const Icon(Icons.dashboard_outlined, color: Colors.black87),
            title: const Text('Tableau de bord', style: TextStyle(fontWeight: FontWeight.bold)),
            selectedTileColor: Colors.grey.shade100,
            selected: true, // A rendre dynamique plus tard
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Syndics'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.domain),
            title: const Text('Tranches'),
            onTap: () {
              // On utilise Navigator.pushReplacement pour ne pas empiler les pages inutilement
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const TranchesManagementScreen(residenceId: 1)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.apartment),
            title: const Text('Immeubles'),
            onTap: () {},
          ),
          const Spacer(), // Pousse le profil vers le bas
          const Divider(),
          // Section Profil en bas
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.black, child: Text('AD', style: TextStyle(color: Colors.white))),
            title: const Text('Administrateur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('admin@residence.ma', style: TextStyle(fontSize: 12)),
            onTap: () {},
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}