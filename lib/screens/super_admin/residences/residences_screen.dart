import 'package:flutter/material.dart';
import '../../../../services/super_admin_service.dart';
import '../../../../models/residence_model.dart';
import '../syndics/syndics_screen.dart';
import '../super_admin_dashboard_screen.dart';
import '../demandes/demandes_screen.dart';

class ResidencesScreen extends StatefulWidget {
  const ResidencesScreen({super.key});
  @override
  State<ResidencesScreen> createState() => _ResidencesScreenState();
}

class _ResidencesScreenState extends State<ResidencesScreen> {
  final SuperAdminService _service = SuperAdminService();
  String _searchQuery = '';

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
        title: const Text('Résidences',
            style: TextStyle(color: _dark, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: _dark),
      ),
      drawer: _buildDrawer(context),
      body: Column(children: [
        // ── HEADER ──
        _buildHeader(),
        // ── SEARCH ──
        _buildSearch(),
        // ── LISTE ──
        Expanded(
          child: FutureBuilder<List<ResidenceModel>>(
            future: _service.getAllResidences(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: _coral));
              }
              final all = snapshot.data!;
              final filtered = all.where((r) =>
              r.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  r.adresse.toLowerCase().contains(_searchQuery.toLowerCase()))
                  .toList();

              if (filtered.isEmpty) {
                return Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business_outlined,
                        size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('Aucune résidence trouvée',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 15)),
                  ],
                ));
              }

              return RefreshIndicator(
                color: _coral,
                onRefresh: () async => setState(() {}),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildCard(filtered[i]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  // ── HEADER ──
  Widget _buildHeader() {
    return FutureBuilder<List<ResidenceModel>>(
      future: _service.getAllResidences(),
      builder: (context, snapshot) {
        final total = snapshot.data?.length ?? 0;
        final avecSyndic = snapshot.data
            ?.where((r) => r.syndicNom != null).length ?? 0;
        final sansSyndic = total - avecSyndic;

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(children: [
            _statMini('$total', 'Total', Colors.grey),
            const SizedBox(width: 8),
            _statMini('$avecSyndic', 'Avec syndic', Colors.green),
            const SizedBox(width: 8),
            _statMini('$sansSyndic', 'Sans syndic',
                sansSyndic > 0 ? _coral : Colors.grey),
          ]),
        );
      },
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

  // ── SEARCH ──
  Widget _buildSearch() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Rechercher une résidence...',
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
    );
  }

  // ── CARD ──
  Widget _buildCard(ResidenceModel res) {
    final hasSyndic = res.syndicNom != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            color: hasSyndic ? _coral : Colors.grey.shade300,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── NOM + BADGE ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _coral.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.business_rounded,
                        color: _coral, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(res.nom,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15, color: _dark),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.location_on_outlined,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Expanded(child: Text(res.adresse,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                      ]),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Active',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── STATS ──
              Row(children: [
                _statBox(Icons.grid_view_rounded,
                    '${res.nombreTranches}', 'Tranches'),
                const SizedBox(width: 8),
                _statBox(Icons.business_outlined,
                    '${res.totalImmeubles}', 'Immeubles'),
                const SizedBox(width: 8),
                _statBox(Icons.home_outlined,
                    '${res.totalAppartements}', 'Appts'),
              ]),
              const SizedBox(height: 14),

              // ── SYNDIC ──
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: hasSyndic
                      ? _coral.withOpacity(0.06)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: hasSyndic
                          ? _coral.withOpacity(0.2)
                          : Colors.grey.shade200),
                ),
                child: Row(children: [
                  Icon(
                    hasSyndic
                        ? Icons.person_rounded
                        : Icons.person_off_outlined,
                    color: hasSyndic ? _coral : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasSyndic
                        ? 'Syndic : ${res.syndicNom}'
                        : 'Aucun syndic assigné',
                    style: TextStyle(
                        color: hasSyndic ? _coral : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _statBox(IconData icon, String value, String label) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 15, color: _dark)),
        Text(label, style: TextStyle(
            color: Colors.grey.shade500, fontSize: 10)),
      ]),
    ));
  }

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
          leading: const Icon(Icons.dashboard_outlined),
          title: const Text('Dashboard'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => SuperAdminDashboardScreen()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.business, color: _coral),
          title: const Text('Résidences',
              style: TextStyle(color: _coral, fontWeight: FontWeight.bold)),
          onTap: () => Navigator.pop(context),
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
          title: const Text('Déconnexion',
              style: TextStyle(color: Colors.red)),
          onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
        const SizedBox(height: 16),
      ])),
    );
  }
}