import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/kpi_card.dart';
import '../../services/syndic_dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  final int residenceId;
  final int syndicId;
  const DashboardScreen({Key? key, required this.residenceId, required this.syndicId}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SyndicDashboardService _service = SyndicDashboardService();

  final Color primaryOrange = const Color(0xFFFF6F4A);
  final Color darkGrey = const Color(0xFF2C2C2C);
  final Color successGreen = const Color(0xFF4DB6AC);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isWeb = width > 900;

    return MainLayout(
      title: 'Statistiques Globales',
      activePage: 'Dashboard',
      residenceId: widget.residenceId,
      syndicId: widget.syndicId,
      body: Stack(
        children: [
          // 1. IMAGE D'ARRIÈRE-PLAN
          Positioned.fill(
            child: Image.asset(
              'assets/images/residence_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // 2. VOILE SOMBRE POUR LA LISIBILITÉ
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          // 3. CONTENU DU DASHBOARD
          FutureBuilder<List<dynamic>>(
            future: Future.wait([
              _service.fetchDashboardStats(widget.residenceId),
              _service.getChartsData(widget.residenceId),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (snapshot.hasError) return Center(child: Text("Erreur: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
              if (!snapshot.hasData) return const Center(child: Text("Aucune donnée", style: TextStyle(color: Colors.white)));

              final DashboardStats stats = snapshot.data![0];
              final Map<String, dynamic> chartData = snapshot.data![1];
              final List<double> expenses = chartData['expenses'];
              final List<double> revenues = chartData['revenues'];

              return SingleChildScrollView(
                padding: EdgeInsets.all(isWeb ? 40 : 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // N'affiche le titre que sur WEB pour éviter la répétition sur Mobile
                    if (isWeb) ...[
                      const Text("Statistiques Globales", 
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                      const Text("Analyse en temps réel de votre résidence", 
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 30),
                    ],

                    // CARTES KPI
                    _buildKpiSection(stats, isWeb),
                    const SizedBox(height: 35),

                    // ANALYSES (Graphiques)
                    if (isWeb)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildMonthlyBalanceChart(revenues, expenses)),
                          const SizedBox(width: 25),
                          Expanded(flex: 1, child: _buildRecoveryGauge(stats.recoveryRate, true)),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildMonthlyBalanceChart(revenues, expenses),
                          const SizedBox(height: 25),
                          _buildRecoveryGauge(stats.recoveryRate, false),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSection(DashboardStats stats, bool isWeb) {
    double cardWidth = isWeb ? 220 : (MediaQuery.of(context).size.width / 2) - 25;

    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: [
        _miniCard("Tranches", stats.tranches.toString(), Icons.layers, Colors.blue, cardWidth),
        _miniCard("Immeubles", stats.immeubles.toString(), Icons.apartment, Colors.indigo, cardWidth),
        _miniCard("Appartements", stats.appartements.toString(), Icons.home, Colors.teal, cardWidth),
        _miniCard("Parkings", stats.parkings.toString(), Icons.local_parking, Colors.blueGrey, cardWidth),
        _miniCard("Garages", stats.garages.toString(), Icons.storefront, Colors.brown, cardWidth),
        _miniCard("Boxes", stats.boxes.toString(), Icons.inventory_2, Colors.blueGrey, cardWidth),
        _miniCard("Total Dépenses", "${stats.chargesTotales.toInt()} DH", Icons.outbond, Colors.redAccent, cardWidth),
        _miniCard("Total Paiements", "${stats.revenusParkings.toInt()} DH", Icons.payments, Colors.green, cardWidth),
        _miniCard("Solde Net", "${(stats.revenusParkings - stats.chargesTotales).toInt()} DH", Icons.account_balance_wallet, darkGrey, cardWidth),
      ],
    );
  }

  Widget _miniCard(String title, String value, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9), // Effet Glassmorphism léger
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w700)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGrey))),
        ],
      ),
    );
  }

  Widget _buildRecoveryGauge(double percentage, bool isLarge) {
    return Container(
      padding: const EdgeInsets.all(22),
      height: isLarge ? 420 : 280,
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Text("Performance de Collecte", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: 270,
                    sectionsSpace: 0,
                    centerSpaceRadius: isLarge ? 85 : 55,
                    sections: [
                      PieChartSectionData(value: percentage, color: primaryOrange, radius: 14, showTitle: false),
                      PieChartSectionData(value: (100 - percentage).clamp(0, 100), color: Colors.grey.shade200, radius: 14, showTitle: false),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${percentage.toStringAsFixed(1)}%",
                        style: TextStyle(fontSize: isLarge ? 34 : 24, fontWeight: FontWeight.bold, color: darkGrey)),
                    const Text("Payé", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 15),
          const Text("Taux de recouvrement par rapport aux charges dues.", textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
        ],
      ),
    );
  }

  Widget _buildMonthlyBalanceChart(List<double> revenues, List<double> expenses) {
    double maxVal = 0;
    for (var v in [...revenues, ...expenses]) { if (v > maxVal) maxVal = v; }
    double calculatedMaxY = maxVal == 0 ? 1000 : maxVal * 1.2;

    return Container(
      padding: const EdgeInsets.all(22),
      height: 400,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Bilan Mensuel Réel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 35),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: calculatedMaxY,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(['Jan','Fev','Mar','Avr','Mai','Jun','Jul','Aou','Sep','Oct','Nov','Dec'][v.toInt() % 12], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ))),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: calculatedMaxY / 4, getTitlesWidget: (v, m) {
                    if (v == 0) return const Text("");
                    return Text(v >= 1000 ? "${(v/1000).toInt()}k" : v.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10));
                  })),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(revenues.length > 6 ? 6 : revenues.length, (i) => _makeGroupData(i, revenues[i], expenses[i])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double income, double expense) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(toY: income, color: successGreen, width: 10, borderRadius: BorderRadius.circular(3)),
      BarChartRodData(toY: expense, color: primaryOrange, width: 10, borderRadius: BorderRadius.circular(3)),
    ]);
  }
}