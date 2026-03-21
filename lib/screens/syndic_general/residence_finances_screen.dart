import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:resimanager/widgets/main_layout.dart';
import '../../services/finance_service.dart';
import 'add_global_expense_screen.dart';

class ResidenceFinancesScreen extends StatefulWidget {
  final int residenceId;
  final int syndicId;
  const ResidenceFinancesScreen({Key? key, required this.residenceId, required this.syndicId}) : super(key: key);

  @override
  _ResidenceFinancesScreenState createState() => _ResidenceFinancesScreenState();
}

class _ResidenceFinancesScreenState extends State<ResidenceFinancesScreen> {
  final FinanceService _service = FinanceService();
  int _selectedAnnee = DateTime.now().year;
  int? _selectedMois;
  int? _selectedFilterCatId;

  final Color primaryOrange = const Color(0xFFFF6F4A);
  final Color darkGrey = const Color(0xFF2C2C2C);

  final List<String> _moisFr = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 800;

    return MainLayout(
      title: '', // On vide le titre ici
      activePage: 'Finances',
      residenceId: widget.residenceId,
      syndicId: widget.syndicId,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(left: isMobile ? 15 : 30, right: isMobile ? 15 : 30, bottom: 30, top: isMobile ? 10 : 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActionHeader(isMobile),
            const SizedBox(height: 35),
            _buildSearchAndFilters(isMobile),
            const SizedBox(height: 25),
            _buildExpensesTable(isMobile, screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildActionHeader(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Gestion des Dépenses", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C))),
          const Text("Gérez les factures et sorties d'argent", style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 15),
          _addBtn(true),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Gestion des Dépenses", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C))),
          const Text("Gérez les factures et sorties d'argent", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ]),
        _addBtn(false),
      ],
    );
  }

