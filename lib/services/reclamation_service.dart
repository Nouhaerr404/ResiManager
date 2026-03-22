// lib/services/reclamation_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Valeurs EXACTES de l'enum statut_reclam_enum dans Supabase ──
enum StatutReclamation { en_cours, resolue, rejetee }

extension StatutReclamationExt on StatutReclamation {
  String get dbValue {
    switch (this) {
      case StatutReclamation.en_cours: return 'en_cours';
      case StatutReclamation.resolue:  return 'resolue';
      case StatutReclamation.rejetee:  return 'rejetee';
    }
  }

  String get label {
    switch (this) {
      case StatutReclamation.en_cours: return 'En cours';
      case StatutReclamation.resolue:  return 'Resolu';
      case StatutReclamation.rejetee:  return 'Rejete';
    }
  }
}

class ReclamationModel {
  final int     id;
  final String  titre;
  final String  description;
  final int     residentId;
  final String  statut;
  final String? documentPath;   // chemin dans Storage ex: reclamations/3/123.pdf
  final String? documentUrl;    // URL publique generee depuis Storage
  final DateTime createdAt;
  final String? residentNom;
  final String? residentPrenom;
  final String? residentEmail;

  const ReclamationModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.residentId,
    required this.statut,
    this.documentPath,
    this.documentUrl,
    required this.createdAt,
    this.residentNom,
    this.residentPrenom,
    this.residentEmail,
  });

  String get nomComplet => '${residentPrenom ?? ''} ${residentNom ?? ''}'.trim();

  bool get hasDocument =>
      (documentPath != null && documentPath!.isNotEmpty) ||
          (documentUrl  != null && documentUrl!.isNotEmpty);

  // Retourne true si c'est une image (jpg/jpeg/png)
  bool get isImage {
    final path = (documentPath ?? documentUrl ?? '').toLowerCase();
    return path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png');
  }

  StatutReclamation get statutEnum {
    switch (statut) {
      case 'resolue': return StatutReclamation.resolue;
      case 'rejetee': return StatutReclamation.rejetee;
      default:        return StatutReclamation.en_cours;
    }
  }

  factory ReclamationModel.fromJson(
      Map<String, dynamic> j, {
        Map<String, dynamic>? user,
        String? publicUrl,
      }) {
    return ReclamationModel(
      id:            j['id'] as int,
      titre:         j['titre']?.toString() ?? '',
      description:   j['description']?.toString() ?? '',
      residentId:    j['resident_id'] as int,
      statut:        j['statut']?.toString() ?? 'en_cours',
      documentPath:  j['document_path']?.toString(),
      documentUrl:   publicUrl,
      createdAt:     j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      residentNom:    user?['nom']?.toString(),
      residentPrenom: user?['prenom']?.toString(),
      residentEmail:  user?['email']?.toString(),
    );
  }
}

class ReclamationService {
  final _db = Supabase.instance.client;

  // ─────────────────────────────────────────────────────────
  // Generer l'URL publique depuis le chemin Storage
  // Bucket : "reclamations" (doit etre Public dans Supabase)
  // ─────────────────────────────────────────────────────────
  String? getDocumentUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    try {
      return _db.storage.from('reclamations').getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────
  // GET reclamations par tranche avec URLs publiques des documents
  // ─────────────────────────────────────────────────────────
  Future<List<ReclamationModel>> getReclamationsByTranche(int trancheId) async {
    try {
      final res = await _db
          .from('reclamations')
          .select('id, titre, description, resident_id, statut, document_path, created_at')
          .eq('tranche_id', trancheId)
          .order('created_at', ascending: false);

      final rows = res as List;
      if (rows.isEmpty) return [];

      final userIds = rows.map((r) => r['resident_id'] as int).toSet().toList();
      final users   = await _db
          .from('users')
          .select('id, nom, prenom, email')
          .inFilter('id', userIds);

      final userMap = <int, Map<String, dynamic>>{};
      for (final u in users as List) {
        userMap[u['id'] as int] = Map<String, dynamic>.from(u);
      }

      return rows.map((r) {
        final uid  = r['resident_id'] as int;
        final path = r['document_path']?.toString();

        // Generer l'URL publique depuis le chemin Storage
        final publicUrl = getDocumentUrl(path);

        return ReclamationModel.fromJson(
          Map<String, dynamic>.from(r),
          user:      userMap[uid],
          publicUrl: publicUrl,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────
  // Changer le statut d'une reclamation
  // ─────────────────────────────────────────────────────────
  Future<String?> updateStatut(int reclamationId, StatutReclamation statut) async {
    try {
      await _db.from('reclamations').update({
        'statut':     statut.dbValue,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reclamationId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────────────────────
  // Stats par tranche
  // ─────────────────────────────────────────────────────────
  Future<Map<String, int>> getStats(int trancheId) async {
    try {
      final res = await _db
          .from('reclamations')
          .select('statut')
          .eq('tranche_id', trancheId);

      final rows = res as List;
      int enCours = 0, resolu = 0, rejete = 0;
      for (final r in rows) {
        switch (r['statut']?.toString()) {
          case 'resolue': resolu++;  break;
          case 'rejetee': rejete++;  break;
          default:        enCours++; break;
        }
      }
      return {
        'en_cours': enCours,
        'resolu':   resolu,
        'rejete':   rejete,
        'total':    rows.length,
      };
    } catch (e) {
      return {'en_cours': 0, 'resolu': 0, 'rejete': 0, 'total': 0};
    }
  }
}