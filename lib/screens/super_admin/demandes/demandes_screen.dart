import 'package:flutter/material.dart';
import '../../../../services/super_admin_service.dart';
import '../super_admin_dashboard_screen.dart';
import '../syndics/syndics_screen.dart';
import '../residences/residences_screen.dart';

class DemandesScreen extends StatefulWidget {
  const DemandesScreen({super.key});
  @override
  State<DemandesScreen> createState() => _DemandesScreenState();
}

class _DemandesScreenState extends State<DemandesScreen> {
  final SuperAdminService _service = SuperAdminService();
  String _filter = 'tous';
  int _refreshKey = 0;
  String _searchQuery = '';

  static const _coral = Color(0xFFFF6B4A);
  static const _dark  = Color(0xFF222222);

  void _refresh() => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Demandes d\'inscription',
            style: TextStyle(color: _dark, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: _dark),
      ),
      drawer: _buildDrawer(context),
      body: Column(children: [
        // ── HEADER STATS ──
        _buildHeader(),
        // ── SEARCH ──
        _buildSearch(),
        // ── FILTRES ──
        _buildFiltres(),
        // ── LISTE ──
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            key: ValueKey('demandes_$_refreshKey'),
            future: _service.getDemandesInscription(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: _coral));
              }

              final all = snapshot.data!;
              final filtered = all.where((d) {
                final matchFilter = _filter == 'tous' || d['statut'] == _filter;
                final matchSearch = _searchQuery.isEmpty ||
                    '${d['prenom']} ${d['nom']}'.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (d['email'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
                return matchFilter && matchSearch;
              }).toList();

              if (filtered.isEmpty) {
                return Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('Aucune demande trouvée',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                  ],
                ));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _buildDemandeCard(filtered[i]),
              );
            },
          ),
        ),
      ]),
    );
  }

  // ── HEADER STATS ──
  Widget _buildHeader() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('header_$_refreshKey'),
      future: _service.getDemandesInscription(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 80);
        final all = snapshot.data!;
        final attente  = all.where((d) => d['statut'] == 'en_attente').length;
        final acceptes = all.where((d) => d['statut'] == 'accepte').length;
        final refuses  = all.where((d) => d['statut'] == 'refuse').length;

        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(children: [
            _statChip('Total', '${all.length}', Colors.grey),
            const SizedBox(width: 8),
            _statChip('En attente', '$attente', const Color(0xFFFF9500)),
            const SizedBox(width: 8),
            _statChip('Acceptées', '$acceptes', Colors.green),
            const SizedBox(width: 8),
            _statChip('Refusées', '$refuses', Colors.red),
          ]),
        );
      },
    );
  }

  Widget _statChip(String label, String count, Color color) {
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
            color: color.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w500)),
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
          hintText: 'Rechercher par nom ou email...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          filled: true,
          fillColor: const Color(0xFFF4F6F9),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ── FILTRES ──
  Widget _buildFiltres() {
    final filters = [
      ('tous', 'Toutes'),
      ('en_attente', 'En attente'),
      ('accepte', 'Acceptées'),
      ('refuse', 'Refusées'),
    ];
    return Container(
      height: 50,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.map((f) {
          final sel = _filter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? _coral : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(f.$2, style: TextStyle(
                    color: sel ? Colors.white : Colors.grey.shade700,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── CARTE DEMANDE ──
  Widget _buildDemandeCard(Map<String, dynamic> d) {
    final String statut   = d['statut'] as String? ?? 'en_attente';
    final String dateStr  = (d['created_at'] as String?)?.split('T').first ?? '—';

    Color statutColor; IconData statutIcon; String statutLabel;
    switch (statut) {
      case 'accepte':
        statutColor = Colors.green; statutIcon = Icons.check_circle_rounded;
        statutLabel = 'Accepté'; break;
      case 'refuse':
        statutColor = Colors.red; statutIcon = Icons.cancel_rounded;
        statutLabel = 'Refusé'; break;
      default:
        statutColor = const Color(0xFFFF9500); statutIcon = Icons.hourglass_top_rounded;
        statutLabel = 'En attente';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        // ── INFO ──
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: statutColor.withOpacity(0.1),
              child: Icon(Icons.person_outline, color: statutColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${d['prenom']} ${d['nom']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(d['email'] ?? '',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                if ((d['telephone'] ?? '').toString().isNotEmpty)
                  Text(d['telephone'],
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text('Demande du $dateStr',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                ]),
              ],
            )),
            // ── BADGE STATUT ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statutColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(statutIcon, color: statutColor, size: 13),
                const SizedBox(width: 4),
                Text(statutLabel, style: TextStyle(
                    color: statutColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
        ),

        // ── MOTIF REFUS ──
        if (statut == 'refuse' && d['motif_refus'] != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text('Motif : ${d['motif_refus']}',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
            ),
          ),

        // ── BOUTONS ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(children: [

            // En attente → Accepter + Refuser
            if (statut == 'en_attente') Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _showRefuserDialog(d['id'] as int),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Refuser'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(
                onPressed: () => _accepter(d['id'] as int),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Accepter'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
              )),
            ]),

            // Refusé → Annuler le refus
            if (statut == 'refuse') SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _annulerRefus(d['id'] as int),
                icon: const Icon(Icons.undo_rounded, size: 16),
                label: const Text('Annuler le refus'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF9500),
                    side: const BorderSide(color: Color(0xFFFF9500)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
              ),
            ),

            // Accepté → rien (lecture seule)
          ]),
        ),
      ]),
    );
  }

  // ── ACTIONS ──
  Future<void> _accepter(int demandeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer l\'acceptation'),
        content: const Text('Le compte syndic général sera créé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accepter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final error = await _service.accepterDemande(demandeId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error == null ? 'Compte créé avec succès !' : 'Erreur : $error'),
      backgroundColor: error == null ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
    _refresh();
  }

  Future<void> _showRefuserDialog(int demandeId) async {
    final motifCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Refuser la demande'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Motif du refus (optionnel) :'),
          const SizedBox(height: 10),
          TextField(
            controller: motifCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ex : Informations incomplètes...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Refuser', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final error = await _service.refuserDemande(demandeId,
        motif: motifCtrl.text.trim().isEmpty ? null : motifCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error == null ? 'Demande refusée.' : 'Erreur : $error'),
      backgroundColor: error == null ? Colors.orange : Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
    _refresh();
  }

  Future<void> _annulerRefus(int demandeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Annuler le refus'),
        content: const Text('La demande sera remise en attente de validation.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFF9500)),
            child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    // ── Remettre en attente ──
    final error = await _service.annulerRefus(demandeId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error == null
          ? 'Demande remise en attente !' : 'Erreur : $error'),
      backgroundColor: error == null ? const Color(0xFFFF9500) : Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
    _refresh();
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
        // ── DEMANDES avec badge ──
        FutureBuilder<int>(
          future: _service.getNbDemandesEnAttente(),
          builder: (context, snap) {
            final nb = snap.data ?? 0;
            return ListTile(
              leading: const Icon(Icons.person_add_outlined,
                  color: _coral),
              title: Row(children: [
                const Text('Demandes',
                    style: TextStyle(
                        color: _coral, fontWeight: FontWeight.bold)),
                if (nb > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: _coral,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('$nb', style: const TextStyle(
                        color: Colors.white, fontSize: 11,
                        fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
              onTap: () => Navigator.pop(context),
            );
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