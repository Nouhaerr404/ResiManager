import 'package:flutter/material.dart';
import '../../../../services/super_admin_service.dart';
import '../../../../models/user_model.dart';
import '../residences/residences_screen.dart';
import '../super_admin_dashboard_screen.dart';
import '../demandes/demandes_screen.dart';

class SyndicsScreen extends StatefulWidget {
  const SyndicsScreen({super.key});
  @override
  State<SyndicsScreen> createState() => _SyndicsScreenState();
}

class _SyndicsScreenState extends State<SyndicsScreen> {
  final SuperAdminService _service = SuperAdminService();
  int _refreshKey = 0;
  String _searchQuery = '';
  String _filter = 'tous';

  static const _coral = Color(0xFFFF6B4A);
  static const _dark  = Color(0xFF222222);
  static const _bg    = Color(0xFFF4F6F9);

  void _refresh() => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Syndics Généraux',
            style: TextStyle(color: _dark, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: _dark),
      ),
      drawer: _buildDrawer(context),
      body: FutureBuilder<List<UserModel>>(
        key: ValueKey('syndics_$_refreshKey'),
        future: _service.getSyndicsGeneraux(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: _coral));
          }

          final all = snapshot.data!;
          final actifs   = all.where((u) => u.statut.name == 'actif').length;
          final inactifs = all.where((u) => u.statut.name == 'inactif').length;

          final filtered = all.where((u) {
            final matchSearch = _searchQuery.isEmpty ||
                u.nomComplet.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                u.email.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchFilter = _filter == 'tous' ||
                (_filter == 'actif' && u.statut.name == 'actif') ||
                (_filter == 'inactif' && u.statut.name == 'inactif');
            return matchSearch && matchFilter;
          }).toList();

          return Column(children: [
            // ── HEADER STATS ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(children: [
                _statMini('${all.length}', 'Total', Colors.grey),
                const SizedBox(width: 8),
                _statMini('$actifs', 'Actifs', Colors.green),
                const SizedBox(width: 8),
                _statMini('$inactifs', 'Inactifs',
                    inactifs > 0 ? Colors.red : Colors.grey),
              ]),
            ),

            // ── SEARCH ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Rechercher un syndic...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // ── FILTRES ──
            Container(
              color: Colors.white,
              height: 46,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(children: [
                _filterChip('tous', 'Tous'),
                const SizedBox(width: 8),
                _filterChip('actif', 'Actifs'),
                const SizedBox(width: 8),
                _filterChip('inactif', 'Inactifs'),
              ]),
            ),

            const SizedBox(height: 4),

            // ── LISTE ──
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Aucun syndic trouvé',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 15)),
                ],
              ))
                  : RefreshIndicator(
                color: _coral,
                onRefresh: () async => _refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _syndicCard(filtered[i]),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _statMini(String count, String label, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(count, style: TextStyle(
            color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 10, fontWeight: FontWeight.w500)),
      ]),
    ));
  }

  Widget _filterChip(String value, String label) {
    final sel = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? _coral : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(
            color: sel ? Colors.white : Colors.grey.shade700,
            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            fontSize: 12)),
      ),
    );
  }

  Widget _syndicCard(UserModel user) {
    final bool isActif = user.statut.name == 'actif';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        // ── BANDE TOP ──
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: isActif ? Colors.green : Colors.grey.shade300,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              // ── AVATAR ──
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: isActif
                      ? _coral.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    user.nomComplet.isNotEmpty
                        ? user.nomComplet[0].toUpperCase() : '?',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isActif ? _coral : Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.nomComplet,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15, color: _dark),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.email_outlined,
                        size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Expanded(child: Text(user.email,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                        overflow: TextOverflow.ellipsis)),
                  ]),
                ],
              )),
              // ── BADGE STATUT ──
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActif
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    isActif
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 12,
                    color: isActif ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(isActif ? 'Actif' : 'Inactif',
                      style: TextStyle(
                          color: isActif ? Colors.green : Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            ]),
            const SizedBox(height: 14),

            // ── BOUTON ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _service.toggleSyndicStatus(
                      user.id, user.statut.name);
                  _refresh();
                },
                icon: Icon(
                  isActif
                      ? Icons.block_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 16,
                ),
                label: Text(
                  isActif ? 'Désactiver ce compte' : 'Activer ce compte',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActif
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  foregroundColor: isActif ? Colors.red : Colors.green,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

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
          leading: const Icon(Icons.dashboard_outlined),
          title: const Text('Dashboard'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => SuperAdminDashboardScreen()));
          },
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
          leading: const Icon(Icons.people_outline, color: _coral),
          title: const Text('Syndics Généraux',
              style: TextStyle(color: _coral, fontWeight: FontWeight.bold)),
          onTap: () => Navigator.pop(context),
        ),
        ListTile(
          leading: const Icon(Icons.person_add_outlined, color: _coral),
          title: const Text('Demandes',
              style: TextStyle(color: _coral, fontWeight: FontWeight.bold)),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const DemandesScreen()));
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