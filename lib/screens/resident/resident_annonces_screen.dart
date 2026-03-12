import 'package:flutter/material.dart';
import '../../services/resident_service.dart';
import '../../widgets/resident_nav_bar.dart';

class ResidentAnnoncesScreen extends StatelessWidget {
  final ResidentService _service = ResidentService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: const ResidentNavBar(currentIndex: 2),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _service.getAnnoncesAndReunions(3),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final List annonces = snapshot.data!['annonces'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Annonces", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const Text("Consultez les dernières annonces de votre résidence", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),

                // KPI CARDS
                Row(
                  children: [
                    _kpi("Total Annonces", "${annonces.length}", Icons.description, Colors.blue),
                    const SizedBox(width: 20),
                    _kpi("Prioritaires", "${annonces.where((e)=>e['type']=='urgente').length}", Icons.warning_amber, Colors.red),
                    const SizedBox(width: 20),
                    _kpi("Maintenance", "${annonces.where((e)=>e['type']=='information').length}", Icons.build, Colors.orange),
                  ],
                ),
                const SizedBox(height: 40),

                // GRID DES ANNONCES
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // On passe à 3 colonnes pour réduire la taille
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.8, // Ratio ajusté pour être plus horizontal (moins haut)
                    ),

                  itemCount: annonces.length,
                  itemBuilder: (context, index) => _buildAnnonceCard(annonces[index]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnnonceCard(Map a) {
    bool isUrgent = a['type'] == 'urgente';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0xFFFFF1F1) : const Color(0xFFFFF9EB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isUrgent ? Colors.red.shade100 : Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isUrgent ? Icons.warning_amber : Icons.build, color: isUrgent ? Colors.red : Colors.orange),
              const SizedBox(width: 10),
              Expanded(child: Text(a['titre'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 15),
          Text(a['contenu'], style: const TextStyle(color: Colors.black87), maxLines: 3),
          const Spacer(),
          Row(children: [const Icon(Icons.location_on_outlined, size: 14), Text(" Tranche A", style: const TextStyle(fontSize: 12))]),
          Text("Publiée le ${a['created_at'].toString().split('T')[0]}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _kpi(String l, String v, IconData i, Color c) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: c.withOpacity(0.1), child: Icon(i, color: c, size: 20)),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 12, color: Colors.grey)), Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
        ],
      ),
    ),
  );
}