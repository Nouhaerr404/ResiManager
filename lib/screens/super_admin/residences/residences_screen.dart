// lib/screens/super_admin/residences/residences_screen.dart

import 'package:flutter/material.dart';
import '../../../../services/super_admin_service.dart';
import '../../../../models/residence_model.dart';
import '../syndics/syndics_screen.dart';
import '../super_admin_dashboard_screen.dart';

class ResidencesScreen extends StatefulWidget {
  const ResidencesScreen({super.key});

  @override
  State<ResidencesScreen> createState() => _ResidencesScreenState();
}

class _ResidencesScreenState extends State<ResidencesScreen> {
  final SuperAdminService _service = SuperAdminService();

  // ════════════════════════════════════════════════════════
  // AUCUNE FONCTION METIER MODIFIEE
  // ════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Residences',
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
              'Liste des Residences',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<ResidenceModel>>(
                future: _service.getAllResidences(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Aucune residence enregistree.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) =>
                        _buildCard(snapshot.data![index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card residence (meme logique, layout mobile) ──────
  Widget _buildCard(ResidenceModel res) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  res.nom,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Chip(
                label: Text('Active',
                    style: TextStyle(fontSize: 12)),
                backgroundColor: Color(0xFFE8F5E9),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(res.adresse,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          Row(children: [
            _box('${res.nombreTranches}', 'Tranches'),
            const SizedBox(width: 8),
            _box('${res.totalImmeubles}', 'Immeubles'),
            const SizedBox(width: 8),
            _box('${res.totalAppartements}', 'Appts'),
          ]),
          const Divider(height: 24),
          Text(
            'Syndic : ${res.syndicNom ?? "Aucun"}',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _box(String v, String l) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        Text(v,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15)),
        Text(l,
            style: const TextStyle(
                color: Colors.grey, fontSize: 11)),
      ]),
    ),
  );

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
            leading: const Icon(Icons.business,
                color: Color(0xFFFF6B4A)),
            title: const Text('Residences',
                style: TextStyle(
                    color: Color(0xFFFF6B4A),
                    fontWeight: FontWeight.bold)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Syndics Generaux'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => SyndicsScreen()),
              );
            },
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