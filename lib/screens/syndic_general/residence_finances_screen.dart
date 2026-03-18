import 'package:flutter/material.dart';
import 'package:resimanager/widgets/main_layout.dart';
import '../../services/finance_service.dart';
import '../../screens/syndic_general/add_global_expense_screen.dart';

class ResidenceFinancesScreen extends StatefulWidget {
  final int residenceId;
  const ResidenceFinancesScreen({Key? key, required this.residenceId}) : super(key: key);

  @override
  _ResidenceFinancesScreenState createState() => _ResidenceFinancesScreenState();
}

class _ResidenceFinancesScreenState extends State<ResidenceFinancesScreen> {
  final FinanceService _service = FinanceService();

  // États pour les filtres
  int _selectedAnnee = DateTime.now().year;
  int? _selectedMois;
  int? _selectedFilterCatId;

  final Color primaryOrange = const Color(0xFFFF6F4A);
  final Color darkGrey = const Color(0xFF2C2C2C);
  final Color successGreen = const Color(0xFF4DB6AC);

  final List<String> _moisFr = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 700;

    return MainLayout(
      title: isMobile ? 'Finances' : '',
      activePage: 'Finances',
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
            left: isMobile ? 15 : 30,
            right: isMobile ? 15 : 30,
            bottom: 30,
            top: isMobile ? 10 : 25  // Espace très réduit en haut
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isMobile),
            const SizedBox(height: 15),
            _buildSearchAndFilters(isMobile),
            const SizedBox(height: 25),
            _buildExpensesList(isMobile, screenWidth),
          ],
        ),
      ),
    );
  }

  // 1. EN-TÊTE ADAPTATIF
  Widget _buildHeader(bool isMobile) {
    String subtitle = "Admin Général - Toutes les tranches";
    return isMobile
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Gestion des Dépenses", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 15),
        _addExpenseButton(true),
      ],
    )
        : Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Gestion des Dépenses", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ]),
        _addExpenseButton(false),
      ],
    );
  }

  Widget _addExpenseButton(bool isFullWidth) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddGlobalExpenseScreen(residenceId: widget.residenceId))).then((_) => setState((){})),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Ajouter une dépense", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // 2. RÉSUMÉ FINANCIER RÉEL

  Widget _summaryCard(String title, double amount, Color color, bool isMobile) {
    return Container(
      width: isMobile ? 180 : 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),
          FittedBox(child: Text("${amount.toInt()} DH", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  // 3. FILTRES RESPONSIVE
  Widget _buildSearchAndFilters(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade100)
      ),
      child: Column(
        children: [
          // BARRE DE RECHERCHE
          TextField(
            decoration: InputDecoration(
              hintText: "Rechercher une dépense...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),

          // LIGNE DES FILTRES (Année + Mois + Catégorie)
          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: [
              // FILTRE ANNÉE
              SizedBox(
                width: isMobile ? double.infinity : 120,
                child: DropdownButtonFormField<int>(
                  value: _selectedAnnee,
                  decoration: const InputDecoration(labelText: "Année", border: OutlineInputBorder()),
                  items: [2024, 2025, 2026, 2027].map((a) => DropdownMenuItem(value: a, child: Text(a.toString()))).toList(),
                  onChanged: (v) => setState(() => _selectedAnnee = v!),
                ),
              ),

              // FILTRE MOIS
              SizedBox(
                width: isMobile ? double.infinity : 160,
                child: _buildMoisDropdown(),
              ),

              // FILTRE CATÉGORIE
              SizedBox(
                width: isMobile ? double.infinity : 220,
                child: _buildCatDropdown(),
              ),
            ],
          )
        ],
      ),
    );
  }
  // 4. TABLEAU DES DÉPENSES AVEC SCROLL
  Widget _buildExpensesList(bool isMobile, double screenWidth) {
    return Container(
      width: double.infinity, // Force la largeur maximale
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // Étire le contenu
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: primaryOrange,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15))
            ),
            child: const Text(
                "Liste des Dépenses",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
            ),
          ),

          // Utilisation de LayoutBuilder pour forcer le tableau à prendre toute la largeur
          LayoutBuilder(
              builder: (context, constraints) {
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _service.getMyExpenses(
                      residenceId: widget.residenceId,
                      mySyndicId: 1,
                      annee: _selectedAnnee,
                      mois: _selectedMois,
                      categorieId: _selectedFilterCatId
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
                    final list = snapshot.data!;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        // On force le tableau à faire au moins la largeur de l'écran
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          // On augmente l'espace entre colonnes sur Web
                          columnSpacing: isMobile ? 30 : (screenWidth / 10),
                          headingRowHeight: 60,
                          dataRowHeight: 70,
                          columns: const [
                            DataColumn(label: Text('Catégorie', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Montant', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: list.map((d) => DataRow(cells: [
                            DataCell(Text(d['categories']['nom'])),
                            DataCell(Text("${d['montant']} DH", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                            DataCell(Text(d['date'].toString())),
                            DataCell(ElevatedButton(
                              onPressed: () => _showDetails(d),
                              style: ElevatedButton.styleFrom(backgroundColor: darkGrey),
                              child: const Text("Détails", style: TextStyle(color: Colors.white)),
                            )),
                          ])).toList(),
                        ),
                      ),
                    );
                  },
                );
              }
          ),
        ],
      ),
    );
  }


  Widget _buildYearFilterCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Filtrer par année :", style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<int>(
            value: _selectedAnnee,
            items: [2024, 2025, 2026, 2027].map((a) => DropdownMenuItem(value: a, child: Text(a.toString()))).toList(),
            onChanged: (v) => setState(() => _selectedAnnee = v!),
            underline: const SizedBox(),
          )
        ],
      ),
    );
  }

  Widget _buildMoisDropdown() {
    return DropdownButtonFormField<int?>(
      value: _selectedMois,
      decoration: const InputDecoration(labelText: "Mois", border: OutlineInputBorder()),
      items: [
        const DropdownMenuItem(value: null, child: Text("Tous les mois")),
        ...List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(_moisFr[i]))),
      ],
      onChanged: (v) => setState(() => _selectedMois = v),
    );
  }

  Widget _buildCatDropdown() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _service.getCategories('globale'),
      builder: (context, snapshot) {
        final cats = snapshot.data ?? [];
        return DropdownButtonFormField<int?>(
          value: _selectedFilterCatId,
          decoration: const InputDecoration(labelText: "Catégorie", border: OutlineInputBorder()),
          items: [
            const DropdownMenuItem(value: null, child: Text("Toutes catégories")),
            ...cats.map((c) => DropdownMenuItem(value: c['id'], child: Text(c['nom']))),
          ],
          onChanged: (v) => setState(() => _selectedFilterCatId = v),
        );
      },
    );
  }

