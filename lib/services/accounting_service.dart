import 'package:supabase_flutter/supabase_flutter.dart';

class AccountingService {
  final _db = Supabase.instance.client;

  /// Audit certifié : Recalcule tout depuis les flux réels (historique_paiements) 
  /// pour garantir la cohérence mathématique.
  Future<Map<String, dynamic>> getFullResidenceAudit(int residenceId, int annee) async {
    final results = await Future.wait([
      // 1. Dépenses (Flux sortant) - AJOUT de inter_syndic pour savoir qui a payé
      _db.from('depenses')
          .select('*, categories(nom, type), tranches(nom), inter_syndic:inter_syndic_id(nom, prenom)')
          .eq('residence_id', residenceId)
          .eq('annee', annee),

      // 2. Créances (Dettes théoriques)
      _db.from('paiements')
          .select('*, appartements(id, numero, immeubles(id, tranche_id, tranches(id, nom)))')
          .eq('residence_id', residenceId),

      // 3. TOUT l'historique des encaissements (Flux entrant global)
      // On prend tout pour calculer le "Global" et on filtrera en local pour l'année
      _db.from('historique_paiements')
          .select('*, paiement:paiement_id!inner(id, residence_id, appartements!inner(immeubles!inner(tranche_id)))')
          .eq('paiement.residence_id', residenceId),

      // 4. Structure des tranches
      _db.from('tranches')
          .select('*, inter_syndic:inter_syndic_id(id, nom, prenom)')
          .eq('residence_id', residenceId),

      // 5. Mandats
      _db.from('historique_affectations')
          .select('*, inter_syndic:inter_syndic_id(nom, prenom), tranches!inner(id, nom, residence_id)')
          .eq('tranches.residence_id', residenceId)
          .order('date_debut', ascending: false),
    ]);

    final data = {
      'expenses': results[0] as List,
      'payments': results[1] as List,
      'all_history': results[2] as List,
      'tranches': results[3] as List,
      'history': results[4] as List,
      'selected_year': annee,
    };

    return {
      ...data,
      'certified_stats': _calculateCertifiedStats(data, annee),
    };
  }

  Map<String, dynamic> _calculateCertifiedStats(Map<String, dynamic> data, int selectedYear) {
    final tranches = data['tranches'] as List;
    final allHistory = data['all_history'] as List;
    final allPayments = data['payments'] as List;
    final allExpenses = data['expenses'] as List;

    Map<int, Map<String, dynamic>> trancheStats = {};

    for (var tranche in tranches) {
      final tId = tranche['id'] as int;

      // --- CALCULS PAR TRANCHE ---

      // Dépenses de l'année pour cette tranche
      double spentYear = allExpenses
          .where((e) => e['tranche_id'] == tId)
          .fold(0.0, (sum, e) => sum + (double.tryParse(e['montant'].toString()) ?? 0.0));

      // Encaissements RÉELS de l'année pour cette tranche
      double collectedYear = allHistory
          .where((h) {
        final date = DateTime.parse(h['date']);
        return h['paiement']['appartements']['immeubles']['tranche_id'] == tId && date.year == selectedYear;
      })
          .fold(0.0, (sum, h) => sum + (double.tryParse(h['montant'].toString()) ?? 0.0));

      // Encaissements RÉELS GLOBAUX (toute l'histoire)
      double collectedGlobal = allHistory
          .where((h) => h['paiement']['appartements']['immeubles']['tranche_id'] == tId)
          .fold(0.0, (sum, h) => sum + (double.tryParse(h['montant'].toString()) ?? 0.0));

      // Dettes théoriques (Total à payer selon le contrat)
      double dueGlobal = allPayments
          .where((p) => p['appartements']['immeubles']['tranche_id'] == tId)
          .fold(0.0, (sum, p) => sum + (double.tryParse(p['montant_total'].toString()) ?? 0.0));

      trancheStats[tId] = {
        'collected_year': collectedYear,
        'spent_year': spentYear,
        'solde_year': collectedYear - spentYear,
        'collected_global': collectedGlobal,
        'due_global': dueGlobal,
        'recovery_rate': dueGlobal > 0 ? (collectedGlobal / dueGlobal) * 100 : 0.0,
      };
    }

    // --- CALCULS GLOBAUX RÉSIDENCE ---
    double totalCollectedYear = allHistory
        .where((h) => DateTime.parse(h['date']).year == selectedYear)
        .fold(0.0, (sum, h) => sum + (double.tryParse(h['montant'].toString()) ?? 0.0));

    double totalSpentYear = allExpenses
        .fold(0.0, (sum, e) => sum + (double.tryParse(e['montant'].toString()) ?? 0.0));

    return {
      'tranches': trancheStats,
      'total_collected_year': totalCollectedYear,
      'total_spent_year': totalSpentYear,
      'global_solde_year': totalCollectedYear - totalSpentYear,
    };
  }

  Future<List<Map<String, dynamic>>> getAuditCategories() async {
    final res = await _db.from('categories').select('id, nom').order('nom');
    return List<Map<String, dynamic>>.from(res);
  }
}
