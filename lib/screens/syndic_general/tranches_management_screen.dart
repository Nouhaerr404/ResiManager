import 'package:flutter/material.dart';
import 'package:resimanager/widgets/main_layout.dart';
import '../../models/tranche_model.dart';
import '../../services/tranche_service.dart';
import '../../widgets/tranche_detail_card.dart';
import '../../widgets/assign_syndic_dialog.dart'; // IMPORTANT : L'import pour le dialogue

class TranchesManagementScreen extends StatefulWidget {
  final int residenceId;
  const TranchesManagementScreen({Key? key, required this.residenceId}) : super(key: key);

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

  // --- 1. FONCTION POUR ASSIGNER UN SYNDIC (Celle qui manquait !) ---
  void _showAssignSyndicDialog(TrancheModel tranche, VoidCallback onAssigned) {
    showDialog(
      context: context,
      builder: (context) => AssignSyndicDialog(
        tranche: tranche,
        service: _service,
        onAssigned: onAssigned,
      ),
    );
  }

  // --- 2. FONCTION POUR AJOUTER UNE TRANCHE ---
  void _showAddTrancheDialog() {
    final nomController = TextEditingController();
    final nbImmController = TextEditingController(text: '0');
    final nbAppController = TextEditingController(text: '0');
    final nbParkController = TextEditingController(text: '0');
    final nbGarController = TextEditingController(text: '0');
    final nbBoxController = TextEditingController(text: '0');
    int? selectedSyndicId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Text(
            "Ajouter une Tranche",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF2C2C2C)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- NOM ---
                _buildFieldLabel("Nom de la tranche"),
                TextField(
                  controller: nomController,
                  decoration: _buildInputDecoration("Ex: Tranche A"),
                ),
                const SizedBox(height: 15),

                // --- SYNDIC ---
                _buildFieldLabel("Syndic Affecté"),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _service.getAvailableInterSyndics(),
                  builder: (context, snapshot) {
                    final syndics = snapshot.data ?? [];
                    return DropdownButtonFormField<int>(
                      isExpanded: true,
                      decoration: _buildInputDecoration("Sélectionner un syndic"),
                      items: syndics.map((s) => DropdownMenuItem<int>(
                        value: s['id'],
                        child: Text("${s['prenom']} ${s['nom']}"),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => selectedSyndicId = val),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // --- COMPTEURS (En ligne pour gagner de la place) ---
                Row(
                  children: [
                    Expanded(child: _buildCounterField("Immeubles", nbImmController)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildCounterField("Appartements", nbAppController)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildCounterField("Parkings", nbParkController)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildCounterField("Garages", nbGarController)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                    width: (MediaQuery.of(context).size.width / 2) - 40,
                    child: _buildCounterField("Boxes", nbBoxController)
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
                    onPressed: () async {
                      if (nomController.text.isNotEmpty) {
                        await _service.createTrancheComplet(
                          widget.residenceId,
                          nomController.text,
                          "", // Description vide car supprimée du formulaire
                          selectedSyndicId,
                          int.tryParse(nbImmController.text) ?? 0,
                          int.tryParse(nbAppController.text) ?? 0,
                          int.tryParse(nbParkController.text) ?? 0,
                          int.tryParse(nbGarController.text) ?? 0,
                          int.tryParse(nbBoxController.text) ?? 0,
                        );
                        Navigator.pop(context);
                        _loadTranches(); // Rafraîchir la liste
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6F4A), // Orange Corail
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Ajouter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS POUR LE DESIGN ---

  Widget _buildCounterField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: _buildInputDecoration("0"),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4A4E69)),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFF6F4A), width: 1.5),
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 15 : 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResponsiveHeader(isMobile),
            const SizedBox(height: 25),
            _buildSearchBar(),
            const SizedBox(height: 25),

            // RÉSUMÉ KPIs
            FutureBuilder<List<TrancheModel>>(
              future: _tranchesFuture,
              builder: (context, snapshot) => _buildTopSummary(snapshot.data ?? []),
            ),
            const SizedBox(height: 35),

            // GRILLE DE TRANCHES (Responsive)
            FutureBuilder<List<TrancheModel>>(
              future: _tranchesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tranches = snapshot.data ?? [];
                if (tranches.isEmpty)
                  return const Center(child: Text("Aucune tranche trouvée."));

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tranches.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 1 : 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    mainAxisExtent: isMobile
                        ? 320
                        : 380, // Hauteur que tu as choisie
                  ),
                  itemBuilder: (context, index) {
                    final tranche = tranches[index]; // On récupère la tranche actuelle

                    return TrancheDetailCard(
                      tranche: tranche,
                      service: _service,
                      onAssignTap: () =>
                          _showAssignSyndicDialog(tranche, _loadTranches),
                      onEditTap: () =>
                          _showEditTrancheDialog(
                              tranche), // Action pour le bouton modifier
                    );
                  },
                );
              }
            )
          ]
        ),
      ),
    );
  }

  // --- HELPERS UI ---

  Widget _buildResponsiveHeader(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Gestion des Tranches", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkGrey)),
          const SizedBox(height: 10),
          _addButton(true),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Gestion des Tranches", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: darkGrey)),
          const Text("Gérez les tranches de la résidence", style: TextStyle(color: Colors.grey)),
        ]),
        _addButton(false),
      ],
    );
  }

  Widget _addButton(bool isFullWidth) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: _showAddTrancheDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Ajouter une Tranche", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: "Rechercher une tranche...",
        prefixIcon: const Icon(Icons.search),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildTopSummary(List<TrancheModel> list) {
    int totalImm = list.fold(0, (sum, t) => sum + t.nombreImmeubles);
    int totalApp = list.fold(0, (sum, t) => sum + t.nombreAppartements);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _kpiItem("Total Tranches", list.length.toString(), Icons.domain, Colors.blue),
          const SizedBox(width: 15),
          _kpiItem("Immeubles", totalImm.toString(), Icons.apartment, Colors.green),
          const SizedBox(width: 15),
          _kpiItem("Appartements", totalApp.toString(), Icons.home_work, Colors.orange),
        ],
      ),
    );
  }

  Widget _kpiItem(String title, String val, IconData icon, Color color) {
    return Container(
      width: 180, padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10), overflow: TextOverflow.ellipsis),
          Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGrey)),
        ])),
      ]),
    );
  }

  void _showEditTrancheDialog(TrancheModel tranche) {
    // On pré-remplit les contrôleurs avec les données actuelles de la tranche
    final nomController = TextEditingController(text: tranche.nom);
    final nbImmController = TextEditingController(text: tranche.nombreImmeubles.toString());
    final nbAppController = TextEditingController(text: tranche.nombreAppartements.toString());
    final nbParkController = TextEditingController(text: tranche.nombreParkings.toString());
    final nbGarController = TextEditingController(text: tranche.nombreGarages.toString());
    final nbBoxController = TextEditingController(text: tranche.nombreBoxes.toString());
    int? selectedSyndicId = tranche.interSyndicId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Text(
            "Modifier ${tranche.nom}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF2C2C2C)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel("Nom de la tranche"),
                TextField(controller: nomController, decoration: _buildInputDecoration("Nom")),
                const SizedBox(height: 15),

                _buildFieldLabel("Syndic Affecté"),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _service.getAvailableInterSyndics(),
                  builder: (context, snapshot) {
                    final syndics = snapshot.data ?? [];
                    return DropdownButtonFormField<int>(
                      value: selectedSyndicId,
                      isExpanded: true,
                      decoration: _buildInputDecoration("Sélectionner"),
                      items: syndics.map((s) => DropdownMenuItem<int>(
                        value: s['id'],
                        child: Text("${s['prenom']} ${s['nom']}"),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => selectedSyndicId = val),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // LES COMPTEURS EN GRILLE (Design Premium)
                Row(
                  children: [
                    Expanded(child: _buildCounterField("Immeubles", nbImmController)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildCounterField("Appartements", nbAppController)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildCounterField("Parkings", nbParkController)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildCounterField("Garages", nbGarController)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCounterField("Boxes", nbBoxController),
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
                    onPressed: () async {
                      await _service.updateTrancheComplet(
                        tranche.id,
                        nomController.text,
                        selectedSyndicId,
                        int.tryParse(nbImmController.text) ?? 0,
                        int.tryParse(nbAppController.text) ?? 0,
                        int.tryParse(nbParkController.text) ?? 0,
                        int.tryParse(nbGarController.text) ?? 0,
                        int.tryParse(nbBoxController.text) ?? 0,
                      );
                      Navigator.pop(context);
                      _loadTranches();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6F4A),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Enregistrer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }}