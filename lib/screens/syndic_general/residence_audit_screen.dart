import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';
import '../../services/accounting_service.dart';

class ResidenceAuditScreen extends StatefulWidget {
  final int residenceId;
  final int syndicId;
  const ResidenceAuditScreen({Key? key, required this.residenceId, required this.syndicId}) : super(key: key);

  @override
  _ResidenceAuditScreenState createState() => _ResidenceAuditScreenState();
}

class _ResidenceAuditScreenState extends State<ResidenceAuditScreen> {
  final AccountingService _service = AccountingService();
  int _selectedAnnee = DateTime.now().year;
  String _searchQuery = ""; // Valeur de recherche

  final Color primaryOrange = const Color(0xFFFF6F4A);
  final Color darkGrey = const Color(0xFF2C2C2C);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isWeb = width > 900;

    return MainLayout(
      activePage: 'Audit',
      residenceId: widget.residenceId,
      syndicId: widget.syndicId,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _service.getFullResidenceAudit(widget.residenceId, _selectedAnnee),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!;
          final List allExpenses = data['expenses'];
          final List allPayments = data['payments'];
          final List tranches = data['tranches'];

          // --- LOGIQUE DE FILTRAGE GLOBALE ---
          final query = _searchQuery.toLowerCase();

          // 1. Filtrer les dépenses globales
          final filteredGlobalExpenses = allExpenses.where((e) {
            bool isGlobal = e['tranches'] == null;
            if (!isGlobal) return false;
            return e['categories']['nom'].toString().toLowerCase().contains(query);
          }).toList();

          // 2. Filtrer les tranches
          final filteredTranches = tranches.where((t) {
            String tName = t['nom'].toString().toLowerCase();
            // Une tranche reste si son nom correspond OU si un de ses résidents correspond
            bool trancheMatches = tName.contains(query);
            bool residentInTrancheMatches = allPayments.any((p) =>
            p['appartements']?['immeubles']?['tranches']?['nom'] == t['nom'] &&
                p['resident']['nom'].toString().toLowerCase().contains(query));

            return trancheMatches || residentInTrancheMatches;
          }).toList();

          return ListView(
            padding: EdgeInsets.all(isWeb ? 40 : 15),
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSearchBar(), // NOUVELLE BARRE DE RECHERCHE
              const SizedBox(height: 30),

              // SECTION FRAIS GÉNÉRAUX (Visible seulement si on ne cherche pas un résident précis ou si le nom correspond)
              if (filteredGlobalExpenses.isNotEmpty) ...[
                _buildGlobalAuditCard(filteredGlobalExpenses),
                const SizedBox(height: 30),
              ],

              const Padding(
                padding: EdgeInsets.only(left: 5, bottom: 15),
                child: Text("BILAN PAR TRANCHE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey, letterSpacing: 1.1)),
              ),

              ...filteredTranches.map((t) {
                final tExp = allExpenses.where((e) => e['tranche_id'] == t['id']).toList();
                // Filtrer les paiements de la tranche selon la recherche
                final tPay = allPayments.where((p) {
                  bool isThisTranche = p['appartements']?['immeubles']?['tranches']?['nom'] == t['nom'];
                  bool matchesQuery = p['resident']['nom'].toString().toLowerCase().contains(query) ||
                      t['nom'].toString().toLowerCase().contains(query);
                  return isThisTranche && matchesQuery;
                }).toList();

                return _buildTrancheAuditCard(t['nom'], tExp, tPay);
              }).toList(),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  // --- HEADER SANS BOUTONS NAVIGATION ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Audit Financier", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        DropdownButton<int>(
          value: _selectedAnnee,
          underline: const SizedBox(),
          items: [2024, 2025, 2026].map((a) => DropdownMenuItem(value: a, child: Text("Année $a"))).toList(),
          onChanged: (v) => setState(() => _selectedAnnee = v!),
        ),
      ],
    );
  }

  // --- BARRE DE RECHERCHE ---
  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: "Rechercher une tranche, un résident, une catégorie...",
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }

  // --- LES CARTES ET TABLEAUX (Gardent le même style optimisé) ---
  Widget _buildGlobalAuditCard(List expenses) {
    double total = expenses.fold(0, (sum, e) => sum + (e['montant'] as num).toDouble());
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.2)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.account_balance, color: Colors.blue, size: 20),
          title: const Text("Frais Généraux Résidence", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
          trailing: Text("${total.toInt()} DH", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          children: [_buildExpenseTable(expenses)],
        ),
      ),
    );
  }

  Widget _buildTrancheAuditCard(String name, List expenses, List payments) {
    double totalExp = expenses.fold(0, (sum, e) => sum + (e['montant'] as num).toDouble());
    double totalPay = payments.fold(0, (sum, p) => sum + (p['montant_paye'] as num).toDouble());
    double solde = totalPay - totalExp;

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: darkGrey.withOpacity(0.2), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: primaryOrange,
          title: Text(name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: darkGrey)),
          subtitle: Text("Solde : ${solde.toInt()} DH", style: TextStyle(color: solde >= 0 ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildSubTile("Dépenses", totalExp, Colors.redAccent, _buildExpenseTable(expenses)),
                  const SizedBox(height: 8),
                  _buildSubTile("Paiements Reçus", totalPay, Colors.green, _buildImmeubleGrouping(payments)),
                  const Divider(height: 20),
                  _buildSmallSummary(totalExp, totalPay, solde),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- REPRENDS TES AUTRES FONCTIONS (_buildImmeubleGrouping, _buildExpenseTable, etc.) ICI ---
  // Elles restent identiques car elles sont déjà parfaites.

  Widget _buildImmeubleGrouping(List payments) {
    Map<String, List<Map<String, dynamic>>> immGroups = {};
    for (var p in payments) {
      String iName = p['appartements']?['immeubles']?['nom'] ?? "Extérieur";
      if (!immGroups.containsKey(iName)) immGroups[iName] = [];
      immGroups[iName]!.add(p);
    }
    return Column(children: immGroups.entries.map((e) => _buildImmeubleLevel(e.key, e.value)).toList());
  }

  Widget _buildImmeubleLevel(String name, List<Map<String, dynamic>> data) {
    double immTotal = data.fold(0, (sum, p) => sum + (p['montant_paye'] as num).toDouble());
    return ExpansionTile(
      title: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
      trailing: Text("${immTotal.toInt()} DH", style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold)),
      children: [_buildPaymentTable(data)],
    );
  }

  Widget _buildPaymentTable(List data) {
    Map<int, List<Map<String, dynamic>>> grouped = {};
    for (var p in data) {
      int rId = p['resident']?['id'] ?? 0;
      if (!grouped.containsKey(rId)) grouped[rId] = [];
      grouped[rId]!.add(p);
    }
    return LayoutBuilder(builder: (context, constraints) {
      bool isLarge = constraints.maxWidth > 800;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            columnSpacing: isLarge ? (constraints.maxWidth / 10) : 20,
            headingRowHeight: 30, dataRowHeight: 45,
            columns: const [
              DataColumn(label: Text('RÉSIDENT', style: TextStyle(fontSize: 8))),
              DataColumn(label: Text('APP.', style: TextStyle(fontSize: 8))),
              DataColumn(label: Text('PARKING', style: TextStyle(fontSize: 8))),
              DataColumn(label: Text('GARAGE', style: TextStyle(fontSize: 8))),
              DataColumn(label: Text('TOTAL', style: TextStyle(fontSize: 8))),
            ],
            rows: grouped.entries.map((entry) {
              final pays = entry.value;
              return DataRow(cells: [
                DataCell(Text("${pays.first['resident']['nom']}", style: const TextStyle(fontSize: 10))),
                _buildRatioCell(pays, 'charges', sub: pays.first['appartements']?['numero'] ?? "-"),
                _buildRatioCell(pays, 'parking'),
                _buildRatioCell(pays, 'garage'),
                DataCell(Text("${pays.fold(0, (s, p) => s + (p['montant_paye'] as num).toInt())} DH", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              ]);
            }).toList(),
          ),
        ),
      );
    });
  }

  Widget _buildExpenseTable(List data) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isLarge = constraints.maxWidth > 800;
      return ConstrainedBox(
        constraints: BoxConstraints(minWidth: constraints.maxWidth),
        child: DataTable(
          columnSpacing: isLarge ? (constraints.maxWidth / 5) : 20,
          headingRowHeight: 30, dataRowHeight: 40,
          columns: const [
            DataColumn(label: Text('CATÉGORIE', style: TextStyle(fontSize: 8))),
            DataColumn(label: Text('DATE', style: TextStyle(fontSize: 8))),
            DataColumn(label: Text('MONTANT', style: TextStyle(fontSize: 8))),
          ],
          rows: data.map((e) => DataRow(cells: [
            DataCell(Text(e['categories']['nom'], style: const TextStyle(fontSize: 10))),
            DataCell(Text(e['date'], style: const TextStyle(fontSize: 10))),
            DataCell(Text("${e['montant']} DH", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent))),
          ])).toList(),
        ),
      );
    });
  }

  Widget _buildSubTile(String title, double amount, Color color, Widget content) {
    return ExpansionTile(
      title: Row(children: [Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)), const SizedBox(width: 5), Icon(Icons.expand_more, size: 14, color: color)]),
      trailing: Text("${amount.toInt()} DH", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      children: [content],
    );
  }

  DataCell _buildRatioCell(List<Map<String, dynamic>> items, String type, {String sub = ""}) {
    final pList = items.where((e) => e['type_paiement'] == type).toList();
    if (pList.isEmpty) return const DataCell(Center(child: Text("-", style: TextStyle(color: Colors.grey, fontSize: 9))));
    final p = pList.first;
    double mP = (p['montant_paye'] as num).toDouble();
    double mT = (p['montant_total'] as num).toDouble();
    bool ok = mP >= mT;
    return DataCell(Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (sub.isNotEmpty) Text(sub, style: const TextStyle(fontSize: 7, color: Colors.grey)),
      Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: ok ? Colors.green.withOpacity(0.1) : primaryOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text("${mP.toInt()}/${mT.toInt()}", style: TextStyle(fontSize: 8, color: ok ? Colors.green : primaryOrange, fontWeight: FontWeight.bold))),
    ]));
  }

  Widget _buildSmallSummary(double exp, double pay, double solde) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("BILAN FINAL TRANCHE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text("${solde.toInt()} DH", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: solde >= 0 ? Colors.green : Colors.red)),
      ]),
    );
  }

  Widget _buildGlobalSoldeCard(double totalExp, double totalPay, double solde) {
    bool pos = solde >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: darkGrey, borderRadius: BorderRadius.circular(15)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("BILAN GÉNÉRAL RÉSIDENCE", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text("Entrées: +${totalPay.toInt()} | Sorties: -${totalExp.toInt()}", style: const TextStyle(color: Colors.white54, fontSize: 9)),
        ]),
        Text("${solde.toInt()} DH", style: TextStyle(color: pos ? Colors.greenAccent : Colors.redAccent, fontSize: 20, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}