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
    // On demande à Supabase de compter les relations (immeubles et appartements)
    final response = await _db
        .from('tranches')
        .select('''
          *,
          users(nom, prenom),
          immeubles(count),
          appartements_count:immeubles(appartements(count))
        ''')
        .eq('residence_id', residenceId);

    return (response as List).map((e) {
      // On calcule le nombre d'appartements total en sommant les comptes des immeubles
      int realAppCount = 0;
      if (e['appartements_count'] != null) {
        for (var imm in e['appartements_count']) {
          realAppCount += (imm['appartements'][0]['count'] as int);
        }
      }

      return TrancheModel(
        id: e['id'],
        nom: e['nom'],
        description: e['description'],
        residenceId: e['residence_id'],
        interSyndicId: e['inter_syndic_id'],
        // ON REMPLACE LES COLONNES PAR LES COMPTES RÉELS
        nombreImmeubles: e['immeubles'][0]['count'],
        nombreAppartements: realAppCount,
        nombreParkings: e['nombre_parkings'] ?? 0,
        nombreGarages: e['nombre_garages'] ?? 0,
        nombreBoxes: e['nombre_boxes'] ?? 0,
        interSyndicNom: e['users'] != null ? "${e['users']['prenom']} ${e['users']['nom']}" : null,
      );
    }).toList();
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

  // Récupérer les numéros d'appartements d'une tranche (via les immeubles)
  Future<List<String>> getAppartementNumeros(int trancheId) async {
    final res = await _db.from('appartements')
        .select('numero, immeubles!inner(tranche_id)')
        .eq('immeubles.tranche_id', trancheId);
    return (res as List).map((a) => a['numero'] as String).toList();
  }

  // Récupérer les numéros de parkings
  Future<List<String>> getParkingNumeros(int trancheId) async {
    final res = await _db.from('parkings').select('numero').eq('tranche_id', trancheId);
    return (res as List).map((p) => p['numero'] as String).toList();
  }

  // Récupérer les numéros de garages
  Future<List<String>> getGarageNumeros(int trancheId) async {
    final res = await _db.from('garages').select('numero').eq('tranche_id', trancheId);
    return (res as List).map((g) => g['numero'] as String).toList();
  }

  // --- NOUVELLE MÉTHODE À AJOUTER À LA FIN DE TA CLASSE ---
  Future<List<Map<String, dynamic>>> getMyAvailableInterSyndics(int myId) async {
    try {
      // Le secret est d'ajouter "!inner" après le nom de la table jointe
      final response = await _db
          .from('liens_syndics')
          .select('''
            inter_syndic:users!inter_syndic_id!inner (
              id, nom, prenom, statut
            )
          ''')
          .eq('syndic_general_id', myId)
          .eq('inter_syndic.statut', 'actif'); // On utilise l'alias défini au dessus

      final List data = response as List;

      // On extrait proprement le profil pour le Dropdown
      return data.map((item) => item['inter_syndic'] as Map<String, dynamic>).toList();

    } catch (e) {
      print("ERREUR FILTRAGE ACTIFS : $e");
      return [];
    }
  }

}