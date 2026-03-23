import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../services/finance_service.dart';

class AddGlobalExpenseScreen extends StatefulWidget {
  final int residenceId;
  final int syndicId;
  const AddGlobalExpenseScreen({Key? key, required this.residenceId, required this.syndicId}) : super(key: key);

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

  // Pour forcer le rafraîchissement du FutureBuilder des catégories
  Key _gridKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isWeb = width > 900;

    return Scaffold(
      backgroundColor: backgroundBeige,
      appBar: AppBar(
        title: const Text("Ajouter une Dépense", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isWeb ? width * 0.2 : 20, vertical: 30),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("1. Catégorie *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton.icon(
                    onPressed: _showAddCategoryDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Nouvelle"),
                    style: TextButton.styleFrom(foregroundColor: primaryOrange),
                  )
                ],
              ),
              const SizedBox(height: 10),

              _buildCatGrid(isWeb),

              const SizedBox(height: 30),
              const Text("2. Détails de la dépense", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 15),

              _buildFormCard(),

              const SizedBox(height: 40),
              _buildActionBtns(),
              const SizedBox(height: 30),
            ]
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final TextEditingController catController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nouvelle Catégorie Globale"),
        content: TextField(
          controller: catController,
          decoration: const InputDecoration(hintText: "Nom de la catégorie (ex: Ascenseur)"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
            onPressed: () async {
              if (catController.text.trim().isEmpty) return;
              try {
                // On passe explicitement le type 'globale'
                await _service.addExpenseCategory(catController.text.trim(), type: 'globale');
                Navigator.pop(context);
                setState(() {
                  _gridKey = UniqueKey(); // Rafraîchit la grille
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Catégorie ajoutée !")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red));
              }
            },
            child: const Text("Ajouter", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCatGrid(bool isWeb) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: _gridKey,
      future: _service.getCategories('globale'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final cats = snapshot.data ?? [];
        
        if (cats.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text("Aucune catégorie globale. Cliquez sur 'Nouvelle' pour en ajouter une."),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWeb ? 3 : 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3
          ),
          itemCount: cats.length,
          itemBuilder: (context, i) {
            bool sel = _selectedCategoryId == cats[i]['id'];
            return InkWell(
              onTap: () => setState(() => _selectedCategoryId = cats[i]['id']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                    color: sel ? primaryOrange : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? primaryOrange : Colors.grey.shade200, width: 2),
                    boxShadow: sel ? [BoxShadow(color: primaryOrange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : []
                ),
                child: Center(
                  child: Text(
                    cats[i]['nom'], 
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal, 
                      color: sel ? Colors.white : Colors.black87,
                      fontSize: 13
                    )
                  )
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: Column(children: [
        DropdownButtonFormField<int>(
            value: _selectedAnnee,
            decoration: const InputDecoration(labelText: "Année de facturation", prefixIcon: Icon(Icons.calendar_today)),
            items: [2024, 2025, 2026, 2027].map((a) => DropdownMenuItem(value: a, child: Text("Année $a"))).toList(),
            onChanged: (v) => setState(() => _selectedAnnee = v!)
        ),
        const SizedBox(height: 20),
        TextField(
            controller: _montantController,
            decoration: const InputDecoration(labelText: "Montant (DH)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.money)),
            keyboardType: const TextInputType.numberWithOptions(decimal: true)
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _descController,
          maxLines: 2,
          decoration: const InputDecoration(labelText: "Description (Optionnel)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
        ),
        const SizedBox(height: 25),
        _buildUploadBox(),
      ]),
    );
  }

  Widget _buildUploadBox() {
    return InkWell(
      onTap: () async {
        FilePickerResult? r = await FilePicker.platform.pickFiles(type: FileType.image);
        if (r != null) setState(() => _pickedFile = r.files.first);
      },
      child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
          decoration: BoxDecoration(
              color: const Color(0xFFF8F7FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple.shade100, style: BorderStyle.solid, width: 2)
          ),
          child: Column(children: [
            Icon(Icons.cloud_upload_outlined, size: 40, color: _pickedFile == null ? Colors.deepPurple : Colors.green),
            const SizedBox(height: 12),
            Text(
              _pickedFile == null ? "Cliquer pour joindre la facture" : "Facture jointe : ${_pickedFile!.name}",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: _pickedFile == null ? Colors.black87 : Colors.green),
            ),
            if (_pickedFile != null) ...[
              const SizedBox(height: 8),
              Text("Cliquez pour changer", style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
            ]
          ])
      ),
    );
  }

  Widget _buildActionBtns() {
    return SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60), 
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
            ),
            onPressed: _isUploading ? null : _submitForm,
            child: _isUploading
                ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Text("ENREGISTRER LA DÉPENSE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2))
        )
    );
  }

  void _submitForm() async {
    if (_montantController.text.isEmpty || _selectedCategoryId == null) return;

    setState(() => _isUploading = true);

    try {
      String? fileUrl;

      // ÉTAPE A : On envoie l'image d'abord
      if (_pickedFile != null) {
        // On récupère le chemin pour Windows ou les bytes pour le Web
        final dynamic fileData = kIsWeb ? _pickedFile!.bytes : _pickedFile!.path;

        fileUrl = await _service.uploadInvoice(_pickedFile!.name, fileData);

        if (fileUrl == null) {
          throw Exception("L'upload a échoué, vérifiez votre connexion ou le bucket Supabase");
        }
      }

      // ÉTAPE B : On enregistre avec le lien reçu (fileUrl)
      await _service.addGlobalExpense(
        residenceId: widget.residenceId,
        montant: double.parse(_montantController.text.replaceAll(',', '.')),
        categorieId: _selectedCategoryId!,
        annee: _selectedAnnee,
        syndicId: widget.syndicId,
        facturePath: fileUrl, // <--- C'est ici que le "Oui" se joue !
        description: _descController.text,
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red));
    }
  }}