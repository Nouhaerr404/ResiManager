import 'package:supabase_flutter/supabase_flutter.dart';

class AccountingService {
  final _db = Supabase.instance.client;

  // 1. Audit complet pour la vue consolidée
  Future<Map<String, dynamic>> getFullResidenceAudit(int residenceId, int annee) async {
    final results = await Future.wait([
      // Dépenses avec info inter-syndic
      _db.from('depenses')
          .select('*, categories(nom, type), tranches(nom), inter_syndic:inter_syndic_id(nom, prenom)')
          .eq('residence_id', residenceId)
          .eq('annee', annee),
          
      // Paiements avec info inter-syndic
      _db.from('paiements')
          .select('*, inter_syndic:inter_syndic_id(nom, prenom), resident:resident_id(nom, prenom), appartements(id, numero, immeubles(id, nom, tranches(id, nom)))')
          .eq('residence_id', residenceId)
          .eq('annee', annee),
          
      // Tranches avec l'inter-syndic actuel
      _db.from('tranches')
          .select('*, inter_syndic:inter_syndic_id(id, nom, prenom)')
          .eq('residence_id', residenceId),

      // Historique des affectations
      _db.from('historique_affectations')
          .select('*, inter_syndic:inter_syndic_id(nom, prenom)')
          .order('date_debut', ascending: false),
    ]);

    return {
      'expenses': results[0] as List,
      'payments': results[1] as List,
      'tranches': results[2] as List,
      'history': results[3] as List,
    };
  }

  // Autres méthodes pour les filtres
  Future<List<Map<String, dynamic>>> getAuditCategories() async {
    final res = await _db.from('categories').select('id, nom').order('nom');
    return List<Map<String, dynamic>>.from(res);
  }
}