  Widget _addBtn(bool isFullWidth) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddGlobalExpenseScreen(residenceId: widget.residenceId, syndicId: widget.syndicId))).then((_) => setState((){})),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nouvelle Dépense", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade100)),
      child: Column(children: [
        TextField(decoration: InputDecoration(hintText: "Rechercher...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: const Color(0xFFF8F9FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        const SizedBox(height: 20),
        Wrap(spacing: 15, runSpacing: 15, children: [
          SizedBox(width: isMobile ? double.infinity : 120, child: _dropdownAnnee()),
          SizedBox(width: isMobile ? double.infinity : 160, child: _dropdownMois()),
          SizedBox(width: isMobile ? double.infinity : 220, child: _dropdownCat()),
        ]),
      ]),
    );
  }

  Widget _buildExpensesTable(bool isMobile, double screenWidth) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: primaryOrange, borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
            child: const Text("Toutes les dépenses", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _service.getMyExpenses(residenceId: widget.residenceId, mySyndicId: widget.syndicId, annee: _selectedAnnee, mois: _selectedMois, categorieId: _selectedFilterCatId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator()));
              final list = snapshot.data!;
              if (list.isEmpty) return const Padding(padding: EdgeInsets.all(50), child: Center(child: Text("Aucune dépense trouvée.")));
              
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: isMobile ? 600 : screenWidth - 350),
                  child: DataTable(
                    headingRowHeight: 60,
                    dataRowHeight: 70,
                    columns: const [
                      DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Catégorie', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Montant', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Justificatif', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: list.map((d) => DataRow(cells: [
                      DataCell(Text(d['date']?.toString() ?? "Date inconnue")),
                      DataCell(Text(d['categories']?['nom'] ?? 'Inconnu')),
                      DataCell(Text("${d['montant']} DH", style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(_buildJustifBadge(d['facture_path'])),
                      DataCell(Row(
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _showEditDialog(d)),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _confirmDelete(d['id'])),
                        ],
                      )),
                    ])).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJustifBadge(dynamic path) {
    bool exists = path != null && path.toString().trim().isNotEmpty && path.toString() != 'null';
    if (exists) {
      return InkWell(
        onTap: () => _showInvoiceViewer(path.toString()),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
            const SizedBox(width: 4),
            const Text("Oui", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Icon(Icons.description, color: primaryOrange, size: 18),
          ],
        ),
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.cancel, color: Colors.grey, size: 18),
          SizedBox(width: 4),
          Text("Non", style: TextStyle(color: Colors.grey)),
        ],
      );
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer cette dépense ?"),
        content: const Text("Cette action est irréversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _service.deleteExpense(id);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> d) {
    final TextEditingController mntController = TextEditingController(text: d['montant'].toString());
    final TextEditingController descController = TextEditingController(text: d['description'] ?? '');
    int? selectedCatId = d['categorie_id'];
    PlatformFile? newFile;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Text("Modifier la dépense", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: mntController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: "Montant (DH)", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _service.getCategories('globale'),
                  builder: (context, snapshot) {
                    final cats = snapshot.data ?? [];
                    return DropdownButtonFormField<int>(
                      value: selectedCatId,
                      decoration: const InputDecoration(labelText: "Catégorie", border: OutlineInputBorder()),
                      items: cats.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['nom']))).toList(),
                      onChanged: (v) => setDialogState(() => selectedCatId = v),
                    );
                  }
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const Text("Justificatif", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    FilePickerResult? r = await FilePicker.platform.pickFiles(type: FileType.image);
                    if (r != null) setDialogState(() => newFile = r.files.first);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_upload, color: newFile == null ? Colors.grey : Colors.green),
                        const SizedBox(width: 10),
                        Expanded(child: Text(newFile == null ? (d['facture_path'] != null ? "Changer la facture" : "Ajouter une facture") : newFile!.name, style: TextStyle(fontSize: 12, color: newFile == null ? Colors.black54 : Colors.green, fontWeight: newFile == null ? FontWeight.normal : FontWeight.bold))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Annuler", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      if (mntController.text.isEmpty || selectedCatId == null) return;
                      
                      setDialogState(() => isSaving = true);
                      try {
                        String? fileUrl;
                        if (newFile != null) {
                          fileUrl = kIsWeb ? newFile!.name : newFile!.path;
                        }

                        await _service.updateGlobalExpense(
                          expenseId: d['id'],
                          montant: double.parse(mntController.text.replaceAll(',', '.')),
                          categorieId: selectedCatId!,
                          annee: d['annee'],
                          description: descController.text,
                          facturePath: fileUrl,
                        );
                        Navigator.pop(context);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dépense mise à jour !"), backgroundColor: Colors.green));
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Enregistrer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showInvoiceViewer(String fileName) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildImageWidget(fileName),
                  ),
                  const SizedBox(height: 10),
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Fermer")),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(ctx),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String path) {
    if (path.startsWith('http')) {
      return Image.network(path);
    }
    
    if (!kIsWeb && File(path).existsSync()) {
      return Image.file(File(path));
    }

    // 2. Sinon on cherche dans les assets
    return Image.asset(
      'assets/images/$path',
      errorBuilder: (context, error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text("Fichier '$path' introuvable."),
        ),
      ),
    );
  }

    Widget _dropdownAnnee() { return DropdownButtonFormField<int>(value: _selectedAnnee, decoration: const InputDecoration(labelText: "Année"), items: [2024, 2025, 2026, 2027].map((a) => DropdownMenuItem(value: a, child: Text(a.toString()))).toList(), onChanged: (v) => setState(() => _selectedAnnee = v!)); }
  Widget _dropdownMois() { return DropdownButtonFormField<int?>(value: _selectedMois, decoration: const InputDecoration(labelText: "Mois"), items: [const DropdownMenuItem(value: null, child: Text("Tous les mois")), ...List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(_moisFr[i])))], onChanged: (v) => setState(() => _selectedMois = v)); }
  Widget _dropdownCat() { return FutureBuilder<List<Map<String, dynamic>>>(future: _service.getCategories('globale'), builder: (context, snapshot) {
    final cats = snapshot.data ?? [];
    return DropdownButtonFormField<int?>(value: _selectedFilterCatId, decoration: const InputDecoration(labelText: "Catégorie"), items: [const DropdownMenuItem(value: null, child: Text("Toutes")), ...cats.map((c) => DropdownMenuItem(value: c['id'], child: Text(c['nom'])))], onChanged: (v) => setState(() => _selectedFilterCatId = v));
  });}
}