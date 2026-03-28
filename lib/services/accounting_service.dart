import 'package:supabase_flutter/supabase_flutter.dart';

class AccountingService {
  final _db = Supabase.instance.client;

  // 1. Audit complet pour la vue consolidée
  Future<Map<String, dynamic>> getFullResidenceAudit(int residenceId, int annee) async {
    final results = await Future.wait([
      // Dépenses de l'année filtrée
      _db.from('depenses')
          .select('*, categories(nom, type), tranches(nom), inter_syndic:inter_syndic_id(nom, prenom)')
          .eq('residence_id', residenceId)
          .eq('annee', annee),
          
      // Paiements (Dettes globales) liées à la résidence
      _db.from('paiements')
          .select('*, inter_syndic:inter_syndic_id(nom, prenom), resident:resident_id(nom, prenom), appartements(id, numero, immeubles(id, nom, tranches(id, nom)))')
          .eq('residence_id', residenceId),
          
      // Tranches de la résidence
      _db.from('tranches')
          .select('*, inter_syndic:inter_syndic_id(id, nom, prenom)')
          .eq('residence_id', residenceId),

      // Historique des affectations (Mandats) - Filtré par résidence
      _db.from('historique_affectations')
          .select('*, inter_syndic:inter_syndic_id(nom, prenom), tranches!inner(residence_id)')
          .eq('tranches.residence_id', residenceId)
          .order('date_debut', ascending: false),

      // Historique des paiements REELS effectués durant l'année filtrée - Filtré par résidence
      _db.from('historique_paiements')
          .select('*, paiement:paiement_id!inner(id, appartement_id, type_paiement, inter_syndic_id, residence_id)')
          .eq('paiement.residence_id', residenceId)
          .gte('date', '$annee-01-01')
          .lte('date', '$annee-12-31'),
    ]);

    return {
      'expenses': results[0] as List,
      'payments': results[1] as List,
      'tranches': results[2] as List,
      'history': results[3] as List,
      'payment_history': results[4] as List,
    };
  }

  // Autres méthodes pour les filtres
  Future<List<Map<String, dynamic>>> getAuditCategories() async {
    final res = await _db.from('categories').select('id, nom').order('nom');
    return List<Map<String, dynamic>>.from(res);
  }
}
