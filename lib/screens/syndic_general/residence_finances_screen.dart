import 'package:flutter/material.dart';
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

  void _showAddExpenseDialog() async {
    final cats = await _service.getCategories('globale');
    final montantController = TextEditingController();
    int? selectedCatId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter une dépense globale"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: montantController, decoration: const InputDecoration(labelText: "Montant (DH)"), keyboardType: TextInputType.number),
            DropdownButtonFormField<int>(
              items: cats.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['nom']))).toList(),
              onChanged: (val) => selectedCatId = val,
              decoration: const InputDecoration(labelText: "Catégorie"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              if (selectedCatId != null && montantController.text.isNotEmpty) {
                await _service.addGlobalExpense(
                  residenceId: widget.residenceId,
                  montant: double.parse(montantController.text),
                  categorieId: selectedCatId!,
                  date: DateTime.now(),
                  syndicId: 1, // À remplacer par l'ID de l'user connecté
                );
                Navigator.pop(context);
                setState(() {}); // Rafraîchir le tableau
              }
            },
            child: const Text("Enregistrer"),
          )
        ],
      ),
    );
  }

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
                    ).then((_) {
                      setState(() {
                      });
                    });
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Dépense Globale", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6F4A)),
                )
              ],
            ),
            const SizedBox(height: 20),
            // TABLEAU
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
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

  Widget _buildDropdown(List<int> items, int current, String label, Function(int?) onChanged) {
    return DropdownButton<int>(
      value: current,
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.toString()))).toList(),
      onChanged: onChanged,
    );
  }
}