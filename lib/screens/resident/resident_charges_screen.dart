import 'package:flutter/material.dart';
import '../../services/resident_service.dart';
import 'resident_dashboard_screen.dart';

class ResidentChargesScreen extends StatefulWidget {
  final int userId;
  final Function(int)? onNavigate; // ← AJOUT
  const ResidentChargesScreen({
    super.key,
    this.userId = 3,
    this.onNavigate,
  });

  @override
  _ResidentChargesScreenState createState() => _ResidentChargesScreenState();
}

class _ResidentChargesScreenState extends State<ResidentChargesScreen> {
  final ResidentService _service = ResidentService();
  String _filter = "Toutes";
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final bool inLayout = widget.onNavigate != null; // ← AJOUT

    final body = FutureBuilder<Map<String, dynamic>>(
      future: _service.getTrancheExpensesDetailed(
          widget.userId, DateTime.now().year),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B4A)));
        }
        if (snapshot.hasError)
          return Center(child: Text("Erreur : ${snapshot.error}"));

        final data = snapshot.data!;
        final List allDeps = data['depenses'];

        final filteredDeps = allDeps.where((d) {
          bool matchesSearch = (d['categories']?['nom'] ?? "")
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
          bool isPaye = d['facture_path'] != null;
          bool matchesFilter = _filter == "Toutes" ||
              (_filter == "Payées" && isPaye) ||
              (_filter == "En attente" && !isPaye);
          return matchesSearch && matchesFilter;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKpis(data),
              const SizedBox(height: 25),
              _buildSearchAndFilters(allDeps),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: 800,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildTableHeader(),
                      ...filteredDeps.map((d) => _buildTableRow(d)).toList(),
                      _buildTableFooter(data['total'].toInt()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildInfoBox(),
            ],
          ),
        );
      },
    );

    // ← Si dans layout : juste le body
    if (inLayout) return body;

    // ← Si standalone : Scaffold complet
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      appBar: AppBar(
        title: const Text("Dépenses de la Tranche",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFFFF6B4A)),
      ),
      drawer: ResidentMobileDrawer(
          currentIndex: 1, userId: widget.userId),
      body: body,
    );
  }

  // ── le reste du code est identique à avant ──

  Widget _buildKpis(Map data) {
    return Column(children: [
      _kpiItem("Total Tranche", "${data['total'].toInt()} DH", Colors.black),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _kpiItem("Payé", "${data['payees'].toInt()} DH", Colors.green)),
        const SizedBox(width: 10),
        Expanded(child: _kpiItem("Attente", "${data['attente'].toInt()} DH", Colors.red)),
      ])
    ]);
  }

  Widget _kpiItem(String label, String value, Color color) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 20)),
    ]),
  );

  Widget _buildSearchAndFilters(List all) {
    return Column(children: [
      TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: "Rechercher une dépense...",
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true, fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 15),
      Row(children: [
        _filterChip("Toutes", all.length),
        _filterChip("Payées", all.where((e) => e['facture_path'] != null).length),
        _filterChip("En attente", all.where((e) => e['facture_path'] == null).length),
      ])
    ]);
  }

  Widget _filterChip(String label, int count) {
    bool isSel = _filter.contains(label);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text("$label ($count)",
            style: TextStyle(fontSize: 11, color: isSel ? Colors.white : Colors.black87)),
        selected: isSel,
        onSelected: (v) => setState(() => _filter = label),
        selectedColor: const Color(0xFF222222),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      decoration: const BoxDecoration(color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(10))),
      child: Row(children: const [
        Expanded(flex: 1, child: Text("TYPE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
        Expanded(flex: 3, child: Text("DESCRIPTION", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: Text("CATÉGORIE", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: Text("DATE", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: Text("MONTANT", textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: Text("STATUT", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("FACTURE", textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
      ]),
    );
  }

  Widget _buildTableRow(Map d) {
    String catName = d['categories']?['nom'] ?? "Charge";
    bool isCommune = d['categories']?['type'] == 'globale';
    bool isPaye = d['facture_path'] != null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(children: [
        Expanded(flex: 1, child: Icon(_getIcon(catName), color: Colors.blueAccent, size: 20)),
        Expanded(flex: 3, child: Text(catName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        Expanded(flex: 2, child: _badge(isCommune ? "Commune" : "Individuelle", isCommune ? Colors.brown : Colors.orange)),
        Expanded(flex: 2, child: Text(d['date'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
        Expanded(flex: 2, child: Text("${d['montant']} DH", textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: _statusBadge(isPaye)),
        Expanded(flex: 1, child: IconButton(
          icon: const Icon(Icons.remove_red_eye, size: 18, color: Colors.grey),
          onPressed: () => _showFacture(d),
          alignment: Alignment.centerRight,
        )),
      ]),
    );
  }

  Widget _buildTableFooter(int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("TOTAL TOUTES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        Text("$total DH", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
      ]),
    );
  }

  Widget _badge(String t, Color c) => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(t, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)),
    ),
  );

  Widget _statusBadge(bool paye) {
    Color c = paye ? Colors.green : Colors.orange;
    return Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(paye ? Icons.check_circle : Icons.timer, size: 12, color: c),
      const SizedBox(width: 4),
      Text(paye ? "Payé" : "En attente", style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
    ]));
  }

  IconData _getIcon(String label) {
    if (label.contains("Sécurité")) return Icons.security;
    if (label.contains("Jardin")) return Icons.park;
    if (label.contains("Eau")) return Icons.opacity;
    return Icons.receipt_long;
  }

  void _showFacture(Map d) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: Text(d['categories']?['nom'] ?? "Facture"),
      content: Container(height: 300, width: 300, color: Colors.grey.shade50,
          child: const Icon(Icons.picture_as_pdf, size: 80, color: Colors.grey)),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Fermer"))],
    ));
  }

  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
      child: const Text("• Les dépenses sont certifiées par le Syndic Général.",
          style: TextStyle(fontSize: 11, color: Colors.blue)),
    );
  }
}