// Garde tes fonctions _showDetails, _showInvoiceViewer et _detailRow à la fin ici...
// (Le code que tu as déjà est très bien pour ces fonctions là)


  void _showDetails(Map<String, dynamic> d) {
    // On vérifie si le lien de la facture existe dans Supabase
    bool hasInvoice = d['facture_path'] != null && d['facture_path'].toString().isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Entête Orange
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: Color(0xFFFF6F4A),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Détails de la Dépense", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            // Corps des détails
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  _detailRow("Catégorie", d['categories']['nom']),
                  _detailRow("Montant", "${d['montant']} DH"),
                  _detailRow("Date", d['date'].toString()),
                  const SizedBox(height: 30),

                  // --- LOGIQUE DU BOUTON ---
                  if (hasInvoice)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // On ferme les détails
                        _showInvoiceViewer(d['facture_path']); // On ouvre l'image
                      },
                      icon: const Icon(Icons.image_search, color: Colors.white),
                      label: const Text("Voir la facture", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6F4A),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    )
                  else
                    const Text("Aucun justificatif disponible", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }

  void _showInvoiceViewer(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // L'IMAGE
            InteractiveViewer( // Permet de zoomer sur l'image avec les doigts
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: const Text("Impossible d'afficher l'image"),
                  ),
                ),
              ),
            ),
            // BOUTON FERMER en haut à droite
            Positioned(
              top: 10, right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}