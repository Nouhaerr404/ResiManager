import 'package:flutter/material.dart';
import '../models/tranche_model.dart';
import '../services/tranche_service.dart';

class TrancheDetailCard extends StatelessWidget {
  final TrancheModel tranche;
  final TrancheService service;
  final VoidCallback onAssignTap;
  final VoidCallback onEditTap;

  const TrancheDetailCard({
    Key? key,
    required this.tranche,
    required this.service,
    required this.onAssignTap,
    required this.onEditTap,
  }) : super(key: key);

  final Color primaryOrange = const Color(0xFFFF6F4A);
  final Color darkGrey = const Color(0xFF2C2C2C);


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), // Padding réduit
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // La carte s'adapte au contenu
        children: [
          // 1. HEADER : NOM + ACTIONS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(tranche.nom, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkGrey))),
              IconButton(
                onPressed: onEditTap, // <--- ON UTILISE L'ACTION ICI
                icon: Icon(Icons.edit_outlined, color: Colors.blue.shade300, size: 18)
              )  ],
          ),
          if (tranche.description != null)
            Text(tranche.description!, style: const TextStyle(color: Colors.grey, fontSize: 12)),

          const SizedBox(height: 15),

          // 2. BLOC RESPONSABLE
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: primaryOrange.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Icon(Icons.person_pin_rounded, color: primaryOrange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      tranche.interSyndicNom ?? "Non assigné",
                      style: TextStyle(fontWeight: FontWeight.bold, color: darkGrey, fontSize: 13)
                  ),
                ),
                if (tranche.interSyndicNom == null)
                  InkWell(
                    onTap: onAssignTap,
                    child: const Text("Assigner", style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                  )
              ],
            ),
          ),
          const SizedBox(height: 15),

          // 3. MINI STATS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat(Icons.apartment, tranche.nombreImmeubles.toString(), "Imm."),
              _buildMiniStat(Icons.home_work_outlined, tranche.nombreAppartements.toString(), "App."),
              _buildMiniStat(Icons.local_parking, tranche.nombreParkings.toString(), "Park."),
            ],
          ),
          const SizedBox(height: 15),

          // 4. TAGS IMMEUBLES (VRAIES DONNÉES)
          const Text("Immeubles rattachés :", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          FutureBuilder<List<String>>(
            future: service.getImmeubleNames(tranche.id),
            builder: (context, snapshot) {
              final names = snapshot.data ?? [];
              return Wrap(
                spacing: 6, runSpacing: 6,
                children: names.map((n) => _buildTag(n)).toList(),
              );
            },
          ),
          // Suppression du Spacer et de la date du bas
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String val, String label) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkGrey)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTag(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(6)),
      child: Text(name, style: TextStyle(fontSize: 10, color: darkGrey)),
    );
  }

}