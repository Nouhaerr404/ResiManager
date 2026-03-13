// lib/screens/inter_syndic/finance/add_tranche_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../../services/finance_service.dart';
import '../../../services/tranche_service.dart';
import '../../../models/tranche_model.dart';

class AddTrancheExpenseScreen extends StatefulWidget {
  final int residenceId;
  final int interSyndicId;
  final Map<String, dynamic>? expenseData; // Optionnel pour l'édition

  const AddTrancheExpenseScreen({
    Key? key,
    required this.residenceId,
    required this.interSyndicId,
    this.expenseData,
  }) : super(key: key);

  @override
  _AddTrancheExpenseScreenState createState() => _AddTrancheExpenseScreenState();
}

class _AddTrancheExpenseScreenState extends State<AddTrancheExpenseScreen> {
  final FinanceService _financeService = FinanceService();
  final TrancheService _trancheService = TrancheService();

  int? _selectedCategoryId;
  int? _selectedTrancheId;
  DateTime _selectedDate = DateTime.now();
  late TextEditingController _montantController;
  late TextEditingController _descController;
  PlatformFile? _pickedFile;
  bool _isUploading = false;
  List<TrancheModel> _myTranches = [];

  bool get isEdit => widget.expenseData != null;

  @override
  void initState() {
    super.initState();
    _montantController = TextEditingController(text: isEdit ? widget.expenseData!['montant'].toString() : '');
    _descController = TextEditingController(text: isEdit ? (widget.expenseData!['description'] ?? '') : '');
    
    if (isEdit) {
      _selectedCategoryId = widget.expenseData!['categorie_id'];
      _selectedTrancheId = widget.expenseData!['tranche_id'];
      _selectedDate = DateTime.parse(widget.expenseData!['date']);
    }
    
    _loadTranches();
  }

