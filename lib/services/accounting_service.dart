import 'package:supabase_flutter/supabase_flutter.dart';

class AccountingService {
  final _db = Supabase.instance.client;

  // 1. Journal des Dépenses filtré
  Future<List<Map<String, dynamic>>> getAuditExpenses(int residenceId, int annee) async {
    try {
      final response = await _db.from('depenses').select('''
        id, montant, date, description,
        categories ( id, nom, type ),
        tranches ( nom ),
        inter_syndic:inter_syndic_id ( nom, prenom )
      ''')
          .eq('residence_id', residenceId)
          .eq('annee', annee)
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // 2. Audit détaillé des Recettes (Paiements)
  Future<List<Map<String, dynamic>>> getDetailedAccounting(int residenceId, int annee) async {
    try {
      final response = await _db.from('paiements').select('''
        id, montant_total, montant_paye, type_paiement, annee, mois, statut,
        resident:users!paiements_resident_id_fkey(id, nom, prenom),
        appartements(
          id, numero, 
          immeubles(id, nom, tranches(id, nom))
        )
      ''')
          .eq('residence_id', residenceId)
          .eq('annee', annee);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // 3. Récupérer les catégories pour le filtre (Celle qui manquait)
  Future<List<Map<String, dynamic>>> getAuditCategories() async {
    final res = await _db.from('categories').select('id, nom').order('nom');
    return List<Map<String, dynamic>>.from(res);
  }
  Future<Map<String, dynamic>> getFullResidenceAudit(int residenceId, int annee) async {
    // On lance toutes les requêtes en même temps pour la performance
    final results = await Future.wait([
      _db.from('depenses').select('*, categories(nom, type), tranches(nom), inter_syndic:inter_syndic_id(nom)').eq('residence_id', residenceId).eq('annee', annee),
      _db.from('paiements').select('*, resident:resident_id(nom, prenom), appartements(numero, immeubles(nom, tranches(nom)))').eq('residence_id', residenceId).eq('annee', annee),
      _db.from('tranches').select('id, nom').eq('residence_id', residenceId),
    ]);

    return {
      'expenses': results[0] as List,
      'payments': results[1] as List,
      'tranches': results[2] as List,
    };
  }
}