import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tranche_model.dart';


class TrancheService {
  final _db = Supabase.instance.client;

  Future<List<TrancheModel>> getTranchesOfInterSyndic(
      int interSyndicId) async {
    try {
      print('>>> Chargement tranches pour interSyndicId=$interSyndicId');

      final res = await _db
          .from('tranches')
          .select('*, residences(*), users(nom, prenom)')
          .eq('inter_syndic_id', interSyndicId)
          .timeout(const Duration(seconds: 10));

      final list = res as List;
      print('>>> Tranches trouvees: ${list.length}');

      return list.map((e) => TrancheModel.fromJson(e)).toList();

    } catch (e, s) {
      print('>>> ERREUR getTranches: $e\n$s');
      return [];
    }
  }

  Future<Map<String, dynamic>> getTrancheStats(int trancheId) async {
    try {
      print('>>> Stats pour tranche=$trancheId');

      // Immeubles
      final immeubles = await _db
          .from('immeubles')
          .select('id')
          .eq('tranche_id', trancheId)
          .timeout(const Duration(seconds: 10));
      final immeubleIds = (immeubles as List)
          .map((i) => i['id'] as int)
          .toList();

      int nbResidents = 0;
      int nbAppartements = 0;

      if (immeubleIds.isNotEmpty) {
        final appartements = await _db
            .from('appartements')
            .select('id')
            .inFilter('immeuble_id', immeubleIds);
        final appartIds = (appartements as List)
            .map((a) => a['id'] as int)
            .toList();
        nbAppartements = appartIds.length;

        if (appartIds.isNotEmpty) {
          final residents = await _db
              .from('residents')
              .select('id')
              .inFilter('appartement_id', appartIds);
          nbResidents = (residents as List).length;
        }
      }

      // Personnel
      final personnel = await _db
          .from('personnel')
          .select('id')
          .eq('tranche_id', trancheId);

      // Parkings
      final parkings = await _db
          .from('parkings')
          .select('id')
          .eq('tranche_id', trancheId);

      // Garages
      final garages = await _db
          .from('garages')
          .select('id')
          .eq('tranche_id', trancheId);

      // Boxes
      final boxes = await _db
          .from('boxes')
          .select('id')
          .eq('tranche_id', trancheId);

      // Finances
      final finances = await _db
          .from('finances_summary')
          .select('*')
          .eq('tranche_id', trancheId)
          .maybeSingle();

      // Reunions planifiees
      final reunions = await _db
          .from('reunions')
          .select('id')
          .eq('tranche_id', trancheId)
          .eq('statut', 'planifiee');

      // Reclamations en cours
      final reclamations = await _db
          .from('reclamations')
          .select('id')
          .eq('tranche_id', trancheId)
          .eq('statut', 'en_cours');

      // Annonces publiées
      final annonces = await _db
          .from('annonces')
          .select('id')
          .eq('tranche_id', trancheId)
          .eq('statut', 'publiee');

      final stats = {
        'nbResidents':     nbResidents,
        'nbAppartements':  nbAppartements,
        'nbPersonnel':     (personnel as List).length,
        'nbParkings':      (parkings as List).length,
        'nbGarages':       (garages as List).length,
        'nbBoxes':         (boxes as List).length,
        'nbReunions':      (reunions as List).length,
        'nbReclamations':  (reclamations as List).length,
        'nbAnnonces':      (annonces as List).length,
        'solde':    finances?['solde'] ?? 0,
        'revenus':  finances?['revenus_total'] ?? 0,
        'depenses': finances?['depenses_total'] ?? 0,
      };

      print('>>> Stats: $stats');
      return stats;

    } catch (e, s) {
      print('>>> ERREUR getTrancheStats: $e\n$s');
      return {
        'nbResidents':    0,
        'nbAppartements': 0,
        'nbPersonnel':    0,
        'nbParkings':     0,
        'nbGarages':      0,
        'nbBoxes':        0,
        'nbReunions':     0,
        'nbReclamations': 0,
        'nbAnnonces':     0,
        'solde':          0,
        'revenus':        0,
        'depenses':       0,
      };
    }
  }

  Future<List<TrancheModel>> getTranchesByResidence(int residenceId) async {
    final response = await _db
        .from('tranches')
        .select('''
          *, 
          users(nom, prenom),
          immeubles(count),
          appartements_count:immeubles(appartements(count))
        ''')
        .eq('residence_id', residenceId);

    final List list = response as List;

    return list.map((e) {
      int realImmCount = 0;
      if (e['immeubles'] != null && (e['immeubles'] as List).isNotEmpty) {
        realImmCount = e['immeubles'][0]['count'] ?? 0;
      }

      int totalApparts = 0;
      if (e['appartements_count'] != null) {
        for (var imm in e['appartements_count']) {
          if (imm['appartements'] != null && (imm['appartements'] as List).isNotEmpty) {
            totalApparts += (imm['appartements'][0]['count'] as int);
          }
        }
      }

      return TrancheModel(
        id: e['id'],
        nom: e['nom'] ?? '',
        description: e['description'],
        residenceId: e['residence_id'],
        interSyndicId: e['inter_syndic_id'],
        nombreImmeubles: realImmCount,
        nombreAppartements: totalApparts,
        nombreParkings: e['nombre_parkings'] ?? 0,
        nombreGarages: e['nombre_garages'] ?? 0,
        nombreBoxes: e['nombre_boxes'] ?? 0,
        prixAnnuel: e['prix_annuel'] != null ? (e['prix_annuel'] as num).toDouble() : 0.0,
        statut: e['Statut'] ?? 'Actif',
        interSyndicNom: e['users'] != null
            ? "${e['users']['prenom']} ${e['users']['nom']}"
            : null,
      );
    }).toList();
  }

