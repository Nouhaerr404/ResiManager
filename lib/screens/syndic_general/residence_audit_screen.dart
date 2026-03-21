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
  final Color primaryOrange = const Color(0xFFFF6F4A);
  final Color darkGrey = const Color(0xFF2C2C2C);
  final Color successGreen = const Color(0xFF4DB6AC);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: MainLayout(
        activePage: 'Audit',
        title: 'Audit & Bilans',
        residenceId: widget.residenceId,
        syndicId: widget.syndicId,
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                labelColor: primaryOrange,
                unselectedLabelColor: Colors.grey,
                indicatorColor: primaryOrange,
                tabs: const [
                  Tab(text: "JOURNAL DES DÉPENSES"),
                  Tab(text: "RECOUVREMENT RÉSIDENTS"),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildExpensesAudit(),
                  _buildIncomesAudit(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1 : DÉPENSES (GROUPÉES) ---
  Widget _buildExpensesAudit() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _service.getAuditExpenses(widget.residenceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Aucune dépense enregistrée."));
        final data = snapshot.data!;

        Map<String, List<Map<String, dynamic>>> grouped = {};
        for (var d in data) {
          String trancheName = d['tranches']?['nom'] ?? "Globales";
          if (!grouped.containsKey(trancheName)) grouped[trancheName] = [];
          grouped[trancheName]!.add(d);
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: grouped.entries.map((entry) {
            return _buildGroupSection(entry.key, entry.value);
          }).toList(),
        );
      },
    );
  }

  Widget _buildGroupSection(String title, List<Map<String, dynamic>> expenses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title, title == "Globales" ? Colors.blue : primaryOrange),
        ...expenses.map((d) {
          final catName = d['categories']?['nom'] ?? "Inconnue";
          final author = d['inter_syndic'] != null ? "${d['inter_syndic']['prenom']}" : "Général";
          return ListTile(
            leading: const Icon(Icons.receipt),
            title: Text(catName),
            subtitle: Text("par $author le ${d['date']}"),
            trailing: Text("${d['montant']} DH", style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        }),
      ],
    );
  }

  // --- TAB 2 : RECETTES (LISTE SÉCURISÉE) ---
  Widget _buildIncomesAudit() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _service.getAuditPaiements(widget.residenceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text("Erreur : ${snapshot.error}", style: const TextStyle(color: Colors.red)));
        final data = snapshot.data ?? [];
        if (data.isEmpty) return const Center(child: Text("Aucun paiement trouvé."));

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: data.length,
          itemBuilder: (context, i) {
            final p = data[i];

            final residentData = p['resident'] as Map<String, dynamic>?;
            final residentName = residentData != null ? "${residentData['prenom']} ${residentData['nom']}" : "Résident non trouvé";

            final appData = p['appartements'] as Map<String, dynamic>?;
            final appNumero = appData?['numero'] ?? "N/A";

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(residentName),
                subtitle: Text("Appartement $appNumero"),
                trailing: Text("${p['montant_paye']} / ${p['montant_total']} DH"),
              ),
            );
          },
        );
      },
    );
  }

  // --- HELPERS ---
  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    );
  }
}