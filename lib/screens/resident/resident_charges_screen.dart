import 'package:flutter/material.dart';
import '../../services/resident_service.dart';
import '../../widgets/resident_nav_bar.dart';

class ResidentChargesScreen extends StatefulWidget {
  @override
  _ResidentChargesScreenState createState() => _ResidentChargesScreenState();
}

class _ResidentChargesScreenState extends State<ResidentChargesScreen> {
  final ResidentService _service = ResidentService();
  String _searchQuery = "";
  String _filter = "Toutes";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      appBar: const ResidentNavBar(currentIndex: 1), // Index 2 correspond à l'onglet Dépenses
      body: FutureBuilder<Map<String, dynamic>>(
        future: _service.getTrancheExpensesDetailed(3, 2026),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B4A)));
          }
          if (snapshot.hasError) return Center(child: Text("Erreur : ${snapshot.error}"));

          final data = snapshot.data!;
          final List allDeps = data['depenses'];

          // Filtrage interactif (Recherche + Status)
          final filteredDeps = allDeps.where((d) {
            bool matchesSearch = (d['categories']?['nom'] ?? "").toLowerCase().contains(_searchQuery.toLowerCase());
            bool isPaye = d['facture_path'] != null;
            bool matchesFilter = _filter == "Toutes" ||
                (_filter == "Payées" && isPaye) ||
                (_filter == "En attente" && !isPaye);
            return matchesSearch && matchesFilter;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER TITRE ---
                const Text("Dépenses de la Tranche", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D))),
                Text("${data['tranche_nom']}", style: const TextStyle(color: Colors.grey, fontSize: 16)),
                const Text("Géré par le Syndic Général", style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 30),

                // --- SÉLECTEUR ANNÉE ---
                _buildYearSelector(),
                const SizedBox(height: 30),

                // --- KPI CARDS (TOTAL, PAYÉES, ATTENTE) ---
                Row(
                  children: [
                    _buildKpiCard("Total dépenses", "${data['total'].toInt()} DH", Colors.black87),
                    const SizedBox(width: 20),
                    _buildKpiCard("Payées", "${data['payees'].toInt()} DH", const Color(0xFF4CAF50)),
                    const SizedBox(width: 20),
                    _buildKpiCard("En attente", "${data['attente'].toInt()} DH", const Color(0xFFFF5252)),
                  ],
                ),
                const SizedBox(height: 40),

                // --- BARRE DE RECHERCHE ---
                _buildSearchBar(),
                const SizedBox(height: 20),

                // --- FILTRES CHIPS ---
                _buildFilterRow(allDeps),
                const SizedBox(height: 30),

                // --- TABLEAU DES DÉPENSES ---
                _buildDataTable(filteredDeps),

                // --- FOOTER TOTAL NOIR ---
                _buildTableFooter(data['total'].toInt()),

                const SizedBox(height: 40),
                _buildInfoBox(),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- COMPOSANTS UI CORRIGÉS ---

  Widget _buildYearSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: const [
          Icon(Icons.calendar_today, size: 18, color: Colors.grey),
          SizedBox(width: 15),
          Text("Année", style: TextStyle(color: Colors.black87)),
          SizedBox(width: 20),
          Text("2026", style: TextStyle(fontWeight: FontWeight.bold)),
          Spacer(),
          Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade100)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (v) => setState(() => _searchQuery = v),
      decoration: InputDecoration(
        hintText: "Rechercher une dépense...",
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF1F1F1),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildFilterRow(List all) {
    return Row(
      children: [
        _filterChip("Toutes", all.length),
        const SizedBox(width: 10),
        _filterChip("Payées", all.where((e) => e['facture_path'] != null).length),
        const SizedBox(width: 10),
        _filterChip("En attente", all.where((e) => e['facture_path'] == null).length),
      ],
    );
  }

  Widget _filterChip(String label, int count) {
    bool isSel = _filter == label;
    return ChoiceChip(
      label: Text("$label ($count)"),
      selected: isSel,
      onSelected: (v) => setState(() => _filter = label),
      selectedColor: const Color(0xFF2D2D2D),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildDataTable(List deps) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // HEADER NOIR (Corrigé : textAlign déplacé hors de TextStyle)
          Container(
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: Row(
              children: const [
                Expanded(flex: 1, child: Text("TYPE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                Expanded(flex: 4, child: Text("DESCRIPTION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                Expanded(flex: 2, child: Text("CATÉGORIE", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                Expanded(flex: 2, child: Text("DATE", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                Expanded(flex: 2, child: Text("MONTANT", textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                Expanded(flex: 2, child: Text("STATUT", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                Expanded(flex: 1, child: Text("FACTURE", textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              ],
            ),
          ),
          // LIGNES
          if (deps.isEmpty) Container(padding: const EdgeInsets.all(50), child: const Text("Aucune dépense trouvée.")),
          ...deps.map((d) => _buildRow(d)).toList(),
        ],
      ),
    );
  }

  Widget _buildRow(Map d) {
    String catName = d['categories']?['nom'] ?? "Charge";
    bool isCommune = d['categories']?['type'] == 'globale';
    bool isPaye = d['facture_path'] != null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        children: [
          Expanded(flex: 1, child: Icon(_getIcon(catName), color: Colors.blueAccent, size: 22)),
          Expanded(flex: 4, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(catName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Text("Dépense liée à la maintenance de la tranche...", style: TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          )),
          Expanded(flex: 2, child: _categoryBadge(isCommune)),
          Expanded(flex: 2, child: Text(d['date'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
          Expanded(flex: 2, child: Text("${d['montant']} DH", textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          Expanded(flex: 2, child: _statusBadge(isPaye)),
          Expanded(flex: 1, child: IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.grey),
            onPressed: () => _showFacture(d),
            padding: EdgeInsets.zero, alignment: Alignment.centerRight,
          )),
        ],
      ),
    );
  }

  Widget _buildTableFooter(int total) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 30),
      decoration: const BoxDecoration(color: Color(0xFF1A1A1A), borderRadius: BorderRadius.vertical(bottom: Radius.circular(15))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("TOTAL TOUTES DÉPENSES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          Text("$total DH", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- HELPERS STYLES ---

  Widget _categoryBadge(bool commune) {
    Color c = commune ? Colors.brown : Colors.orange;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(commune ? Icons.business : Icons.home, size: 12, color: c),
          const SizedBox(width: 5),
          Text(commune ? "Commune" : "Individuelle", style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold))
        ]),
      ),
    );
  }

  Widget _statusBadge(bool paye) {
    Color c = paye ? Colors.green : Colors.orange;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(paye ? Icons.check : Icons.hourglass_empty, size: 12, color: c),
          const SizedBox(width: 5),
          Text(paye ? "Payé" : "En attente", style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold))
        ]),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: const Color(0xFFFDF7E7), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade100)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text("ℹ️ INFORMATION SUR LES CHARGES", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 13)),
        SizedBox(height: 10),
        Text("• Cotisation annuelle : Montant fixe que chaque résident doit payer par an.", style: TextStyle(fontSize: 12, color: Colors.brown)),
        Text("• Dépenses de la tranche : Géré par le Syndic Général pour toute la tranche.", style: TextStyle(fontSize: 12, color: Colors.brown)),
        Text("• Factures : Documents justificatifs officiels fournis par le Syndic.", style: TextStyle(fontSize: 12, color: Colors.brown)),
      ]),
    );
  }

  IconData _getIcon(String label) {
    if (label.contains("Sécurité")) return Icons.security;
    if (label.contains("Jardin")) return Icons.park;
    if (label.contains("Eau")) return Icons.opacity;
    if (label.contains("Élec")) return Icons.bolt;
    return Icons.receipt_long;
  }

  void _showFacture(Map d) {
    showDialog(context: context, builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(d['categories']?['nom'] ?? "Facture"),
      content: Container(
          height: 350, width: 400,
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.picture_as_pdf, size: 80, color: Colors.grey),
              SizedBox(height: 20),
              Text("Aperçu de la facture officielle", style: TextStyle(color: Colors.grey)),
            ],
          )
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Fermer", style: TextStyle(color: Colors.black87)))],
    ));
  }
}