import 'package:flutter/material.dart';
import '../../models/tranche_model.dart';
import '../../services/tranche_service.dart';

class TrancheDetailCard extends StatelessWidget {
  final TrancheModel tranche;
  final TrancheService service;
  final VoidCallback onAssignTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  const TrancheDetailCard({
    Key? key,
    required this.tranche,
    required this.service,
    required this.onAssignTap,
    required this.onEditTap,
    required this.onDeleteTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ExpansionTile(
        title: Text(tranche.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          tranche.interSyndicNom ?? "Aucun inter-syndic assigné",
          style: TextStyle(color: tranche.interSyndicNom == null ? Colors.red : Colors.green),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: onEditTap),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDeleteTap),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          ListTile(
            title: const Text("Capacité de la tranche"),
            subtitle: Text(
              "Immeubles: ${tranche.nombreImmeubles} | Appartements: ${tranche.nombreAppartements}\n"
              "Parkings: ${tranche.nombreParkings} | Garages: ${tranche.nombreGarages} | Boxes: ${tranche.nombreBoxes}",
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: onAssignTap,
              icon: const Icon(Icons.person_add),
              label: const Text("Assigner un Inter-syndic"),
            ),
          )
        ],
      ),
    );
  }
}