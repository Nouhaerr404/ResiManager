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
      body: FutureBuilder<List<dynamic>>(
        // ON CHARGE LES DEUX SOURCES DE DONNÉES EN MÊME TEMPS
        future: Future.wait([
          _service.fetchDashboardStats(widget.residenceId),
          _service.getChartsData(widget.residenceId),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text("Erreur: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: Text("Aucune donnée"));

          // Extraction des données réelles
          final DashboardStats stats = snapshot.data![0];
          final Map<String, dynamic> chartData = snapshot.data![1];
          final List<double> expenses = chartData['expenses'];
          final List<double> revenues = chartData['revenues'];

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

                // 2. LES ANALYSES (Graphiques)
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

  // --- SECTION 1 : CARTES KPI UNIFORMES ---
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

  // --- SECTION 2 : JAUGE DE RECOUVREMENT ---
  Widget _buildRecoveryGauge(double percentage, bool isLarge) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: isLarge ? 400 : 250, // On augmente un peu la hauteur pour l'explication
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: Column(
        children: [
          // 1. TITRE DU DIAGRAMME
          const Text(
              "Performance de Collecte",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
          ),
          const SizedBox(height: 20),

          // 2. LE DIAGRAMME (L'ANNEAU)
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: 270,
                    sectionsSpace: 0,
                    centerSpaceRadius: isLarge ? 80 : 50,
                    sections: [
                      PieChartSectionData(value: percentage, color: primaryOrange, radius: 12, showTitle: false),
                      PieChartSectionData(value: (100 - percentage).clamp(0, 100), color: Colors.grey.shade100, radius: 12, showTitle: false),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${percentage.toStringAsFixed(1)}%",
                        style: TextStyle(fontSize: isLarge ? 32 : 22, fontWeight: FontWeight.bold, color: darkGrey)),
                    Text("Payé", style: TextStyle(color: Colors.grey, fontSize: isLarge ? 12 : 10)),
                  ],
                )
              ],
            ),
          ),

          // 3. EXPLICATION (Le "Pourquoi")
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10)
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Ce taux compare l'argent encaissé par rapport au total des charges dues par les résidents.",
                    style: TextStyle(fontSize: isLarge ? 11 : 9, color: Colors.blueGrey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // --- SECTION 3 : BILAN MENSUEL ---
  Widget _buildMonthlyBalanceChart(List<double> revenues, List<double> expenses) {
    double maxVal = 0;
    for (var v in [...revenues, ...expenses]) { if (v > maxVal) maxVal = v; }
    double calculatedMaxY = maxVal == 0 ? 1000 : maxVal * 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      height: 400,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Bilan Mensuel Réel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 30),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: calculatedMaxY,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(['Jan','Fev','Mar','Avr','Mai','Jun','Jul','Aou','Sep','Oct','Nov','Dec'][v.toInt() % 12], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ))),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45, // Plus d'espace pour que les chiffres ne touchent pas le bord

                      // CORRECTION : On définit un intervalle fixe (ex: une graduation tous les 1/5ème de la valeur max)
                      interval: calculatedMaxY / 4,

                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text("");

                        // Formatage intelligent
                        String text = "";
                        if (value >= 1000000) {
                          text = "${(value / 1000000).toStringAsFixed(1)}M";
                        } else if (value >= 1000) {
                          text = "${(value / 1000).toInt()}k";
                        } else {
                          text = value.toInt().toString();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            text,
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                // ON GÉNÈRE 6 MOIS POUR LE TEST
                barGroups: List.generate(6, (i) => _makeGroupData(i, revenues[i], expenses[i])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double income, double expense) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(toY: income, color: successGreen, width: 10, borderRadius: BorderRadius.circular(2)),
      BarChartRodData(toY: expense, color: primaryOrange, width: 10, borderRadius: BorderRadius.circular(2)),
    ]);
  }
}