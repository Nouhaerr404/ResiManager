import 'package:flutter/material.dart';
import '../../services/resident_service.dart';
import '../../widgets/resident_nav_bar.dart';
import 'resident_dashboard_screen.dart';
class ResidentAnnoncesScreen extends StatelessWidget {
  final ResidentService _service = ResidentService();
   ResidentAnnoncesScreen({super.key});  // ← AJOUTEZ const


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: const Text("Annonces", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFFFF6B4A)),
      ),
      drawer: ResidentMobileDrawer(currentIndex: 3),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _service.getAnnoncesAndReunions(3),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B4A)));
          final List annonces = snapshot.data!['annonces'];

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
                  border: Border.all(color: isUrgent ? Colors.red.shade100 : Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a['titre'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(a['contenu'], style: const TextStyle(color: Colors.black87)),
                    const Divider(height: 30),
                    Text("Publié le ${a['created_at'].toString().split('T')[0]}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}