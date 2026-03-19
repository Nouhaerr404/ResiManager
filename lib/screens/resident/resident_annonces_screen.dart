import 'package:flutter/material.dart';
import '../../services/resident_service.dart';
import 'resident_dashboard_screen.dart';

class ResidentAnnoncesScreen extends StatelessWidget {
  final int userId;
  final Function(int)? onNavigate; // ← AJOUT
  final ResidentService _service = ResidentService();

  ResidentAnnoncesScreen({super.key, this.userId = 3, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final bool inLayout = onNavigate != null; // ← AJOUT

    final body = FutureBuilder<Map<String, dynamic>>(
      future: _service.getAnnoncesAndReunions(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B4A)));
        final List annonces = snapshot.data!['annonces'];
        if (annonces.isEmpty)
          return const Center(
              child: Text("Aucune annonce",
                  style: TextStyle(color: Colors.grey)));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: annonces.length,
          itemBuilder: (context, index) {
            final a = annonces[index];
            bool isUrgent = a['type'] == 'urgente';
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isUrgent ? const Color(0xFFFFF1F1) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    color: isUrgent
                        ? Colors.red.shade100
                        : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a['titre'],
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(a['contenu'],
                      style: const TextStyle(color: Colors.black87)),
                  const Divider(height: 30),
                  Text(
                      "Publié le ${a['created_at'].toString().split('T')[0]}",
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            );
          },
        );
      },
    );

    // ← Si dans layout : juste le body
    if (inLayout) return body;

    // ← Si standalone : Scaffold complet
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: const Text("Annonces",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFFFF6B4A)),
      ),
      drawer: ResidentMobileDrawer(currentIndex: 3, userId: userId),
      body: body,
    );
  }
}