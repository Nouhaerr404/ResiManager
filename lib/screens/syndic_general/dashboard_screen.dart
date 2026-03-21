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
      activePage: 'Dashboard',
      residenceId: widget.residenceId,
      syndicId: widget.syndicId,
      body: FutureBuilder<DashboardStats>(
        future: _service.fetchDashboardStats(widget.residenceId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final stats = snapshot.data!;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isWeb ? 40 : 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Statistiques Globales", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const Text("Analyse en temps réel de votre résidence", style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 25),

                // 1. LES CARTES KPI UNIFORMES
                _buildKpiSection(stats, isWeb),
                const SizedBox(height: 30),

                // 2. LES ANALYSES
                if (isWeb)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildMonthlyBalanceChart(stats)),
                      const SizedBox(width: 25),
                      Expanded(flex: 1, child: _buildRecoveryGauge(stats.recoveryRate, true)),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildMonthlyBalanceChart(stats),
                      const SizedBox(height: 20),
                      _buildRecoveryGauge(stats.recoveryRate, false),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- LES CARTES UNIFORMES ---
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
        _miniCard("Garages", stats.garages.toString(), Icons.garage, Colors.brown, cardWidth),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
              Icon(icon, color: color.withOpacity(0.5), size: 16),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGrey))),
        ],
      ),
    );
  }

  // --- GRAPHIQUES ---
  Widget _buildRecoveryGauge(double percentage, bool isLarge) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: isLarge ? 400 : 180,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(PieChartData(startDegreeOffset: 270, sectionsSpace: 0, centerSpaceRadius: isLarge ? 80 : 45, sections: [
            PieChartSectionData(value: percentage, color: primaryOrange, radius: 12, showTitle: false),
            PieChartSectionData(value: 100 - percentage, color: Colors.grey.shade100, radius: 12, showTitle: false),
          ])),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text("${percentage.toStringAsFixed(1)}%", style: TextStyle(fontSize: isLarge ? 32 : 20, fontWeight: FontWeight.bold)),
            Text("Recouvré", style: TextStyle(color: Colors.grey, fontSize: isLarge ? 12 : 9)),
          ])
        ],
      ),
    );
  }

  Widget _buildMonthlyBalanceChart(DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 400,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Bilan Mensuel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 30),
        Expanded(child: BarChart(BarChartData(
          maxY: 60000,
          titlesData: FlTitlesData(bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Text(['Jan', 'Fev', 'Mar', 'Avr', 'Mai', 'Jun'][v.toInt() % 6], style: const TextStyle(fontSize: 10))))),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [_makeBar(0, 30000, 20000), _makeBar(1, 35000, 25000), _makeBar(2, 45000, 30000)],
        ))),
      ]),
    );
  }

  BarChartGroupData _makeBar(int x, double y1, double y2) {
    return BarChartGroupData(x: x, barRods: [BarChartRodData(toY: y1, color: successGreen, width: 10), BarChartRodData(toY: y2, color: primaryOrange, width: 10)]);
  }
}