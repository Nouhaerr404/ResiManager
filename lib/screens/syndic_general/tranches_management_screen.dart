import 'package:flutter/material.dart';
import 'package:resimanager/widgets/main_layout.dart';
import '../../models/tranche_model.dart';
import '../../services/tranche_service.dart';

// IMPORTANT : C'est ici qu'on importe le widget qu'on a séparé !
import '../../widgets/tranche_detail_card.dart';

class TranchesManagementScreen extends StatefulWidget {
  final int residenceId;
  const TranchesManagementScreen({Key? key, required this.residenceId}) : super(key: key);

  @override
  _TranchesManagementScreenState createState() => _TranchesManagementScreenState();
}

class _TranchesManagementScreenState extends State<TranchesManagementScreen> {
  final TrancheService _service = TrancheService();
  late Future<List<TrancheModel>> _tranchesFuture;

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

  // Boîte de dialogue pour ajouter une tranche (elle reste ici car elle est liée à l'écran)
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
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Gestion des Tranches',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _showAddTrancheDialog,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une tranche'),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TrancheModel>>(
              future: _tranchesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tranches = snapshot.data ?? [];
                if (tranches.isEmpty) {
                  return const Center(child: Text("Aucune tranche. Cliquez sur '+' pour en ajouter une."));
                }
                return ListView.builder(
                  itemCount: tranches.length,
                  itemBuilder: (context, index) {
                    return TrancheDetailCard(tranche: tranches[index], service: _service);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}