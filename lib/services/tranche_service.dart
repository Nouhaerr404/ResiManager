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
      print('>>> Tranches trouvées: ${list.length}');

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
      if (immeubleIds.isNotEmpty) {
        final appartements = await _db
            .from('appartements')
            .select('id')
            .inFilter('immeuble_id', immeubleIds);
        final appartIds = (appartements as List)
            .map((a) => a['id'] as int)
            .toList();

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

      // Appartements (count réel via immeubles)
      int nbAppartements = 0;
      if (immeubleIds.isNotEmpty) {
        final appts = await _db
            .from('appartements')
            .select('id')
            .inFilter('immeuble_id', immeubleIds);
        nbAppartements = (appts as List).length;
      }

      final stats = {
        'nbResidents':     nbResidents,
        'nbAppartements':  nbAppartements,
        'nbPersonnel':     (personnel as List).length,
        'nbParkings':      (parkings as List).length,
        'nbGarages':       (garages as List).length,
        'nbBoxes':         (boxes as List).length,
        'solde':    finances?['solde'] ?? 0,
        'revenus':  finances?['revenus_total'] ?? 0,
        'depenses': finances?['depenses_total'] ?? 0,
      };

      print('>>> Stats: $stats');
      return stats;

    } catch (e, s) {
      print('>>> ERREUR getTrancheStats: $e\n$s');
      return {
        'nbResidents': 0,
        'nbAppartements': 0,
        'nbPersonnel': 0,
        'nbParkings': 0,
        'nbGarages': 0,
        'nbBoxes': 0,
        'solde': 0,
        'revenus': 0,
        'depenses': 0,
      };
    }
  }

  Future<List<TrancheModel>> getTranchesByResidence(int residenceId) async {
    final response = await _db
        .from('tranches')
        .select('*, residences(*), users(nom, prenom)') // Jointure avec users pour le nom de l'inter-syndic
        .eq('residence_id', residenceId);

    return (response as List)
        .map((e) => TrancheModel.fromJson(e))
        .toList();
  }

  Future<void> createTrancheComplet(
      int residenceId,
      String nom,
      String description,
      int? interSyndicId, // <--- AJOUT ICI
      int nbImm, int nbApp, int nbPark, int nbGar, int nbBox) async {

    await _db.from('tranches').insert({
      'residence_id': residenceId,
      'nom': nom,
      'inter_syndic_id': interSyndicId, // <--- AJOUT ICI
      'nombre_immeubles': nbImm,
      'nombre_appartements': nbApp,
      'nombre_parkings': nbPark,
      'nombre_garages': nbGar,
      'nombre_boxes': nbBox,
    });
  }

  // Récupère la liste des inter-syndics disponibles
  Future<List<Map<String, dynamic>>> getAvailableInterSyndics() async {
    final response = await _db
        .from('users')
        .select('id, nom, prenom')
        .eq('role', 'inter_syndic')
        .eq('statut', 'actif');
    return List<Map<String, dynamic>>.from(response);
  }

  // Met à jour la tranche avec le nouvel ID d'inter-syndic
  Future<void> assignInterSyndic(int trancheId, int? interSyndicId) async {
    await _db
        .from('tranches')
        .update({'inter_syndic_id': interSyndicId})
        .eq('id', trancheId);
  }

  // Récupérer les immeubles pour une tranche spécifique (IDs et Noms)
  Future<List<Map<String, dynamic>>> getImmeublesByTranche(int trancheId) async {
    final response = await _db
        .from('immeubles')
        .select('id, nom')
        .eq('tranche_id', trancheId);

    return List<Map<String, dynamic>>.from(response);
  }
  // Récupérer les noms des immeubles pour une tranche spécifique (pour TrancheDetailCard)
  Future<List<String>> getImmeubleNames(int trancheId) async {
    final response = await _db
        .from('immeubles')
        .select('nom')
        .eq('tranche_id', trancheId);

    return (response as List).map((i) => i['nom'] as String).toList();
  }

  // Mettre à jour une tranche existante (Nom + Syndic)
  Future<void> updateTrancheComplet(
      int trancheId,
      String nom,
      int? interSyndicId,
      int nbImm, int nbApp, int nbPark, int nbGar, int nbBox) async {

    await _db.from('tranches').update({
      'nom': nom,
      'inter_syndic_id': interSyndicId,
      'nombre_immeubles': nbImm,
      'nombre_appartements': nbApp,
      'nombre_parkings': nbPark,
      'nombre_garages': nbGar,
      'nombre_boxes': nbBox,
    }).eq('id', trancheId);
  }

}