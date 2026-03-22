// lib/services/reunion_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reunion_model.dart';
import '../utils/temp_session.dart';

class ReunionService {
  final _db = Supabase.instance.client;

  // ─────────────────────────────────────────────────────────
  // Charger les vrais noms (residence, tranche, inter-syndic)
  // Utilise pour personnaliser les PDFs de convocation
  // ─────────────────────────────────────────────────────────
  Future<Map<String, String>> getTrancheInfo(int trancheId) async {
    try {
      final res = await _db
          .from('tranches')
          .select('nom, inter_syndic_id, residences(nom)')
          .eq('id', trancheId)
          .maybeSingle();

      if (res == null) return {};

      final trancheNom   = res['nom']?.toString() ?? '';
      final residenceNom = res['residences']?['nom']?.toString() ?? '';
      final isId         = res['inter_syndic_id'];

      String interSyndicNom = '';
      if (isId != null) {
        final u = await _db
            .from('users')
            .select('nom, prenom')
            .eq('id', isId)
            .maybeSingle();
        if (u != null) {
          interSyndicNom = '${u['prenom'] ?? ''} ${u['nom'] ?? ''}'.trim();
        }
      }

      return {
        'tranche_nom':      trancheNom,
        'residence_nom':    residenceNom,
        'inter_syndic_nom': interSyndicNom,
      };
    } catch (_) {
      return {};
    }
  }

