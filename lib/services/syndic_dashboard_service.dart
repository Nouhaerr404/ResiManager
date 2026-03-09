import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Définition du modèle
class DashboardStats {
  final int syndicsActifs;
  final int tranches;
  final int immeubles;
  final int appartements;
  final double chargesTotales;
  final double revenusParkings;

  DashboardStats({
    required this.syndicsActifs,
    required this.tranches,
    required this.immeubles,
    required this.appartements,
    required this.chargesTotales,
    required this.revenusParkings,
  });
}

// 2. Le Service
class SyndicDashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<DashboardStats> fetchDashboardStats(int residenceId) async {
    try {
      // -- Récupération des Tranches --
      final tranchesRes = await _supabase
          .from('tranches')
          .select('id, inter_syndic_id')
          .eq('residence_id', residenceId);

      final int tranchesCount = tranchesRes.length;
      final List<dynamic> trancheIds = tranchesRes.map((t) => t['id']).toList();

      // -- Syndics Actifs (Uniques) --
      final activeSyndics = tranchesRes
          .where((t) => t['inter_syndic_id'] != null)
          .map((t) => t['inter_syndic_id'])
          .toSet();

      // -- Immeubles et Appartements --
      // -- Immeubles et Appartements --
      int immeublesCount = 0;
      int appartementsCount = 0;

      if (trancheIds.isNotEmpty) {
        // 1. On récupère les immeubles de ces tranches
        final immeublesRes = await _supabase
            .from('immeubles')
            .select('id')
            .inFilter('tranche_id', trancheIds);

        immeublesCount = immeublesRes.length;

        // 2. On extrait les IDs de ces immeubles
        final List<dynamic> immeubleIds = immeublesRes.map((i) => i['id']).toList();

        // 3. ON COMPTE LES VRAIES LIGNES DANS LA TABLE APPARTEMENTS
        if (immeubleIds.isNotEmpty) {
          final appartementsRes = await _supabase
              .from('appartements')
              .select('id')
              .inFilter('immeuble_id', immeubleIds);

          appartementsCount = appartementsRes.length; // Ça affichera exactement 10 !
        }
      }

      // -- Charges Totales (Correction de la jointure avec la table categories) --
      final currentMonth = DateTime.now().month;
      final currentYear = DateTime.now().year;

      // Ici on fait un INNER JOIN avec categories pour filtrer sur le type 'globale'
      final depensesRes = await _supabase
          .from('depenses')
          .select('montant, categories!inner(type)')
          .eq('residence_id', residenceId)
          .eq('categories.type', 'globale')
          .eq('mois', currentMonth)
          .eq('annee', currentYear);

      double chargesTotales = 0.0;
      for (var d in depensesRes) {
        chargesTotales += (d['montant'] as num? ?? 0).toDouble();
      }

      // -- Revenus Parkings --
      final parkingsRes = await _supabase
          .from('parkings')
          .select('prix_annuel')
          .eq('residence_id', residenceId)
          .eq('statut', 'occupe');

      double revenusParkings = 0.0;
      for (var p in parkingsRes) {
        revenusParkings += ((p['prix_annuel'] as num? ?? 0).toDouble() / 12);
      }

      return DashboardStats(
        syndicsActifs: activeSyndics.length,
        tranches: tranchesCount,
        immeubles: immeublesCount,
        appartements: appartementsCount,
        chargesTotales: chargesTotales,
        revenusParkings: revenusParkings,
      );
    } catch (e) {
      throw Exception('Erreur Supabase : $e');
    }
  }
}