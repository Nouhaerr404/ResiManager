import 'package:supabase_flutter/supabase_flutter.dart';

// 1. LE MODÈLE (Synchronisé avec ton écran)
class DashboardStats {
  final int tranches, immeubles, appartements, parkings, garages, boxes;
  final double chargesTotales, revenusParkings, recoveryRate;

  DashboardStats({
    required this.tranches, required this.immeubles, required this.appartements,
    required this.parkings, required this.garages, required this.boxes,
    required this.chargesTotales, required this.revenusParkings,
    required this.recoveryRate,
  });
}

class SyndicDashboardService {
  final _supabase = Supabase.instance.client;

  Future<DashboardStats> fetchDashboardStats(int residenceId) async {
    try {
      // 1. Structure
      final tranches = await _supabase.from('tranches').select('id').eq('residence_id', residenceId);
      final List<int> tIds = tranches.map((t) => int.parse(t['id'].toString())).toList();

      int appCount = 0;
      if (tIds.isNotEmpty) {
        final imms = await _supabase.from('immeubles').select('id').inFilter('tranche_id', tIds);
        final immIds = imms.map((i) => i['id']).toList();
        if (immIds.isNotEmpty) {
          final apps = await _supabase.from('appartements').select('id').inFilter('immeuble_id', immIds);
          appCount = apps.length;
        }
      }

      // 2. Espaces
      final pks = await _supabase.from('parkings').select('id').eq('residence_id', residenceId);
      final grs = await _supabase.from('garages').select('id').eq('residence_id', residenceId);
      final bxs = await _supabase.from('boxes').select('id').eq('residence_id', residenceId);

      // 3. Finances (Vraies sommes)
      final year = DateTime.now().year;
      final deps = await _supabase.from('depenses').select('montant').eq('residence_id', residenceId).eq('annee', year);
      final pays = await _supabase.from('paiements').select('montant_paye, montant_total').eq('residence_id', residenceId).eq('annee', year);

      double totalExp = deps.fold(0, (sum, e) => sum + (e['montant'] as num).toDouble());
      double totalPay = pays.fold(0, (sum, p) => sum + (p['montant_paye'] as num).toDouble());
      double totalDue = pays.fold(0, (sum, p) => sum + (p['montant_total'] as num).toDouble());

      return DashboardStats(
        tranches: tranches.length,
        immeubles: tIds.length,
        appartements: appCount,
        parkings: pks.length,
        garages: grs.length,
        boxes: bxs.length,
        chargesTotales: totalExp,
        revenusParkings: totalPay,
        recoveryRate: totalDue > 0 ? (totalPay / totalDue) * 100 : 0,
      );
    } catch (e) {
      return DashboardStats(tranches:0, immeubles:0, appartements:0, parkings:0, garages:0, boxes:0, chargesTotales:0, revenusParkings:0, recoveryRate:0);
    }
  }
}