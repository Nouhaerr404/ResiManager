import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reunion_model.dart';
import '../utils/temp_session.dart';

class ReunionService {
  final _db = Supabase.instance.client;

  // ─────────────────────────────────────────────────────────
  // GET réunions par tranche (avec nb participants)
  // ─────────────────────────────────────────────────────────
  Future<List<ReunionModel>> getReunionsByTranche(int trancheId) async {
    try {
      // Requête principale
      final res = await _db
          .from('reunions')
          .select('*')
          .eq('tranche_id', trancheId)
          .order('date', ascending: false);

      final reunions = (res as List)
          .map((r) => ReunionModel.fromJson(r))
          .toList();

      // Enrichir avec nb participants (requête séparée pour éviter timeout)
      if (reunions.isEmpty) return [];

      final reunionIds = reunions.map((r) => r.id).toList();
      final participantsRes = await _db
          .from('reunion_resident')
          .select('reunion_id, confirmation')
          .inFilter('reunion_id', reunionIds);

      final participants = participantsRes as List;

      return reunions.map((r) {
        final rParticipants = participants
            .where((p) => p['reunion_id'] == r.id)
            .toList();
        return ReunionModel(
          id:            r.id,
          titre:         r.titre,
          description:   r.description,
          date:          r.date,
          heure:         r.heure,
          lieu:          r.lieu,
          trancheId:     r.trancheId,
          interSyndicId: r.interSyndicId,
          statut:        r.statut,
          createdAt:     r.createdAt,
          nbParticipants: rParticipants.length,
          nbConfirmes: rParticipants
              .where((p) => p['confirmation'] == 'confirme')
              .length,
        );
      }).toList();
    } catch (e) {
      print('>>> ERREUR getReunionsByTranche: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────
  // AJOUTER réunion
  // ─────────────────────────────────────────────────────────
  Future<String?> addReunion({
    required String titre,
    String? description,
    required DateTime date,
    required String heure,   // format "HH:mm:00"
    required String lieu,
    required int trancheId,
  }) async {
    try {
      await _db.from('reunions').insert({
        'titre':           titre.trim(),
        'description':     description?.trim(),
        'date':            '${date.year}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}',
        'heure':           heure,
        'lieu':            lieu.trim(),
        'tranche_id':      trancheId,
        'inter_syndic_id': TempSession.interSyndicId,
        'statut':          'planifiee',
      });
      return null;
    } catch (e) {
      print('>>> ERREUR addReunion: $e');
      return e.toString();
    }
  }

  // ─────────────────────────────────────────────────────────
  // MODIFIER réunion
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
        'date':        '${date.year}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}',
        'heure':       heure,
        'lieu':        lieu.trim(),
        'updated_at':  DateTime.now().toIso8601String(),
      }).eq('id', reunionId);
      return null;
    } catch (e) {
      print('>>> ERREUR updateReunion: $e');
      return e.toString();
    }
  }

  // ─────────────────────────────────────────────────────────
  // CHANGER STATUT
  // statut_reunion_enum: planifiee, confirmee, terminee, annulee
  // ─────────────────────────────────────────────────────────
  Future<String?> updateStatut(int reunionId, StatutReunionEnum statut) async {
    try {
      await _db.from('reunions').update({
        'statut':     statut.name,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reunionId);
      return null;
    } catch (e) {
      print('>>> ERREUR updateStatut: $e');
      return e.toString();
    }
  }

  // ─────────────────────────────────────────────────────────
  // SUPPRIMER réunion (cascade sur reunion_resident)
  // ─────────────────────────────────────────────────────────
  Future<String?> deleteReunion(int reunionId) async {
    try {
      // Supprimer d'abord les participations (pas de CASCADE en DB)
      await _db
          .from('reunion_resident')
          .delete()
          .eq('reunion_id', reunionId);

      // Supprimer les notifications liées
      await _db
          .from('notifications')
          .delete()
          .eq('reunion_id', reunionId);

      // Supprimer la réunion
      await _db.from('reunions').delete().eq('id', reunionId);
      return null;
    } catch (e) {
      print('>>> ERREUR deleteReunion: $e');
      return e.toString();
    }
  }

  // ─────────────────────────────────────────────────────────
  // GET résidents d'une tranche pour la convocation
  // Chemin: tranches → immeubles → appartements → residents → users
  // ─────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getResidentsDeTranche(int trancheId) async {
    try {
      // 1. Immeubles de la tranche
      final immeublesRes = await _db
          .from('immeubles')
          .select('id')
          .eq('tranche_id', trancheId);

      final immeubleIds = (immeublesRes as List)
          .map((i) => i['id'] as int)
          .toList();
      if (immeubleIds.isEmpty) return [];

      // 2. Appartements occupés
      final appartementsRes = await _db
          .from('appartements')
          .select('id')
          .inFilter('immeuble_id', immeubleIds)
          .eq('statut', 'occupe');

      final appartementIds = (appartementsRes as List)
          .map((a) => a['id'] as int)
          .toList();
      if (appartementIds.isEmpty) return [];

      // 3. Résidents actifs
      // residents.user_id → users.id (FK fk_resident_user)
      final residentsRes = await _db
          .from('residents')
          .select('user_id')
          .inFilter('appartement_id', appartementIds)
          .eq('statut', 'actif');

      final userIds = (residentsRes as List)
          .map((r) => r['user_id'] as int)
          .toList();
      if (userIds.isEmpty) return [];

      // 4. Données users
      final usersRes = await _db
          .from('users')
          .select('id, nom, prenom, email, telephone')
          .inFilter('id', userIds);

      return (usersRes as List)
          .map((u) => Map<String, dynamic>.from(u))
          .toList();
    } catch (e) {
      print('>>> ERREUR getResidentsDeTranche: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────
  // ENVOYER CONVOCATIONS
  // reunion_resident: reunion_id, resident_id (→ users.id), confirmation
  // ─────────────────────────────────────────────────────────
  Future<String?> envoyerConvocations(
      int reunionId,
      List<int> userIds, // users.id des résidents
      ) async {
    try {
      // Supprimer anciennes convocations
      await _db
          .from('reunion_resident')
          .delete()
          .eq('reunion_id', reunionId);

      if (userIds.isEmpty) return null;

      // Insérer nouvelles convocations
      // confirmation_enum: en_attente, confirme, absent
      final inserts = userIds
          .map((uid) => {
        'reunion_id':   reunionId,
        'resident_id':  uid,       // FK → users.id
        'confirmation': 'en_attente',
      })
          .toList();

      await _db.from('reunion_resident').insert(inserts);

      // Créer notifications pour chaque résident
      // type_notif_enum → récupérer la réunion pour le message
      final reunionRes = await _db
          .from('reunions')
          .select('titre, date, heure')
          .eq('id', reunionId)
          .single();

      final notifInserts = userIds
          .map((uid) => {
        'user_id':    uid,
        'titre':      'Convocation réunion',
        'message':    'Vous êtes convoqué(e) à la réunion '
            '"${reunionRes['titre']}" '
            'le ${_formatDate(reunionRes['date'])} '
            'à ${reunionRes['heure'].toString().substring(0, 5)}',
        'type':       'reunion',
        'lu':         false,
        'reunion_id': reunionId,
      })
          .toList();

      await _db.from('notifications').insert(notifInserts);

      print('>>> ${userIds.length} convocations + notifications envoyées');
      return null;
    } catch (e) {
      print('>>> ERREUR envoyerConvocations: $e');
      return e.toString();
    }
  }

  // ─────────────────────────────────────────────────────────
  // GET CONVOCATIONS d'une réunion avec détails residents
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

      final usersRes = await _db
          .from('users')
          .select('id, nom, prenom')
          .inFilter('id', userIds);

      final users = usersRes as List;

      return rows.map((r) {
        final user = users.firstWhere(
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
              ? DateTime.tryParse(r['created_at'].toString())
              : null,
          nom:    user['nom']?.toString(),
          prenom: user['prenom']?.toString(),
        );
      }).toList();
    } catch (e) {
      print('>>> ERREUR getConvocations: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────
  // HELPER
  // ─────────────────────────────────────────────────────────
  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    } catch (_) {
      return dateStr;
    }
  }
}