import 'package:flutter/material.dart';
import '../../../models/residence_model.dart';
import '../../../services/residence_service.dart';
import '../../../widgets/syndic_sidebar.dart';

class ResidencesManagementScreen extends StatefulWidget {
  final int syndicGeneralId;
  const ResidencesManagementScreen({Key? key, required this.syndicGeneralId}) : super(key: key);

  @override
  _ResidencesManagementScreenState createState() => _ResidencesManagementScreenState();
}

class _ResidencesManagementScreenState extends State<ResidencesManagementScreen> {
  final ResidenceService _residenceService = ResidenceService();
  late Future<List<Map<String, dynamic>>> _residencesFuture;

  @override
  void initState() {
    super.initState();
    _loadResidences();
  }

  void _loadResidences() {
    setState(() {
      _residencesFuture = _residenceService.getResidences(widget.syndicGeneralId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      drawer: MediaQuery.of(context).size.width < 900 ? const SyndicSidebar() : null,
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 900)
            const SizedBox(width: 250, child: SyndicSidebar()),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Gestion des Résidences', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                      ElevatedButton.icon(
                        onPressed: () => _showResidenceDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6F4A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _residencesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Erreur : ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('Aucune résidence trouvée'));
                        }

                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final res = snapshot.data![index];
                            return _buildResidenceCard(res);
                          },
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

  Widget _buildResidenceCard(Map<String, dynamic> res) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFF6F4A),
          child: Icon(Icons.business, color: Colors.white),
        ),
        title: Text(res['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(res['adresse'] ?? ''),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showResidenceDialog(res: res),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(res),
            ),
          ],
        ),
      ),
    );
  }

  void _showResidenceDialog({Map<String, dynamic>? res}) {
    final nomController = TextEditingController(text: res?['nom']);
    final adresseController = TextEditingController(text: res?['adresse']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(res == null ? 'Ajouter une Résidence' : 'Modifier la Résidence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomController, decoration: const InputDecoration(labelText: 'Nom')),
            TextField(controller: adresseController, decoration: const InputDecoration(labelText: 'Adresse')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (res == null) {
                await _residenceService.createResidence(
                  nomController.text,
                  adresseController.text,
                  widget.syndicGeneralId,
                );
              } else {
                await _residenceService.updateResidence(
                  res['id'],
                  nomController.text,
                  adresseController.text,
                );
              }
              Navigator.pop(context);
              _loadResidences();
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> res) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer la résidence ${res['nom']} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await _residenceService.deleteResidence(res['id']);
              Navigator.pop(context);
              _loadResidences();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
