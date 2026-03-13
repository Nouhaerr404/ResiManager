// lib/screens/inter_syndic/finance/add_tranche_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../services/finance_service.dart';
import '../../../services/tranche_service.dart';
import '../../../models/tranche_model.dart';
import 'manage_categories_screen.dart';

class AddTrancheExpenseScreen extends StatefulWidget {
  final int residenceId;
  final int interSyndicId;
  final Map<String, dynamic>? expense;
  const AddTrancheExpenseScreen({
    super.key,
    required this.residenceId,
    required this.interSyndicId,
    this.expense
  });

  @override
  _AddTrancheExpenseScreenState createState() => _AddTrancheExpenseScreenState();
}


class _AddTrancheExpenseScreenState extends State<AddTrancheExpenseScreen> {
  final FinanceService _financeService = FinanceService();
  final TrancheService _trancheService = TrancheService();

  int? _selectedCategoryId;
  int? _selectedTrancheId; // null means 'Global' (all managed tranches)
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _montantController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  PlatformFile? _pickedFile;
  bool _isUploading = false;
  List<TrancheModel> _myTranches = [];

  final Color primaryOrange = const Color(0xFFFF6F4A);
  final Color darkGrey = const Color(0xFF2C2C2C);
  final Color backgroundBeige = const Color(0xFFFCF9F6);

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _selectedCategoryId = widget.expense!['categorie_id'];
      _selectedTrancheId = widget.expense!['tranche_id'];
      _montantController.text = widget.expense!['montant'].toString();
      _descController.text = widget.expense!['description'] ?? "";
      if (widget.expense!['date'] != null) {
        _selectedDate = DateTime.parse(widget.expense!['date']);
      }
    }
    _loadTranches();
  }

  Future<void> _loadTranches() async {
    final tranches = await _trancheService.getTranchesOfInterSyndic(widget.interSyndicId);
    setState(() {
      _myTranches = tranches;
      if (_selectedTrancheId == null && tranches.isNotEmpty) {
        _selectedTrancheId = tranches.first.id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isWeb = width > 900;

    return Scaffold(
      backgroundColor: backgroundBeige,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(),
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
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle("Catégorie de dépense *"),
                            TextButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()),
                              ).then((_) => setState(() {})),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text("Gérer"),
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildCategoryGrid(isWeb),

                        const SizedBox(height: 40),

                        _buildSectionTitle("Détails de la dépense"),
                        const SizedBox(height: 20),
                        _buildFormCard(isWeb),
                        const SizedBox(height: 40),
                        _buildActionButtons(),
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
              Text(widget.expense == null ? "Nouvelle Dépense" : "Modifier la Dépense",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
              const Text("Espace Inter-Syndic",
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
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
      future: _financeService.getCategories('individuelle'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final categories = snapshot.data!;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWeb ? 4 : 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 3,
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
          color: isSelected ? primaryOrange : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? primaryOrange : Colors.grey.shade300),
        ),
        child: Center(
          child: Text(cat['nom'], style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : darkGrey
          )),
        ),
      ),
    );
  }

  Widget _buildFormCard(bool isWeb) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_myTranches.isNotEmpty) ...[
            _buildFieldLabel("Tranche concernée"),
            DropdownButtonFormField<int>(
              initialValue: _selectedTrancheId,
              decoration: _inputStyle("Sélectionner la tranche"),
              items: _myTranches.map((t) => DropdownMenuItem(value: t.id, child: Text(t.nom))).toList(),
              onChanged: (val) => setState(() => _selectedTrancheId = val),
            ),
            const SizedBox(height: 20),
          ],
          _buildFieldLabel("Montant (DH) *"),
          TextField(
            controller: _montantController,
            keyboardType: TextInputType.number,
            decoration: _inputStyle("Ex: 500"),
          ),
          const SizedBox(height: 20),
          _buildFieldLabel("Description"),
          TextField(
            controller: _descController,
            maxLines: 2,
            decoration: _inputStyle("Justificatif, détails..."),
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
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7FF),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 30, color: Color(0xFF4A4E69)),
            const SizedBox(height: 10),
            Text(_pickedFile == null ? "Télécharger la facture" : _pickedFile!.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF27AE60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isUploading ? null : _submitForm,
        child: _isUploading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(widget.expense == null ? "Enregistrer la dépense" : "Mettre à jour la dépense", 
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
    );
  }

  void _submitForm() async {
    if (_montantController.text.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez remplir les champs obligatoires")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      if (widget.expense == null) {
        await _financeService.addInterSyndicExpense(
          residenceId: widget.residenceId,
          interSyndicId: widget.interSyndicId,
          montant: double.parse(_montantController.text.replaceAll(',', '.')),
          categorieId: _selectedCategoryId!,
          date: _selectedDate,
          trancheId: _selectedTrancheId!,
          description: _descController.text,
        );
      } else {
        await _financeService.updateInterSyndicExpense(
          expenseId: widget.expense!['id'],
          oldMontant: double.parse(widget.expense!['montant'].toString()),
          newMontant: double.parse(_montantController.text.replaceAll(',', '.')),
          categorieId: _selectedCategoryId!,
          date: _selectedDate,
          trancheId: _selectedTrancheId!,
          description: _descController.text,
        );
      }
      Navigator.pop(context);
    } catch (e, stack) {
      debugPrint("Error: $e");
      debugPrint("Stack trace: $stack");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }
}
