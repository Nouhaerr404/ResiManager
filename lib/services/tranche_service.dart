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
          .select('*')
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

      final stats = {
        'nbResidents':  nbResidents,
        'nbPersonnel':  (personnel as List).length,
        'nbParkings':   (parkings as List).length,
        'nbGarages':    (garages as List).length,
        'nbBoxes':      (boxes as List).length,
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
}