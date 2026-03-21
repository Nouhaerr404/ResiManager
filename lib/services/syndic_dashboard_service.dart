import 'package:supabase_flutter/supabase_flutter.dart';

// 1. LE MODÈLE DÉFINITIF (CORRIGÉ)
class DashboardStats {
  final int tranches, immeubles, appartements, parkings, garages, boxes, syndicsActifs;
  final double chargesTotales, revenusParkings, recoveryRate;

  DashboardStats({
    required this.tranches,
    required this.immeubles,
    required this.appartements,
    required this.parkings,
    required this.garages,
    required this.boxes,
    required this.syndicsActifs, // <--- ÉTAIT MANQUANT ICI
    required this.chargesTotales,
    required this.revenusParkings,
    required this.recoveryRate,
  });
}

class SyndicDashboardService {
  final _supabase = Supabase.instance.client;

  Future<DashboardStats> fetchDashboardStats(int residenceId) async {
    try {
      final int currentYear = DateTime.now().year;

      // 1. COMPTE RÉEL DES TRANCHES
      final List<dynamic> tranchesData = await _supabase
          .from('tranches')
          .select('id, inter_syndic_id')
          .eq('residence_id', residenceId);

      final List<int> trancheIds = tranchesData
          .map((t) => int.parse(t['id'].toString()))
          .toList();

      // 2. COMPTE RÉEL DES IMMEUBLES
      int immeublesCount = 0;
      List<int> immeubleIds = [];

      if (trancheIds.isNotEmpty) {
        final List<dynamic> immsRes = await _supabase
            .from('immeubles')
            .select('id')
            .inFilter('tranche_id', trancheIds);

        immeublesCount = immsRes.length;
        immeubleIds = immsRes.map((i) => int.parse(i['id'].toString())).toList();
      }

      // 3. COMPTE RÉEL DES APPARTEMENTS
      int appartementsCount = 0;
      if (immeubleIds.isNotEmpty) {
        final List<dynamic> appsRes = await _supabase
            .from('appartements')
            .select('id')
            .inFilter('immeuble_id', immeubleIds);

        appartementsCount = appsRes.length;
      }

      // 4. COMPTE RÉEL DES ESPACES
      final pks = await _supabase.from('parkings').select('id').eq('residence_id', residenceId);
      final grs = await _supabase.from('garages').select('id').eq('residence_id', residenceId);
      final bxs = await _supabase.from('boxes').select('id').eq('residence_id', residenceId);

      // 5. CALCUL RÉEL DES FINANCES
      final depensesRes = await _supabase
          .from('depenses')
          .select('montant')
          .eq('residence_id', residenceId)
          .eq('annee', currentYear);

      double totalExpenses = depensesRes.fold(0, (sum, e) => sum + (e['montant'] as num).toDouble());

      final paiementsRes = await _supabase
          .from('paiements')
          .select('montant_total, montant_paye')
          .eq('residence_id', residenceId)
          .eq('annee', currentYear);

      double totalAttendu = 0;
      double totalRecolte = 0;
      for (var p in paiementsRes) {
        totalAttendu += (p['montant_total'] as num).toDouble();
        totalRecolte += (p['montant_paye'] as num).toDouble();
      }

      // 6. GÉNÉRATION DES STATISTIQUES FINALES
      return DashboardStats(
        tranches: tranchesData.length,
        immeubles: immeublesCount,
        appartements: appartementsCount,
        parkings: pks.length,
        garages: grs.length,
        boxes: bxs.length,
        syndicsActifs: tranchesData.where((t) => t['inter_syndic_id'] != null).length,
        chargesTotales: totalExpenses,
        revenusParkings: totalRecolte,
        recoveryRate: totalAttendu > 0 ? (totalRecolte / totalAttendu) * 100 : 0.0,
      );

    } catch (e) {
      print('Erreur Service: $e');
      return DashboardStats(
          tranches: 0, immeubles: 0, appartements: 0,
          parkings: 0, garages: 0, boxes: 0, syndicsActifs: 0,
          chargesTotales: 0, revenusParkings: 0, recoveryRate: 0
      );
    }
  }

  // --- LOGIQUE POUR LES GRAPHIQUES ---
  Future<Map<String, dynamic>> getChartsData(int residenceId) async {
    try {
      final deps = await _supabase.from('depenses').select('montant, mois').eq('residence_id', residenceId);
      final revs = await _supabase.from('paiements').select('montant_paye, mois').eq('residence_id', residenceId);
      List<double> mDeps = List.filled(12, 0.0);
      List<double> mRevs = List.filled(12, 0.0);
      for (var d in deps) { if(d['mois'] != null) mDeps[d['mois']-1] += (d['montant'] as num).toDouble(); }
      for (var r in revs) { if(r['mois'] != null) mRevs[r['mois']-1] += (r['montant_paye'] as num).toDouble(); }
      return {'expenses': mDeps, 'revenues': mRevs};
    } catch (e) { return {'expenses': List.filled(12, 0.0), 'revenues': List.filled(12, 0.0)}; }
  }
}