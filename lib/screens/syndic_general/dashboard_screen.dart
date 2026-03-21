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
      title: "Tableau de bord",
      // ON CHARGE TOUTES LES DONNÉES EN MÊME TEMPS
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          _service.fetchDashboardStats(widget.residenceId),
          _service.getChartsData(widget.residenceId),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text("Erreur: ${snapshot.error}"));

          // Récupération des données réelles
          final DashboardStats stats = snapshot.data![0];
          final Map<String, dynamic> chartData = snapshot.data![1];
          final List<double> expenses = chartData['expenses'];
          final List<double> revenues = chartData['revenues'];

          // Calcul du taux de recouvrement réel
          double totalDue = stats.chargesTotales;
          double totalPaid = revenues.fold(0, (sum, item) => sum + item);
          double recoveryRate = (totalDue > 0) ? (totalPaid / totalDue) * 100 : 0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isWeb ? 40 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Statistiques Globales", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const Text("Analyse en temps réel de votre résidence", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),

                // 1. KPIS RÉELS
                _buildKpiGrid(stats),
                const SizedBox(height: 40),

                // 2. GRAPHIQUES RÉELS
                if (isWeb)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildMonthlyBalanceChart(revenues, expenses)),
                      const SizedBox(width: 30),
                      Expanded(flex: 1, child: _buildRecoveryGauge(recoveryRate)),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildMonthlyBalanceChart(revenues, expenses),
                      const SizedBox(height: 30),
                      _buildRecoveryGauge(recoveryRate),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- GRAPHIQUE 1 : RÉEL (Recettes vs Dépenses) ---
  Widget _buildMonthlyBalanceChart(List<double> revenues, List<double> expenses) {
    return _containerWrapper(
      title: "Bilan Financier Mensuel",
      subtitle: "Données réelles de l'année en cours",
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _legend("Recettes", Colors.teal),
              const SizedBox(width: 15),
              _legend("Dépenses", primaryOrange),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 60000, // Tu peux calculer le max dynamiquement
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => darkGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem("${rod.toY.toInt()} DH", const TextStyle(color: Colors.white)),
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Text(['Jan', 'Fev', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aou', 'Sep', 'Oct', 'Nov', 'Dec'][v.toInt() % 12], style: const TextStyle(fontSize: 10)))),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                // ON GÉNÈRE LES BARRES DYNAMIQUEMENT DEPUIS LES LISTES
                barGroups: List.generate(6, (i) => _makeGroupData(i, revenues[i], expenses[i])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- GRAPHIQUE 2 : RÉEL (Jauge de recouvrement) ---
  Widget _buildRecoveryGauge(double percentage) {
    return _containerWrapper(
      title: "Taux de Recouvrement",
      subtitle: "Paiements reçus vs Charges totales",
      child: SizedBox(
        height: 250,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 70,
                sections: [
                  PieChartSectionData(value: percentage, color: successGreen, radius: 15, showTitle: false),
                  PieChartSectionData(value: 100 - percentage, color: Colors.grey.shade100, radius: 15, showTitle: false),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("${percentage.toStringAsFixed(1)}%", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: darkGrey)),
                const Text("Encaissé", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- KPIS RÉELS ---
  Widget _buildKpiGrid(DashboardStats stats) {
    return Wrap(
      spacing: 20, runSpacing: 20,
      children: [
        KpiCard(title: 'Total Tranches', value: stats.tranches.toString(), icon: Icons.domain, iconColor: primaryOrange),
        KpiCard(title: 'Appartements', value: stats.appartements.toString(), icon: Icons.home_filled, iconColor: darkGrey),
        KpiCard(title: 'Charges Globales', value: stats.chargesTotales.toInt().toString(), icon: Icons.payments, iconColor: primaryOrange, isCurrency: true),
      ],
    );
  }

  // --- HELPERS ---
  BarChartGroupData _makeGroupData(int x, double income, double expense) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(toY: income, color: Colors.teal, width: 12, borderRadius: BorderRadius.circular(4)),
      BarChartRodData(toY: expense, color: primaryOrange, width: 12, borderRadius: BorderRadius.circular(4)),
    ]);
  }

  Widget _containerWrapper({required String title, required String subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGrey)),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 30),
        child,
      ]),
    );
  }

  Widget _legend(String l, Color c) => Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)), const SizedBox(width: 5), Text(l, style: const TextStyle(fontSize: 11, color: Colors.grey))]);
}