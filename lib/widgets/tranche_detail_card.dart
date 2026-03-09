import 'package:flutter/material.dart';
import '../../models/tranche_model.dart';
import '../../services/tranche_service.dart';

class TrancheDetailCard extends StatelessWidget { // On peut le transformer en StatelessWidget
  final TrancheModel tranche;
  final TrancheService service;
  final VoidCallback onAssignTap;

  const TrancheDetailCard({Key? key, required this.tranche, required this.service, required this.onAssignTap,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ExpansionTile(
        title: Text(tranche.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(tranche.interSyndicNom ?? "Aucun inter-syndic assigné",
            style: TextStyle(color: tranche.interSyndicNom == null ? Colors.red : Colors.green)),
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
          )// Plus tard, on ajoutera le bouton pour assigner l'inter-syndic ici
        ],
      ),
    );

  }
}