import 'package:flutter/material.dart';
import '../../services/resident_service.dart';
import '../../widgets/resident_nav_bar.dart';

class ResidentChargesScreen extends StatefulWidget {
  @override
  _ResidentChargesScreenState createState() => _ResidentChargesScreenState();
}

class _ResidentChargesScreenState extends State<ResidentChargesScreen> {
  final ResidentService _service = ResidentService();
  String _selectedMonthStr = "Février 2026";
  final int userId = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: const ResidentNavBar(currentIndex: 1),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _service.getFullChargesData(userId, 2026, 2),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF7033FF)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("❌ Erreur : ${snapshot.error}", textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
              ),
            );
          }

          final data = snapshot.data!;
          final p = data['paiement'];
          final List di = data['depenses_immeuble'];
          final List dt = data['depenses_tranche'];

          double total = (p?['montant_total'] ?? 0).toDouble();
          double paye = (p?['montant_paye'] ?? 0).toDouble();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Mes Charges", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                Text(data['appart_info'], style: const TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 30),

                _buildMonthSelector(),
                const SizedBox(height: 30),

                // --- IMAGE 2 : RÉSUMÉ VIOLET ---
                _buildPurpleSummary(total, paye),
                const SizedBox(height: 40),

                // --- IMAGE 3 : DÉTAIL DES CHARGES ---
                _buildSectionTitle(Icons.receipt_long_outlined, "Détail des Charges", const Color(0xFF7033FF)),
                const SizedBox(height: 20),
                _buildDetailsCard(total), // On affiche ici la répartition type
                const SizedBox(height: 40),

                // --- IMAGE 4 : DÉPENSES IMMEUBLE ---
                _buildSectionTitle(Icons.apartment, "Dépenses de ${data['immeuble_nom']}", Colors.blue),
                const SizedBox(height: 20),
                _buildExpenseList(di),
                const SizedBox(height: 40),

                // --- IMAGE 5 : DÉPENSES TRANCHE + BANDEAU BLEU ---
                _buildSectionTitle(Icons.home_outlined, "Dépenses de ${data['tranche_nom']}", Colors.green),
                const SizedBox(height: 20),
                _buildExpenseList(dt, isTranche: true),
                _buildBlueTotalFooter(data['total_tranche']),
                const SizedBox(height: 40),

                // --- IMAGE 6 : HISTORIQUE ---
                _buildSectionTitle(Icons.history, "Historique de Paiement", Colors.orange),
                const SizedBox(height: 20),
                _buildHistoryList(data['historique']),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGETS DESIGN ---

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMonthStr,
          items: [_selectedMonthStr].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
          onChanged: (v) {},
        ),
      ),
    );
  }

  Widget _buildPurpleSummary(double total, double paye) {
    bool isDone = (total - paye) <= 0;
    return Container(
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF7033FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF7033FF).withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 12))],
      ),
      child: Column(
        children: [
          _sumRow("Total à payer", "${total.toStringAsFixed(2)} DH", isTitle: true),
          const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(color: Colors.white24)),
          _sumRow("Montant payé", "${paye.toStringAsFixed(2)} DH"),
          const SizedBox(height: 10),
          _sumRow("Reste à payer", isDone ? "✓ Payé" : "${(total - paye).toStringAsFixed(2)} DH"),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: isDone ? Colors.greenAccent : Colors.white70, size: 20),
                const SizedBox(width: 10),
                Text(isDone ? "Vous êtes à jour pour ce mois" : "Paiement partiel effectué", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDetailsCard(double total) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        children: [
          _detailItem("Sécurité", "Part commune", 200, 12000, Icons.shield_outlined),
          _detailItem("Jardinier", "Part commune", 58.33, 3500, Icons.park_outlined),
          _detailItem("Maintenance", "Part commune", 250, 15000, Icons.build_outlined),
          _detailItem("Eau", "Consommation personnelle", 150, null, Icons.opacity),
        ],
      ),
    );
  }

  Widget _buildExpenseList(List list, {bool isTranche = false}) {
    if (list.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Aucune dépense ce mois-ci")));
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: list.map((e) => ListTile(
          leading: const Icon(Icons.description_outlined, color: Colors.blueGrey),
          title: Text(e['description'] ?? "Service", style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(isTranche ? "Commune - ${e['date']}" : e['date']),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${e['montant']} DH", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Text("✓ Payé", style: TextStyle(color: Colors.green, fontSize: 11)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildBlueTotalFooter(double total) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.shade100)),
      child: Text("Total des dépenses de la tranche : ${total.toStringAsFixed(0)} DH", style: const TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildHistoryList(List history) {
    return Column(
      children: history.map((h) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(h['description'] ?? "Mois précédent", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)), const Text("Paiement effectué", style: TextStyle(color: Colors.grey))]),
            Row(children: [Text("${h['montant']} DH", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(width: 10), const Icon(Icons.check_circle, color: Colors.green, size: 20)]),
          ],
        ),
      )).toList(),
    );
  }

  // --- HELPERS ---

  Widget _sumRow(String l, String v, {bool isTitle = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [Text(l, style: const TextStyle(color: Colors.white70, fontSize: 16)), Text(v, style: TextStyle(color: Colors.white, fontSize: isTitle ? 32 : 20, fontWeight: FontWeight.bold))],
  );

  Widget _detailItem(String t, String s, double m, double? tot, IconData i) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
    leading: Icon(i, color: Colors.blueAccent),
    title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text(s),
    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text("${m.toStringAsFixed(2)} DH", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), if (tot != null) Text("sur $tot DH", style: const TextStyle(fontSize: 11, color: Colors.grey))]),
  );

  Widget _buildSectionTitle(IconData i, String t, Color c) => Row(children: [Icon(i, color: c), const SizedBox(width: 12), Text(t, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))]);
}