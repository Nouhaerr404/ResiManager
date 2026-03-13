import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:resimanager/widgets/main_layout.dart';
import '../../services/finance_service.dart';
import '../../screens/syndic_general/add_global_expense_screen.dart';

class ResidenceFinancesScreen extends StatefulWidget {
  final int residenceId;
  const ResidenceFinancesScreen({Key? key, required this.residenceId}) : super(key: key);

  @override
  _ResidenceFinancesScreenState createState() => _ResidenceFinancesScreenState();
}

class _ResidenceFinancesScreenState extends State<ResidenceFinancesScreen> {
  final FinanceService _service = FinanceService();
  int _selectedAnnee = DateTime.now().year;
  int _selectedMois = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Finances de la Résidence',
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // BARRE D'ACTIONS ET FILTRES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildDropdown(List.generate(12, (i) => i + 1), _selectedMois, "Mois", (v) => setState(() => _selectedMois = v!)),
                    const SizedBox(width: 15),
                    _buildDropdown([2024, 2025, 2026], _selectedAnnee, "Année", (v) => setState(() => _selectedAnnee = v!)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddGlobalExpenseScreen(residenceId: widget.residenceId),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Dépense Globale", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6F4A)),
                )
              ],
            ),
            const SizedBox(height: 20),
            
            // ZONE GRAPHIQUE
            _buildChartsRow(),

            const SizedBox(height: 20),

            // TABLEAU
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _service.getResidenceExpenses(residenceId: widget.residenceId, mois: _selectedMois, annee: _selectedAnnee),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final data = snapshot.data!;
                    return SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Catégorie')),
                          DataColumn(label: Text('Périmètre')),
                          DataColumn(label: Text('Montant')),
                        ],
                        rows: data.map((d) => DataRow(cells: [
                          DataCell(Text(d['date'].toString().substring(0, 10))),
                          DataCell(Text(d['categories']['nom'])),
                          DataCell(Text(d['tranches']?['nom'] ?? 'Résidence')),
                          DataCell(Text('${d['montant']} DH', style: const TextStyle(fontWeight: FontWeight.bold))),
                        ])).toList(),
                      ),
                    );
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChartsRow() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _service.getResidenceExpenseStats(widget.residenceId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        final stats = snapshot.data!;
        if (stats.isEmpty) return Container(height: 100, child: const Center(child: Text("Aucune donnée pour les graphiques")));

        return Container(
          height: 250,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: stats.asMap().entries.map((entry) {
                      final i = entry.key;
                      final s = entry.value;
                      final colors = [Colors.blue, Colors.orange, Colors.green, Colors.red, Colors.purple, Colors.cyan];
                      return PieChartSectionData(
                        color: colors[i % colors.length],
                        value: s['amount'],
                        title: '${s['amount'].toStringAsFixed(0)}',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: stats.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.red, Colors.purple, Colors.cyan];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(width: 12, height: 12, color: colors[i % colors.length]),
                          const SizedBox(width: 8),
                          Text(s['category'], style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown(List<int> items, int current, String label, Function(int?) onChanged) {
    return DropdownButton<int>(
      value: current,
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.toString()))).toList(),
      onChanged: onChanged,
    );
  }
}