import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../services/finance_service.dart';
import '../../../widgets/kpi_card.dart';
import 'add_tranche_expense_screen.dart';
import '../../../services/expense_report_pdf_service.dart';
import '../../../models/tranche_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceDashboardScreen extends StatefulWidget {
  final int residenceId;
  final int interSyndicId;
  final int? trancheId;
  const FinanceDashboardScreen({
    Key? key,
    required this.residenceId,
    required this.interSyndicId,
    this.trancheId,
  }) : super(key: key);

  @override
  _FinanceDashboardScreenState createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  final FinanceService _service = FinanceService();
  late Future<Map<String, dynamic>> _financesFuture;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _financesFuture = _service.getInterSyndicFinances(
          widget.interSyndicId, 
          widget.residenceId, 
          annee: _selectedYear,
          trancheId: widget.trancheId,
      );
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
                            _buildExpensesTable(data),
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
          Expanded(
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                const Expanded(
                  child: Text("Tableau de Bord Financier",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildYearPicker(),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6F4A),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTrancheExpenseScreen(residenceId: widget.residenceId, interSyndicId: widget.interSyndicId))).then((_) => _refresh()),
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            label: const Text("Nouvelle Dépense", style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _generatePDF(context),
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: "Générer Rapport PDF",
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePDF(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF6F4A))),
    );

    try {
      final res = await _service.getInterSyndicFinances(
        widget.interSyndicId,
        widget.residenceId,
        annee: _selectedYear,
        trancheId: widget.trancheId,
      );

      // Fetch residence and tranche names
      final db = Supabase.instance.client;
      final resData = await db.from('residences').select('nom').eq('id', widget.residenceId).single();
      String trancheNom = "Toutes les tranches";
      if (widget.trancheId != null) {
        final tData = await db.from('tranches').select('nom').eq('id', widget.trancheId!).single();
        trancheNom = tData['nom'];
      }

      final bytes = await ExpenseReportPdfService.generate(
        residenceNom: resData['nom'],
        trancheNom: trancheNom,
        annee: _selectedYear,
        financeData: res,
      );

      if (mounted) {
        Navigator.pop(context);
        await ExpenseReportPdfService.preview(bytes);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur PDF: $e")));
      }
    }
  }

  Widget _buildYearPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white30),
      ),
      child: DropdownButton<int>(
        value: _selectedYear,
        dropdownColor: const Color(0xFF2C2C2C),
        underline: const SizedBox(),
        icon: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        items: [2024, 2025, 2026, 2027].map((int y) {
          return DropdownMenuItem<int>(
            value: y,
            child: Text(y.toString()),
          );
        }).toList(),
        onChanged: (int? val) {
          if (val != null) {
            setState(() {
              _selectedYear = val;
              _refresh();
            });
          }
        },
      ),
    );
  }

  Widget _buildKpiGrid(Map<String, dynamic> data) {
    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: [
        KpiCard(
          title: 'Solde Tranche',
          value: '${data['solde']?.toStringAsFixed(0) ?? 0}',
          icon: Icons.account_balance_wallet,
          iconColor: Colors.blue,
          isCurrency: true,
        ),
        KpiCard(
          title: 'Revenus (Paiements)',
          value: '${data['total_revenus']?.toStringAsFixed(0) ?? 0}',
          icon: Icons.trending_up,
          iconColor: Colors.green,
          isCurrency: true,
        ),
        KpiCard(
          title: 'Dépenses Tranche',
          value: '${data['total_depenses']?.toStringAsFixed(0) ?? 0}',
          icon: Icons.trending_down,
          iconColor: Colors.red,
          isCurrency: true,
        ),
        KpiCard(
          title: 'Dépenses Globales',
          value: '${data['total_depenses_globales']?.toStringAsFixed(0) ?? 0}',
          icon: Icons.public,
          iconColor: Colors.orange,
          isCurrency: true,
        ),
      ],
    );
  }

  Widget _buildExpensesTable(Map<String, dynamic> data) {
    final List<dynamic> expenses = data['recent_expenses'] ?? [];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Dépenses de la Tranche",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A1A))),
              Text("$_selectedYear", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          if (expenses.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Aucune dépense enregistrée"),
            ))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                horizontalMargin: 0,
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Catégorie', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Montant', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Justificatif', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: expenses.map((e) {
                  final bool hasFacture = e['facture_path'] != null && e['facture_path'].toString().isNotEmpty;
                  return DataRow(cells: [
                    DataCell(Text(e['date'].toString())),
                    DataCell(Text(e['categorie_nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(e['description'], style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text(e['tranche'], style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      ],
                    )),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: e['type'] == 'Globale' ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(e['type'], style: TextStyle(
                        fontSize: 11,
                        color: e['type'] == 'Globale' ? Colors.blue : Colors.orange.shade800,
                        fontWeight: FontWeight.bold
                      )),
                    )),
                    DataCell(Text('${e['montant'].toStringAsFixed(0)} DH', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(
                      hasFacture
                        ? InkWell(
                            onTap: () => _showInvoicePopup(e['facture_path']),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 4),
                                Text("Oui", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                                const Icon(Icons.receipt_long, color: Color(0xFFFF6F4A), size: 14),
                              ],
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.cancel, color: Colors.grey, size: 16),
                              SizedBox(width: 4),
                              Text("Non", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          )
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (e['type'] == 'Spécifique') ...[
                            IconButton(
                              tooltip: "Modifier",
                              icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddTrancheExpenseScreen(
                                    residenceId: widget.residenceId,
                                    interSyndicId: widget.interSyndicId,
                                    expenseData: e,
                                  ),
                                ),
                              ).then((_) => _refresh()),
                            ),
                            IconButton(
                              tooltip: "Supprimer",
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              onPressed: () => _showDeleteConfirmation(e),
                            ),
                          ] else
                            const Padding(
                              padding: EdgeInsets.only(left: 12.0),
                              child: Icon(Icons.lock, size: 16, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer la dépense ?"),
        content: Text("Voulez-vous vraiment supprimer cette dépense de ${expense['montant']} DH ? Les charges des résidents seront ajustées automatiquement."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.deleteInterSyndicExpense(expense['id'], expense['montant']);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dépense supprimée avec succès')),
                  );
                }
                _refresh();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la suppression : $e')),
                  );
                }
              }
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showInvoicePopup(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: url.startsWith('http')
                      ? Image.network(
                          url,
                          loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
                          errorBuilder: (context, error, stack) => const Center(child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Text("Erreur de chargement de l'image (Réseau)"),
                          )),
                        )
                      : Image.asset(
                          'assets/images/$url',
                          errorBuilder: (context, error, stack) => Center(child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Text("Image introuvable dans assets/images/\nFichier: $url", textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                          )),
                        ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Fermer")),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(ctx),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

