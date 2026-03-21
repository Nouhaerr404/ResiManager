import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/kpi_card.dart';
import '../../services/syndic_dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  final int residenceId;
  const DashboardScreen({Key? key, required this.residenceId}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SyndicDashboardService _service = SyndicDashboardService();

  final Color primaryOrange = const Color(0xFFFF6F4A);
  final Color darkGrey = const Color(0xFF2C2C2C);
  final Color softGrey = const Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isWeb = width > 900;

    return MainLayout(
      activePage: 'Dashboard',
      body: FutureBuilder<DashboardStats>(
        future: _service.fetchDashboardStats(widget.residenceId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final stats = snapshot.data!;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isWeb ? 40 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ---
                const Text("Statistiques Globales", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const Text("Analyse en temps réel de votre résidence", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),

                // --- TOP KPI GRID ---
                _buildKpiGrid(stats, isWeb),
                const SizedBox(height: 40),

                // --- MAIN ANALYTICS SECTION ---
                // --- MAIN ANALYTICS SECTION ---
                if (isWeb)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // REMPLACE _buildTrendSection() PAR :
                      Expanded(flex: 2, child: _buildMonthlyBalanceChart()),
                      const SizedBox(width: 30),
                      Expanded(flex: 1, child: _buildRecoveryGauge(85)),
                    ],
                  )
                else
                  Column(
                    children: [
                      // REMPLACE _buildTrendSection() PAR :
                      _buildMonthlyBalanceChart(),
                      const SizedBox(height: 30),
                      _buildRecoveryGauge(85),
                    ],
                  ),

                const SizedBox(height: 40),
                _buildTranchePerformanceSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  // 📈 GRAPHIQUE 1 : LA TENDANCE FINANCIÈRE (LINE CHART)
  Widget _buildMonthlyBalanceChart() {
    return _containerWrapper(
      title: "Bilan Financier Mensuel",
      subtitle: "Comparaison Revenus vs Dépenses",
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildLegendItem("Revenus", Colors.teal),
              const SizedBox(width: 15),
              _buildLegendItem("Dépenses", primaryOrange),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 60000,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    // CORRECTION ICI : Nouvelle syntaxe pour la couleur du fond
                    getTooltipColor: (group) => darkGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        "${rod.toY.toInt()} DH",
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(months[value.toInt() % 6], style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeGroupData(0, 45000, 32000),
                  _makeGroupData(1, 38000, 41000),
                  _makeGroupData(2, 52000, 28000),
                  _makeGroupData(3, 48000, 35000),
                  _makeGroupData(4, 55000, 30000),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  // Fonction pour créer une paire de barres (Recette + Dépense)
  BarChartGroupData _makeGroupData(int x, double income, double expense) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
            toY: income,
            color: Colors.teal,
            width: 12,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))
        ),
        BarChartRodData(
            toY: expense,
            color: primaryOrange,
            width: 12,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))
        ),
      ],
    );
  }

  // Petit widget pour la légende
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
  Widget _buildRecoveryGauge(double percentage) {
    return _containerWrapper(
      title: "Taux de Recouvrement",
      subtitle: "Charges payées par les résidents",
      child: SizedBox(
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                startDegreeOffset: 270,
                sectionsSpace: 0,
                centerSpaceRadius: 70,
                sections: [
                  PieChartSectionData(value: percentage, color: primaryOrange, radius: 15, showTitle: false),
                  PieChartSectionData(value: 100 - percentage, color: Colors.grey.shade200, radius: 15, showTitle: false),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("${percentage.toInt()}%", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: darkGrey)),
                const Text("Collecté", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // 📊 SECTION 3 : PERFORMANCE PAR TRANCHE
  Widget _buildTranchePerformanceSection() {
    return _containerWrapper(
      title: "Performance par Tranche",
      subtitle: "État des paiements par secteur",
      child: Column(
        children: [
          _trancheProgressRow("Tranche A - Les Jardins", 0.9, Colors.green),
          _trancheProgressRow("Tranche B - Les Palmiers", 0.6, primaryOrange),
          _trancheProgressRow("Tranche C - Le Parc", 0.35, Colors.redAccent),
        ],
      ),
    );
  }

  // --- HELPERS UI ---

  Widget _containerWrapper({required String title, required String subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGrey)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 30),
          child,
        ],
      ),
    );
  }

  Widget _trancheProgressRow(String name, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text("${(progress * 100).toInt()}%", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade100,
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(DashboardStats stats, bool isWeb) {
    return Wrap(
      spacing: 20, runSpacing: 20,
      children: [
        KpiCard(title: 'Total Résidents', value: "148", icon: Icons.people_alt_rounded, iconColor: darkGrey),
        KpiCard(title: 'Appartements Libres', value: "12", icon: Icons.vpn_key_rounded, iconColor: primaryOrange),
        KpiCard(title: 'Charges à Collecter', value: "45 000", icon: Icons.account_balance_wallet, iconColor: darkGrey, isCurrency: true),
      ],
    );
  }
}