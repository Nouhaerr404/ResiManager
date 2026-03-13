import 'package:flutter/material.dart';
import 'package:resimanager/widgets/main_layout.dart';
import '../../models/tranche_model.dart';
import '../../services/tranche_service.dart';
import '../../widgets/tranche_detail_card.dart';
import '../../widgets/assign_syndic_dialog.dart';

class TranchesManagementScreen extends StatefulWidget {
  final int residenceId;
  const TranchesManagementScreen({Key? key, required this.residenceId}) : super(key: key);

  @override
  _TranchesManagementScreenState createState() => _TranchesManagementScreenState();
}

class _TranchesManagementScreenState extends State<TranchesManagementScreen> {
  final TrancheService _service = TrancheService();
  late Future<List<TrancheModel>> _tranchesFuture;

  // Ta palette de couleurs
  final Color primaryOrange = const Color(0xFFFF6F4A);
  final Color darkGrey = const Color(0xFF2C2C2C);

  @override
  void initState() {
    super.initState();
    _refreshTranches();
  }

  void _refreshTranches() {
    setState(() {
      _tranchesFuture = _service.getTranchesByResidence(widget.residenceId);
    });
  }

  // --- FORMULAIRE D'AJOUT DE TRANCHE ---
  void _showAddTrancheDialog() {
    final nomController = TextEditingController();
    final descController = TextEditingController();
    final nbImmController = TextEditingController(text: '0');
    final nbAppController = TextEditingController(text: '0');
    final nbParkController = TextEditingController(text: '0');
    final nbGarController = TextEditingController(text: '0');
    final nbBoxController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une Tranche'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomController, decoration: const InputDecoration(labelText: 'Nom')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
              TextField(controller: nbImmController, decoration: const InputDecoration(labelText: 'Nombre Immeubles'), keyboardType: TextInputType.number),
              TextField(controller: nbAppController, decoration: const InputDecoration(labelText: 'Nombre Appartements'), keyboardType: TextInputType.number),
              TextField(controller: nbParkController, decoration: const InputDecoration(labelText: 'Nombre Parkings'), keyboardType: TextInputType.number),
              TextField(controller: nbGarController, decoration: const InputDecoration(labelText: 'Nombre Garages'), keyboardType: TextInputType.number),
              TextField(controller: nbBoxController, decoration: const InputDecoration(labelText: 'Nombre Boxes'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
            onPressed: () async {
              if (nomController.text.isNotEmpty) {
                await _service.createTrancheComplet(
                  widget.residenceId, nomController.text, descController.text,
                  int.tryParse(nbImmController.text) ?? 0, int.tryParse(nbAppController.text) ?? 0,
                  int.tryParse(nbParkController.text) ?? 0, int.tryParse(nbGarController.text) ?? 0,
                  int.tryParse(nbBoxController.text) ?? 0,
                );
                Navigator.pop(context);
                _refreshTranches();
              }
            },
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  // --- FORMULAIRE DE MODIFICATION DE TRANCHE ---
  void _showEditTrancheDialog(TrancheModel tranche) {
    final nomController = TextEditingController(text: tranche.nom);
    final descController = TextEditingController(text: tranche.description);
    final nbImmController = TextEditingController(text: tranche.nombreImmeubles.toString());
    final nbAppController = TextEditingController(text: tranche.nombreAppartements.toString());
    final nbParkController = TextEditingController(text: tranche.nombreParkings.toString());
    final nbGarController = TextEditingController(text: tranche.nombreGarages.toString());
    final nbBoxController = TextEditingController(text: tranche.nombreBoxes.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la Tranche'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomController, decoration: const InputDecoration(labelText: 'Nom')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
              TextField(controller: nbImmController, decoration: const InputDecoration(labelText: 'Nombre Immeubles'), keyboardType: TextInputType.number),
              TextField(controller: nbAppController, decoration: const InputDecoration(labelText: 'Nombre Appartements'), keyboardType: TextInputType.number),
              TextField(controller: nbParkController, decoration: const InputDecoration(labelText: 'Nombre Parkings'), keyboardType: TextInputType.number),
              TextField(controller: nbGarController, decoration: const InputDecoration(labelText: 'Nombre Garages'), keyboardType: TextInputType.number),
              TextField(controller: nbBoxController, decoration: const InputDecoration(labelText: 'Nombre Boxes'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
            onPressed: () async {
              if (nomController.text.isNotEmpty) {
                await _service.updateTrancheComplet(
                  tranche.id, nomController.text, descController.text,
                  int.tryParse(nbImmController.text) ?? 0, int.tryParse(nbAppController.text) ?? 0,
                  int.tryParse(nbParkController.text) ?? 0, int.tryParse(nbGarController.text) ?? 0,
                  int.tryParse(nbBoxController.text) ?? 0,
                );
                Navigator.pop(context);
                _refreshTranches();
              }
            },
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTranche(TrancheModel tranche) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer la tranche ${tranche.nom} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await _service.deleteTranche(tranche.id);
              Navigator.pop(context);
              _refreshTranches();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  // --- FORMULAIRE D'ASSIGNATION ---
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

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Gestion des Tranches',
      body: Stack(
        children: [
          // 1. IMAGE DE FOND
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/tranche_bg.png'), // Vérifie le chemin
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. VOILE SOMBRE
          Container(
            color: Colors.black.withOpacity(0.55),
          ),

          // 3. LE CONTENU
          Column(
            children: [
              // BOUTON AJOUTER
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _showAddTrancheDialog,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Ajouter une tranche', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),

              // LISTE DES TRANCHES
              Expanded(
                child: FutureBuilder<List<TrancheModel>>(
                  future: _tranchesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    final tranches = snapshot.data ?? [];
                    if (tranches.isEmpty) {
                      return const Center(
                        child: Text("Aucune tranche trouvée", style: TextStyle(color: Colors.white, fontSize: 18)),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemCount: tranches.length,
                      itemBuilder: (context, index) {
                        return Opacity(
                          opacity: 0.95,
                          child: TrancheDetailCard(
                            tranche: tranches[index],
                            service: _service,
                            onAssignTap: () => _showAssignSyndicDialog(tranches[index], _refreshTranches),
                            onEditTap: () => _showEditTrancheDialog(tranches[index]),
                            onDeleteTap: () => _confirmDeleteTranche(tranches[index]),
                          ),

                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}