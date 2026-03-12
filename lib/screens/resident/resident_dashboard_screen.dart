import 'package:flutter/material.dart';
import '../../services/resident_service.dart';
import '../../widgets/resident_nav_bar.dart';
import 'resident_notifications_screen.dart';
import 'resident_annonces_screen.dart';
import 'resident_reunions_screen.dart';
import 'resident_charges_screen.dart';

class ResidentDashboardScreen extends StatefulWidget {
  @override
  _ResidentDashboardScreenState createState() => _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen> {
  final ResidentService _service = ResidentService();
  final int currentUserId = 3; // ID de test pour Ahmed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: const ResidentNavBar(currentIndex: 0),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _service.getResidentDashboardData(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B4A)));
          }
          if (snapshot.hasError) return Center(child: Text("Erreur: ${snapshot.error}"));

          final data = snapshot.data!;
          final user = data['profile'] ?? {};
          final resident = data['resident'] ?? {};
          final appart = resident['appartements'] ?? {};
          final immeuble = appart['immeubles'] ?? {};
          final tranche = immeuble['tranches'] ?? {};
          final stats = data['stats'] ?? {};
          final List recentNotifs = data['recentNotifs'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. BANNIÈRE DE BIENVENUE
                _buildBanner(user['prenom'] ?? "Résident"),
                const SizedBox(height: 32),

                // 2. CARTES KPI (INTERACTIVES)
                Row(
                  children: [
                    _buildKpiCard(
                      "Notifications",
                      "${stats['notifs']} non lues",
                      Icons.notifications_none,
                          () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResidentNotificationsScreen())),
                    ),
                    const SizedBox(width: 20),
                    _buildKpiCard(
                      "Annonces",
                      "${stats['annonces']} actives",
                      Icons.description_outlined,
                          () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResidentAnnoncesScreen())),
                    ),
                    const SizedBox(width: 20),
                    _buildKpiCard(
                      "Réunions",
                      "${stats['reunions']} à venir",
                      Icons.calendar_today,
                          () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResidentReunionsScreen())),
                    ),
                    const SizedBox(width: 20),
                    _buildKpiCard(
                      "Paiement",
                      "À jour",
                      Icons.credit_card,
                          () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResidentChargesScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // COLONNE GAUCHE : INFOS + LOGEMENT
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildInfoSection(user, resident),
                          const SizedBox(height: 32),
                          _buildLogementSection(appart, immeuble, tranche),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),

                    // COLONNE DROITE : NOTIFS + ACTIONS RAPIDES
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildNotifSidebar(recentNotifs),
                          const SizedBox(height: 32),
                          _buildQuickActions(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGETS DE CONSTRUCTION ---

  Widget _buildBanner(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(50),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B4A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Bienvenue, $name!", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
              const Text("Accédez à toutes les informations de votre résidence", style: TextStyle(color: Colors.white70, fontSize: 18)),
            ],
          ),
          const Icon(Icons.home_work_outlined, color: Colors.white24, size: 100),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFFF6F4), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: const Color(0xFFFF6B4A)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
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
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true, crossAxisCount: 2, childAspectRatio: 4, crossAxisSpacing: 20, mainAxisSpacing: 20,
            children: [
              _infoTile("Nom complet", "${user['prenom'] ?? ''} ${user['nom'] ?? ''}"),
              _infoTile("Type", (res['type'] ?? "Résident").toString().toUpperCase()),
              _infoTile("Email", user['email'] ?? ''),
              _infoTile("Téléphone", user['telephone'] ?? "N/A"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogementSection(Map appart, Map immeuble, Map tranche) {
    return _container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(Icons.apartment, "Mon Logement"),
          const SizedBox(height: 24),
          _infoTile("Tranche", tranche['nom'] ?? "N/A", isFull: true),
          const SizedBox(height: 15),
          _infoTile("Immeuble", immeuble['nom'] ?? "N/A", isFull: true, color: const Color(0xFFFFF6F4)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _infoTile("Adresse", immeuble['adresse'] ?? "N/A")),
              const SizedBox(width: 15),
              Expanded(child: _infoTile("Appartement", "N° ${appart['numero'] ?? 'N/A'}")),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildNotifSidebar(List notifs) {
    return _container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(Icons.notifications_none, "Notifications Récentes"),
          const SizedBox(height: 20),
          if (notifs.isEmpty) const Text("Aucune notification récente"),
          ...notifs.map((n) => _notifItem(n['titre'] ?? '', n['created_at'] ?? '')).toList(),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResidentNotificationsScreen())),
            child: const Center(child: Text("Voir toutes les notifications →", style: TextStyle(color: Color(0xFFFF6B4A), fontWeight: FontWeight.bold))),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Actions Rapides", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _actionBtn(Icons.campaign, "Consulter les annonces", () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResidentAnnoncesScreen()));
          }),
          const SizedBox(height: 12),
          _actionBtn(Icons.calendar_today, "Voir les réunions", () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResidentReunionsScreen()));
          }),
        ],
      ),
    );
  }

  // --- HELPERS ---

  Widget _container({required Widget child}) => Container(
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
    child: child,
  );

  Widget _title(IconData i, String t) => Row(children: [Icon(i, color: const Color(0xFFFF6B4A)), const SizedBox(width: 10), Text(t, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]);

  Widget _infoTile(String l, String v, {bool isFull = false, Color color = const Color(0xFFF8F8F8)}) => Container(
    width: isFull ? double.infinity : null,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(color: Colors.grey, fontSize: 12)), Text(v, style: const TextStyle(fontWeight: FontWeight.bold))]),
  );

  Widget _notifItem(String t, String d) => Container(
    margin: const EdgeInsets.only(bottom: 15),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFFFFF6F4), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade100)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.bold)), Text(d.contains('T') ? d.split('T')[0] : d, style: const TextStyle(fontSize: 11, color: Colors.grey))]),
  );

  Widget _actionBtn(IconData i, String l, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [Icon(i, color: Colors.white, size: 20), const SizedBox(width: 12), Text(l, style: const TextStyle(color: Colors.white))]),
    ),
  );
}