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

class _SyndicsScreenState extends State<SyndicsScreen>
    with SingleTickerProviderStateMixin {

  final SuperAdminService _service = SuperAdminService();
  late TabController _tabController;

  // Pour forcer le refresh après action
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Syndics Généraux',
          style: TextStyle(
              color: Color(0xFF222222),
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF222222)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: FutureBuilder<int>(
            future: _service.getNbDemandesEnAttente(),
            builder: (context, snap) {
              final nb = snap.data ?? 0;
              return TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFFF6B4A),
                labelColor: const Color(0xFFFF6B4A),
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  const Tab(text: 'Syndics actifs'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Demandes'),
                        if (nb > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B4A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$nb',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSyndicsTab(),
          _buildDemandesTab(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // ONGLET 1 — SYNDICS ACTIFS
  // ══════════════════════════════════════════════════════
  Widget _buildSyndicsTab() {
    return FutureBuilder<List<UserModel>>(
      key: ValueKey('syndics_$_refreshKey'),
      future: _service.getSyndicsGeneraux(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('Aucun syndic enregistré.',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) =>
              _syndicCard(snapshot.data![index]),
        );
      },
    );
  }

  Widget _syndicCard(UserModel user) {
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
                  Text(user.nomComplet,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis),
                  Text(user.email,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Chip(
              label: Text(isActif ? 'Actif' : 'Inactif',
                  style: const TextStyle(fontSize: 11)),
              backgroundColor: isActif
                  ? Colors.green.shade50
                  : Colors.grey.shade100,
              padding: EdgeInsets.zero,
            ),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await _service.toggleSyndicStatus(
                    user.id, user.statut.name);
                _refresh();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                isActif ? Colors.red.shade50 : Colors.green.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                isActif ? 'Désactiver' : 'Activer',
                style: TextStyle(
                    color: isActif ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // ONGLET 2 — DEMANDES D'INSCRIPTION
  // ══════════════════════════════════════════════════════
  Widget _buildDemandesTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('demandes_$_refreshKey'),
      future: _service.getDemandesInscription(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('Aucune demande.',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) =>
              _demandeCard(snapshot.data![index]),
        );
      },
    );
  }

  Widget _demandeCard(Map<String, dynamic> d) {
    final String statut = d['statut'] as String? ?? 'en_attente';
    final String dateStr = (d['created_at'] as String?)?.split('T').first ?? '—';

    Color statutColor;
    IconData statutIcon;
    String statutLabel;

    switch (statut) {
      case 'accepte':
        statutColor = Colors.green;
        statutIcon  = Icons.check_circle_rounded;
        statutLabel = 'Accepté';
        break;
      case 'refuse':
        statutColor = Colors.red;
        statutIcon  = Icons.cancel_rounded;
        statutLabel = 'Refusé';
        break;
      default:
        statutColor = const Color(0xFFFF9500);
        statutIcon  = Icons.hourglass_top_rounded;
        statutLabel = 'En attente';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Header carte
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: statutColor.withValues(alpha: 0.1),
                child: Icon(Icons.person_outline,
                    color: statutColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${d['prenom']} ${d['nom']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(d['email'] ?? '',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                    if (d['telephone'] != null &&
                        (d['telephone'] as String).isNotEmpty)
                      Text(d['telephone'],
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              // Badge statut
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statutColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(statutIcon, color: statutColor, size: 13),
                  const SizedBox(width: 4),
                  Text(statutLabel,
                      style: TextStyle(
                          color: statutColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            ]),
          ),

          // Date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: Colors.grey),
              const SizedBox(width: 6),
              Text('Demande du $dateStr',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12)),
            ]),
          ),

          // Motif refus si présent
          if (statut == 'refuse' && d['motif_refus'] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Motif : ${d['motif_refus']}',
                  style: TextStyle(
                      color: Colors.red.shade700, fontSize: 12),
                ),
              ),
            ),

          // Boutons action (seulement pour en_attente)
          if (statut == 'en_attente') ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(children: [
                // Refuser
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRefuserDialog(d['id'] as int),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Refuser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Accepter
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _accepter(d['id'] as int),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accepter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ]),
            ),
          ] else
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────

  Future<void> _accepter(int demandeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer l\'acceptation'),
        content: const Text(
            'Le compte syndic général sera créé et le candidat pourra se connecter.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accepter',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final error = await _service.accepterDemande(demandeId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error == null
          ? 'Compte créé avec succès !'
          : 'Erreur : $error'),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Motif du refus (optionnel) :'),
            const SizedBox(height: 10),
            TextField(
              controller: motifCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ex : Informations incomplètes...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Refuser',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final error = await _service.refuserDemande(
        demandeId, motif: motifCtrl.text.trim().isEmpty ? null : motifCtrl.text);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error == null ? 'Demande refusée.' : 'Erreur : $error'),
      backgroundColor: error == null ? Colors.orange : Colors.red,
      behavior: SnackBarBehavior.floating,
    ));

    _refresh();
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
              Navigator.pushReplacement(context,
                  MaterialPageRoute(
                      builder: (_) => SuperAdminDashboardScreen()));
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
            leading: const Icon(Icons.people_outline,
                color: Color(0xFFFF6B4A)),
            title: const Text('Syndics Généraux',
                style: TextStyle(
                    color: Color(0xFFFF6B4A),
                    fontWeight: FontWeight.bold)),
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title:
            const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            onTap: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}