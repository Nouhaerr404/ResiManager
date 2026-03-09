import 'package:flutter/material.dart';
import '../../services/residence_service.dart';
import 'dashboard_screen.dart';

class ResidenceSelectionScreen extends StatefulWidget {
  final int syndicGeneralId;

  const ResidenceSelectionScreen({Key? key, required this.syndicGeneralId}) : super(key: key);

  @override
  _ResidenceSelectionScreenState createState() => _ResidenceSelectionScreenState();
}

class _ResidenceSelectionScreenState extends State<ResidenceSelectionScreen> {
  final ResidenceService _service = ResidenceService();
  late Future<List<Map<String, dynamic>>> _residencesFuture;

  @override
  void initState() {
    super.initState();
    _refreshResidences();
  }

  void _refreshResidences() {
    setState(() {
      _residencesFuture = _service.getResidences(widget.syndicGeneralId);
    });
  }

  // Boîte de dialogue pour créer une résidence
  void _showAddResidenceDialog() {
    final nomController = TextEditingController();
    final adrController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nouvelle Résidence"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(labelText: "Nom de la résidence"),
            ),
            TextField(
              controller: adrController,
              decoration: const InputDecoration(labelText: "Adresse complète"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6F4A)),
            onPressed: () async {
              if (nomController.text.isNotEmpty) {
                await _service.createResidence(
                    nomController.text,
                    adrController.text,
                    widget.syndicGeneralId
                );
                Navigator.pop(context);
                _refreshResidences();
              }
            },
            child: const Text('Créer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. IMAGE DE FOND (L'image que tu as fournie)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/residence_bg.png'), // Assure-toi du chemin
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. VOILE SOMBRE (Pour faire ressortir les cartes et le texte)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // 3. CONTENU
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête personnalisé
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bienvenue,",
                            style: TextStyle(color: Colors.white70, fontSize: 18),
                          ),
                          Text(
                            "Mes Résidences",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                      // Bouton d'ajout stylisé
                      GestureDetector(
                        onTap: _showAddResidenceDialog,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFF6F4A),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF6F4A).withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),

                // Liste des résidences
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _residencesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }

                      final residences = snapshot.data ?? [];
                      if (residences.isEmpty) {
                        return const Center(
                          child: Text(
                            "Aucune résidence gérée pour le moment.",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: residences.length,
                        itemBuilder: (context, index) {
                          final res = residences[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(15),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C2C2C).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.apartment, color: Color(0xFF2C2C2C)),
                              ),
                              title: Text(
                                  res['nom'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)
                              ),
                              subtitle: Text(res['adresse'], style: const TextStyle(color: Colors.grey)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFFF6F4A)),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DashboardScreen(residenceId: res['id']),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}