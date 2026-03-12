// lib/screens/inter_syndic/finance/finance_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../../services/finance_service.dart';
import '../../../widgets/kpi_card.dart';
import 'add_tranche_expense_screen.dart';

class FinanceDashboardScreen extends StatefulWidget {
  final int residenceId;
  final int interSyndicId;
  const FinanceDashboardScreen({
    Key? key,
    required this.residenceId,
    required this.interSyndicId
  }) : super(key: key);

  @override
  _FinanceDashboardScreenState createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  final FinanceService _service = FinanceService();
  late Future<Map<String, dynamic>> _financesFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _financesFuture = _service.getInterSyndicFinances(widget.interSyndicId, widget.residenceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/tranche_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.4)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _financesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }
                      final data = snapshot.data ?? {};
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildKpiGrid(data),
                            const SizedBox(height: 30),
                            _buildChartsSection(data),
                            const SizedBox(height: 30),
                            _buildRecentActions(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
              const Text("Tableau de Bord Financier", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6F4A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTrancheExpenseScreen(residenceId: widget.residenceId, interSyndicId: widget.interSyndicId))).then((_) => _refresh()),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Nouvelle Dépense", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(Map<String, dynamic> data) {
    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: [
        KpiCard(
          title: 'Solde Total',
          value: '${data['solde']?.toStringAsFixed(0) ?? 0}',
          icon: Icons.account_balance_wallet,
          iconColor: Colors.blue,
          isCurrency: true,
        ),
        KpiCard(
          title: 'Total Revenus',
          value: '${data['total_revenus']?.toStringAsFixed(0) ?? 0}',
          icon: Icons.trending_up,
          iconColor: Colors.green,
          isCurrency: true,
        ),
        KpiCard(
          title: 'Total Dépenses',
          value: '${data['total_depenses']?.toStringAsFixed(0) ?? 0}',
          icon: Icons.trending_down,
          iconColor: Colors.red,
          isCurrency: true,
        ),
      ],
    );
  }

  Widget _buildChartsSection(Map<String, dynamic> data) {
    List<dynamic> depByTranche = data['depenses_par_tranche'] ?? [];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Dépenses par Tranche", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),
          if (depByTranche.isEmpty)
            const Center(child: Text("Aucune donnée à afficher"))
          else
            Column(
              children: depByTranche.map((t) {
                double total = data['total_depenses'] > 0 ? (t['montant'] / data['total_depenses']) : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(t['nom'], style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${t['montant'].toStringAsFixed(0)} DH', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Stack(
                        children: [
                          Container(height: 8, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                          FractionallySizedBox(
                            widthFactor: total.clamp(0, 1),
                            child: Container(height: 8, decoration: BoxDecoration(color: const Color(0xFFFF6F4A), borderRadius: BorderRadius.circular(4))),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Répartition par Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 15),
          Row(
            children: [
              _LegendItem(color: Color(0xFFFF6F4A), label: "Dépenses Spécifiques"),
              SizedBox(width: 20),
              _LegendItem(color: Colors.blue, label: "Dépenses Globales"),
            ],
          ),
          // Placeholder for more detailed stats
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
