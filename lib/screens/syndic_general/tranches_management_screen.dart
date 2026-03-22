import 'package:flutter/material.dart';
import 'package:resimanager/widgets/main_layout.dart';
import 'package:resimanager/widgets/nav_buttons.dart';
import '../../models/tranche_model.dart';
import '../../services/tranche_service.dart';
import '../../widgets/tranche_detail_card.dart';
import '../../widgets/assign_syndic_dialog.dart';

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

  // --- 1. FORMULAIRE D'AJOUT (DESIGN PREMIUM) ---
  void _showAddTrancheDialog() {
    final nomController = TextEditingController();
    final prixController = TextEditingController(); // Nouveau
    int? selectedSyndicId;

    showDialog(
      context: context,
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
              onPressed: () async {
                if (nomController.text.isNotEmpty) {
                  await _service.createTrancheComplet(
                    widget.residenceId,
                    nomController.text,
                    "",
                    selectedSyndicId,
                    double.tryParse(prixController.text),
                  );
                  Navigator.pop(context);
                  _loadTranches();
                }
              },
              child: const Text("Ajouter", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. FORMULAIRE DE MODIFICATION (UNIQUEMENT SYNDIC) ---
  void _showEditTrancheDialog(TrancheModel tranche) {
    // On pré-remplit tous les champs avec les données actuelles
    final nomController = TextEditingController(text: tranche.nom);
    final descController = TextEditingController(text: tranche.description ?? '');
    final prixController = TextEditingController(
        text: tranche.prixAnnuel != null ? tranche.prixAnnuel.toString() : ''
    );
    int? selectedSyndicId = tranche.interSyndicId;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Modifier la Tranche", style: TextStyle(fontWeight: FontWeight.bold)),
              // BOUTON SUPPRIMER (Poubelle rouge)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDeleteTranche(tranche, fromEditDialog: true),
              ),
            ],
          ),
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
                TextField(
                  controller: prixController,
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration("Montant en DH"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text("Annuler")
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
              onPressed: isSaving ? null : () async {
                setDialogState(() => isSaving = true);
                try {
                  // MISE À JOUR DANS SUPABASE
                  await _service.updateTrancheComplet(
                    tranche.id,
                    nomController.text,
                    descController.text,
                    selectedSyndicId,
                    double.tryParse(prixController.text),
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    _loadTranches(); // Rafraîchir
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Tranche mise à jour avec succès"))
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setDialogState(() => isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red)
                    );
                  }
                }
              },
              child: isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Enregistrer", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- FONCTION DE CONFIRMATION DE SUPPRESSION ---
  void _confirmDeleteTranche(TrancheModel tranche, {bool fromEditDialog = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer la tranche ?"),
        content: Text("Voulez-vous vraiment supprimer '${tranche.nom}' ? Cette action est irréversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _service.deleteTranche(tranche.id);
              if (mounted) {
                // Ferme le dialogue de confirmation
                Navigator.of(context, rootNavigator: true).pop();
                
                // Si on vient du dialogue d'édition, on le ferme aussi
                if (fromEditDialog) {
                  Navigator.of(context, rootNavigator: true).pop();
                }
                
                _loadTranches(); // Rafraîchit la liste
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Tranche supprimée avec succès"))
                );
              }
            },
            child: const Text("Supprimer définitivement", style: TextStyle(color: Colors.white)),
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
            _buildSearchBar(),
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
                final tranches = snapshot.data ?? [];
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tranches.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 1 : 3,
                    crossAxisSpacing: 20, mainAxisSpacing: 20,
                    mainAxisExtent: isMobile ? 320 : 380,
                  ),
                  itemBuilder: (context, index) {
                    final tranche = tranches[index];
                    return TrancheDetailCard(
                      tranche: tranche,
                      service: _service,
                      onAssignTap: () => _showEditTrancheDialog(tranche),
                      onEditTap: () => _showEditTrancheDialog(tranche),
                      onDeleteTap: () => _confirmDeleteTranche(tranche),
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

  // --- HELPERS UI ---
  Widget _buildResponsiveHeader(bool isMobile) {
    return Column( // On utilise une Column pour que rien ne déborde
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Bouton visible sur WEB
            if (!isMobile) _addButton(false),
          ],
        ),
        // Bouton visible on MOBILE (takes full width)
        if (isMobile) ...[
          const SizedBox(height: 15),
          _addButton(true),
        ]
      ],
    );
  }

  Widget _addButton(bool isFullWidth) {
    return ElevatedButton.icon(
      onPressed: _showAddTrancheDialog,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text("Ajouter une Tranche", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15)),
    );
  }

  Widget _buildSearchBar() {
    return TextField(decoration: InputDecoration(hintText: "Rechercher une tranche...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)));
  }

  Widget _buildTopSummary(List<TrancheModel> list, bool isMobile) {
    // On fait la somme des vrais comptes de chaque tranche
    int totalImm = list.fold(0, (sum, t) => sum + t.nombreImmeubles);
    int totalApp = list.fold(0, (sum, t) => sum + t.nombreAppartements);
    int totalPark = list.fold(0, (sum, t) => sum + t.nombreParkings);
    int totalGar = list.fold(0, (sum, t) => sum + t.nombreGarages);
    int totalBox = list.fold(0, (sum, t) => sum + t.nombreBoxes);

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _kpiItem("Tranches", list.length.toString(), Icons.domain, Colors.blue, true)),
              const SizedBox(width: 8),
              Expanded(child: _kpiItem("Immeubles", totalImm.toString(), Icons.apartment, Colors.green, true)),
              const SizedBox(width: 8),
              Expanded(child: _kpiItem("Apparts", totalApp.toString(), Icons.home_work, Colors.orange, true)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _kpiItem("Parkings", totalPark.toString(), Icons.local_parking, Colors.purple, true)),
              const SizedBox(width: 8),
              Expanded(child: _kpiItem("Garages", totalGar.toString(), Icons.storefront, Colors.teal, true)),
              const SizedBox(width: 8),
              Expanded(child: _kpiItem("Boxes", totalBox.toString(), Icons.inventory_2_outlined, Colors.brown, true)),
            ],
          ),
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _kpiItem("Total Tranches", list.length.toString(), Icons.domain, Colors.blue, false),
          const SizedBox(width: 15),
          _kpiItem("Immeubles", totalImm.toString(), Icons.apartment, Colors.green, false),
          const SizedBox(width: 15),
          _kpiItem("Appartements", totalApp.toString(), Icons.home_work, Colors.orange, false),
          const SizedBox(width: 15),
          _kpiItem("Parkings", totalPark.toString(), Icons.local_parking, Colors.purple, false),
          const SizedBox(width: 15),
          _kpiItem("Garages", totalGar.toString(), Icons.storefront, Colors.teal, false),
          const SizedBox(width: 15),
          _kpiItem("Boxes", totalBox.toString(), Icons.inventory_2_outlined, Colors.brown, false),
        ],
      ),
    );
  }

  Widget _kpiItem(String title, String val, IconData icon, Color color, bool isMobile) {
    return Container(
      width: isMobile ? null : 180, 
      padding: EdgeInsets.all(isMobile ? 10 : 15), 
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), 
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : 8), 
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), 
            child: Icon(icon, color: color, size: isMobile ? 18 : 20)
          ), 
          SizedBox(width: isMobile ? 8 : 12), 
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(title, style: TextStyle(color: Colors.grey, fontSize: isMobile ? 9 : 10), overflow: TextOverflow.ellipsis), 
                Text(val, style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold, color: darkGrey))
              ]
            ),
          )
        ]
      )
    );
  }

  Widget _buildCounterField(String label, TextEditingController controller) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFieldLabel(label), TextField(controller: controller, keyboardType: TextInputType.number, decoration: _buildInputDecoration("0"))]);
  }

  Widget _buildFieldLabel(String label) {
    return Padding(padding: const EdgeInsets.only(bottom: 6.0), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4A4E69))));
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF8F9FA), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryOrange, width: 1.5)));
  }

  Widget _buildSyndicDropdown(int? currentId, Function(int?) onChanged) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      // On utilise ton ID dynamique pour ne voir que ton équipe
      future: _service.getMyAvailableInterSyndics(widget.syndicId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }

        final mySyndics = snapshot.data ?? [];

        if (mySyndics.isEmpty) {
          return const Text(
              "Aucun syndic actif dans votre équipe.",
              style: TextStyle(color: Colors.red, fontSize: 11)
          );
        }

        return DropdownButtonFormField<int>(
          value: currentId,
          isExpanded: true,
          decoration: _buildInputDecoration("Choisir un responsable"),
          items: mySyndics.map((s) => DropdownMenuItem<int>(
            value: s['id'],
            child: Text("${s['prenom']} ${s['nom']}"),
          )).toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}