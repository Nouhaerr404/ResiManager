import 'package:supabase_flutter/supabase_flutter.dart';

class AccountingService {
  final _db = Supabase.instance.client;

  // 1. Audit complet pour la vue consolidée
  Future<Map<String, dynamic>> getFullResidenceAudit(int residenceId, int annee) async {
    final results = await Future.wait([
      // Dépenses
      _db.from('depenses').select('*, categories(nom, type), tranches(nom), inter_syndic:inter_syndic_id(nom)').eq('residence_id', residenceId).eq('annee', annee),
      // Paiements (On récupère tout pour le calcul par appartement)
      _db.from('paiements').select('*, resident:resident_id(nom, prenom), appartements(id, numero, immeubles(id, nom, tranches(id, nom)))').eq('residence_id', residenceId).eq('annee', annee),
      // Tranches
      _db.from('tranches').select('id, nom').eq('residence_id', residenceId),
    ]);

    return {
      'expenses': results[0] as List,
      'payments': results[1] as List,
      'tranches': results[2] as List,
    };
  }

  // Autres méthodes pour les filtres
  Future<List<Map<String, dynamic>>> getAuditCategories() async {
    final res = await _db.from('categories').select('id, nom').order('nom');
    return List<Map<String, dynamic>>.from(res);
  }
}