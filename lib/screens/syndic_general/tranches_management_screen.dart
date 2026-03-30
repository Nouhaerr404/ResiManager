import 'package:flutter/material.dart';
import 'package:resimanager/widgets/main_layout.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

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

  void _confirmDeleteTranche(TrancheModel tranche) async {
    // 1. Scan de la base de données
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final usage = await _service.checkTrancheUsage(tranche.id);
    if (!mounted) return;
    Navigator.pop(context); // Fermer le loader

    int imm = usage['immeubles'] ?? 0;
    int esp = usage['espaces'] ?? 0;
    int dep = usage['depenses'] ?? 0;
    int pay = usage['paiements'] ?? 0;

    bool isPhysicallyUsed = imm > 0 || esp > 0;
    bool isFinanciallyUsed = dep > 0 || pay > 0;

    if (isPhysicallyUsed || isFinanciallyUsed) {
      // SCÉNARIO A : Action impossible
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text("Action impossible", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Cette tranche '${tranche.nom}' ne peut pas être supprimée car elle est encore utilisée :"),
              const SizedBox(height: 15),
              if (imm > 0) _buildUsageInfo(Icons.apartment, "$imm immeuble(s) rattaché(s)"),
              if (esp > 0) _buildUsageInfo(Icons.grid_view, "$esp espace(s) (parking/box/garage)"),
              if (dep > 0) _buildUsageInfo(Icons.money_off, "$dep dépense(s) enregistrée(s)"),
              if (pay > 0) _buildUsageInfo(Icons.payments, "$pay historique de paiements"),
              const SizedBox(height: 15),
              const Text("Cette tranche est actuellement active et contient des données structurelles (immeubles, résidents). Pour garantir la traçabilité de l'historique et la cohérence de l'audit financier, une tranche occupée ne peut pas être supprimée.",
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Compris")),
          ],
        ),
      );
    } else {
      // SCÉNARIO B : Dossier vide, confirmation classique
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Supprimer la tranche ?", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text("Voulez-vous vraiment supprimer la tranche '${tranche.nom}' ? Cette action est définitive."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                Navigator.pop(context); // Fermer le dialogue
                try {
                  await _service.deleteTranche(tranche.id);
                  _loadTranches();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tranche supprimée avec succès"), backgroundColor: Colors.green));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red));
                }
              },
              child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildUsageInfo(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
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
              _buildFieldLabel("L'Inter-Syndic Responsable"),
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
                _buildFieldLabel("L'Inter-Syndic Responsable"),
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
                  await _service.updateTrancheComplet(tranche.id, nomController.text.trim(), "", selectedSyndicId, double.tryParse(prixController.text));
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth >= 900;

    return MainLayout(
      title: isWeb ? '' : 'Gestion Tranches',
      activePage: 'Tranches',
      residenceId: widget.residenceId,
      syndicId: widget.syndicId,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWeb ? 30 : 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResponsiveHeader(isWeb),
            const SizedBox(height: 25),

            // ✅ MESSAGE D'ALERTE TRANCHES NON AFFECTÉES (GÉRÉ AU PLURIEL/SINGULIER)
            FutureBuilder<List<TrancheModel>>(
              future: _tranchesFuture,
              builder: (context, snapshot) {
                final unassigned = (snapshot.data ?? []).where((t) => t.interSyndicId == null).toList();
                if (unassigned.isEmpty) return const SizedBox.shrink();

                String msg;
                if (unassigned.length == 1) {
                  msg = "Alerte : La tranche '${unassigned.first.nom}' n'est plus affectée à un inter-syndic. Veuillez la réassigner.";
                } else {
                  msg = "Alerte : ${unassigned.length} tranches (${unassigned.map((e) => e.nom).join(', ')}) ne sont plus affectées à un inter-syndic. Veuillez les réassigner.";
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 25),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          msg,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            _buildSearchBar(),
            const SizedBox(height: 25),
            FutureBuilder<List<TrancheModel>>(
              future: _tranchesFuture,
              builder: (context, snapshot) => _buildTopSummary(snapshot.data ?? [], isWeb),
            ),
            const SizedBox(height: 35),
            FutureBuilder<List<TrancheModel>>(
              future: _tranchesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final allTranches = snapshot.data ?? [];
                final tranches = allTranches.where((t) => t.nom.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                if (tranches.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text("Aucune tranche trouvée."),
                  ));
                }

                if (!isWeb) {
                  return Column(
                    children: tranches.map((tranche) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TrancheDetailCard(
                        tranche: tranche,
                        service: _service,
                        onAssignTap: () => _showEditTrancheDialog(tranche),
                        onEditTap: () => _showEditTrancheDialog(tranche),
                        onDeleteTap: () => _confirmDeleteTranche(tranche),
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
                    mainAxisExtent: 460, 
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: "Rechercher une tranche...",
          border: InputBorder.none,
          icon: Icon(Icons.search, color: primaryOrange),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = "");
              }) 
            : null
        ),
      ),
    );
  }

  Widget _buildResponsiveHeader(bool isWeb) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (isWeb)
          const Text("Gestion des Tranches", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
        else
          const SizedBox.shrink(),
          
        ElevatedButton.icon(
          onPressed: _showAddTrancheDialog,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryOrange, 
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildTopSummary(List<TrancheModel> list, bool isWeb) {
    int tImm = list.fold(0, (s, t) => s + t.nombreImmeubles);
    int tApp = list.fold(0, (s, t) => s + t.nombreAppartements);
    int tPark = list.fold(0, (s, t) => s + t.nombreParkings);
    int tGar = list.fold(0, (s, t) => s + t.nombreGarages);
    int tBox = list.fold(0, (s, t) => s + t.nombreBoxes);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _kpiCardResponsive("Immeubles", tImm.toString(), Icons.apartment, Colors.green, !isWeb),
          const SizedBox(width: 12),
          _kpiCardResponsive("Apparts", tApp.toString(), Icons.meeting_room, Colors.blue, !isWeb),
          const SizedBox(width: 12),
          _kpiCardResponsive("Parkings", tPark.toString(), Icons.local_parking, Colors.orange, !isWeb),
          const SizedBox(width: 12),
          _kpiCardResponsive("Garages", tGar.toString(), Icons.store_mall_directory, Colors.purple, !isWeb),
          const SizedBox(width: 12),
          _kpiCardResponsive("Boxes", tBox.toString(), Icons.inventory_2_outlined, Colors.brown, !isWeb),
        ],
      ),
    );
  }

  Widget _kpiCardResponsive(String title, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      width: isMobile ? 110 : 160,
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color.withOpacity(0.7), size: isMobile ? 16 : 24),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey,
              fontSize: isMobile ? 10 : 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
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