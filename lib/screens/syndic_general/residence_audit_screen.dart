import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';
import '../../services/accounting_service.dart';
import '../../models/affectation_history_model.dart';
import '../../widgets/nav_buttons.dart';

class ResidenceAuditScreen extends StatefulWidget {
  final int residenceId;
  final int syndicId;
  const ResidenceAuditScreen({Key? key, required this.residenceId, required this.syndicId}) : super(key: key);

  @override
  _ResidenceAuditScreenState createState() => _ResidenceAuditScreenState();
}

class _ResidenceAuditScreenState extends State<ResidenceAuditScreen> {
  final AccountingService _service = AccountingService();

  int? _selectedTrancheId;
  String trancheName = "";
  AffectationHistoryModel? _selectedMandate;
  List<AffectationHistoryModel> _availableMandates = [];
  bool _loadingMandates = false;
  String _searchQuery = "";

  final Color primaryOrange = const Color(0xFFFF6F4A);
  final Color darkGrey = const Color(0xFF2C2C2C);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isWeb = width > 900;

    return MainLayout(
      title: 'Audit & Bilans',
      activePage: 'Audit',
      residenceId: widget.residenceId, syndicId: widget.syndicId,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _service.getTranchesList(widget.residenceId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // 1. On récupère la liste des tranches
          final List<Map<String, dynamic>> tranches = snapshot.data!;

          // 2. LOGIQUE POUR RÉCUPÉRER LE NOM (Une seule fois, proprement)
          String currentTrancheName = "Tranche";
          if (_selectedTrancheId != null) {
            try {
              // On cherche dans la liste l'élément qui a le bon ID
              final found = tranches.firstWhere((t) => (t['id'] as num).toInt() == _selectedTrancheId);
              currentTrancheName = found['nom'] ?? "Tranche";
            } catch (e) {
              currentTrancheName = "Tranche";
            }
          }

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 15, vertical: 20),
            children: [
              Text("Audit & Bilans",style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkGrey)),
              const SizedBox(height: 15),
              _buildIntroDescription(),
              const SizedBox(height: 20),

              _buildSelectors(tranches),
              const SizedBox(height: 60),

              if (_selectedMandate != null)
                _buildMandateResultView(width, currentTrancheName) // ON ENVOIE LE NOM ICI
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelectors(List tranches) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: darkGrey.withOpacity(0.1))),
      child: Column(children: [
        DropdownButtonFormField<int>(
          value: _selectedTrancheId,
          hint: const Text("1. Sélectionner une Tranche"),
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: tranches.map((t) => DropdownMenuItem<int>(value: t['id'], child: Text(t['nom']))).toList(),
          onChanged: (val) async {
            setState(() { _selectedTrancheId = val; _selectedMandate = null; _loadingMandates = true; });
            final m = await _service.getMandates(val!);
            setState(() { _availableMandates = m; _loadingMandates = false; });
          },
        ),
        if (_selectedTrancheId != null) ...[
          const SizedBox(height: 15),
          _loadingMandates ? const LinearProgressIndicator() : DropdownButtonFormField<AffectationHistoryModel>(
            value: _selectedMandate,
            isExpanded: true,
            hint: const Text("2. Sélectionner le Mandat"),
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: _availableMandates.map((m) => DropdownMenuItem(value: m, child: Text("${m.interSyndicNomComplet} (${m.label})", style: const TextStyle(fontSize: 11)))).toList(),
            onChanged: (val) => setState(() => _selectedMandate = val),
          ),
        ]
      ]),
    );
  }

  Widget _buildMandateResultView(double screenWidth, String trancheName) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _service.getMandateAuditDetails(_selectedMandate!.id, _selectedTrancheId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final List<Map<String, dynamic>> expenses = List<Map<String, dynamic>>.from(snapshot.data!['expenses']);
        final List<Map<String, dynamic>> payments = List<Map<String, dynamic>>.from(snapshot.data!['payments']);
        final List<Map<String, dynamic>> apartments = List<Map<String, dynamic>>.from(snapshot.data!['apartments']);

        final query = _searchQuery.toLowerCase();
        final filteredApartments = apartments.where((a) => a['numero'].toString().toLowerCase().contains(query)).toList();

        double totalExp = expenses.fold(0, (sum, e) => sum + (e['montant'] as num).toDouble());
        double totalPay = payments.fold(0, (sum, p) => sum + (p['montant_paye'] as num).toDouble());

        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: darkGrey.withOpacity(0.15))),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              title: Text(
                  trancheName.toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: darkGrey)
              ),
              subtitle: Text(
                "Responsable : ${_selectedMandate!.interSyndicNomComplet}",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              children: [
                Padding(padding: const EdgeInsets.all(12), child: Column(children: [
                  _buildSubTile("Dépenses", "${totalExp.toInt()} DH", Colors.redAccent, _buildExpenseTable(expenses)),
                  const SizedBox(height: 15),
                  const Align(alignment: Alignment.centerLeft, child: Text("PAIEMENTS REÇUS PAR IMMEUBLE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                  const SizedBox(height: 10),
                  _buildImmeubleGrouping(payments, filteredApartments, screenWidth),
                  const Divider(height: 25),
                  _buildFinalBilanCard(totalExp, totalPay),
                ])),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- LOGIQUE IMMEUBLE ---
  Widget _buildImmeubleGrouping(List<Map<String, dynamic>> payments, List<Map<String, dynamic>> apartments, double screenWidth) {
    Map<String, List<Map<String, dynamic>>> immApps = {};
    for (var app in apartments) {
      String iName = app['immeubles']?['nom'] ?? "Extérieur";
      immApps.putIfAbsent(iName, () => []).add(app);
    }

    return Column(
      children: immApps.entries.map((e) {
        double immPaye = payments.where((p) => p['appartements']?['immeuble_id'] == e.value.first['immeuble_id'])
            .fold(0, (sum, p) => sum + (p['montant_paye'] as num).toDouble());

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(border: Border.all(color: Colors.purple.withOpacity(0.1)), borderRadius: BorderRadius.circular(10)),
          child: ExpansionTile(
            leading: const Icon(Icons.keyboard_arrow_right, size: 18, color: Colors.purple),
            title: Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
            trailing: Text("${immPaye.toInt()} DH", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple)),
            children: [_buildPaymentTable(payments, e.value, screenWidth)],
          ),
        );
      }).toList(),
    );
  }

  // --- TABLEAU APPARTEMENTS (CORRECTION DES ERREURS DE TYPE) ---
  Widget _buildPaymentTable(List<Map<String, dynamic>> payments, List<Map<String, dynamic>> apartments, double screenWidth) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            columnSpacing: 12, headingRowHeight: 30, horizontalMargin: 10,
            columns: [ _h("APP."), _h("FIXES"), _h("PARK."), _h("GAR."), _h("BOX."), _h("TOTAL") ],
            rows: apartments.map((app) {
              final appPays = payments.where((p) => p['appartement_id'] == app['id']).toList().cast<Map<String, dynamic>>(); // CAST ICI
              double p = appPays.fold(0, (s, i) => s + (i['montant_paye'] as num).toDouble());
              double d = appPays.fold(0, (s, i) => s + (i['montant_total'] as num).toDouble());

              return DataRow(cells: [
                DataCell(Text(app['numero'] ?? "-", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                _buildRatioCell(appPays, 'charges'),
                _buildRatioCell(appPays, 'parking'),
                _buildRatioCell(appPays, 'garage'),
                _buildRatioCell(appPays, 'box'),
                DataCell(Center(child: Text("${p.toInt()}/${d.toInt()}", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: p >= d && d > 0 ? Colors.green : primaryOrange)))),
              ]);
            }).toList(),
          ),
        ),
      );
    });
  }

  // --- HELPERS ---
  DataCell _buildRatioCell(List<Map<String, dynamic>> items, String type) {
    final pList = items.where((e) => e['type_paiement'] == type).toList();
    if (pList.isEmpty) return const DataCell(Center(child: Text("-", style: TextStyle(color: Colors.grey, fontSize: 9))));
    double p = pList.fold(0, (s, i) => s + (i['montant_paye'] as num).toDouble());
    double d = pList.fold(0, (s, i) => s + (i['montant_total'] as num).toDouble());
    return DataCell(Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: p >= d ? Colors.green.withOpacity(0.1) : primaryOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text("${p.toInt()}/${d.toInt()}", style: TextStyle(fontSize: 8, color: p >= d ? Colors.green : primaryOrange, fontWeight: FontWeight.bold)))));
  }

  Widget _buildIntroDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Consultez l'historique financier et les performances de collecte de votre résidence.",
          style: TextStyle(
            fontSize: 14,
            color: darkGrey.withOpacity(0.7),
            fontWeight: FontWeight.w400,
            height: 1.4, // Donne de l'espace entre les lignes
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          "Sélectionnez une tranche et un mandat pour voir les détails.",
          style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontStyle: FontStyle.italic
          ),
        ),
      ],
    );
  }

  DataColumn _h(String l) => DataColumn(label: Expanded(child: Text(l, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey))));
  Widget _buildSubTile(String t, String a, Color c, Widget content) { return ExpansionTile(initiallyExpanded: true, title: Row(children: [Text(t, style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.bold)), const SizedBox(width: 5), Icon(Icons.expand_more, size: 14, color: c)]), trailing: Text(a, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c)), children: [content]); }
  Widget _buildExpenseTable(List<Map<String, dynamic>> data) { return DataTable(columnSpacing: 10, headingRowHeight: 30, columns: const [DataColumn(label: Text('CATÉGORIE', style: TextStyle(fontSize: 8))), DataColumn(label: Text('DATE', style: TextStyle(fontSize: 8))), DataColumn(label: Text('MONTANT', style: TextStyle(fontSize: 8)))], rows: data.map((e) => DataRow(cells: [DataCell(Text(e['categories']?['nom'] ?? '-', style: const TextStyle(fontSize: 10))), DataCell(Text(e['date'] ?? '-', style: const TextStyle(fontSize: 10))), DataCell(Text("${e['montant']} DH", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent)))])).toList()); }
  Widget _buildFinalBilanCard(double exp, double pay) { double solde = pay - exp; return Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: darkGrey, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("SOLDE DU MANDAT", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)), Text("${solde.toInt()} DH", style: TextStyle(color: solde >= 0 ? Colors.greenAccent : Colors.redAccent, fontSize: 18, fontWeight: FontWeight.w900))])); }
}
