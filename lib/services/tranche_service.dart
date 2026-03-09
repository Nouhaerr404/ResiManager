import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tranche_model.dart';


class TrancheService {
  final _db = Supabase.instance.client;

  Future<List<TrancheModel>> getTranchesOfInterSyndic(int interSyndicId) async {
    final response = await _db
        .from('tranches')
        .select('*')
        .eq('inter_syndic_id', interSyndicId);

    return (response as List)
        .map((e) => TrancheModel.fromJson(e))
        .toList();
  }

  // Pour le résumé financier dans Écran 2
  Future<Map<String, dynamic>> getTrancheStats(int trancheId) async {
    // Nombre résidents
    final residents = await _db
        .from('residents')
        .select('id, appartements!inner(immeubles!inner(tranche_id))')
        .eq('appartements.immeubles.tranche_id', trancheId);

    // Nombre personnel
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

    // Finances summary
    final finances = await _db
        .from('finances_summary')
        .select('*')
        .eq('tranche_id', trancheId)
        .maybeSingle();

    return {
      'nbResidents': (residents as List).length,
      'nbPersonnel': (personnel as List).length,
      'nbParkings': (parkings as List).length,
      'nbGarages': (garages as List).length,
      'nbBoxes': (boxes as List).length,
      'solde': finances?['solde'] ?? 0,
      'revenus': finances?['revenus_total'] ?? 0,
      'depenses': finances?['depenses_total'] ?? 0,
    };
  }

  Future<List<TrancheModel>> getTranchesByResidence(int residenceId) async {
    final response = await _db
        .from('tranches')
        .select('*, users(nom, prenom)') // Jointure avec users pour le nom de l'inter-syndic
        .eq('residence_id', residenceId);

    return (response as List)
        .map((e) => TrancheModel.fromJson(e))
        .toList();
  }

  Future<void> createTrancheComplet(
      int residenceId, String nom, String description,
      int nbImm, int nbApp, int nbPark, int nbGar, int nbBox) async {

    await _db.from('tranches').insert({
      'residence_id': residenceId,
      'nom': nom,
      'description': description,
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

}