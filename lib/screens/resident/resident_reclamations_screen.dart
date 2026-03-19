import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/resident_service.dart';
import 'resident_dashboard_screen.dart';

class ResidentReclamationsScreen extends StatefulWidget {
  final int userId;
  final Function(int)? onNavigate; // ← AJOUT
  const ResidentReclamationsScreen({
    super.key,
    this.userId = 3,
    this.onNavigate,
  });

  @override
  State<ResidentReclamationsScreen> createState() =>
      _ResidentReclamationsScreenState();
}

class _ResidentReclamationsScreenState
    extends State<ResidentReclamationsScreen> {
  final ResidentService _service = ResidentService();
  late int _userId;
  final _titreCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  bool _loading = false;
  bool _sending = false;
  Uint8List? _fileBytes;
  String?    _fileName;
  List<Map<String, dynamic>> _reclamations = [];

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _service.getMesReclamations(_userId);
    setState(() { _reclamations = data; _loading = false; });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _fileBytes = result.files.single.bytes;
        _fileName  = result.files.single.name;
      });
    }
  }

  Future<void> _submit() async {
    if (_titreCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      _snack('Veuillez remplir le titre et la description', isError: true);
      return;
    }
    setState(() => _sending = true);
    final err = await _service.envoyerReclamation(
      residentUserId: _userId,
      titre: _titreCtrl.text,
      description: _descCtrl.text,
      fichier: _fileBytes,
      nomFichier: _fileName,
    );
    setState(() => _sending = false);
    if (err == null) {
      _titreCtrl.clear();
      _descCtrl.clear();
      setState(() { _fileBytes = null; _fileName = null; });
      _snack('Réclamation envoyée avec succès');
      _load();
    } else {
      _snack('Erreur : $err', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFFF6B4A);
    final bool inLayout = widget.onNavigate != null; // ← AJOUT

    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── FORMULAIRE
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nouvelle réclamation',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _titreCtrl,
                  decoration: InputDecoration(
                    labelText: 'Titre *',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        BorderSide(color: Colors.grey.shade200)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        BorderSide(color: Colors.grey.shade200)),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _fileBytes != null
                              ? brand
                              : Colors.grey.shade300),
                    ),
                    child: Row(children: [
                      Icon(
                        _fileBytes != null
                            ? Icons.check_circle
                            : Icons.attach_file,
                        color: _fileBytes != null ? brand : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _fileName ??
                              'Joindre un fichier (image/PDF) — optionnel',
                          style: TextStyle(
                            color: _fileBytes != null
                                ? Colors.black87
                                : Colors.grey,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_fileBytes != null)
                        GestureDetector(
                          onTap: () => setState(() {
                            _fileBytes = null;
                            _fileName = null;
                          }),
                          child: const Icon(Icons.close,
                              size: 18, color: Colors.grey),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brand,
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _sending
                        ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : const Text('Envoyer la réclamation',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('Mes réclamations',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _loading
              ? const Center(
              child: CircularProgressIndicator(color: brand))
              : _reclamations.isEmpty
              ? Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border:
              Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text('Aucune réclamation pour l\'instant',
                  style: TextStyle(color: Colors.grey)),
            ),
          )
              : Column(
            children: _reclamations
                .map((r) => _buildCard(r))
                .toList(),
          ),
        ],
      ),
    );

    // ← Si dans layout : juste le body
    if (inLayout) return body;

    // ← Si standalone : Scaffold complet
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      appBar: AppBar(
        title: const Text('Mes Réclamations',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: brand),
      ),
      drawer: ResidentMobileDrawer(currentIndex: 5, userId: _userId),
      body: body,
    );
  }

  Widget _buildCard(Map<String, dynamic> r) {
    const brand = Color(0xFFFF6B4A);
    final statut = r['statut'] as String;
    final color = statut == 'resolue'
        ? Colors.green
        : statut == 'en_cours'
        ? Colors.orange
        : Colors.grey;
    final label = statut == 'resolue'
        ? 'Résolue'
        : statut == 'en_cours'
        ? 'En cours'
        : 'Fermée';
    final date = (r['created_at'] as String).substring(0, 10);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(r['titre'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(r['description'] ?? '',
              style:
              const TextStyle(color: Colors.grey, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.calendar_today,
                size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(date,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 11)),
            if (r['document_path'] != null) ...[
              const Spacer(),
              const Icon(Icons.attach_file, size: 14, color: brand),
              const SizedBox(width: 4),
              const Text('Fichier joint',
                  style: TextStyle(color: brand, fontSize: 11)),
            ],
          ]),
        ],
      ),
    );
  }
}