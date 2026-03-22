import 'package:flutter/material.dart';
import '../../services/resident_service.dart';
import 'resident_charges_screen.dart';
import 'resident_annonces_screen.dart';
import 'resident_reunions_screen.dart';
import 'historique_paiements_screen.dart';
import 'resident_reclamations_screen.dart';

class ResidentDashboardScreen extends StatefulWidget {
  final int userId;
  final Function(int)? onNavigate;
  const ResidentDashboardScreen({
    super.key,
    this.userId = 3,
    this.onNavigate,
  });

  @override
  _ResidentDashboardScreenState createState() =>
      _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen> {
  final ResidentService _service = ResidentService();
  late int currentUserId;
  List<Map<String, dynamic>> _recentReclamations = [];
  bool _loadingReclamations = false;

  static const _coral = Color(0xFFFF6B4A);
  static const _dark  = Color(0xFF222222);
  static const _bg    = Color(0xFFF4F6F9);

  @override
  void initState() {
    super.initState();
    currentUserId = widget.userId;
    _loadReclamations();
  }

  Future<void> _loadReclamations() async {
    setState(() => _loadingReclamations = true);
    final reclamations = await _service.getMesReclamations(currentUserId);
    setState(() {
      _recentReclamations = reclamations;
      _loadingReclamations = false;
    });
  }

  void _goTo(int index) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(index);
    } else {
      switch (index) {
        case 1: Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => ResidentChargesScreen(userId: currentUserId))); break;
        case 2: Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => HistoriquePaiementsScreen(userId: currentUserId))); break;
        case 3: Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => ResidentAnnoncesScreen(userId: currentUserId))); break;
        case 4: Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => const ResidentReunionsScreen())); break;
        case 5: Navigator.push(context, MaterialPageRoute(
            builder: (_) => ResidentReclamationsScreen(userId: currentUserId))); break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool inLayout = widget.onNavigate != null;

    final body = FutureBuilder<Map<String, dynamic>>(
      future: _service.getResidentDashboardData(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _coral));
        }
        if (snapshot.hasError)
          return Center(child: Text("Erreur: ${snapshot.error}"));

        final data     = snapshot.data!;
        final prenom   = data['prenom']      ?? '';
        final nom      = data['nom']         ?? '';
        final nbAnn    = data['nb_annonces'] ?? 0;
        final nbReu    = data['nb_reunions'] ?? 0;
        final numAppt  = data['num_appart']  ?? 'N/A';
        final immeuble = data['immeuble_nom']?? 'N/A';
        final tranche  = data['tranche_nom'] ?? 'N/A';

        return RefreshIndicator(
          color: _coral,
          onRefresh: () async {
            setState(() {});
            await _loadReclamations();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBanner(prenom, nom, numAppt, tranche, immeuble),
                const SizedBox(height: 20),
                _buildGrid(nbAnn, nbReu),
                const SizedBox(height: 20),
                _buildReclamationsSection(),
                const SizedBox(height: 20),
                _buildInfoLogement(numAppt, immeuble, tranche, prenom, nom),
              ],
            ),
          ),
        );
      },
    );

    if (inLayout) return body;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text("ResiManager",
            style: TextStyle(
                color: _dark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _coral),
      ),
      drawer: ResidentMobileDrawer(
          currentIndex: 0, userId: currentUserId),
      body: body,
    );
  }

  // ── BANNER ──
  Widget _buildBanner(String prenom, String nom,
      String numAppt, String tranche, String immeuble) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_coral, Color(0xFFFF9A6C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Bonjour, $prenom 👋',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('$immeuble · Appt N°$numAppt',
            style: const TextStyle(
                color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.location_on_rounded,
                color: Colors.white70, size: 14),
            const SizedBox(width: 6),
            Text(tranche,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }

  // ── GRID 2x2 ──
  Widget _buildGrid(int nbAnn, int nbReu) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _card('Dépenses', 'Consulter',
            Icons.receipt_long_rounded,
            const Color(0xFFEEF1FF), const Color(0xFF4B6BFB),
                () => _goTo(1)),
        _card('Annonces', '$nbAnn actives',
            Icons.campaign_rounded,
            const Color(0xFFFFF0EB), _coral,
                () => _goTo(3)),
        _card('Réunions', '$nbReu à venir',
            Icons.event_rounded,
            const Color(0xFFEBFAF4), const Color(0xFF34C98B),
                () => _goTo(4)),
        _card('Paiements', 'Consulter',
            Icons.account_balance_wallet_rounded,
            const Color(0xFFFFF8EC), const Color(0xFFFF9500),
                () => _goTo(2)),
      ],
    );
  }

  Widget _card(String title, String value, IconData icon,
      Color iconBg, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 8), // ← AJOUTE

            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              Text(title,
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11)),
            ]),
          ],
        ),
      ),
    );
  }

  // ── RÉCLAMATIONS ──
  Widget _buildReclamationsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Mes Réclamations',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            GestureDetector(
              onTap: () => _goTo(5),
              child: const Text('Voir tout',
                  style: TextStyle(
                      color: _coral,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loadingReclamations)
          const Center(
              child: CircularProgressIndicator(color: _coral))
        else if (_recentReclamations.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucune réclamation en cours',
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 13)),
          )
        else
          ..._recentReclamations.take(3).map(_buildReclamationItem),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _goTo(5),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Nouvelle réclamation'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _coral,
              side: const BorderSide(color: _coral),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildReclamationItem(Map<String, dynamic> r) {
    final statut = r['statut'] ?? 'en_cours';
    final Color c = statut == 'resolue'
        ? Colors.green
        : statut == 'en_cours'
        ? Colors.orange
        : Colors.grey;
    final String label = statut == 'resolue'
        ? 'Résolue'
        : statut == 'en_cours'
        ? 'En cours'
        : statut;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withOpacity(0.15)),
      ),
      child: Row(children: [
        Icon(
          statut == 'resolue'
              ? Icons.check_circle_rounded
              : Icons.access_time_rounded,
          color: c, size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r['titre'] ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(r['description'] ?? '',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Text(label,
              style: TextStyle(
                  color: c,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  // ── INFO LOGEMENT ──
  Widget _buildInfoLogement(String numAppt, String immeuble,
      String tranche, String prenom, String nom) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Mon Logement',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 14),
        _infoRow(Icons.person_outline_rounded, 'Résident', '$prenom $nom'),
        _infoRow(Icons.grid_view_rounded, 'Tranche', tranche),
        _infoRow(Icons.business_rounded, 'Immeuble', immeuble),
        _infoRow(Icons.home_rounded, 'Appartement', 'N°$numAppt'),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade500, fontSize: 12)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════
// DRAWER MOBILE — inchangé
// ═══════════════════════════════════════════════
class ResidentMobileDrawer extends StatelessWidget {
  final int currentIndex;
  final int userId;
  const ResidentMobileDrawer(
      {super.key, required this.currentIndex, this.userId = 3});

  @override
  Widget build(BuildContext context) {
    const Color brand = Color(0xFFFF6B4A);
    return Drawer(
      child: Column(children: [
        const DrawerHeader(
          decoration: BoxDecoration(color: brand),
          child: Center(
              child: Text("ResiManager",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold))),
        ),
        _item(context, "Accueil", Icons.home, 0,
            ResidentDashboardScreen(userId: userId)),
        _item(context, "Dépenses", Icons.receipt_long, 1,
            ResidentChargesScreen(userId: userId)),
        _item(context, "Paiements", Icons.payment, 2,
            HistoriquePaiementsScreen(userId: userId)),
        _item(context, "Annonces", Icons.article, 3,
            ResidentAnnoncesScreen(userId: userId)),
        _item(context, "Réunions", Icons.calendar_today, 4,
            const ResidentReunionsScreen()),
        _item(context, "Réclamations", Icons.report_problem, 5,
            ResidentReclamationsScreen(userId: userId)),
        const Spacer(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text("Déconnexion"),
          onTap: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _item(BuildContext context, String t, IconData i,
      int idx, Widget dest) {
    final bool sel = currentIndex == idx;
    const Color brand = Color(0xFFFF6B4A);
    return ListTile(
      leading: Icon(i, color: sel ? brand : Colors.grey),
      title: Text(t,
          style: TextStyle(
              color: sel ? brand : Colors.black87,
              fontWeight: sel
                  ? FontWeight.bold
                  : FontWeight.normal)),
      onTap: () {
        Navigator.pop(context);
        if (!sel)
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => dest));
      },
    );
  }
}