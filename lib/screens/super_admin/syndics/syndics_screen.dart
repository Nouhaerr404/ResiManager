import 'package:flutter/material.dart';
import '../../../services/super_admin_service.dart';
import '../../../widgets/app_sidebar.dart';
import '../../../models/user_model.dart';

class SyndicsScreen extends StatefulWidget {
  @override
  _SyndicsScreenState createState() => _SyndicsScreenState();
}

class _SyndicsScreenState extends State<SyndicsScreen> {
  final SuperAdminService _service = SuperAdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: Row(
        children: [
          const AppSidebar(currentPage: "syn"), // Sidebar présente !
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Liste des Syndics Généraux", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  Expanded(
                    child: FutureBuilder<List<UserModel>>(
                      future: _service.getSyndicsGeneraux(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) => _synCard(snapshot.data![index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _synCard(UserModel user) {
    bool isActif = user.statut.name == 'actif';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.orange.shade50, child: const Icon(Icons.person, color: Colors.orange)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.nomComplet, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(user.email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
          const Spacer(),
          // LE BOUTON D'ACTION
          ElevatedButton(
            onPressed: () async {
              await _service.toggleSyndicStatus(user.id, user.statut.name);
              setState(() {}); // Rafraîchit l'écran
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isActif ? Colors.red.shade50 : Colors.green.shade50,
              elevation: 0,
            ),
            child: Text(
              isActif ? "Désactiver" : "Activer",
              style: TextStyle(color: isActif ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Chip(
            label: Text(isActif ? "Actif" : "Inactif"),
            backgroundColor: isActif ? Colors.green.shade50 : Colors.grey.shade100,
          )
        ],
      ),
    );
  }
}