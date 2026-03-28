import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';
import '../../services/accounting_service.dart';
import '../../models/affectation_history_model.dart';

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
  int? _filterInterSyndicId;

  final Color primaryOrange = const Color(0xFFFF6F4A);
  final Color darkGrey = const Color(0xFF2C2C2C);

  Map<String, double> _getPaymentStats(List payments) {
    double paye = 0;
    double du = 0;
    for (var p in payments) {
      paye += (p['montant_paye'] as num).toDouble();
      du += (p['montant_total'] as num).toDouble();
    }
    return {'paye': paye, 'du': du};
  }

  String _formatDate(DateTime? d) {
    if (d == null) return "";
    return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Erreur de chargement"));
          }

          final data = snapshot.data!;
          final List allExpenses = data['expenses'] ?? [];
          final List allPayments = data['payments'] ?? [];
          final List tranches = data['tranches'] ?? [];
          
          final List<AffectationHistoryModel> history = (data['history'] as List)
              .map((h) => AffectationHistoryModel.fromJson(h))
              .toList();

          Map<int, String> syndicsMap = {};
          for (var h in history) {
            syndicsMap[h.interSyndicId] = h.interSyndicNomComplet;
          }

          final query = _searchQuery.toLowerCase();
          
          List filteredExpenses = allExpenses;
          List filteredPayments = allPayments;
          if (_filterInterSyndicId != null) {
            filteredExpenses = allExpenses.where((e) => e['inter_syndic_id'] == _filterInterSyndicId).toList();
            filteredPayments = allPayments.where((p) => p['inter_syndic_id'] == _filterInterSyndicId).toList();
          }

          final stats = _getPaymentStats(filteredPayments);
          double grandTotalExp = filteredExpenses.fold(0, (sum, e) => sum + (e['montant'] as num).toDouble());
          double grandTotalPay = stats['paye']!;
          double grandTotalDu = stats['du']!;
          double soldeGlobal = grandTotalPay - grandTotalExp;

          return ListView(
            padding: EdgeInsets.all(isWeb ? 40 : 15),
            children: [
              _buildHeader(syndicsMap),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 30),
              _buildGlobalAuditCard(filteredExpenses.where((e) => e['tranche_id'] == null).toList(), isWeb),
              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.only(left: 5, bottom: 15),
                child: Text("BILAN PAR TRANCHE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey, letterSpacing: 1.1)),
              ),
              ...tranches.where((t) => (t['nom'] ?? "").toString().toLowerCase().contains(query)).map((t) {
                final tExp = filteredExpenses.where((e) => e['tranche_id'] == t['id']).toList();
                final tPay = filteredPayments.where((p) => p['appartements']?['immeubles']?['tranche_id'] == t['id'] || (p['appartements']?['immeubles']?['tranches']?['id'] == t['id'])).toList();
                final tHist = history.where((h) => h.trancheId == t['id']).toList();
                return _buildTrancheAuditCard(t, tExp, tPay, tHist, isWeb);
              }),
              const SizedBox(height: 20),
              _buildGlobalSoldeCard(grandTotalExp, grandTotalPay, grandTotalDu, soldeGlobal),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTrancheAuditCard(Map<String, dynamic> tranche, List expenses, List payments, List<AffectationHistoryModel> history, bool isWeb) {
    final String name = tranche['nom'] ?? "Sans nom";
    final String? status = tranche['statut'];
    
    AffectationHistoryModel? current;
    try { 
      current = history.firstWhere((h) => h.isCurrent && h.trancheId == tranche['id']); 
    } catch(_) {}
    
    final String currentName = current != null ? current.interSyndicNomComplet : "Non assigné";

    final stats = _getPaymentStats(payments);
    double totalExp = expenses.fold(0, (sum, e) => sum + (e['montant'] as num).toDouble());
    double totalPay = stats['paye']!;
    double totalDu = stats['du']!;
    double solde = totalPay - totalExp;

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: darkGrey.withOpacity(0.15), width: 1.2),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          iconColor: primaryOrange,
          title: Row(children: [
            Text(name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: darkGrey)),
            if (status != null) ...[const SizedBox(width: 8), _buildStatusBadge(status)],
          ]),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Solde : ${solde.toInt()} DH (${totalPay.toInt()}/${totalDu.toInt()} payé)", style: TextStyle(color: solde >= 0 ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text("Responsable Actuel : $currentName", style: TextStyle(fontSize: 11, color: Colors.grey[700])),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                _buildSubTile("Dépenses", "${totalExp.toInt()} DH", Colors.redAccent, _buildExpenseTable(expenses, isWeb)),
                const SizedBox(height: 15),
                _buildSubTile("Paiements par Appartement", "${totalPay.toInt()} / ${totalDu.toInt()} DH", Colors.green, _buildCustomPaymentList(payments, isWeb, history)),
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
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.3))), child: Text(status.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color))); 
  }
  
  Widget _buildHeader(Map<int, String> syndics) { 
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 15,
      runSpacing: 15,
      children: [
        const Text("Audit Financier", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (syndics.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                child: DropdownButton<int?>(
                  value: _filterInterSyndicId,
                  hint: const Text("Filtrer par syndic", style: TextStyle(fontSize: 13)),
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text("Tous les syndics", style: TextStyle(fontSize: 13))),
                    ...syndics.entries.map((e) => DropdownMenuItem<int?>(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13)))),
                  ],
                  onChanged: (v) => setState(() => _filterInterSyndicId = v),
                ),
              ),
              const SizedBox(width: 15),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
              child: DropdownButton<int>(value: _selectedAnnee, underline: const SizedBox(), items: [2024, 2025, 2026].map((a) => DropdownMenuItem(value: a, child: Text("Année $a", style: const TextStyle(fontSize: 13)))).toList(), onChanged: (v) => setState(() => _selectedAnnee = v!)),
            ),
          ],
        ),
      ],
    ); 
  }

  Widget _buildSearchBar() { return TextField(onChanged: (v) => setState(() => _searchQuery = v), decoration: InputDecoration(hintText: "Rechercher une tranche...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)))); }
  
  Widget _buildGlobalAuditCard(List expenses, bool isWeb) { 
    double total = expenses.fold(0, (sum, e) => sum + (e['montant'] as num).toDouble()); 
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1.2)), 
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.account_balance, color: Colors.blue, size: 20), 
          title: const Text("Frais Généraux Résidence", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue)), 
          trailing: Text("${total.toInt()} DH", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue)), 
          children: [Padding(padding: const EdgeInsets.all(16), child: _buildExpenseTable(expenses, isWeb))]
        ),
      )
    ); 
  }
  
  Widget _buildImmeubleGrouping(List payments, bool isWeb, List<AffectationHistoryModel> history) { 
    Map<String, List<Map<String, dynamic>>> immGroups = {}; 
    for (var p in payments) { 
      String iName = p['appartements']?['immeubles']?['nom'] ?? "Extérieur"; 
      if (!immGroups.containsKey(iName)) immGroups[iName] = []; 
      immGroups[iName]!.add(p); 
    } 
    return Column(children: immGroups.entries.map((e) => _buildImmeubleLevel(e.key, e.value, isWeb, history)).toList()); 
  }
  
  Widget _buildImmeubleLevel(String name, List<Map<String, dynamic>> data, bool isWeb, List<AffectationHistoryModel> history) { 
    final stats = _getPaymentStats(data); 
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: const Icon(Icons.business, size: 18, color: Colors.purple), 
        title: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)), 
        trailing: Text("${stats['paye']!.toInt()} / ${stats['du']!.toInt()} DH", style: const TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.bold)), 
        children: [_buildCustomPaymentList(data, isWeb, history)]
      ),
    ); 
  }
  
  Widget _buildExpenseTable(List data, bool isWeb) { 
    if (data.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(10), child: Text("Aucune dépense", style: TextStyle(fontSize: 11, color: Colors.grey))));
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(scrollDirection: Axis.horizontal, child: ConstrainedBox(constraints: BoxConstraints(minWidth: constraints.maxWidth), child: DataTable(columnSpacing: isWeb ? 40 : 15, headingRowHeight: 35, columns: const [DataColumn(label: Text('CATÉGORIE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))), DataColumn(label: Text('DATE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))), DataColumn(label: Text('MONTANT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)))], rows: data.map((e) => DataRow(cells: [DataCell(Text(e['categories']?['nom'] ?? 'Inconnue', style: const TextStyle(fontSize: 11))), DataCell(Text(e['date'] ?? '-', style: const TextStyle(fontSize: 11))), DataCell(Text("${e['montant']} DH", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)))])).toList())));
    });
  }
  
  Widget _buildCustomPaymentList(List data, bool isWeb, List<AffectationHistoryModel> history) {
    Map<int, List<Map<String, dynamic>>> groupedByApp = {};
    for (var p in data) {
      int appId = p['appartements']?['id'] ?? 0;
      groupedByApp.putIfAbsent(appId, () => []).add(p);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('APPART.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600]))),
              Expanded(child: Text('FIXES', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600]))),
              Expanded(child: Text('PARK.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600]))),
              Expanded(child: Text('GAR.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600]))),
              Expanded(child: Text('BOX', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600]))),
              Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600]))),
            ],
          ),
        ),
        const Divider(height: 1),
        ...groupedByApp.entries.map((entry) {
          final pays = entry.value;
          double pPaye = pays.fold(0.0, (sum, p) => sum + (p['montant_paye'] as num).toDouble());
          double pDu = pays.fold(0.0, (sum, p) => sum + (p['montant_total'] as num).toDouble());

          // Agrégation par responsable pour cet appartement
          Map<int, Map<String, dynamic>> syndicAgg = {};
          for (var p in pays) {
            int isId = p['inter_syndic_id'];
            if (!syndicAgg.containsKey(isId)) {
              final hMatch = history.where((h) => h.interSyndicId == isId).toList();
              String sName = hMatch.isNotEmpty ? hMatch.first.interSyndicNomComplet : "Inconnu";
              syndicAgg[isId] = {'name': sName, 'total_paye': 0.0, 'details': []};
            }
            syndicAgg[isId]!['total_paye'] += (p['montant_paye'] as num).toDouble();
            syndicAgg[isId]!['details'].add(p);
          }

          return Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 15),
              title: Row(
                children: [
                  Expanded(flex: 3, child: Text(pays.first['appartements']?['numero'] ?? "-", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(child: _buildCellRatio(pays, 'charges')),
                  Expanded(child: _buildCellRatio(pays, 'parking')),
                  Expanded(child: _buildCellRatio(pays, 'garage')),
                  Expanded(child: _buildCellRatio(pays, 'box')),
                  Expanded(flex: 2, child: Text("${pPaye.toInt()}/${pDu.toInt()}", textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: pPaye >= pDu && pDu > 0 ? Colors.green : primaryOrange))),
                ],
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.only(bottom: 10, left: 15, right: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("DÉTAIL PAR RESPONSABLE :", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.1)),
                      const SizedBox(height: 12),
                      ...syndicAgg.entries.map((sEntry) {
                        final sData = sEntry.value;
                        final List sDetails = sData['details'];
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(sData['name'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  Text("TOTAL : ${sData['total_paye'].toInt()} DH", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.green)),
                                ],
                              ),
                              const Divider(height: 15),
                              ...sDetails.map((det) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("• ${det['type_paiement'].toString().toUpperCase()}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    Text("${det['montant_paye']} / ${det['montant_total']} DH", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              )).toList(),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                )
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCellRatio(List<Map<String, dynamic>> items, String type) {
    final pList = items.where((e) => e['type_paiement'] == type).toList();
    if (pList.isEmpty) return const Text("-", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 10));
    double mP = pList.fold(0.0, (sum, p) => sum + (p['montant_paye'] as num).toDouble());
    double mT = pList.fold(0.0, (sum, p) => sum + (p['montant_total'] as num).toDouble());
    bool ok = mP >= mT && mT > 0;
    return Text("${mP.toInt()}/${mT.toInt()}", textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: ok ? Colors.green : primaryOrange, fontWeight: FontWeight.w600));
  }

  Widget _buildSmallSummary(double exp, double pay, double du, double solde) { return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("TOTAL TRANCHE (Attendu: ${du.toInt()} DH)", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)), Text("${solde.toInt()} DH", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: solde >= 0 ? Colors.green : Colors.red))]); }
  Widget _buildGlobalSoldeCard(double totalExp, double totalPay, double totalDu, double solde) { return Container(padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: darkGrey, borderRadius: BorderRadius.circular(15)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("BILAN GÉNÉRAL RÉSIDENCE", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text("Payé: ${totalPay.toInt()} / Attendu: ${totalDu.toInt()} | Sorties: -${totalExp.toInt()}", style: const TextStyle(color: Colors.white54, fontSize: 11))]), Text("${solde.toInt()} DH", style: TextStyle(color: solde >= 0 ? Colors.greenAccent : Colors.redAccent, fontSize: 24, fontWeight: FontWeight.w900))])); }
  Widget _buildSubTile(String title, String amountText, Color color, Widget content) { return Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent), child: ExpansionTile(initiallyExpanded: true, title: Row(children: [Text(title, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)), const SizedBox(width: 8), Icon(Icons.expand_more, size: 16, color: color)]), trailing: Text(amountText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)), children: [content])); }
}
