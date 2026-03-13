// lib/screens/inter_syndic/finance/finance_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/finance_service.dart';
import '../../../widgets/kpi_card.dart';
import 'add_tranche_expense_screen.dart';
import 'manage_categories_screen.dart';

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

  void _editExpense(Map<String, dynamic> expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTrancheExpenseScreen(
          residenceId: widget.residenceId,
          interSyndicId: widget.interSyndicId,
          expense: expense,
        ),
      ),
    ).then((_) => _refresh());
  }

  void _deleteExpense(Map<String, dynamic> expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer la dépense"),
        content: const Text("Êtes-vous sûr de vouloir supprimer cette dépense ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          TextButton(
            onPressed: () async {
              try {
                await _service.deleteInterSyndicExpense(
                  expenseId: expense['id'],
                  montant: double.parse(expense['montant'].toString()),
                  trancheId: expense['tranche_id'],
                );
                Navigator.pop(context);
                _refresh();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
              }
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
                            _buildChartsRow(data),
                            const SizedBox(height: 30),
                            _buildRecentActionsList(),
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
              const Text("Finances des Tranches", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCategoriesScreen())),
                icon: const Icon(Icons.settings, color: Colors.white, size: 18),
                label: const Text("Catégories", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6F4A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTrancheExpenseScreen(residenceId: widget.residenceId, interSyndicId: widget.interSyndicId))).then((_) => _refresh()),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Dépense Tranche", style: TextStyle(color: Colors.white)),
              ),
            ],
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
          title: 'Budget Restant',
          value: '${data['solde']?.toStringAsFixed(0) ?? 0}',
          icon: Icons.account_balance_wallet,
          iconColor: Colors.blue,
          isCurrency: true,
        ),
        KpiCard(
          title: 'Total Budget (Dotation)',
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

  Widget _buildChartsRow(Map<String, dynamic> data) {
    List<dynamic> depByTranche = data['depenses_par_tranche'] ?? [];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Répartition du Budget par Tranche", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),
          if (depByTranche.isEmpty)
            const Center(child: Text("Aucune donnée à afficher"))
          else
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 150,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        sections: depByTranche.asMap().entries.map((entry) {
                          final i = entry.key;
                          final t = entry.value;
                          final colors = [Colors.blue, Colors.orange, Colors.green, Colors.red, Colors.purple, Colors.cyan];
                          return PieChartSectionData(
                            color: colors[i % colors.length],
                            value: t['montant'] > 0 ? t['montant'] : 1, // fallback to 1 for visual
                            title: '',
                            radius: 40,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: depByTranche.map((t) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(t['nom'], style: const TextStyle(fontSize: 12)),
                            Text('${t['montant'].toStringAsFixed(0)} DH', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRecentActionsList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Dernières Dépenses (Spécifiques & Diffusées)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 15),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _service.getInterSyndicRecentExpenses(widget.interSyndicId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final expenses = snapshot.data!;
              if (expenses.isEmpty) return const Center(child: Text("Aucune dépense enregistrée"));

              return Column(
                children: expenses.map((e) {
                  bool isDiffused = e['description']?.toString().contains('réf: #') ?? false;
                  bool isEditable = e['inter_syndic_id'] != null;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: isDiffused ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      child: Icon(isDiffused ? Icons.share : Icons.receipt_long, color: isDiffused ? Colors.blue : Colors.orange, size: 20),
                    ),
                    title: Text(e['categories']?['nom'] ?? 'Sans Catégorie', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${e['tranches']?['nom']} • ${e['date'].toString().substring(0, 10)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${e['montant']} DH', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        if (isEditable) ...[
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                            onPressed: () => _editExpense(e),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            onPressed: () => _deleteExpense(e),
                          ),
                        ]
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
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
