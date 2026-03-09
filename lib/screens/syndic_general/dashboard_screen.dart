import 'package:flutter/material.dart';
import '../../services/syndic_dashboard_service.dart';
import '../../widgets/syndic_sidebar.dart';
import '../../widgets/kpi_card.dart';

class DashboardScreen extends StatefulWidget {
  final int residenceId; // L'ID de la résidence gérée

  const DashboardScreen({Key? key, required this.residenceId}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SyndicDashboardService _service = SyndicDashboardService();
  late Future<DashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _service.fetchDashboardStats(widget.residenceId);
  }

  @override
  Widget build(BuildContext context) {
    // Le Scaffold englobe toute la page
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // Fond gris très clair (style dashboard)
      // Sur mobile, le Drawer sera caché derrière un bouton burger menu
      drawer: MediaQuery.of(context).size.width < 900 ? const SyndicSidebar() : null,

      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sur Web (grand écran), on affiche toujours la Sidebar
          if (MediaQuery.of(context).size.width >= 900)
            const SizedBox(
              width: 250,
              child: SyndicSidebar(),
            ),

          // Le contenu principal prend le reste de l'espace
          Expanded(
            child: _buildMainContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return FutureBuilder<DashboardStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('Aucune donnée disponible'));
        }

        final data = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Mobile (Burger menu)
              if (MediaQuery.of(context).size.width < 900)
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),

              // Titre de la page
              const Text('Tableau de Bord', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              const Text("Vue d'ensemble de la gestion de la résidence", style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 30),

              // Première rangée : Les 4 petites cartes
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  KpiCard(
                      title: 'Syndics Actifs',
                      value: data.syndicsActifs.toString(),
                      icon: Icons.people,
                      iconColor: Colors.blue
                  ),
                  KpiCard(
                      title: 'Tranches',
                      value: data.tranches.toString(),
                      icon: Icons.domain,
                      iconColor: Colors.purple
                  ),
                  KpiCard(
                      title: 'Immeubles',
                      value: data.immeubles.toString(),
                      icon: Icons.apartment,
                      iconColor: Colors.green
                  ),
                  KpiCard(
                      title: 'Appartements',
                      value: data.appartements.toString(),
                      icon: Icons.home,
                      iconColor: Colors.orange
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Deuxième rangée : Finances
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  KpiCard(
                    title: 'Charges Totales (Ce mois)',
                    value: data.chargesTotales.toStringAsFixed(2),
                    icon: Icons.attach_money,
                    iconColor: Colors.red,
                    isCurrency: true,
                    subtitle: 'par mois',
                  ),
                  KpiCard(
                    title: 'Revenus Parkings',
                    value: data.revenusParkings.toStringAsFixed(2),
                    icon: Icons.local_parking,
                    iconColor: Colors.indigo,
                    isCurrency: true,
                    subtitle: 'par mois',
                  ),
                ],
              ),

              const SizedBox(height: 40),
              // Ici, on viendra ajouter les graphiques (fl_chart) plus tard !
              // _buildChartsRow(),
            ],
          ),
        );
      },
    );
  }
}