  // ─────────────────────────────────────────────────────────
  // GET reunions par tranche (avec nb participants)
  // ─────────────────────────────────────────────────────────
  Future<List<ReunionModel>> getReunionsByTranche(int trancheId) async {
    try {
      final res = await _db
          .from('reunions')
          .select('*')
          .eq('tranche_id', trancheId)
          .order('date', ascending: false);

      final reunions = (res as List).map((r) => ReunionModel.fromJson(r)).toList();
      if (reunions.isEmpty) return [];

      final reunionIds      = reunions.map((r) => r.id).toList();
      final participantsRes = await _db
          .from('reunion_resident')
          .select('reunion_id, confirmation')
          .inFilter('reunion_id', reunionIds);

      final participants = participantsRes as List;

      return reunions.map((r) {
        final rp = participants.where((p) => p['reunion_id'] == r.id).toList();
        return ReunionModel(
          id: r.id, titre: r.titre, description: r.description,
          date: r.date, heure: r.heure, lieu: r.lieu,
          trancheId: r.trancheId, interSyndicId: r.interSyndicId,
          statut: r.statut, createdAt: r.createdAt,
          nbParticipants: rp.length,
          nbConfirmes: rp.where((p) => p['confirmation'] == 'confirme').length,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────
  // AJOUTER reunion
  // ─────────────────────────────────────────────────────────
  Future<String?> addReunion({
    required String titre,
    String? description,
    required DateTime date,
    required String heure,
    required String lieu,
    required int trancheId,
  }) async {
    try {
      await _db.from('reunions').insert({
        'titre':           titre.trim(),
        'description':     description?.trim(),
        'date':            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'heure':           heure,
        'lieu':            lieu.trim(),
        'tranche_id':      trancheId,
        'inter_syndic_id': TempSession.interSyndicId,
        'statut':          'planifiee',
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────────────────────
  // MODIFIER reunion
  // ─────────────────────────────────────────────────────────
  Future<String?> updateReunion({
    required int reunionId,
    required String titre,
    String? description,
    required DateTime date,
    required String heure,
    required String lieu,
  }) async {
    try {
      await _db.from('reunions').update({
        'titre':       titre.trim(),
        'description': description?.trim(),
        'date':        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'heure':       heure,
        'lieu':        lieu.trim(),
        'updated_at':  DateTime.now().toIso8601String(),
      }).eq('id', reunionId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────────────────────
  // CHANGER STATUT
  // ─────────────────────────────────────────────────────────
  Future<String?> updateStatut(int reunionId, StatutReunionEnum statut) async {
    try {
      await _db.from('reunions').update({
        'statut':     statut.name,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reunionId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────────────────────
  // SUPPRIMER reunion
  // ─────────────────────────────────────────────────────────
  Future<String?> deleteReunion(int reunionId) async {
    try {
      await _db.from('reunion_resident').delete().eq('reunion_id', reunionId);
      await _db.from('notifications').delete().eq('reunion_id', reunionId);
      await _db.from('reunions').delete().eq('id', reunionId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────────────────────
  // GET residents d'une tranche
  // ─────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getResidentsDeTranche(int trancheId) async {
    try {
      final immRes = await _db.from('immeubles').select('id').eq('tranche_id', trancheId);
      final immIds = (immRes as List).map((i) => i['id'] as int).toList();
      if (immIds.isEmpty) return [];

      final appRes = await _db.from('appartements').select('id')
          .inFilter('immeuble_id', immIds).eq('statut', 'occupe');
      final appIds = (appRes as List).map((a) => a['id'] as int).toList();
      if (appIds.isEmpty) return [];

      final resRes = await _db.from('residents').select('user_id')
          .inFilter('appartement_id', appIds).eq('statut', 'actif');
      final userIds = (resRes as List).map((r) => r['user_id'] as int).toList();
      if (userIds.isEmpty) return [];

      final usersRes = await _db.from('users')
          .select('id, nom, prenom, email, telephone').inFilter('id', userIds);
      return (usersRes as List).map((u) => Map<String, dynamic>.from(u)).toList();
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────
  // ENVOYER CONVOCATIONS (notifications en base uniquement)
  // ─────────────────────────────────────────────────────────
  Future<String?> envoyerConvocations(int reunionId, List<int> userIds) async {
    try {
      await _db.from('reunion_resident').delete().eq('reunion_id', reunionId);
      if (userIds.isEmpty) return null;

      await _db.from('reunion_resident').insert(
        userIds.map((uid) => {
          'reunion_id':   reunionId,
          'resident_id':  uid,
          'confirmation': 'en_attente',
        }).toList(),
      );

      final r = await _db.from('reunions')
          .select('titre, date, heure').eq('id', reunionId).single();

      await _db.from('notifications').insert(
        userIds.map((uid) => {
          'user_id':    uid,
          'titre':      'Convocation reunion',
          'message':    'Vous etes convoque(e) a la reunion "${r['titre']}" '
              'le ${_fmt(r['date'])} a ${r['heure'].toString().substring(0, 5)}',
          'type':       'reunion',
          'lu':         false,
          'reunion_id': reunionId,
        }).toList(),
      );

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────────────────────
  // GET CONVOCATIONS d'une reunion avec details residents
  // ─────────────────────────────────────────────────────────
  Future<List<ReunionResidentModel>> getConvocations(int reunionId) async {
    try {
      final res = await _db
          .from('reunion_resident')
          .select('id, reunion_id, resident_id, confirmation, created_at')
          .eq('reunion_id', reunionId);

      final rows = res as List;
      if (rows.isEmpty) return [];

      final userIds = rows.map((r) => r['resident_id'] as int).toList();
      final users   = await _db.from('users').select('id, nom, prenom').inFilter('id', userIds);

      return rows.map((r) {
        final user = (users as List).firstWhere(
              (u) => u['id'] == r['resident_id'],
          orElse: () => <String, dynamic>{},
        ) as Map<String, dynamic>;

        return ReunionResidentModel(
          id:           r['id'] as int,
          reunionId:    r['reunion_id'] as int,
          residentId:   r['resident_id'] as int,
          confirmation: ConfirmationEnum.values.firstWhere(
                (e) => e.name == (r['confirmation']?.toString() ?? 'en_attente'),
            orElse: () => ConfirmationEnum.en_attente,
          ),
          createdAt: r['created_at'] != null
              ? DateTime.tryParse(r['created_at'].toString()) : null,
          nom:    user['nom']?.toString(),
          prenom: user['prenom']?.toString(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  String _fmt(String d) {
    try {
      final dt = DateTime.parse(d);
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
    } catch (_) { return d; }
  }
}