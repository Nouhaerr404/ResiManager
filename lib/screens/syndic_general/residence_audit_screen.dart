import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';
import '../../services/accounting_service.dart';
import '../../widgets/nav_buttons.dart';

class ResidenceAuditScreen extends StatefulWidget {
  final int residenceId;
  final int syndicId;
  const ResidenceAuditScreen({super.key, required this.residenceId, required this.syndicId});

  @override
  State<ResidenceAuditScreen> createState() => _ResidenceAuditScreenState();
}

class _ResidenceAuditScreenState extends State<ResidenceAuditScreen> {
  final AccountingService _service = AccountingService();
  int _selectedAnnee = DateTime.now().year;
  String _searchQuery = "";

  final Color primaryOrange = const Color(0xFFFF6F4A);
  final Color darkGrey = const Color(0xFF2C2C2C);

  // Helper pour calculer les totaux de paiement sans doublons (cohérent avec le tableau)
  Map<String, double> _getPaymentStats(List payments) {
    double paye = 0;
    double du = 0;
    Map<int, List<Map<String, dynamic>>> grouped = {};
    for (var p in payments) {
      int appId = p['appartements']?['id'] ?? 0;
      grouped.putIfAbsent(appId, () => []).add(p);
    }
    for (var entry in grouped.values) {
      for (var type in ['charges', 'parking', 'garage', 'box']) {
        final match = entry.where((p) => p['type_paiement'] == type).toList();
        if (match.isNotEmpty) {
          paye += (match.first['montant_paye'] as num).toDouble();
          du += (match.first['montant_total'] as num).toDouble();
        }
      }
    }
    return {'paye': paye, 'du': du};
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isWeb = width > 900;

    return MainLayout(
      activePage: 'Audit',
      residenceId: widget.residenceId,
      syndicId: widget.syndicId,
      title: "Audit et Bilans",
      body: FutureBuilder<Map<String, dynamic>>(
        future: _service.getFullResidenceAudit(widget.residenceId, _selectedAnnee),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!;
          final List allExpenses = data['expenses'];
          final List allPayments = data['payments'];
          final List tranches = data['tranches'];

          final query = _searchQuery.toLowerCase();
          final globalExpenses = allExpenses.where((e) => e['tranches'] == null && e['categories']['nom'].toString().toLowerCase().contains(query)).toList();

          // CALCULS GLOBAUX
          final stats = _getPaymentStats(allPayments);
          double grandTotalExp = allExpenses.fold(0, (sum, e) => sum + (e['montant'] as num).toDouble());
          double grandTotalPay = stats['paye']!;
          double grandTotalDu = stats['du']!;
          double soldeGlobal = grandTotalPay - grandTotalExp;

          return ListView(
            padding: EdgeInsets.all(isWeb ? 40 : 15),
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 30),

              // 1. FRAIS GÉNÉRAUX RÉSIDENCE (CONTOUR BLEU)
              _buildGlobalAuditCard(globalExpenses),
              const SizedBox(height: 30),

              const Padding(
                padding: EdgeInsets.only(left: 5, bottom: 15),
                child: Text("BILAN PAR TRANCHE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey, letterSpacing: 1.1)),
              ),

              // 2. LISTE DES TRANCHES (CONTOUR NOIR)
              ...tranches.where((t) => t['nom'].toString().toLowerCase().contains(query)).map((t) {
                final tExp = allExpenses.where((e) => e['tranche_id'] == t['id']).toList();
                final tPay = allPayments.where((p) => p['appartements']?['immeubles']?['tranches']?['nom'] == t['nom']).toList();
                return _buildTrancheAuditCard(t['nom'], t['statut'], tExp, tPay);
              }),

              // 3. BILAN FINAL NOIR
              const SizedBox(height: 20),
              _buildGlobalSoldeCard(grandTotalExp, grandTotalPay, grandTotalDu, soldeGlobal),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  // --- COMPOSANT : CARTE DE TRANCHE ---
  Widget _buildTrancheAuditCard(String name, String? status, List expenses, List payments) {
    double totalExp = expenses.fold(0, (sum, e) => sum + (e['montant'] as num).toDouble());
    final stats = _getPaymentStats(payments);
    double totalPay = stats['paye']!;
    double totalDu = stats['du']!;
    double solde = totalPay - totalExp;

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: darkGrey.withValues(alpha: 0.2), width: 1.2), // Contour noir fin
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: primaryOrange,
          title: Row(children: [
            Text(name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: darkGrey)),
            if (status != null) ...[
              const SizedBox(width: 8),
              _buildStatusBadge(status),
            ],
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
          ]),
          subtitle: Text("Solde : ${solde.toInt()} DH (${totalPay.toInt()}/${totalDu.toInt()} payé)", style: TextStyle(color: solde >= 0 ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                _buildSubTile("Dépenses", "${totalExp.toInt()} DH", Colors.redAccent, _buildExpenseTable(expenses)),
                const SizedBox(height: 8),
                _buildSubTile("Paiements Reçus", "${totalPay.toInt()} / ${totalDu.toInt()} DH", Colors.green, _buildImmeubleGrouping(payments)),
                const Divider(height: 25),
                _buildSmallSummary(totalExp, totalPay, totalDu, solde),
              ]),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    String label = status.toLowerCase();
    if (label == 'actif' || label == 'ouverte') color = Colors.green;
    if (label == 'terminé' || label == 'cloturée') color = Colors.blue;
    if (label == 'archivé') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  // --- TABLEAU DES PAIEMENTS (APPAREMENT + BOX + FRAIS FIXES) ---
  Widget _buildPaymentTable(List data) {
    Map<int, List<Map<String, dynamic>>> groupedByApp = {};
    for (var p in data) {
      int appId = p['appartements']?['id'] ?? 0;
      if (!groupedByApp.containsKey(appId)) groupedByApp[appId] = [];
      groupedByApp[appId]!.add(p);
    }

    return LayoutBuilder(builder: (context, constraints) {
      bool isLarge = constraints.maxWidth > 800;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            columnSpacing: isLarge ? 40 : 15,
            headingRowHeight: 35,
            dataRowMinHeight: 50,
            dataRowMaxHeight: 50,
            columns: const [
              DataColumn(label: Text('APPART.', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey))),
              DataColumn(label: Text('FRAIS FIXES', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey))),
              DataColumn(label: Text('PARKING', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey))),
              DataColumn(label: Text('GARAGE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey))),
              DataColumn(label: Text('BOX', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey))),
              DataColumn(label: Text('TOTAL PAYÉ / DÛ', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey))),
            ],
            rows: groupedByApp.entries.map<DataRow>((entry) {
              final pays = entry.value;
              const types = ['charges', 'parking', 'garage', 'box'];
              double totalLignePaye = 0;
              double totalLigneDu = 0;
              for (var type in types) {
                final match = pays.where((p) => p['type_paiement'] == type).toList();
                if (match.isNotEmpty) {
                  totalLignePaye += (match.first['montant_paye'] as num).toDouble();
                  totalLigneDu += (match.first['montant_total'] as num).toDouble();
                }
              }
              bool isLigneComplete = totalLignePaye >= totalLigneDu && totalLigneDu > 0;

              return DataRow(cells: [
                DataCell(Text(pays.first['appartements']?['numero'] ?? "-", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                _buildRatioCell(pays, 'charges'),
                _buildRatioCell(pays, 'parking'),
                _buildRatioCell(pays, 'garage'),
                _buildRatioCell(pays, 'box'),
                DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLigneComplete ? Colors.green.withValues(alpha: 0.1) : primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${totalLignePaye.toInt()} / ${totalLigneDu.toInt()} DH",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isLigneComplete ? Colors.green : primaryOrange),
                      ),
                    )
                ),
              ]);
            }).toList(),
          ),
        ),
      );
    });
  }

  DataCell _buildRatioCell(List<Map<String, dynamic>> items, String type) {
    final pList = items.where((e) => e['type_paiement'] == type).toList();
    if (pList.isEmpty) return const DataCell(Center(child: Text("-", style: TextStyle(color: Colors.grey, fontSize: 9))));
    final p = pList.first;
    double mP = (p['montant_paye'] as num).toDouble();
    double mT = (p['montant_total'] as num).toDouble();
    bool ok = mP >= mT && mT > 0;
    return DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(color: ok ? Colors.green.withValues(alpha: 0.1) : primaryOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
        child: Text("${mP.toInt()}/${mT.toInt()}", style: TextStyle(fontSize: 8, color: ok ? Colors.green : primaryOrange, fontWeight: FontWeight.bold))
    ));
  }

  Widget _buildSmallSummary(double exp, double pay, double du, double solde) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text("BILAN TRANCHE (Dû: ${du.toInt()} DH)", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
      Text("${solde.toInt()} DH", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: solde >= 0 ? Colors.green : Colors.red)),
    ]);
  }

  Widget _buildGlobalSoldeCard(double totalExp, double totalPay, double totalDu, double solde) {
    bool pos = solde >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: darkGrey, borderRadius: BorderRadius.circular(15)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("BILAN GÉNÉRAL RÉSIDENCE", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          Text("Payé: ${totalPay.toInt()} / Attendu: ${totalDu.toInt()} | Sorties: -${totalExp.toInt()}", style: const TextStyle(color: Colors.white54, fontSize: 9)),
        ]),
        Text("${solde.toInt()} DH", style: TextStyle(color: pos ? Colors.greenAccent : Colors.redAccent, fontSize: 20, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Audit Financier", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        DropdownButton<int>(
          value: _selectedAnnee,
          underline: const SizedBox(),
          items: [2024, 2025, 2026].map((a) => DropdownMenuItem(value: a, child: Text("Année $a"))).toList(),
          onChanged: (v) => setState(() => _selectedAnnee = v!),
        ),
      ],
    );
  }

  Widget _buildSearchBar() { return TextField(onChanged: (v) => setState(() => _searchQuery = v), decoration: InputDecoration(hintText: "Rechercher...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)))); }
  Widget _buildGlobalAuditCard(List expenses) { double total = expenses.fold(0, (sum, e) => sum + (e['montant'] as num).toDouble()); return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1.2)), child: Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent), child: ExpansionTile(leading: const Icon(Icons.account_balance, color: Colors.blue, size: 20), title: Row(children: const [Text("Frais Généraux Résidence", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)), SizedBox(width: 8), Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.blue)]), trailing: Text("${total.toInt()} DH", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)), children: [_buildExpenseTable(expenses)]))); }
  Widget _buildImmeubleGrouping(List payments) { Map<String, List<Map<String, dynamic>>> immGroups = {}; for (var p in payments) { String iName = p['appartements']?['immeubles']?['nom'] ?? "Extérieur"; if (!immGroups.containsKey(iName)) immGroups[iName] = []; immGroups[iName]!.add(p); } return Column(children: immGroups.entries.map((e) => _buildImmeubleLevel(e.key, e.value)).toList()); }
  
  Widget _buildImmeubleLevel(String name, List<Map<String, dynamic>> data) { 
    final stats = _getPaymentStats(data);
    double immPaye = stats['paye']!;
    double immDu = stats['du']!;
    return ExpansionTile(
      leading: const Icon(Icons.keyboard_arrow_right, size: 18, color: Colors.purple), 
      title: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)), 
      trailing: Text("${immPaye.toInt()} / ${immDu.toInt()} DH", style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold)), 
      children: [_buildPaymentTable(data)]
    ); 
  }
  
  Widget _buildExpenseTable(List data) { return SizedBox(width: double.infinity, child: DataTable(columnSpacing: 15, headingRowHeight: 35, dataRowMinHeight: 40, dataRowMaxHeight: 40, columns: const [DataColumn(label: Text('CATÉGORIE', style: TextStyle(fontSize: 8))), DataColumn(label: Text('DATE', style: TextStyle(fontSize: 8))), DataColumn(label: Text('MONTANT', style: TextStyle(fontSize: 8)))], rows: data.map((e) => DataRow(cells: [DataCell(Text(e['categories']['nom'], style: const TextStyle(fontSize: 10))), DataCell(Text(e['date'], style: const TextStyle(fontSize: 10))), DataCell(Text("${e['montant']} DH", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent)))])).toList())); }
  
  Widget _buildSubTile(String title, String amountText, Color color, Widget content) { 
    return ExpansionTile(
      title: Row(children: [Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)), const SizedBox(width: 5), Icon(Icons.expand_more, size: 14, color: color)]), 
      trailing: Text(amountText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)), 
      children: [content]
    ); 
  }
}
