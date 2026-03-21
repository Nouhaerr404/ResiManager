import 'package:supabase_flutter/supabase_flutter.dart';

class AccountingService {
  final _db = Supabase.instance.client;

  // 1. Audit des Dépenses (Détails)
  Future<List<Map<String, dynamic>>> getAuditExpenses(int residenceId) async {
    try {
      final response = await _db.from('depenses').select('''
        id, montant, date, description,
        categories ( nom ),
        tranches ( nom ),
        inter_syndic:inter_syndic_id ( nom, prenom )
      ''')
          .eq('residence_id', residenceId)
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Erreur SQL Dépenses: $e");
      return [];
    }
  }

  // 2. Audit des Paiements (Recettes)
  Future<List<Map<String, dynamic>>> getAuditPaiements(int residenceId) async {
    try {
      final response = await _db.from('paiements').select('''
        montant_total, montant_paye, statut, type_paiement,
        resident:resident_id ( nom, prenom ),
        appartements (
          numero, 
          immeubles (
            nom, 
            tranches ( nom )
          )
        )
      ''')
          .eq('residence_id', residenceId)
          .order('id');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Erreur SQL Paiements: $e");
      return [];
    }
  }
}