import 'package:flutter/material.dart';
import 'package:resimanager/widgets/main_layout.dart';
import 'package:resimanager/widgets/nav_buttons.dart';
import '../../models/tranche_model.dart';
import '../../services/tranche_service.dart';
import '../../widgets/tranche_detail_card.dart';

class TranchesManagementScreen extends StatefulWidget {
  final int residenceId;
  final int syndicId;

  const TranchesManagementScreen({
    Key? key,
    required this.residenceId,
    required this.syndicId
  }) : super(key: key);

  @override
  _TranchesManagementScreenState createState() => _TranchesManagementScreenState();
}

class _TranchesManagementScreenState extends State<TranchesManagementScreen> {
  final TrancheService _service = TrancheService();
  late Future<List<TrancheModel>> _tranchesFuture;
  String _selectedFilter = "Tous"; // "Tous", "Actif", "Inactif"

  final Color primaryOrange = const Color(0xFFFF6F4A);
  final Color darkGrey = const Color(0xFF2C2C2C);

  @override
  void initState() {
    super.initState();
    _loadTranches();
  }

  void _loadTranches() {
    setState(() {
      _tranchesFuture = _service.getTranchesByResidence(widget.residenceId);
    });
  }

  // --- FORMULAIRE D'AJOUT CORRIGÉ ---
  void _showAddTrancheDialog() {
    final nomController = TextEditingController();
    final prixController = TextEditingController();
    int? selectedSyndicId;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Nouvelle Tranche", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel("Nom de la tranche *"),
              TextField(controller: nomController, decoration: _buildInputDecoration("Ex: Tranche Est")),
              const SizedBox(height: 20),
              _buildFieldLabel("Syndic Responsable"),
              _buildSyndicDropdown(selectedSyndicId, (val) => setDialogState(() => selectedSyndicId = val)),
              const SizedBox(height: 20),
              _buildFieldLabel("Objectif de collecte annuel (Optionnel)"),
              TextField(
                controller: prixController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration("Ex: 50000 DH"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context), 
              child: const Text("Annuler")
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
              onPressed: isSaving ? null : () async {
                if (nomController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Le nom est obligatoire")));
                  return;
                }

                setDialogState(() => isSaving = true);
                try {
                  await _service.createTrancheComplet(
                    widget.residenceId,
                    nomController.text.trim(),
                    "",
                    selectedSyndicId,
                    double.tryParse(prixController.text) ?? 0.0,
                  );
                  
                  if (mounted) {
                    Navigator.pop(context); // Ferme le dialogue
                    _loadTranches(); // Rafraîchit la liste
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Tranche ajoutée avec succès !"), backgroundColor: Colors.green)
                    );
                  }
                } catch (e) {
                  setDialogState(() => isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erreur lors de l'ajout : $e"), backgroundColor: Colors.red)
                  );
                }
              },
              child: isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Ajouter", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- FORMULAIRE DE MODIFICATION ---
  void _showEditTrancheDialog(TrancheModel tranche) {
    final nomController = TextEditingController(text: tranche.nom);
    final descController = TextEditingController(text: tranche.description ?? '');
    final prixController = TextEditingController(text: tranche.prixAnnuel.toString());
    int? selectedSyndicId = tranche.interSyndicId;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Modifier la Tranche", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel("Nom de la tranche"),
                TextField(controller: nomController, decoration: _buildInputDecoration("Nom")),
                const SizedBox(height: 15),
                _buildFieldLabel("Description (Optionnel)"),
                TextField(controller: descController, maxLines: 2, decoration: _buildInputDecoration("Ex: Bloc Sud...")),
                const SizedBox(height: 15),
                _buildFieldLabel("Syndic Responsable"),
                _buildSyndicDropdown(selectedSyndicId, (val) => setDialogState(() => selectedSyndicId = val)),
                const SizedBox(height: 15),
                _buildFieldLabel("Objectif de collecte annuel"),
                TextField(controller: prixController, keyboardType: TextInputType.number, decoration: _buildInputDecoration("Montant en DH")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
              onPressed: isSaving ? null : () async {
                setDialogState(() => isSaving = true);
                try {
                  await _service.updateTrancheComplet(tranche.id, nomController.text.trim(), descController.text.trim(), selectedSyndicId, double.tryParse(prixController.text));
                  if (mounted) {
                    Navigator.pop(context);
                    _loadTranches();
                  }
                } catch (e) {
                  setDialogState(() => isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red));
                }
              },
              child: const Text("Enregistrer", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmToggleTrancheStatut(TrancheModel tranche) {
    bool isActif = tranche.statut == 'Actif';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isActif ? "Désactiver la tranche ?" : "Réactiver la tranche ?"),
        content: Text(isActif ? "Désactiver '${tranche.nom}' ?" : "Réactiver '${tranche.nom}' ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isActif ? Colors.red : Colors.green),
            onPressed: () async {
              try {
                await _service.setTrancheStatut(tranche.id, isActif ? 'Inactif' : 'Actif');
                if (mounted) {
                  Navigator.pop(context);
                  _loadTranches();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red));
              }
            },
            child: Text(isActif ? "Désactiver" : "Réactiver", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 800;

    return MainLayout(
      title: isMobile ? 'Gestion Tranches' : '',
      activePage: 'Tranches',
      residenceId: widget.residenceId,
      syndicId: widget.syndicId,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 15 : 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResponsiveHeader(isMobile),
            const SizedBox(height: 25),
            _buildFilterBar(),
            const SizedBox(height: 25),
            FutureBuilder<List<TrancheModel>>(
              future: _tranchesFuture,
              builder: (context, snapshot) => _buildTopSummary(snapshot.data ?? [], isMobile),
            ),
            const SizedBox(height: 35),
            FutureBuilder<List<TrancheModel>>(
              future: _tranchesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final allTranches = snapshot.data ?? [];
                final tranches = allTranches.where((t) => _selectedFilter == "Tous" ? true : t.statut == _selectedFilter).toList();

                if (tranches.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text("Aucune tranche trouvée."),
                  ));
                }

                // CHANGEMENT : Utilisation d'une Column sur mobile pour éviter les overflows de grille
                if (isMobile) {
                  return Column(
                    children: tranches.map((tranche) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TrancheDetailCard(
                        tranche: tranche,
                        service: _service,
                        onAssignTap: () => _showEditTrancheDialog(tranche),
                        onEditTap: () => _showEditTrancheDialog(tranche),
                        onDeleteTap: () => _confirmToggleTrancheStatut(tranche),
                      ),
                    )).toList(),
                  );
                }

                // Desktop Grid
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tranches.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 20, mainAxisSpacing: 20,
                    mainAxisExtent: 480, // Hauteur augmentée pour éviter les coupures
                  ),
                  itemBuilder: (context, index) {
                    final tranche = tranches[index];
                    return TrancheDetailCard(
                      tranche: tranche,
                      service: _service,
                      onAssignTap: () => _showEditTrancheDialog(tranche),
                      onEditTap: () => _showEditTrancheDialog(tranche),
                      onDeleteTap: () => _confirmToggleTrancheStatut(tranche),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: ["Tous", "Actif", "Inactif"].map((f) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: ChoiceChip(
          label: Text(f),
          selected: _selectedFilter == f,
          onSelected: (val) => setState(() => _selectedFilter = f),
          selectedColor: primaryOrange,
          labelStyle: TextStyle(color: _selectedFilter == f ? Colors.white : Colors.black),
        ),
      )).toList(),
    );
  }

  Widget _buildResponsiveHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Gestion des Tranches", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ElevatedButton.icon(
          onPressed: _showAddTrancheDialog,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
        ),
      ],
    );
  }

  Widget _buildTopSummary(List<TrancheModel> list, bool isMobile) {
    int tImm = list.fold(0, (s, t) => s + t.nombreImmeubles);
    int tApp = list.fold(0, (s, t) => s + t.nombreAppartements);
    return Row(children: [_kpiS("Tranches", list.length.toString(), Colors.blue), const SizedBox(width: 15), _kpiS("Immeubles", tImm.toString(), Colors.green), const SizedBox(width: 15), _kpiS("Apparts", tApp.toString(), Colors.orange)]);
  }

  Widget _kpiS(String t, String v, Color c) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontSize: 10, color: Colors.grey)), Text(v, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c))]));
  }

  Widget _buildFieldLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 6.0), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)));
  InputDecoration _buildInputDecoration(String hint) => InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF8F9FA), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)));

  Widget _buildSyndicDropdown(int? currentId, Function(int?) onChanged) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _service.getMyAvailableInterSyndics(widget.syndicId, widget.residenceId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final mySyndics = snapshot.data ?? [];
        return DropdownButtonFormField<int>(
          value: currentId,
          isExpanded: true,
          decoration: _buildInputDecoration("Choisir un responsable"),
          items: mySyndics.map((s) => DropdownMenuItem<int>(value: s['id'], child: Text("${s['prenom']} ${s['nom']}"))).toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}