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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text(
          "Nouvelle Résidence",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF2C2C2C)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CHAMP NOM ---
            _buildFieldLabel("Nom de la résidence"),
            TextField(
              controller: nomController,
              decoration: _buildInputDecoration("Ex: Résidence Les Jardins"),
            ),
            const SizedBox(height: 20),

            // --- CHAMP ADRESSE ---
            _buildFieldLabel("Adresse complète"),
            TextField(
              controller: adrController,
              maxLines: 2,
              decoration: _buildInputDecoration("Ex: Avenue de la mer, Tétouan"),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        actions: [
          Row(
            children: [
              // BOUTON ANNULER
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Annuler", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 15),
              // BOUTON CRÉER (ORANGE)
              Expanded(
                child: ElevatedButton(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6F4A),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Créer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- PETITS HELPERS POUR LE DESIGN ---

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4A4E69)),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF6F4A), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. IMAGE DE FOND
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/residence_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. VOILE SOMBRE
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
                // En-tête personnalisé avec bouton retour
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
                  child: Row(
                    children: [
                      // BOUTON RETOUR À L'ACCUEIL
                      IconButton(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacementNamed(context, '/home');
                          }
                        },
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Bienvenue,",
                              style: TextStyle(color: Colors.white70, fontSize: 18),
                            ),
                            Text(
                              "Mes Résidences",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Bouton d'ajout
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
                                final int idDeLaResidenceChoisie = res['id'];
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DashboardScreen(residenceId: idDeLaResidenceChoisie, syndicId: widget.syndicGeneralId),
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