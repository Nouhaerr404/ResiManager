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
  final TextEditingController _searchController = TextEditingController();

  int? _selectedTrancheId;
  String trancheName = "";
  AffectationHistoryModel? _selectedMandate;
  List<AffectationHistoryModel> _availableMandates = [];
  bool _loadingMandates = false;
  String _searchQuery = "";

  // ✅ REDÉFINITION DES COULEURS (MANQUANTES DANS LA DERNIÈRE VERSION)
  final Color primaryOrange = const Color(0xFFFF6F4A);
  final Color darkGrey = const Color(0xFF2C2C2C);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

          final List<Map<String, dynamic>> tranches = snapshot.data!;

          String currentTrancheName = "Tranche";
          if (_selectedTrancheId != null) {
            try {
              final found = tranches.firstWhere((t) => (t['id'] as num).toInt() == _selectedTrancheId);
              currentTrancheName = found['nom'] ?? "Tranche";
            } catch (e) {
              currentTrancheName = "Tranche";
            }
          }

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 15, vertical: 20),
            children: [
              if (isWeb) ...[
                Text("Audit & Bilans", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C))),
                const SizedBox(height: 15),
              ],
              _buildIntroDescription(),
              const SizedBox(height: 20),

              _buildSelectors(tranches),
              const SizedBox(height: 60),

              if (_selectedMandate != null)
                _buildMandateResultView(width, currentTrancheName, isWeb)
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

  Widget _buildMandateResultView(double screenWidth, String trancheName, bool isWeb) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _service.getMandateAuditDetails(_selectedMandate!.id, _selectedTrancheId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final List<Map<String, dynamic>> expenses = List<Map<String, dynamic>>.from(snapshot.data!['expenses']);
        final List<Map<String, dynamic>> payments = List<Map<String, dynamic>>.from(snapshot.data!['payments']);
        final List<Map<String, dynamic>> apartments = List<Map<String, dynamic>>.from(snapshot.data!['apartments']);

        final query = _searchQuery.toLowerCase();
        
        final filteredApartments = _searchQuery.isEmpty 
          ? apartments 
          : apartments.where((a) {
              final immName = (a['immeubles']?['nom'] ?? "").toString().toLowerCase();
              final appNum = (a['numero'] ?? "").toString().toLowerCase();
              return immName.contains(query) || appNum.contains(query);
            }).toList();

        double totalExp = expenses.fold(0, (sum, e) => sum + (e['montant'] as num).toDouble());
        double totalPay = payments.fold(0, (sum, p) => sum + (p['montant_paye'] as num).toDouble());
        double totalDue = payments.fold(0, (sum, p) => sum + (p['montant_total'] as num).toDouble());

        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: darkGrey.withOpacity(0.15))),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              title: Row(
                children: [
                  Text(
                      trancheName.toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: isWeb ? 16 : 13, color: darkGrey)
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      "${totalPay.toInt()} / ${totalDue.toInt()} DH REÇUS",
                      style: TextStyle(fontSize: isWeb ? 12 : 10, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                "Responsable : ${_selectedMandate!.interSyndicNomComplet}",
                style: TextStyle(fontSize: isWeb ? 13 : 11, color: Colors.grey),
              ),
              children: [
                Padding(padding: const EdgeInsets.all(12), child: Column(children: [
                  _buildSubTile("Dépenses", "${totalExp.toInt()} DH", Colors.redAccent, _buildExpenseTable(expenses, isWeb), isWeb),
                  const SizedBox(height: 25),
                  
                  Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Rechercher un immeuble ou un appartement...",
                        prefixIcon: Icon(Icons.search, color: primaryOrange),
                        suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = "");
                              },
                            )
                          : null,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryOrange)),
                      ),
                    ),
                  ),

                  Align(alignment: Alignment.centerLeft, child: Text("PAIEMENTS REÇUS PAR IMMEUBLE", style: TextStyle(fontSize: isWeb ? 13 : 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                  const SizedBox(height: 10),
                  
                  _buildImmeubleGrouping(payments, filteredApartments, isWeb),
                  const Divider(height: 25),
                  _buildFinalBilanCard(totalExp, totalPay, isWeb),
                ])),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImmeubleGrouping(List<Map<String, dynamic>> payments, List<Map<String, dynamic>> apartments, bool isWeb) {
    Map<String, List<Map<String, dynamic>>> immApps = {};
    for (var app in apartments) {
      String iName = app['immeubles']?['nom'] ?? "Extérieur";
      immApps.putIfAbsent(iName, () => []).add(app);
    }

    if (immApps.isEmpty && _searchQuery.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Text("Aucun résultat pour cette recherche.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
      );
    }

    return Column(
      children: immApps.entries.map((e) {
        double immPaye = payments.where((p) => p['appartements']?['immeuble_id'] == e.value.first['immeuble_id'])
            .fold(0, (sum, p) => sum + (p['montant_paye'] as num).toDouble());

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(border: Border.all(color: Colors.purple.withOpacity(0.1)), borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            initiallyExpanded: _searchQuery.isNotEmpty, 
            leading: const Icon(Icons.keyboard_arrow_right, size: 20, color: Colors.purple),
            title: Text(e.key, style: TextStyle(fontSize: isWeb ? 14 : 12, fontWeight: FontWeight.bold, color: Colors.purple)),
            trailing: Text("${immPaye.toInt()} DH", style: TextStyle(fontSize: isWeb ? 13 : 11, fontWeight: FontWeight.bold, color: Colors.purple)),
            children: [_buildPaymentTable(payments, e.value, isWeb)],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentTable(List<Map<String, dynamic>> payments, List<Map<String, dynamic>> apartments, bool isWeb) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            columnSpacing: isWeb ? 40 : 12, 
            headingRowHeight: isWeb ? 50 : 30, 
            dataRowHeight: isWeb ? 60 : 48,
            horizontalMargin: 10,
            columns: [ _h("APP.", isWeb), _h("FIXES", isWeb), _h("PARK.", isWeb), _h("GAR.", isWeb), _h("BOX.", isWeb), _h("TOTAL", isWeb) ],
            rows: apartments.map((app) {
              final appPays = payments.where((p) => p['appartement_id'] == app['id']).toList().cast<Map<String, dynamic>>();
              double p = appPays.fold(0, (s, i) => s + (i['montant_paye'] as num).toDouble());
              double d = appPays.fold(0, (s, i) => s + (i['montant_total'] as num).toDouble());

              return DataRow(cells: [
                DataCell(Text(app['numero'] ?? "-", style: TextStyle(fontSize: isWeb ? 13 : 9, fontWeight: FontWeight.bold))),
                _buildRatioCell(appPays, 'charges', isWeb),
                _buildRatioCell(appPays, 'parking', isWeb),
                _buildRatioCell(appPays, 'garage', isWeb),
                _buildRatioCell(appPays, 'box', isWeb),
                DataCell(Center(child: Text("${p.toInt()}/${d.toInt()}", style: TextStyle(fontSize: isWeb ? 13 : 9, fontWeight: FontWeight.bold, color: p >= d && d > 0 ? Colors.green : primaryOrange)))),
              ]);
            }).toList(),
          ),
        ),
      );
    });
  }

  DataCell _buildRatioCell(List<Map<String, dynamic>> items, String type, bool isWeb) {
    final pList = items.where((e) => e['type_paiement'] == type).toList();
    if (pList.isEmpty) return DataCell(Center(child: Text("-", style: TextStyle(color: Colors.grey, fontSize: isWeb ? 12 : 9))));
    double p = pList.fold(0, (s, i) => s + (i['montant_paye'] as num).toDouble());
    double d = pList.fold(0, (s, i) => s + (i['montant_total'] as num).toDouble());
    return DataCell(Center(child: Container(padding: EdgeInsets.symmetric(horizontal: isWeb ? 8 : 4, vertical: isWeb ? 4 : 1), decoration: BoxDecoration(color: p >= d ? Colors.green.withOpacity(0.1) : primaryOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text("${p.toInt()}/${d.toInt()}", style: TextStyle(fontSize: isWeb ? 11 : 8, color: p >= d ? Colors.green : primaryOrange, fontWeight: FontWeight.bold)))));
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
            height: 1.4,
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

  DataColumn _h(String l, bool isWeb) => DataColumn(label: Expanded(child: Text(l, textAlign: TextAlign.center, style: TextStyle(fontSize: isWeb ? 12 : 8, fontWeight: FontWeight.bold, color: Colors.grey))));
  
  Widget _buildSubTile(String t, String a, Color c, Widget content, bool isWeb) { 
    return ExpansionTile(
      initiallyExpanded: true, 
      title: Row(children: [Text(t, style: TextStyle(fontSize: isWeb ? 15 : 12, color: c, fontWeight: FontWeight.bold)), const SizedBox(width: 5), Icon(Icons.expand_more, size: isWeb ? 18 : 14, color: c)]), 
      trailing: Text(a, style: TextStyle(fontSize: isWeb ? 15 : 12, fontWeight: FontWeight.bold, color: c)), 
      children: [content]
    ); 
  }

  Widget _buildExpenseTable(List<Map<String, dynamic>> data, bool isWeb) { 
    return SizedBox(
      width: double.infinity,
      child: DataTable(
        columnSpacing: isWeb ? 40 : 10, 
        headingRowHeight: isWeb ? 50 : 30,
        dataRowHeight: isWeb ? 60 : 48,
        columns: [
          DataColumn(label: Text('CATÉGORIE', style: TextStyle(fontSize: isWeb ? 12 : 8, fontWeight: FontWeight.bold))), 
          DataColumn(label: Text('DATE', style: TextStyle(fontSize: isWeb ? 12 : 8, fontWeight: FontWeight.bold))), 
          DataColumn(label: Text('MONTANT', style: TextStyle(fontSize: isWeb ? 12 : 8, fontWeight: FontWeight.bold)))
        ], 
        rows: data.map((e) => DataRow(cells: [
          DataCell(Text(e['categories']?['nom'] ?? '-', style: TextStyle(fontSize: isWeb ? 14 : 10))), 
          DataCell(Text(e['date'] ?? '-', style: TextStyle(fontSize: isWeb ? 14 : 10))), 
          DataCell(Text("${e['montant']} DH", style: TextStyle(fontSize: isWeb ? 14 : 10, fontWeight: FontWeight.bold, color: Colors.redAccent)))
        ])).toList()
      ),
    ); 
  }

  Widget _buildFinalBilanCard(double exp, double pay, bool isWeb) { 
    double solde = pay - exp; 
    return Container(
      padding: const EdgeInsets.all(20), 
      decoration: BoxDecoration(color: darkGrey, borderRadius: BorderRadius.circular(15)), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Text("SOLDE DU MANDAT", style: TextStyle(color: Colors.white70, fontSize: isWeb ? 13 : 10, fontWeight: FontWeight.bold)), 
          Text("${solde.toInt()} DH", style: TextStyle(color: solde >= 0 ? Colors.greenAccent : Colors.redAccent, fontSize: isWeb ? 24 : 18, fontWeight: FontWeight.w900))
        ]
      )
    ); 
  }
}