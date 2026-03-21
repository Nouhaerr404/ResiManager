// lib/screens/super_admin/super_admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import '../../../services/super_admin_service.dart';
import '../../../models/residence_model.dart';
import 'residences/residences_screen.dart';
import 'syndics/syndics_screen.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  final SuperAdminService _service = SuperAdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Super Admin',
          style: TextStyle(
              color: Color(0xFF222222),
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF222222)),
        actions: [
          // Badge demandes en attente dans la barre
          FutureBuilder<int>(
            future: _service.getNbDemandesEnAttente(),
            builder: (context, snap) {
              final nb = snap.data ?? 0;
              if (nb == 0) return const SizedBox();
              return GestureDetector(
                onTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const SyndicsScreen())),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B4A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.person_add_outlined,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text('$nb',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard Super Admin',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222)),
            ),
            const SizedBox(height: 4),
            const Text(
              "Vue d'ensemble de toutes les résidences",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),

            FutureBuilder<Map<String, dynamic>>(
              future: _service.getGlobalStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final stats = snapshot.data!;
                final int sansSyndic = stats['residences_sans_syndic'];
                final int nbDemandes = stats['demandes_en_attente'] ?? 0;

                return Column(children: [
                  Row(children: [
                    _buildStatCard('Résidences',
                        '${stats['residences_totales']}', 'Total',
                        Icons.business, Colors.black87),
                    const SizedBox(width: 12),
                    _buildStatCard('Syndics',
                        '${stats['syndics_totaux']}',
                        '${stats['syndics_actifs']} actifs',
                        Icons.people_outline, const Color(0xFFFF6B4A)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    _buildStatCard('Immeubles',
                        '${stats['immeubles_totaux']}',
                        '${stats['residences_totales']} résidences',
                        Icons.home_work_outlined, Colors.black87),
                    const SizedBox(width: 12),
                    _buildStatCard('Appartements',
                        '${stats['appartements_totaux']}', 'Total système',
                        Icons.check_circle_outline, const Color(0xFFFF6B4A)),
                  ]),

                  if (sansSyndic > 0) ...[
                    const SizedBox(height: 16),
                    _buildAlertBox(sansSyndic),
                  ],

                  // Alerte demandes en attente
                  if (nbDemandes > 0) ...[
                    const SizedBox(height: 12),
                    _buildDemandesAlert(context, nbDemandes),
                  ],
                ]);
              },
            ),

            const SizedBox(height: 24),
            const Text('Accès Rapide',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(children: [
              _buildQuickAccessCard(context, 'Résidences',
                  Icons.business, ResidencesScreen()),
              const SizedBox(width: 12),
              _buildQuickAccessCard(context, 'Syndics',
                  Icons.people_outline, const SyndicsScreen()),
            ]),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Résidences Récentes',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(
                          builder: (_) => ResidencesScreen())),
                  child: const Text('Voir tout',
                      style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<ResidenceModel>>(
              future: _service.getAllResidences(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.isEmpty) {
                  return const Text('Aucune résidence enregistrée.');
                }
                final recent = snapshot.data!.take(3).toList();
                return Column(
                  children: recent
                      .map((res) => _buildRecentResidenceCard(res))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Alerte demandes en attente ─────────────────────────
  Widget _buildDemandesAlert(BuildContext context, int nb) {
    return GestureDetector(
      onTap: () => Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const SyndicsScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFD8A0)),
        ),
        child: Row(children: [
          const Icon(Icons.person_add_outlined,
              color: Color(0xFFFF9500), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Demandes d\'inscription',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF222222))),
                const SizedBox(height: 4),
                Text(
                  '$nb demande(s) en attente de validation',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              size: 14, color: Colors.grey),
        ]),
      ),
    );
  }

  // ── Drawer ─────────────────────────────────────────────
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
                Text('Administration générale',
                    style: TextStyle(color: Colors.white60, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _drawerItem(context,
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              onTap: () => Navigator.pop(context)),
          _drawerItem(context,
              icon: Icons.business,
              label: 'Résidences',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => ResidencesScreen()));
              }),
          // Syndics avec badge
          FutureBuilder<int>(
            future: _service.getNbDemandesEnAttente(),
            builder: (context, snap) {
              final nb = snap.data ?? 0;
              return ListTile(
                leading: const Icon(Icons.people_outline),
                title: Row(children: [
                  const Text('Syndics Généraux'),
                  if (nb > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B4A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$nb',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ]),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(
                          builder: (_) => const SyndicsScreen()));
                },
              );
            },
          ),
          const Spacer(),
          _drawerItem(context,
              icon: Icons.logout,
              label: 'Déconnexion',
              onTap: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
              color: Colors.red),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _drawerItem(BuildContext context,
      {required IconData icon,
        required String label,
        required VoidCallback onTap,
        Color color = const Color(0xFF222222)}) =>
      ListTile(
        leading: Icon(icon, color: color),
        title: Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        onTap: onTap,
      );

  // ── Widgets stats ──────────────────────────────────────
  Widget _buildStatCard(String title, String count, String subtitle,
      IconData icon, Color borderColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 24, color: Colors.black87),
              Text(count,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _buildAlertBox(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD8D0)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Color(0xFFFF6B4A)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Résidences sans syndic',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF222222))),
            const SizedBox(height: 4),
            Text('$count résidence(s) sans syndic général',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildQuickAccessCard(
      BuildContext context, String title, IconData icon, Widget target) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => target)),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 28, color: Colors.black87),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
        ),
      ),
    );
  }

  Widget _buildRecentResidenceCard(ResidenceModel res) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(res.nom,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Active',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(res.adresse,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
            Text(res.syndicNom ?? 'Aucun syndic',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        Row(children: [
          _infoChip('${res.nombreTranches} tranches'),
          const SizedBox(width: 8),
          _infoChip('${res.totalImmeubles} immeubles'),
          const SizedBox(width: 8),
          _infoChip('${res.totalAppartements} appts'),
        ]),
      ]),
    );
  }

  Widget _infoChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label,
        style: const TextStyle(color: Colors.grey, fontSize: 12)),
  );
}