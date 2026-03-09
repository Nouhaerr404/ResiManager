import 'package:flutter/material.dart';
import '../../models/tranche_model.dart';
import '../../services/tranche_service.dart';

class TrancheDetailCard extends StatelessWidget { // On peut le transformer en StatelessWidget
  final TrancheModel tranche;
  final TrancheService service;

  const TrancheDetailCard({Key? key, required this.tranche, required this.service}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ExpansionTile(
        title: Text(tranche.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(tranche.description ?? "Sans description"),
        children: [
          ListTile(
            title: const Text("Capacité de la tranche"),
            subtitle: Text(
              "Immeubles: ${tranche.nombreImmeubles} | Appartements: ${tranche.nombreAppartements}\n"
                  "Parkings: ${tranche.nombreParkings} | Garages: ${tranche.nombreGarages} | Boxes: ${tranche.nombreBoxes}",
            ),
          ),
          // Plus tard, on ajoutera le bouton pour assigner l'inter-syndic ici
        ],
      ),
    );
  }
}