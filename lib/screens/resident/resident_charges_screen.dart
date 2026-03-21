import 'package:flutter/material.dart';
import '../../services/resident_service.dart';
import 'resident_dashboard_screen.dart'; // ← GARDE

class ResidentChargesScreen extends StatefulWidget {
  final int userId;
  final Function(int)? onNavigate;
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
  int _selectedAnnee = DateTime.now().year;

  static const _coral = Color(0xFFFF6B4A);
  static const _dark = Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    final bool inLayout = widget.onNavigate != null;

    final body = FutureBuilder<Map<String, dynamic>>(
      future: _service.getTrancheExpensesDetailed(widget.userId, _selectedAnnee),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _coral));
        }
        if (snapshot.hasError)
          return Center(child: Text("Erreur : ${snapshot.error}"));

        final data = snapshot.data!;
        final List allDeps = data['depenses'];

        final filteredDeps = allDeps.where((d) {
          bool matchesSearch = (d['description']?.toString() ?? d['categories']?['nom'] ?? "")
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
          bool isPaye = d['facture_path'] != null;
          bool matchesFilter = _filter == "Toutes" ||
              (_filter == "Payées" && isPaye) ||
              (_filter == "En attente" && !isPaye);
          return matchesSearch && matchesFilter;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Dépenses", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _dark)),
                    Text(data['tranche_nom'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  ]),
                  _buildAnneeSelector(),
                ],
              ),
              const SizedBox(height: 20),
              _buildKpis(data),
              const SizedBox(height: 24),
              _buildSearchAndFilters(allDeps),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: 820,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(children: [
                    _buildTableHeader(),
                    ...filteredDeps.asMap().entries.map((e) => _buildTableRow(e.value, e.key)).toList(),
                    _buildTableFooter(data['total'].toInt()),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoBox(),
            ],
          ),
        );
      },
    );

    if (inLayout) return body;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      appBar: AppBar(
        title: const Text("Dépenses de la Tranche",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: _coral),
      ),
      drawer: ResidentMobileDrawer(currentIndex: 1, userId: widget.userId),
      body: body,
    );
  }

  Widget _buildAnneeSelector() {
    final List<int> annees = List.generate(5, (i) => DateTime.now().year - i);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedAnnee,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          isDense: true,
          items: annees.map((y) => DropdownMenuItem(
            value: y,
            child: Text(y.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          )).toList(),
          onChanged: (v) => setState(() => _selectedAnnee = v!),
        ),
      ),
    );
  }

  Widget _buildKpis(Map data) {
    return Row(children: [
      Expanded(child: _kpiCard("Total Tranche", "${data['total'].toInt()} DH",
          Icons.account_balance_wallet_outlined, _dark, const Color(0xFFEEF2FF))),
      const SizedBox(width: 12),
      Expanded(child: _kpiCard("Payé", "${data['payees'].toInt()} DH",
          Icons.check_circle_outline, Colors.green, const Color(0xFFECFDF5))),
      const SizedBox(width: 12),
      Expanded(child: _kpiCard("En attente", "${data['attente'].toInt()} DH",
          Icons.timer_outlined, _coral, const Color(0xFFFFF5F3))),
    ]);
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 12),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ]),
    );
  }

  Widget _buildSearchAndFilters(List all) {
    return Column(children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: "Rechercher une dépense...",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Row(children: [
        _filterChip("Toutes", all.length),
        _filterChip("Payées", all.where((e) => e['facture_path'] != null).length),
        _filterChip("En attente", all.where((e) => e['facture_path'] == null).length),
      ]),
    ]);
  }

  Widget _filterChip(String label, int count) {
    bool isSel = _filter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? _dark : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: isSel ? _dark : Colors.grey.shade200),
            boxShadow: isSel ? [BoxShadow(color: _dark.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))] : [],
          ),
          child: Text("$label ($count)",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isSel ? Colors.white : Colors.grey.shade600)),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_dark, Color(0xFF16213E)]),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(children: const [
        Expanded(flex: 1, child: Text("TYPE", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
        Expanded(flex: 3, child: Text("DESCRIPTION", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
        Expanded(flex: 2, child: Text("CATÉGORIE", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
        Expanded(flex: 2, child: Text("DATE", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
        Expanded(flex: 2, child: Text("MONTANT", textAlign: TextAlign.right, style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
        Expanded(flex: 2, child: Text("STATUT", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
        Expanded(flex: 1, child: Text("FACTURE", textAlign: TextAlign.right, style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
      ]),
    );
  }

  Widget _buildTableRow(Map d, int index) {
    String catName = d['categories']?['nom'] ?? "Charge";
    String description = d['description']?.toString() ?? catName;
    bool isCommune = d['categories']?['type'] == 'globale';
    bool isPaye = d['facture_path'] != null;
    final bg = index.isEven ? Colors.white : const Color(0xFFFAFAFC);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(children: [
        Expanded(flex: 1, child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
          child: Icon(_getIcon(catName), color: Colors.blue.shade400, size: 16),
        )),
        // ✅ CORRECT
        Expanded(flex: 3, child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        )),
        Expanded(flex: 2, child: _badge(isCommune ? "Commune" : "Individuelle",
            isCommune ? const Color(0xFF7C5CBF) : const Color(0xFFEA8C00))),
        Expanded(flex: 2, child: Text(d['date'] ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
        Expanded(flex: 2, child: Text("${d['montant']} DH",
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        Expanded(flex: 2, child: _statusBadge(isPaye)),
        Expanded(flex: 1, child: IconButton(
          icon: Icon(Icons.visibility_outlined, size: 18, color: Colors.grey.shade400),
          onPressed: () => _showFacture(d),
          alignment: Alignment.centerRight,
        )),
      ]),
    );
  }

  Widget _buildTableFooter(int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_coral, Color(0xFFFF8C42)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("TOTAL TOUTES LES DÉPENSES",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
        Text("$total DH",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
      ]),
    );
  }

  Widget _badge(String t, Color c) => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.3))),
      child: Text(t, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    ),
  );

  Widget _statusBadge(bool paye) {
    Color c = paye ? Colors.green : Colors.orange;
    Color bg = paye ? Colors.green.shade50 : Colors.orange.shade50;
    return Center(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(paye ? Icons.check_circle : Icons.schedule, size: 11, color: c),
        const SizedBox(width: 4),
        Text(paye ? "Payé" : "En attente",
            style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
    ));
  }

  IconData _getIcon(String label) {
    if (label.contains("Sécurité")) return Icons.security;
    if (label.contains("Jardin")) return Icons.park;
    if (label.contains("Eau")) return Icons.opacity;
    return Icons.receipt_long;
  }

  void _showFacture(Map d) {
    showDialog(context: context, builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(d['categories']?['nom'] ?? "Facture"),
      content: Container(height: 300, width: 300, color: Colors.grey.shade50,
          child: const Icon(Icons.picture_as_pdf, size: 80, color: Colors.grey)),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Fermer"))],
    ));
  }

  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade50, Colors.indigo.shade50]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(children: [
        Icon(Icons.verified_outlined, color: Colors.blue.shade400, size: 18),
        const SizedBox(width: 10),
        const Expanded(child: Text("Les dépenses sont certifiées par le Syndic Général.",
            style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}
//karim.moussaoui99@gmail.com
//hashed_password