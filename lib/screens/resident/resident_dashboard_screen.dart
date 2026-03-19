import 'package:flutter/material.dart';
import '../../services/resident_service.dart';
import 'resident_charges_screen.dart';
import 'resident_annonces_screen.dart';
import 'resident_reunions_screen.dart';
import 'historique_paiements_screen.dart';
import 'resident_reclamations_screen.dart';

class ResidentDashboardScreen extends StatefulWidget {
  final int userId;
  final Function(int)? onNavigate; // ← AJOUT pour communiquer avec le layout
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

  // ← Navigation : si dans layout → onNavigate, sinon pushReplacement
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
    const Color brandColor = Color(0xFFFF6B4A);

    // ← Si utilisé dans le layout, pas de Scaffold/AppBar/Drawer
    final bool inLayout = widget.onNavigate != null;

    final body = FutureBuilder<Map<String, dynamic>>(
      future: _service.getResidentDashboardData(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: brandColor));
        }
        if (snapshot.hasError)
          return Center(child: Text("Erreur: ${snapshot.error}"));

        final data = snapshot.data!;
        final user = {
          'prenom': data['prenom'] ?? '',
          'nom': data['nom'] ?? '',
          'email': '',
        };
        final stats = {
          'annonces': data['nb_annonces'],
          'reunions': data['nb_reunions'],
        };
        final appart = {
          'numero': data['num_appart'],
          'immeubles': {
            'nom': data['immeuble_nom'],
            'tranches': {'nom': data['tranche_nom']}
          }
        };
        final resident = {'type': 'proprietaire'};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBanner(user['prenom'] ?? "Résident"),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildKpiCard("Dépenses", "Consulter",
                      Icons.receipt_long, () => _goTo(1)),
                  _buildKpiCard("Annonces",
                      "${stats['annonces'] ?? 0} actives",
                      Icons.article_outlined, () => _goTo(3)),
                  _buildKpiCard("Réunions",
                      "${stats['reunions'] ?? 0} à venir",
                      Icons.calendar_today, () => _goTo(4)),
                  _buildKpiCard("Paiement", "À jour",
                      Icons.check_circle_outline, () => _goTo(2)),
                ],
              ),
              const SizedBox(height: 24),
              _buildReclamationsSection(),
              const SizedBox(height: 20),
              _buildInfoSection(user, resident),
              const SizedBox(height: 20),
              _buildLogementSection(appart),
              const SizedBox(height: 20),
              _buildQuickActions(context),
            ],
          ),
        );
      },
    );

    // ← Si dans layout : retourner juste le body sans Scaffold
    if (inLayout) return body;

    // ← Si standalone (ex: démo) : retourner avec Scaffold complet
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: const Text("ResiManager",
            style:
            TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: brandColor),
      ),
      drawer: ResidentMobileDrawer(currentIndex: 0, userId: currentUserId),
      body: body,
    );
  }

  Widget _buildBanner(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B4A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Bonjour, $name 👋",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold)),
          const Text("Accédez à vos informations de résidence",
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
      String title, String value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFFF6B4A), size: 24),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildReclamationsSection() {
    return _container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _title(Icons.report_problem, "Mes Réclamations"),
              TextButton(
                onPressed: () => _goTo(5),
                child: const Text("Voir tout",
                    style: TextStyle(color: Color(0xFFFF6B4A))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loadingReclamations)
            const Center(
                child:
                CircularProgressIndicator(color: Color(0xFFFF6B4A)))
          else if (_recentReclamations.isEmpty)
            const Text("Aucune réclamation en cours",
                style: TextStyle(color: Colors.grey, fontSize: 13))
          else
            ..._recentReclamations
                .take(3)
                .map((r) => _buildReclamationItem(r)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _goTo(5),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Nouvelle réclamation"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF6B4A),
                side: const BorderSide(color: Color(0xFFFF6B4A)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReclamationItem(Map<String, dynamic> r) {
    final statut = r['statut'] ?? 'en_cours';
    final Color statusColor = statut == 'resolue'
        ? Colors.green
        : statut == 'en_cours'
        ? Colors.orange
        : Colors.grey;
    final String statusText = statut == 'resolue'
        ? 'Résolue'
        : statut == 'en_cours'
        ? 'En cours'
        : statut;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              statut == 'resolue'
                  ? Icons.check_circle
                  : Icons.access_time,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['titre'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(r['description'] ?? '',
                    style:
                    const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(statusText,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Map user, Map res) {
    return _container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(Icons.person_outline, "Mes Informations"),
          const SizedBox(height: 15),
          _infoItem("Nom complet",
              "${user['prenom'] ?? ''} ${user['nom'] ?? ''}"),
          _infoItem("Email", user['email'] ?? 'N/A'),
          _infoItem(
              "Type",
              (res['type'] ?? "Résident")
                  .toString()
                  .toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildLogementSection(Map appart) {
    return _container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(Icons.apartment, "Mon Logement"),
          const SizedBox(height: 15),
          _infoItem("Tranche",
              appart['immeubles']?['tranches']?['nom'] ?? "N/A"),
          _infoItem("Immeuble", appart['immeubles']?['nom'] ?? "N/A"),
          _infoItem(
              "Appartement", "N° ${appart['numero'] ?? 'N/A'}"),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Actions Rapides",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _actionBtn(Icons.payment, "Mes paiements", () => _goTo(2)),
          const SizedBox(height: 15),
          _actionBtn(Icons.campaign, "Consulter les annonces",
                  () => _goTo(3)),
          const SizedBox(height: 15),
          _actionBtn(
              Icons.calendar_today, "Voir les réunions", () => _goTo(4)),
          const SizedBox(height: 15),
          _actionBtn(Icons.report_problem, "Mes réclamations",
                  () => _goTo(5)),
        ],
      ),
    );
  }

  Widget _container({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100)),
    child: child,
  );

  Widget _title(IconData i, String t) => Row(children: [
    Icon(i, color: const Color(0xFFFF6B4A), size: 20),
    const SizedBox(width: 10),
    Text(t,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold))
  ]);

  Widget _infoItem(String l, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 10.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l,
            style:
            const TextStyle(color: Colors.grey, fontSize: 13)),
        Flexible(
            child: Text(v,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis)),
      ],
    ),
  );

  Widget _actionBtn(IconData i, String l, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Row(children: [
          Icon(i, color: Colors.white, size: 20),
          const SizedBox(width: 15),
          Text(l,
              style:
              const TextStyle(color: Colors.white, fontSize: 15))
        ]),
      );
}

// ═══════════════════════════════════════════════
// DRAWER MOBILE — garde pour compatibilité
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
      child: Column(
        children: [
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
            leading:
            const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Déconnexion"),
            onTap: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, String t, IconData i, int idx,
      Widget dest) {
    final bool sel = currentIndex == idx;
    const Color brand = Color(0xFFFF6B4A);
    return ListTile(
      leading: Icon(i, color: sel ? brand : Colors.grey),
      title: Text(t,
          style: TextStyle(
              color: sel ? brand : Colors.black87,
              fontWeight:
              sel ? FontWeight.bold : FontWeight.normal)),
      onTap: () {
        Navigator.pop(context);
        if (!sel)
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => dest));
      },
    );
  }
}