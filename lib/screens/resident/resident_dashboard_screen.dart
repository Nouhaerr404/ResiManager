// lib/screens/resident/resident_dashboard_screen.dart

import 'package:flutter/material.dart';
import '../../services/resident_service.dart';
import 'resident_charges_screen.dart';
import 'resident_annonces_screen.dart';
import 'resident_reunions_screen.dart';
import 'historique_paiements_screen.dart'; // ← AJOUT

class ResidentDashboardScreen extends StatefulWidget {
  const ResidentDashboardScreen({super.key});

  @override
  _ResidentDashboardScreenState createState() => _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen> {
  final ResidentService _service = ResidentService();
  final int currentUserId = 3;

  @override
  Widget build(BuildContext context) {
    const Color brandColor = Color(0xFFFF6B4A);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: const Text("ResiManager",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: brandColor),
      ),
      drawer: const ResidentMobileDrawer(currentIndex: 0),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _service.getResidentDashboardData(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: brandColor));
          }
          if (snapshot.hasError)
            return Center(child: Text("Erreur: ${snapshot.error}"));

          final data = snapshot.data!;
          final user = {'prenom': data['prenom'], 'nom': data['nom'], 'email': ''};
          final stats = {'annonces': data['nb_annonces'], 'reunions': data['nb_reunions']};
          final List recentNotifs = [];
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
                        Icons.receipt_long, () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ResidentChargesScreen()));
                        }),
                    _buildKpiCard(
                        "Annonces",
                        "${stats['annonces'] ?? 0} actives",
                        Icons.article_outlined, () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ResidentAnnoncesScreen()));
                    }),
                    _buildKpiCard(
                        "Réunions",
                        "${stats['reunions'] ?? 0} à venir",
                        Icons.calendar_today, () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ResidentReunionsScreen()));
                    }),
                    // ← FIX : navigue vers HistoriquePaiementsScreen
                    _buildKpiCard("Paiement", "À jour",
                        Icons.check_circle_outline, () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const HistoriquePaiementsScreen()));
                        }),
                  ],
                ),
                const SizedBox(height: 24),

                _buildInfoSection(user, resident),
                const SizedBox(height: 20),
                _buildLogementSection(appart),
                const SizedBox(height: 20),
                _buildNotifSidebar(recentNotifs),
                const SizedBox(height: 24),
                _buildQuickActions(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBanner(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B4A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Bienvenue, $name!",
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
                style:
                const TextStyle(color: Colors.grey, fontSize: 11)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ],
        ),
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
          _infoItem("Type",
              (res['type'] ?? "Résident").toString().toUpperCase()),
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
          _infoItem("Appartement", "N° ${appart['numero'] ?? 'N/A'}"),
        ],
      ),
    );
  }

  Widget _buildNotifSidebar(List notifs) {
    return _container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(Icons.notifications_none, "Notifications"),
          const SizedBox(height: 15),
          if (notifs.isEmpty)
            const Text("Aucune notification récente",
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ...notifs
              .map((n) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.circle,
                    size: 6, color: Color(0xFFFF6B4A)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(n['titre'] ?? '',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
          ))
              .toList(),
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
          _actionBtn(Icons.payment, "Mes paiements", () {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const HistoriquePaiementsScreen()));
          }),
          const SizedBox(height: 15),
          _actionBtn(Icons.campaign, "Consulter les annonces", () {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => ResidentAnnoncesScreen()));
          }),
          const SizedBox(height: 15),
          _actionBtn(Icons.calendar_today, "Voir les réunions", () {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const ResidentReunionsScreen()));
          }),
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
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
  ]);

  Widget _infoItem(String l, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 10.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Flexible(
            child: Text(v,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis)),
      ],
    ),
  );

  Widget _actionBtn(IconData i, String l, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Row(children: [
      Icon(i, color: Colors.white, size: 20),
      const SizedBox(width: 15),
      Text(l,
          style: const TextStyle(color: Colors.white, fontSize: 15))
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════
// DRAWER MOBILE — 5 items avec Paiements
// ═══════════════════════════════════════════════════════════════

class ResidentMobileDrawer extends StatelessWidget {
  final int currentIndex;
  const ResidentMobileDrawer({super.key, required this.currentIndex});

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
          _item(context, "Accueil",   Icons.home,             0, const ResidentDashboardScreen()),
          _item(context, "Dépenses",  Icons.receipt_long,     1, ResidentChargesScreen()),
          // ← PAIEMENTS à l'index 2
          _item(context, "Paiements", Icons.payment,          2, const HistoriquePaiementsScreen()),
          _item(context, "Annonces",  Icons.article,          3, ResidentAnnoncesScreen()),
          _item(context, "Réunions",  Icons.calendar_today,   4, const ResidentReunionsScreen()),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Retour Démo"),
            onTap: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, String t, IconData i, int idx, Widget dest) {
    final bool sel = currentIndex == idx;
    const Color brand = Color(0xFFFF6B4A);
    return ListTile(
      leading: Icon(i, color: sel ? brand : Colors.grey),
      title: Text(t,
          style: TextStyle(
              color: sel ? brand : Colors.black87,
              fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      onTap: () {
        Navigator.pop(context);
        if (!sel) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => dest));
        }
      },
    );
  }
}