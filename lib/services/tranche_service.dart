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
}