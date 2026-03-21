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
      title: "Audit et Bilans",
      body: FutureBuilder<Map<String, dynamic>>(
        future: _service.getFullResidenceAudit(widget.residenceId, _selectedAnnee),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!;
          final List allExpenses = data['expenses'];
          final List allPayments = data['payments'];
          final List tranches = data['tranches'];
          final globalExpenses = allExpenses.where((e) => e['tranches'] == null).toList();

          double grandTotalExpenses = allExpenses.fold(0, (sum, e) => sum + (e['montant'] as num).toDouble());
          double grandTotalPayments = allPayments.fold(0, (sum, p) => sum + (p['montant_paye'] as num).toDouble());
          double soldeGlobal = grandTotalPayments - grandTotalExpenses;

          return ListView(
            padding: EdgeInsets.all(isWeb ? 40 : 20),
            children: [
              _buildHeader(isWeb),
              const SizedBox(height: 30),

              _buildGlobalAuditCard(globalExpenses),
              const SizedBox(height: 25),

              const Padding(
                padding: EdgeInsets.only(left: 5, bottom: 10),
                child: Text("BILAN PAR TRANCHE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey, letterSpacing: 1.1)),
              ),

              ...tranches.map((t) {
                final tExp = allExpenses.where((e) => e['tranche_id'] == t['id']).toList();
                final tPay = allPayments.where((p) => p['appartements']?['immeubles']?['tranches']?['nom'] == t['nom']).toList();
                return _buildTrancheAuditCard(t['nom'], tExp, tPay);
              }).toList(),

              const SizedBox(height: 20),
              const Divider(),
              _buildGlobalSoldeCard(grandTotalExpenses, grandTotalPayments, soldeGlobal),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isWeb) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DropdownButton<int>(
          value: _selectedAnnee,
          underline: const SizedBox(),
          style: TextStyle(color: darkGrey, fontWeight: FontWeight.bold, fontSize: 14),
          items: [2024, 2025, 2026].map((a) => DropdownMenuItem(value: a, child: Text("Année $a"))).toList(),
          onChanged: (v) => setState(() => _selectedAnnee = v!),
        ),
      ],
    );
  }

  // --- DESIGN COMPACT POUR LES DÉPENSES GLOBALES ---
  Widget _buildGlobalAuditCard(List expenses) {
    double total = expenses.fold(0, (sum, e) => sum + (e['montant'] as num).toDouble());
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.account_balance, color: Colors.blue, size: 20),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text("Frais Généraux Résidence", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.blue),
          ],
        ),
        trailing: Text("${total.toInt()} DH", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        children: [_buildExpenseTable(expenses)],
      ),
    );
  }

  // --- DESIGN COMPACT POUR LES TRANCHES ---
  Widget _buildTrancheAuditCard(String name, List expenses, List payments) {
    double totalExp = expenses.fold(0, (sum, e) => sum + (e['montant'] as num).toDouble());
    double totalPay = payments.fold(0, (sum, p) => sum + (p['montant_paye'] as num).toDouble());
    double solde = totalPay - totalExp;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: ExpansionTile(
        iconColor: primaryOrange,
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text("Solde : ${solde.toInt()} DH",
            style: TextStyle(color: solde >= 0 ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                _buildSubTile("Dépenses", totalExp, Colors.redAccent, _buildExpenseTable(expenses)),
                _buildSubTile("Paiements Reçus", totalPay, Colors.green, _buildPaymentTable(payments)),
                const Divider(),
                _buildSmallSummary(totalExp, totalPay, solde),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSubTile(String title, double amount, Color color, Widget content) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        visualDensity: VisualDensity.compact,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
            const SizedBox(width: 6),
            Icon(Icons.expand_more_rounded, size: 14, color: color.withOpacity(0.7)),
          ],
        ),
        trailing: Text("${amount.toInt()} DH", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        children: [content],
      ),
    );
  }

  Widget _buildExpenseTable(List data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 10),
      child: DataTable(
        headingRowHeight: 35,
        dataRowHeight: 40,
        columnSpacing: 15,
        columns: const [
          DataColumn(label: Text('CATÉGORIE', style: TextStyle(fontSize: 10, color: Colors.grey))),
          DataColumn(label: Text('DATE', style: TextStyle(fontSize: 10, color: Colors.grey))),
          DataColumn(label: Text('MONTANT', style: TextStyle(fontSize: 10, color: Colors.grey))),
        ],
        rows: data.map((e) => DataRow(cells: [
          DataCell(Text(e['categories']['nom'], style: const TextStyle(fontSize: 11))),
          DataCell(Text(e['date'], style: const TextStyle(fontSize: 11))),
          DataCell(Text("${e['montant']} DH", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        ])).toList(),
      ),
    );
  }

  Widget _buildPaymentTable(List data) {
    // 1. On regroupe les paiements par Résident pour n'avoir qu'une ligne par personne
    Map<int, List<Map<String, dynamic>>> groupedByResident = {};
    for (var p in data) {
      int rId = p['resident']?['id'] ?? 0;
      if (!groupedByResident.containsKey(rId)) groupedByResident[rId] = [];
      groupedByResident[rId]!.add(p);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Indispensable pour voir toutes les colonnes sur mobile
        child: DataTable(
          headingRowHeight: 35,
          dataRowHeight: 50,
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('RÉSIDENT', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('APP.', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('PARKING', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('GARAGE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('BOX', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('TOTAL PAYÉ', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))),
          ],
          rows: groupedByResident.entries.map((entry) {
            final payments = entry.value;
            final first = payments.first;

            // Nom Complet
            String fullName = "${first['resident']?['prenom'] ?? ''} ${first['resident']?['nom'] ?? 'Inconnu'}";
            String appNum = first['appartements']?['numero'] ?? "-";

            // Calcul du total payé pour ce résident (toutes catégories confondues)
            double rowTotal = payments.fold(0, (sum, p) => sum + (p['montant_paye'] as num).toDouble());

            return DataRow(cells: [
              DataCell(Text(fullName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
              _buildRatioCell(payments, 'charges', sub: appNum), // Colonne Appartement
              _buildRatioCell(payments, 'parking'),             // Colonne Parking
              _buildRatioCell(payments, 'garage'),              // Colonne Garage
              _buildRatioCell(payments, 'box'),                 // Colonne Box
              DataCell(Text("${rowTotal.toInt()} DH", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // --- HELPER POUR LES CELLULES AVEC BADGE CORAIL ---
  DataCell _buildRatioCell(List<Map<String, dynamic>> items, String type, {String sub = ""}) {
    // On cherche s'il existe un paiement de ce type pour ce résident
    final pList = items.where((e) => e['type_paiement'] == type).toList();

    if (pList.isEmpty) {
      return const DataCell(Center(child: Text("-", style: TextStyle(color: Colors.grey, fontSize: 11))));
    }

    final p = pList.first;
    double paye = (p['montant_paye'] as num).toDouble();
    double total = (p['montant_total'] as num).toDouble();
    bool isOk = paye >= total;

    return DataCell(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (sub.isNotEmpty)
            Text(sub, style: const TextStyle(fontSize: 8, color: Colors.grey)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOk ? Colors.green.withOpacity(0.1) : primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "${paye.toInt()}/${total.toInt()}",
              style: TextStyle(
                  fontSize: 10,
                  color: isOk ? Colors.green : primaryOrange,
                  fontWeight: FontWeight.bold
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSmallSummary(double exp, double pay, double solde) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("BILAN DÉFINITIF", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          Text("${solde.toInt()} DH", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: solde >= 0 ? Colors.green : Colors.red)),
        ],
      ),
    );
  }

  Widget _buildGlobalSoldeCard(double totalExp, double totalPay, double solde) {
    bool isPositive = solde >= 0;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkGrey,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("BILAN GÉNÉRAL RÉSIDENCE",
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              Icon(isPositive ? Icons.account_balance_wallet : Icons.warning_amber_rounded,
                  color: isPositive ? Colors.greenAccent : Colors.redAccent, size: 18),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _miniTotalLabel("Dépenses (Sorties)", "- ${totalExp.toInt()} DH"),
                  const SizedBox(height: 4),
                  _miniTotalLabel("Paiements (Entrées)", "+ ${totalPay.toInt()} DH"),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("SOLDE NET", style: TextStyle(color: Colors.white60, fontSize: 9)),
                  Text(
                    "${solde.toInt()} DH",
                    style: TextStyle(
                        color: isPositive ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.w900
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniTotalLabel(String label, String value) {
    return Text(
      "$label : $value",
      style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w400),
    );
  }
}
