import 'package:flutter/material.dart';
import '../../services/syndic_dashboard_service.dart';
import '../../widgets/main_layout.dart'; // IMPORTANT : On importe le layout
import '../../widgets/kpi_card.dart';

class DashboardScreen extends StatefulWidget {
  final int residenceId;

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
    // ON REMPLACE TOUT LE SCAFFOLD MANUEL PAR LE MAINLAYOUT
    return MainLayout(
      title: '', // Pas de titre sur Web (géré par le layout)
      activePage: 'Dashboard', // Pour que le menu soit orange sur "Tableau de bord"
      body: _buildMainContent(context),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 700;

    return FutureBuilder<DashboardStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        final data = snapshot.data!;

        return SingleChildScrollView(
          // On ajuste le padding pour que ça soit collé en haut sur Web
          padding: EdgeInsets.only(
              left: isMobile ? 15 : 30,
              right: isMobile ? 15 : 30,
              top: isMobile ? 10 : 25,
              bottom: 30
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TITRE DE LA PAGE
              const Text('Tableau de Bord', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
              const Text("Vue d'ensemble de la gestion de la résidence", style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 30),

              // RANGÉE 1 : STATISTIQUES GÉNÉRALES
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  KpiCard(
                      title: 'Syndics Actifs',
                      value: data.syndicsActifs.toString(),
                      icon: Icons.people,
                      iconColor: const Color(0xFF2C2C2C)
                  ),
                  KpiCard(
                      title: 'Tranches',
                      value: data.tranches.toString(),
                      icon: Icons.domain,
                      iconColor: const Color(0xFFFF6F4A)
                  ),
                  KpiCard(
                      title: 'Immeubles',
                      value: data.immeubles.toString(),
                      icon: Icons.apartment,
                      iconColor: const Color(0xFF2C2C2C)
                  ),
                  KpiCard(
                      title: 'Appartements',
                      value: data.appartements.toString(),
                      icon: Icons.home,
                      iconColor: const Color(0xFFFF6F4A)
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // RANGÉE 2 : RÉSUMÉ FINANCIER
              const Text('Résumé Financier', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  KpiCard(
                    title: 'Charges Totales (Ce mois)',
                    value: data.chargesTotales.toStringAsFixed(0),
                    icon: Icons.payments_outlined,
                    iconColor: const Color(0xFF2C2C2C),
                    isCurrency: true,
                    subtitle: 'par mois',
                  ),
                  KpiCard(
                    title: 'Revenus Parkings',
                    value: data.revenusParkings.toStringAsFixed(0),
                    icon: Icons.local_parking,
                    iconColor: const Color(0xFFFF6F4A),
                    isCurrency: true,
                    subtitle: 'par mois',
                  ),
                ],
              ),

              const SizedBox(height: 40),
              // Espace pour les graphiques futurs
            ],
          ),
        );
      },
    );
  }
}