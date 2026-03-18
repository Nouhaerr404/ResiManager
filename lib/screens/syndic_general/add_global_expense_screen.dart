import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../services/finance_service.dart';

class AddGlobalExpenseScreen extends StatefulWidget {
  final int residenceId;
  const AddGlobalExpenseScreen({Key? key, required this.residenceId}) : super(key: key);

  @override
  _AddGlobalExpenseScreenState createState() => _AddGlobalExpenseScreenState();
}

class _AddGlobalExpenseScreenState extends State<AddGlobalExpenseScreen> {
  final FinanceService _service = FinanceService();

  int? _selectedCategoryId;
  int _selectedAnnee = DateTime.now().year;
  final TextEditingController _montantController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  PlatformFile? _pickedFile;
  bool _isUploading = false;

  final Color primaryOrange = const Color(0xFFFF6F4A);
  final Color darkGrey = const Color(0xFF2C2C2C);
  final Color backgroundBeige = const Color(0xFFFCF9F6);

  final List<String> _moisFr = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  @override
  Widget build(BuildContext context) {
    // Détecter si on est sur Web/Grand écran
    double width = MediaQuery.of(context).size.width;
    bool isWeb = width > 900;

    return Scaffold(
      backgroundColor: backgroundBeige,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(), // En-tête type "Site Web"
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: isWeb ? width * 0.1 : 20,
                    vertical: 30
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Type de dépense *"),
                        const SizedBox(height: 20),

                        // 1. GRILLE DES CATÉGORIES (Adaptative)
                        _buildCategoryGrid(isWeb),

                        const SizedBox(height: 20),

                        // 2. BANDEAU INFO BLEU (Comme sur ta maquette)
                        _buildInfoBanner(),

                        const SizedBox(height: 40),

                        // 3. FORMULAIRE (Affiché seulement si catégorie choisie)
                        if (_selectedCategoryId != null) ...[
                          _buildSectionTitle("Détails de la consommation"),
                          const SizedBox(height: 20),
                          _buildFormCard(isWeb),
                          const SizedBox(height: 40),
                          _buildActionButtons(isWeb),
                        ],

                        if (_selectedCategoryId == null)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.0),
                              child: Text("Sélectionnez d'abord un type de dépense pour continuer",
                                  style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- COMPOSANTS UI ---

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Ajouter une Dépense",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
              Text("Résidence Les Jardins",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGrey));
  }

  Widget _buildCategoryGrid(bool isWeb) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _service.getAllCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final categories = snapshot.data!;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWeb ? 3 : 2, // 3 colonnes sur Web, 2 sur Mobile
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 3.5,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            bool isSelected = _selectedCategoryId == categories[index]['id'];
            return _buildCategoryItem(categories[index], isSelected);
          },
        );
      },
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> cat, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _selectedCategoryId = cat['id']),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? primaryOrange : Colors.grey.shade300, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getIconForCategory(cat['nom']), color: isSelected ? primaryOrange : Colors.blueGrey, size: 20),
            const SizedBox(width: 12),
            Text(cat['nom'], style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF3FF),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildFormCard(bool isWeb) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20)],
      ),
      child: Column(
        children: [
          _buildFieldLabel("Année de consommation *"),
          DropdownButtonFormField<int>(
            value: _selectedAnnee,
            decoration: _inputStyle("Sélectionner une année"),
            items: [2024, 2025, 2026, 2027, 2028, 2029, 2030].map((int annee) {
              return DropdownMenuItem<int>(
                value: annee,
                child: Text("Année $annee"),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedAnnee = val!),
          ),
          const SizedBox(height: 25),
          _buildFieldLabel("Montant (DH) *"),
          TextField(
            controller: _montantController,
            keyboardType: TextInputType.number,
            decoration: _inputStyle("Ex: 150"),
          ),
          const SizedBox(height: 25),
          _buildFieldLabel("Description"),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: _inputStyle("Ex: Index compteur..."),
          ),
          const SizedBox(height: 30),
          _buildUploadBox(),
        ],
      ),
    );
  }

  Widget _buildUploadBox() {
    return GestureDetector(
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles();
        if (result != null) setState(() => _pickedFile = result.files.first);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7FF),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.deepPurple.shade100, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.deepPurple),
            const SizedBox(height: 15),
            Text(_pickedFile == null ? "Cliquer pour télécharger la facture" : _pickedFile!.name,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A4E69))),
            const Text("PDF, PNG, JPG (Max 10MB)", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isWeb) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isUploading ? null : _submitForm,
            child: _isUploading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Enregistrer la Dépense", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ),
      ],
    );
  }

  // --- HELPERS ---
  Widget _buildFieldLabel(String label) {
    return Align(alignment: Alignment.centerLeft, child: Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    ));
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }

  IconData _getIconForCategory(String nom) {
    String n = nom.toLowerCase();
    if (n.contains('eau')) return Icons.water_drop;
    if (n.contains('électri')) return Icons.bolt;
    if (n.contains('salaire')) return Icons.payments;
    if (n.contains('entretien')) return Icons.cleaning_services;
    if (n.contains('jardin')) return Icons.grass;
    if (n.contains('éclairage')) return Icons.lightbulb;
    return Icons.category;
  }

  void _submitForm() async {
    if (_montantController.text.isEmpty || _selectedCategoryId == null) return;

    setState(() => _isUploading = true);

    try {
      String? facturePath;
      if (_pickedFile != null) {
        // Sauvegarde du nom de fichier uniquement, pour chargement depuis les assets
        facturePath = _pickedFile!.name;
      }

      await _service.addGlobalExpense(
        residenceId: widget.residenceId,
        montant: double.parse(_montantController.text.replaceAll(',', '.')),
        categorieId: _selectedCategoryId!,
        date: DateTime(_selectedAnnee, 1, 1),
        syndicId: 1,
        description: _descController.text,
        facturePath: facturePath,
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }
}