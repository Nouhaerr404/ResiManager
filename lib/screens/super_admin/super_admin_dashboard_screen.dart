import 'package:flutter/material.dart';
import '../../../services/super_admin_service.dart';
import '../../../models/residence_model.dart';
import 'residences/residences_screen.dart';
import 'syndics/syndics_screen.dart';
import 'demandes/demandes_screen.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  final SuperAdminService _service = SuperAdminService();

  static const _coral = Color(0xFFFF6B4A);
  static const _dark  = Color(0xFF222222);
  static const _bg    = Color(0xFFF4F6F9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Super Admin',
            style: TextStyle(color: _dark, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: _dark),
        actions: [
          FutureBuilder<int>(
            future: _service.getNbDemandesEnAttente(),
            builder: (context, snap) {
              final nb = snap.data ?? 0;
              if (nb == 0) return const SizedBox();
              return GestureDetector(
                onTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const DemandesScreen())),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: _coral, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.person_add_outlined,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text('$nb', style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        color: _coral,
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── GREETING ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_dark, Color(0xFF3A3A4A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: _coral,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.admin_panel_settings_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Bonjour, Admin 👋',
                          style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Vue d\'ensemble du système',
                          style: TextStyle(color: Colors.white60, fontSize: 12)),
                    ]),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),

              // ── STATS ──
              FutureBuilder<Map<String, dynamic>>(
                future: _service.getGlobalStats(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: _coral),
                        ));
                  }
                  final stats = snapshot.data!;
                  final int sansSyndic = stats['residences_sans_syndic'] ?? 0;
                  final int nbDemandes = stats['demandes_en_attente'] ?? 0;

                  return Column(children: [
                    // ── LIGNE 1 ──
                    Row(children: [
                      _statCard(
                        icon: Icons.business_rounded,
                        iconBg: const Color(0xFFEEF1FF),
                        iconColor: const Color(0xFF4B6BFB),
                        count: '${stats['residences_totales']}',
                        title: 'Résidences',
                        subtitle: 'Total système',
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        icon: Icons.people_rounded,
                        iconBg: const Color(0xFFFFF0EB),
                        iconColor: _coral,
                        count: '${stats['syndics_totaux']}',
                        title: 'Syndics',
                        subtitle: '${stats['syndics_actifs']} actifs',
                      ),
                    ]),
                    const SizedBox(height: 12),
                    // ── LIGNE 2 ──
                    Row(children: [
                      _statCard(
                        icon: Icons.home_work_rounded,
                        iconBg: const Color(0xFFEBFAF4),
                        iconColor: const Color(0xFF34C98B),
                        count: '${stats['immeubles_totaux']}',
                        title: 'Immeubles',
                        subtitle: 'Total système',
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        icon: Icons.home_rounded,
                        iconBg: const Color(0xFFFFF8EC),
                        iconColor: const Color(0xFFF5A623),
                        count: '${stats['appartements_totaux']}',
                        title: 'Appartements',
                        subtitle: 'Total système',
                      ),
                    ]),

                    // ── ALERTES ──
                    if (sansSyndic > 0) ...[
                      const SizedBox(height: 14),
                      _alertBox(
                        icon: Icons.warning_amber_rounded,
                        color: _coral,
                        bg: const Color(0xFFFFF0EB),
                        border: const Color(0xFFFFD8C8),
                        title: 'Résidences sans syndic',
                        message: '$sansSyndic résidence(s) sans syndic général',
                      ),
                    ],
                    if (nbDemandes > 0) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(context,
                            MaterialPageRoute(
                                builder: (_) => const DemandesScreen())),
                        child: _alertBox(
                          icon: Icons.person_add_rounded,
                          color: const Color(0xFFFF9500),
                          bg: const Color(0xFFFFF8EC),
                          border: const Color(0xFFFFD8A0),
                          title: 'Demandes en attente',
                          message: '$nbDemandes demande(s) à valider',
                          showArrow: true,
                        ),
                      ),
                    ],
                  ]);
                },
              ),

              const SizedBox(height: 24),

              // ── ACCÈS RAPIDE ──
              const Text('Accès Rapide',
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.bold, color: _dark)),
              const SizedBox(height: 12),
              Row(children: [
                _quickCard(context, 'Résidences',
                    Icons.business_rounded,
                    const Color(0xFFEEF1FF),
                    const Color(0xFF4B6BFB),
                    ResidencesScreen()),
                const SizedBox(width: 12),
                _quickCard(context, 'Syndics',
                    Icons.people_rounded,
                    const Color(0xFFFFF0EB),
                    _coral,
                    const SyndicsScreen()),
                const SizedBox(width: 12),
                _quickCard(context, 'Demandes',
                    Icons.person_add_rounded,
                    const Color(0xFFFFF8EC),
                    const Color(0xFFFF9500),
                    const DemandesScreen()),
              ]),

              const SizedBox(height: 24),

              // ── RÉSIDENCES RÉCENTES ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Résidences Récentes',
                      style: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.bold, color: _dark)),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => ResidencesScreen())),
                    child: const Text('Voir tout',
                        style: TextStyle(color: _coral,
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<ResidenceModel>>(
                future: _service.getAllResidences(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: _coral));
                  }
                  if (snapshot.data!.isEmpty) {
                    return Center(child: Text('Aucune résidence.',
                        style: TextStyle(color: Colors.grey.shade400)));
                  }
                  return Column(
                    children: snapshot.data!.take(3)
                        .map((res) => _recentCard(res))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── STAT CARD ──
  Widget _statCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String count,
    required String title,
    required String subtitle,
  }) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 12),
        Text(count, style: const TextStyle(
            fontSize: 26, fontWeight: FontWeight.w900, color: _dark)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 13, color: _dark)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(
            color: Colors.grey.shade500, fontSize: 11)),
      ]),
    ));
  }

  // ── ALERT BOX ──
  Widget _alertBox({
    required IconData icon,
    required Color color,
    required Color bg,
    required Color border,
    required String title,
    required String message,
    bool showArrow = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: _dark)),
            const SizedBox(height: 2),
            Text(message, style: TextStyle(
                color: Colors.grey.shade600, fontSize: 12)),
          ],
        )),
        if (showArrow)
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: Colors.grey.shade400),
      ]),
    );
  }

  // ── QUICK ACCESS CARD ──
  Widget _quickCard(BuildContext context, String title, IconData icon,
      Color bg, Color color, Widget target) {
    return Expanded(child: GestureDetector(
      onTap: () => Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => target)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 12, color: _dark)),
        ]),
      ),
    ));
  }

  // ── RECENT CARD ──
  Widget _recentCard(ResidenceModel res) {
    final hasSyndic = res.syndicNom != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: const Color(0xFFEEF1FF),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.business_rounded,
              color: Color(0xFF4B6BFB), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(res.nom,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14, color: _dark),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(res.adresse,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              _chip('${res.nombreTranches} tr.'),
              const SizedBox(width: 6),
              _chip('${res.totalImmeubles} imm.'),
              const SizedBox(width: 6),
              _chip('${res.totalAppartements} apt.'),
            ]),
          ],
        )),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hasSyndic
                ? const Color(0xFFEBFAF4)
                : const Color(0xFFFFF0EB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            hasSyndic ? 'Syndic ✓' : 'Sans syndic',
            style: TextStyle(
                color: hasSyndic
                    ? const Color(0xFF34C98B)
                    : _coral,
                fontSize: 10,
                fontWeight: FontWeight.bold),
          ),
        ),
      ]),
    );
  }

  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
        color: _bg, borderRadius: BorderRadius.circular(6)),
    child: Text(label,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
  );

  // ── DRAWER ──
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          color: _dark,
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
            SizedBox(height: 12),
            Text('Super Admin', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Administration générale',
                style: TextStyle(color: Colors.white60, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.dashboard_outlined, color: _coral),
          title: const Text('Dashboard',
              style: TextStyle(color: _coral, fontWeight: FontWeight.bold)),
          onTap: () => Navigator.pop(context),
        ),
        ListTile(
          leading: const Icon(Icons.business),
          title: const Text('Résidences'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => ResidencesScreen()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.people_outline),
          title: const Text('Syndics Généraux'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const SyndicsScreen()));
          },
        ),
        FutureBuilder<int>(
          future: _service.getNbDemandesEnAttente(),
          builder: (context, snap) {
            final nb = snap.data ?? 0;
            return ListTile(
              leading: const Icon(Icons.person_add_outlined, color: _coral),
              title: Row(children: [
                const Text('Demandes',
                    style: TextStyle(color: _coral, fontWeight: FontWeight.bold)),
                if (nb > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: _coral, borderRadius: BorderRadius.circular(10)),
                    child: Text('$nb', style: const TextStyle(
                        color: Colors.white, fontSize: 11,
                        fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const DemandesScreen()));
              },
            );
          },
        ),
        const Spacer(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
        const SizedBox(height: 16),
      ])),
    );
  }
}