  Future<void> _loadTranches() async {
    final tranches = await _trancheService.getTranchesOfInterSyndic(widget.interSyndicId);
    setState(() {
      _myTranches = tranches;
      if (!isEdit && _selectedTrancheId == null && tranches.isNotEmpty) {
        _selectedTrancheId = tranches.first.id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isWeb = width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: EdgeInsets.symmetric(
                horizontal: isWeb ? width * 0.15 : 20,
                vertical: 30
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildModernSectionTitle("Catégorie de dépense", "Choisissez une catégorie ou créez-en une nouvelle"),
                const SizedBox(height: 20),
                _buildCategoryGrid(isWeb),
                const SizedBox(height: 40),
                _buildModernSectionTitle("Détails financiers", "Remplissez les informations relatives au montant"),
                const SizedBox(height: 20),
                _buildPremiumFormCard(isWeb),
                const SizedBox(height: 40),
                _buildPremiumActionButtons(),
                const SizedBox(height: 50),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: Text(isEdit ? "Modifier la Dépense" : "Nouvelle Dépense",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        background: Container(color: Colors.white),
      ),
    );
  }

  Widget _buildModernSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildCategoryGrid(bool isWeb) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _financeService.getAllCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final categories = snapshot.data!;
        
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...categories.map((cat) {
              bool isSelected = _selectedCategoryId == cat['id'];
              return _buildCategoryItem(cat, isSelected);
            }).toList(),
            _buildAddCategoryButton(),
          ],
        );
      },
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> cat, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _selectedCategoryId = cat['id']),
      onLongPress: () => _showDeleteCategoryDialog(cat),
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6F4A) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? const Color(0xFFFF6F4A) : Colors.grey.shade300, width: 1.5),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFFF6F4A).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Text(cat['nom'], style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF4A4A4A),
          fontSize: 14,
        )),
      ),
    );
  }

  void _showDeleteCategoryDialog(Map<String, dynamic> cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Supprimer '${cat['nom']}' ?"),
        content: const Text("Voulez-vous vraiment supprimer cette catégorie ? Cela échouera si elle est déjà utilisée par des dépenses."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              try {
                await _financeService.deleteExpenseCategory(cat['id']);
                Navigator.pop(ctx);
                if (_selectedCategoryId == cat['id']) _selectedCategoryId = null;
                setState(() {});
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Impossible de supprimer : cette catégorie est probablement utilisée."),
                  backgroundColor: Colors.red,
                ));
              }
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCategoryButton() {
    return InkWell(
      onTap: _showAddCategoryDialog,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.blue.shade300, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Text("Ajouter", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Nouvelle Catégorie", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Nom de la catégorie (ex: Peinture)",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6F4A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final nom = controller.text.trim();
              if (nom.isEmpty) return;
              
              try {
                await _financeService.addExpenseCategory(nom);
                Navigator.pop(ctx);
                setState(() {}); // Refresh categories
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Catégorie '$nom' ajoutée avec succès")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Erreur lors de la création de la catégorie. Elle existe peut-être déjà."),
                  backgroundColor: Colors.red,
                ));
              }
            },
            child: const Text("Créer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFormCard(bool isWeb) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isEdit) ...[
            _buildModernFieldLabel("Tranche concernée"),
            DropdownButtonFormField<int>(
              value: _selectedTrancheId,
              icon: const Icon(Icons.keyboard_arrow_down),
              decoration: _premiumInputStyle("Sélectionner la tranche", Icons.home_work_outlined),
              items: _myTranches.map((t) => DropdownMenuItem(value: t.id, child: Text(t.nom))).toList(),
              onChanged: (val) => setState(() => _selectedTrancheId = val),
            ),
            const SizedBox(height: 24),
          ],
          _buildModernFieldLabel("Montant de la dépense *"),
          TextField(
            controller: _montantController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: _premiumInputStyle("0.00", Icons.account_balance_wallet_outlined, suffixText: "DH"),
          ),
          const SizedBox(height: 24),
          _buildModernFieldLabel("Date de la dépense"),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, color: Colors.grey, size: 20),
                  const SizedBox(width: 12),
                  Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  const Icon(Icons.edit_outlined, size: 16, color: Colors.blue),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildModernFieldLabel("Description & Note"),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: _premiumInputStyle("Détaillez la dépense...", Icons.description_outlined),
          ),
          const SizedBox(height: 32),
          _buildPremiumUploadBox(),
        ],
      ),
    );
  }

  Widget _buildPremiumUploadBox() {
    return GestureDetector(
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles();
        if (result != null) setState(() => _pickedFile = result.files.first);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade100, width: 2, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10)]),
              child: const Icon(Icons.cloud_upload, size: 28, color: Colors.blue),
            ),
            const SizedBox(height: 16),
            Text(_pickedFile == null ? "Ajouter un justificatif" : _pickedFile!.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4A4E69))),
            const SizedBox(height: 4),
            Text(_pickedFile == null ? "PDF, Images acceptés" : "Fichier prêt", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              elevation: 4,
              shadowColor: const Color(0xFF27AE60).withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _isUploading ? null : _submitForm,
            child: _isUploading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(isEdit ? "Mettre à jour la dépense" : "Enregistrer la dépense", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Annuler", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildModernFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4A4A4A))),
    );
  }

  InputDecoration _premiumInputStyle(String hint, IconData icon, {String? suffixText}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      suffixText: suffixText,
      suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6F4A), width: 2)),
    );
  }

  void _submitForm() async {
    if (_montantController.text.isEmpty || _selectedCategoryId == null || (_selectedTrancheId == null && !isEdit)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Veuillez remplir les champs obligatoires"),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isUploading = true);

    try {
      double montant = double.parse(_montantController.text.replaceAll(',', '.'));
      String? facturePath;
      if (_pickedFile != null) {
        facturePath = await _financeService.uploadInvoice(
          _pickedFile!.name,
          kIsWeb ? _pickedFile!.bytes : _pickedFile!.path,
        );
      }

      if (isEdit) {
        await _financeService.updateInterSyndicExpense(
          expenseId: widget.expenseData!['id'],
          oldMontant: double.parse(widget.expenseData!['montant'].toString()),
          newMontant: montant,
          categorieId: _selectedCategoryId!,
          date: _selectedDate,
          description: _descController.text,
          facturePath: facturePath,
        );
      } else {
        await _financeService.addInterSyndicExpense(
          residenceId: widget.residenceId,
          interSyndicId: widget.interSyndicId,
          montant: montant,
          categorieId: _selectedCategoryId!,
          date: _selectedDate,
          trancheId: _selectedTrancheId,
          description: _descController.text,
          facturePath: facturePath,
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }
}
