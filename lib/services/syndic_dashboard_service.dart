import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Définition du modèle mis à jour pour inclure le taux de recouvrement
class DashboardStats {
  final int syndicsActifs;
  final int tranches;
  final int immeubles;
  final int appartements;
  final double chargesTotales;
  final double revenusParkings;
  final double recoveryRate; // <--- NOUVEAU CHAMP POUR LA JAUGE

  DashboardStats({
    required this.syndicsActifs,
    required this.tranches,
    required this.immeubles,
    required this.appartements,
    required this.chargesTotales,
    required this.revenusParkings,
    required this.recoveryRate, // <--- AJOUTÉ ICI
  });
}

class SyndicDashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<DashboardStats> fetchDashboardStats(int residenceId) async {
    try {
      // --- 1. RÉCUPÉRATION DES TRANCHES ---
      final List<dynamic> tranchesData = await _supabase
          .from('tranches')
          .select('id, inter_syndic_id')
          .eq('residence_id', residenceId);

      final int tranchesCount = tranchesData.length;

      // Conversion sécurisée en List<int> pour éviter l'erreur de type
      final List<int> trancheIds = tranchesData
          .map((t) => int.parse(t['id'].toString()))
          .toList();

      final activeSyndics = tranchesData
          .where((t) => t['inter_syndic_id'] != null)
          .map((t) => t['inter_syndic_id'])
          .toSet();

      // --- 2. IMMEUBLES ET APPARTEMENTS ---
      int immeublesCount = 0;
      int appartementsCount = 0;

      if (trancheIds.isNotEmpty) {
        final List<dynamic> immeublesData = await _supabase
            .from('immeubles')
            .select('id')
            .inFilter('tranche_id', trancheIds);

        immeublesCount = immeublesData.length;

        final List<int> immeubleIds = immeublesData
            .map((i) => int.parse(i['id'].toString()))
            .toList();

        if (immeubleIds.isNotEmpty) {
          final List<dynamic> appartementsData = await _supabase
              .from('appartements')
              .select('id')
              .inFilter('immeuble_id', immeubleIds);

          appartementsCount = appartementsData.length;
        }
      }

      // --- 3. CHARGES RÉELLES (Sorties d'argent / Factures) ---
      final List<dynamic> depensesRes = await _supabase
          .from('depenses')
          .select('montant')
          .eq('residence_id', residenceId);

      double totalCharges = 0;
      for (var d in depensesRes) {
        totalCharges += (d['montant'] as num).toDouble();
      }

      // --- 4. REVENUS RÉELS ET TAUX DE RECOUVREMENT (Calcul pour la jauge) ---
      // On récupère ce que les résidents DOIVENT payer vs ce qu'ils ONT payé
      final List<dynamic> paiementsData = await _supabase
          .from('paiements')
          .select('montant_total, montant_paye')
          .eq('residence_id', residenceId);

      double totalAttendu = 0;
      double totalRecolte = 0;

      for (var p in paiementsData) {
        totalAttendu += (p['montant_total'] as num).toDouble();
        totalRecolte += (p['montant_paye'] as num).toDouble();
      }

      // Calcul du pourcentage réel de recouvrement
      double calculatedRecoveryRate = (totalAttendu > 0)
          ? (totalRecolte / totalAttendu) * 100
          : 0.0;

      // --- 5. REVENUS PARKINGS RÉELS ---
      final List<dynamic> parkingsData = await _supabase
          .from('parkings')
          .select('prix_annuel')
          .eq('residence_id', residenceId)
          .eq('statut', 'occupe');

      double totalParkings = 0;
      for (var p in parkingsData) {
        totalParkings += ((p['prix_annuel'] as num).toDouble() / 12);
      }

      return DashboardStats(
        syndicsActifs: activeSyndics.length,
        tranches: tranchesCount,
        immeubles: immeublesCount,
        appartements: appartementsCount,
        chargesTotales: totalCharges,
        revenusParkings: totalParkings,
        recoveryRate: calculatedRecoveryRate, // On renvoie le vrai taux !
      );

    } catch (e) {
      print('Erreur Dashboard Service: $e');
      return DashboardStats(
          syndicsActifs: 0, tranches: 0, immeubles: 0,
          appartements: 0, chargesTotales: 0, revenusParkings: 0, recoveryRate: 0
      );
    }
  }

  Future<Map<String, dynamic>> getChartsData(int residenceId) async {
    try {
      // 1. Dépenses par mois
      final depensesRes = await _supabase.from('depenses')
          .select('montant, mois')
          .eq('residence_id', residenceId);

      // 2. Revenus (Paiements reçus) par mois
      final revenusRes = await _supabase.from('paiements')
          .select('montant_paye, mois')
          .eq('residence_id', residenceId);

      List<double> monthlyDeps = List.filled(12, 0.0);
      List<double> monthlyRevs = List.filled(12, 0.0);

      for (var d in depensesRes) {
        if (d['mois'] != null && d['mois'] > 0 && d['mois'] <= 12) {
          monthlyDeps[d['mois'] - 1] += (d['montant'] as num).toDouble();
        }
      }
      for (var r in revenusRes) {
        if (r['mois'] != null && r['mois'] > 0 && r['mois'] <= 12) {
          monthlyRevs[r['mois'] - 1] += (r['montant_paye'] as num).toDouble();
        }
      }

      return {
        'expenses': monthlyDeps,
        'revenues': monthlyRevs,
      };
    } catch (e) {
      return {'expenses': List.filled(12, 0.0), 'revenues': List.filled(12, 0.0)};
    }
  }
}