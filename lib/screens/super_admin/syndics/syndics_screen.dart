// lib/screens/super_admin/syndics/syndics_screen.dart

import 'package:flutter/material.dart';
import '../../../../services/super_admin_service.dart';
import '../../../../models/user_model.dart';
import '../residences/residences_screen.dart';
import '../super_admin_dashboard_screen.dart';

class SyndicsScreen extends StatefulWidget {
  const SyndicsScreen({super.key});

  @override
  State<SyndicsScreen> createState() => _SyndicsScreenState();
}

class _SyndicsScreenState extends State<SyndicsScreen> {
  final SuperAdminService _service = SuperAdminService();

  // ════════════════════════════════════════════════════════
  // AUCUNE FONCTION METIER MODIFIEE
  // toggleSyndicStatus + getSyndicsGeneraux = identiques
  // ════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Syndics Generaux',
          style: TextStyle(
              color: Color(0xFF222222),
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF222222)),
      ),

      drawer: _buildDrawer(context),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Liste des Syndics Generaux',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<UserModel>>(
                future: _service.getSyndicsGeneraux(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Aucun syndic enregistre.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) =>
                        _synCard(snapshot.data![index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card syndic (logique toggleSyndicStatus inchangee) ─
  Widget _synCard(UserModel user) {
    final bool isActif = user.statut.name == 'actif';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Ligne 1 : avatar + nom + badge statut
          Row(children: [
            CircleAvatar(
              backgroundColor: Colors.orange.shade50,
              child: const Icon(Icons.person, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nomComplet,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Badge statut
            Chip(
              label: Text(
                isActif ? 'Actif' : 'Inactif',
                style: const TextStyle(fontSize: 11),
              ),
              backgroundColor: isActif
                  ? Colors.green.shade50
                  : Colors.grey.shade100,
              padding: EdgeInsets.zero,
            ),
          ]),

          const SizedBox(height: 12),

          // Ligne 2 : bouton action (logique inchangee)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // LOGIQUE INCHANGEE
                await _service.toggleSyndicStatus(
                    user.id, user.statut.name);
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                isActif ? Colors.red.shade50 : Colors.green.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isActif ? 'Desactiver' : 'Activer',
                style: TextStyle(
                  color: isActif ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Drawer ────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: const Color(0xFF222222),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.admin_panel_settings,
                    color: Colors.white, size: 40),
                SizedBox(height: 12),
                Text('Super Admin',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                Text('Administration generale',
                    style:
                    TextStyle(color: Colors.white60, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => SuperAdminDashboardScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Residences'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => ResidencesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_outline,
                color: Color(0xFFFF6B4A)),
            title: const Text('Syndics Generaux',
                style: TextStyle(
                    color: Color(0xFFFF6B4A),
                    fontWeight: FontWeight.bold)),
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Deconnexion',
                style: TextStyle(color: Colors.red)),
            onTap: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}