import 'package:flutter/material.dart';
import '../models/tranche_model.dart';

class TrancheCard extends StatelessWidget {
  final TrancheModel tranche;
  final VoidCallback onTap;

  const TrancheCard({
    super.key,
    required this.tranche,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: const Icon(Icons.domain, color: Colors.blue),
        ),
        title: Text(tranche.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tranche.description ?? "Pas de description"),
            const SizedBox(height: 5),
            // Utilisation des compteurs de ton modèle
            Text(
              "Immeubles: ${tranche.nombreImmeubles} | Apparts: ${tranche.nombreAppartements}",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}