  Future<void> createTrancheComplet(
      int residenceId,
      String nom,
      String description,
      int? interSyndicId,
      double? prixAnnuel) async {

    await _db.from('tranches').insert({
      'residence_id':    residenceId,
      'nom':             nom,
      'inter_syndic_id': interSyndicId,
      'prix_annuel':     (prixAnnuel != null && prixAnnuel > 0) ? prixAnnuel : null,
    });
  }

  Future<List<Map<String, dynamic>>> getAvailableInterSyndics() async {
    final response = await _db
        .from('users')
        .select('id, nom, prenom')
        .eq('role', 'inter_syndic')
        .eq('statut', 'actif');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> assignInterSyndic(int trancheId, int? interSyndicId) async {
    await _db
        .from('tranches')
        .update({'inter_syndic_id': interSyndicId})
        .eq('id', trancheId);
  }

  Future<List<Map<String, dynamic>>> getImmeublesByTranche(int trancheId) async {
    final response = await _db
        .from('immeubles')
        .select('id, nom')
        .eq('tranche_id', trancheId);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<String>> getImmeubleNames(int trancheId) async {
    final response = await _db
        .from('immeubles')
        .select('nom')
        .eq('tranche_id', trancheId);

    return (response as List).map((i) => i['nom'] as String).toList();
  }

  Future<void> updateTrancheComplet(
      int trancheId,
      String nom,
      String? description,
      int? interSyndicId,
      double? prixAnnuel) async {

    await _db.from('tranches').update({
      'nom':             nom,
      'description':     description,
      'inter_syndic_id': interSyndicId,
      'prix_annuel':     (prixAnnuel != null && prixAnnuel > 0) ? prixAnnuel : null,
    }).eq('id', trancheId);
  }

  Future<void> setTrancheStatut(int trancheId, String statut) async {
    await _db.from('tranches').update({'Statut': statut}).eq('id', trancheId);
  }

  Future<void> deleteTranche(int trancheId) async {
    await _db.from('tranches').delete().eq('id', trancheId);
  }

  Future<List<String>> getAppartementNumeros(int trancheId) async {
    final res = await _db.from('appartements')
        .select('numero, immeubles!inner(tranche_id)')
        .eq('immeubles.tranche_id', trancheId);
    return (res as List).map((a) => a['numero'] as String).toList();
  }

  Future<List<String>> getParkingNumeros(int trancheId) async {
    final res = await _db.from('parkings').select('numero').eq('tranche_id', trancheId);
    return (res as List).map((p) => p['numero'] as String).toList();
  }

  Future<List<String>> getGarageNumeros(int trancheId) async {
    final res = await _db.from('garages').select('numero').eq('tranche_id', trancheId);
    return (res as List).map((g) => g['numero'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getMyAvailableInterSyndics(int myId) async {
    try {
      print(">>> DEBUG : Recherche des syndics pour l'Admin ID : $myId");

      final response = await _db
          .from('liens_syndics')
          .select('inter_syndic_id')
          .eq('syndic_general_id', myId);

      final List data = response as List;
      if (data.isEmpty) return [];

      final List<int> ids = data.map((item) => item['inter_syndic_id'] as int).toList();

      final usersResponse = await _db
          .from('users')
          .select('id, nom, prenom')
          .inFilter('id', ids);

      print(">>> DEBUG : ${usersResponse.length} syndics trouves !");
      return List<Map<String, dynamic>>.from(usersResponse);

    } catch (e) {
      print("ERREUR getMyAvailableInterSyndics : $e");
      return [];
    }
  }

  // ─── CRUD Annonces ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAnnoncesByTranche(int trancheId) async {
    try {
      final res = await _db
          .from('annonces')
          .select()
          .eq('tranche_id', trancheId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      print('>>> ERREUR getAnnoncesByTranche: $e');
      return [];
    }
  }

  Future<String?> addAnnonce({
    required int trancheId,
    required String titre,
    required String contenu,
    required String type,
  }) async {
    try {
      await _db.from('annonces').insert({
        'tranche_id': trancheId,
        'titre':      titre.trim(),
        'contenu':    contenu.trim(),
        'type':       type,
        'statut':     'brouillon',
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateAnnonce({
    required int id,
    required String titre,
    required String contenu,
    required String type,
    required String statut,
  }) async {
    try {
      await _db.from('annonces').update({
        'titre':   titre.trim(),
        'contenu': contenu.trim(),
        'type':    type,
        'statut':  statut,
      }).eq('id', id);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteAnnonce(int id) async {
    try {
      await _db.from('annonces').delete().eq('id', id);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}