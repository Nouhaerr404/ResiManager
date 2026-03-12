import 'package:flutter/material.dart';
import '../../../services/super_admin_service.dart';
import '../../../widgets/app_sidebar.dart';
import '../../../models/residence_model.dart';

class ResidencesScreen extends StatefulWidget {
  @override
  _ResidencesScreenState createState() => _ResidencesScreenState();
}

class _ResidencesScreenState extends State<ResidencesScreen> {
  final SuperAdminService _service = SuperAdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: Row(
        children: [
          const AppSidebar(currentPage: "res"), // Sidebar présente !
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Liste des Résidences", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  Expanded(
                    child: FutureBuilder<List<ResidenceModel>>(
                      future: _service.getAllResidences(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) => _buildCard(snapshot.data![index]),
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

  Widget _buildCard(ResidenceModel res) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(res.nom, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Chip(label: Text("Active"), backgroundColor: Color(0xFFE8F5E9)),
            ],
          ),
          Text(res.adresse, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Row(
            children: [
              _box("${res.nombreTranches}", "Tranches"),
              const SizedBox(width: 10),
              _box("${res.totalImmeubles}", "Immeubles"),
              const SizedBox(width: 10),
              _box("${res.totalAppartements}", "Appts"),
            ],
          ),
          const Divider(height: 40),
          Text("Syndic Général : ${res.syndicNom}", style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _box(String v, String l) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [Text(v, style: const TextStyle(fontWeight: FontWeight.bold)), Text(l, style: const TextStyle(color: Colors.grey, fontSize: 12))]),
    ),
  );
}