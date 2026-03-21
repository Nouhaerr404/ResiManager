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
          title: const Text("Ajouter une Tranche", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel("Nom de la tranche"),
                TextField(controller: nomController, decoration: _buildInputDecoration("Ex: Tranche A")),
                const SizedBox(height: 15),

                _buildFieldLabel("Syndic Affecté"),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _service.getMyAvailableInterSyndics(widget.syndicId), // ID DYNAMIQUE
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
          actions: [
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler"))),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
                    onPressed: () async {
                      if (nomController.text.isNotEmpty) {
                        await _service.createTrancheComplet(
                          widget.residenceId, nomController.text, "", selectedSyndicId,
                          int.tryParse(nbImmController.text) ?? 0, int.tryParse(nbAppController.text) ?? 0,
                          int.tryParse(nbParkController.text) ?? 0, int.tryParse(nbGarController.text) ?? 0,
                          int.tryParse(nbBoxController.text) ?? 0,
                        );
                        Navigator.pop(context);
                        _loadTranches();
                      }
                    },
                    child: const Text("Ajouter", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. FORMULAIRE DE MODIFICATION (UNIQUEMENT SYNDIC) ---
  void _showEditTrancheDialog(TrancheModel tranche) {
    print(">>> L'ID du syndic connecté utilisé est : ${widget.syndicId}");
    // Variable pour stocker le choix, initialisée avec le syndic actuel
    int? currentSelectedId = tranche.interSyndicId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // INDISPENSABLE pour que le clic marche
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Responsable : ${tranche.nom}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel("Nouveau Syndic Responsable"),

                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _service.getMyAvailableInterSyndics(widget.syndicId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: LinearProgressIndicator());
                    }

                    final mySyndics = snapshot.data ?? [];

                    if (mySyndics.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text("Aucun syndic trouvé dans votre équipe.", style: TextStyle(color: Colors.red, fontSize: 12)),
                      );
                    }

                    // LE MENU DÉROULANT
                    return DropdownButtonFormField<int>(
                      value: currentSelectedId,
                      isExpanded: true,
                      hint: const Text("Choisir un collaborateur"),
                      decoration: _buildInputDecoration(""),
                      items: mySyndics.map((s) {
                        return DropdownMenuItem<int>(
                          value: s['id'],
                          child: Text("${s['prenom']} ${s['nom']}"),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        // On utilise setDialogState pour mettre à jour l'affichage de la popup
                        setDialogState(() {
                          currentSelectedId = newValue;
                        });
                        print("Syndic sélectionné : $newValue");
                      },
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
                onPressed: () async {
                  // On appelle la fonction de mise à jour réelle
                  await _service.assignInterSyndic(tranche.id, currentSelectedId);
                  Navigator.pop(context);
                  _loadTranches(); // On rafraîchit la page principale
                },
                child: const Text("Enregistrer", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
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
              builder: (context, snapshot) => _buildTopSummary(snapshot.data ?? []),
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
                  itemBuilder: (context, index) => TrancheDetailCard(
                    tranche: tranches[index],
                    service: _service,
                    onAssignTap: () => _showEditTrancheDialog(tranches[index]),
                    onEditTap: () => _showEditTrancheDialog(tranches[index]),
                  ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        if (!isMobile) _addButton(false),
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

  Widget _buildTopSummary(List<TrancheModel> list) {
    int totalImm = list.fold(0, (sum, t) => sum + t.nombreImmeubles);
    int totalApp = list.fold(0, (sum, t) => sum + t.nombreAppartements);
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
      _kpiItem("Tranches", list.length.toString(), Icons.domain, Colors.blue),
      const SizedBox(width: 15),
      _kpiItem("Immeubles", totalImm.toString(), Icons.apartment, Colors.green),
      const SizedBox(width: 15),
      _kpiItem("Appartements", totalApp.toString(), Icons.home_work, Colors.orange),
    ]));
  }

  Widget _kpiItem(String title, String val, IconData icon, Color color) {
    return Container(width: 180, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10)), Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGrey))])]));
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
}