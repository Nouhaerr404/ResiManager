// lib/screens/super_admin/super_admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import '../../../services/super_admin_service.dart';
import '../../../models/residence_model.dart';
import 'residences/residences_screen.dart';
import 'syndics/syndics_screen.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  final SuperAdminService _service = SuperAdminService();

  // ════════════════════════════════════════════════════════
  // AUCUNE FONCTION METIER MODIFIEE
  // Seul le layout change : Scaffold mobile + AppBar + Drawer
  // ════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),

      // ── AppBar mobile ──────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Super Admin',
          style: TextStyle(
            color: Color(0xFF222222),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF222222)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ── Drawer (remplace AppSidebar) ───────────────────
      drawer: _buildDrawer(context),

      // ── Corps principal ────────────────────────────────
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Titre
            const Text(
              'Dashboard Super Admin',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Vue d'ensemble de toutes les residences",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // ── Cartes statistiques (logique inchangee) ──
            FutureBuilder<Map<String, dynamic>>(
              future: _service.getGlobalStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final stats = snapshot.data!;
                final int sansSyndic = stats['residences_sans_syndic'];

                return Column(children: [

                  // 2 cartes par ligne sur mobile
                  Row(children: [
                    _buildStatCard(
                      'Residences',
                      '${stats['residences_totales']}',
                      'Total',
                      Icons.business,
                      Colors.black87,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      'Syndics',
                      '${stats['syndics_totaux']}',
                      '${stats['syndics_actifs']} actifs',
                      Icons.people_outline,
                      const Color(0xFFFF6B4A),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    _buildStatCard(
                      'Immeubles',
                      '${stats['immeubles_totaux']}',
                      '${stats['residences_totales']} residences',
                      Icons.home_work_outlined,
                      Colors.black87,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      'Appartements',
                      '${stats['appartements_totaux']}',
                      'Total systeme',
                      Icons.check_circle_outline,
                      const Color(0xFFFF6B4A),
                    ),
                  ]),

                  // Alerte (logique inchangee)
                  if (sansSyndic > 0) ...[
                    const SizedBox(height: 16),
                    _buildAlertBox(sansSyndic),
                  ],
                ]);
              },
            ),

            const SizedBox(height: 24),

            // ── Acces rapide ─────────────────────────────
            const Text(
              'Acces Rapide',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _buildQuickAccessCard(
                context,
                'Residences',
                Icons.business,
                ResidencesScreen(),
              ),
              const SizedBox(width: 12),
              _buildQuickAccessCard(
                context,
                'Syndics',
                Icons.people_outline,
                SyndicsScreen(),
              ),
            ]),

            const SizedBox(height: 24),

            // ── Residences recentes (logique inchangee) ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Residences Recentes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => ResidencesScreen()),
                  ),
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                  return const Text('Aucune residence enregistree.');
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

  // ── Drawer navigation ──────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(children: [

          // Header drawer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: const Color(0xFF222222),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.admin_panel_settings,
                  color: Colors.white, size: 40),
              const SizedBox(height: 12),
              const Text('Super Admin',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              const Text('Administration generale',
                  style: TextStyle(color: Colors.white60, fontSize: 13)),
            ]),
          ),

          const SizedBox(height: 8),

          // Items navigation
          _drawerItem(
            context,
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _drawerItem(
            context,
            icon: Icons.business,
            label: 'Residences',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => ResidencesScreen()),
              );
            },
          ),
          _drawerItem(
            context,
            icon: Icons.people_outline,
            label: 'Syndics Generaux',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => SyndicsScreen()),
              );
            },
          ),

          const Spacer(),

          // Deconnexion
          _drawerItem(
            context,
            icon: Icons.logout,
            label: 'Deconnexion',
            onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
            color: Colors.red,
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _drawerItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
        Color color = const Color(0xFF222222),
      }) =>
      ListTile(
        leading: Icon(icon, color: color),
        title: Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        onTap: onTap,
      );

  // ══════════════════════════════════════════════════════
  // WIDGETS — IDENTIQUES A L'ORIGINAL, JUSTE ADAPTES MOBILE
  // ══════════════════════════════════════════════════════

  Widget _buildStatCard(
      String title,
      String count,
      String subtitle,
      IconData icon,
      Color borderColor,
      ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                style:
                const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
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
            const Text('Residences sans syndic',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF222222))),
            const SizedBox(height: 4),
            Text(
              "$count residence(s) sans syndic general",
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildQuickAccessCard(
      BuildContext context,
      String title,
      IconData icon,
      Widget targetScreen,
      ) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => targetScreen),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: Colors.black87),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
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
              child: Text(
                res.nom,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              child: Text(
                res.adresse,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              res.syndicNom ?? 'Aucun syndic',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
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
    padding:
    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label,
        style: const TextStyle(color: Colors.grey, fontSize: 12)),
  );
}