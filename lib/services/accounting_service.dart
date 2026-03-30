import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/affectation_history_model.dart';

class AccountingService {
  final _db = Supabase.instance.client;

  // 1. Liste des tranches
  Future<List<Map<String, dynamic>>> getTranchesList(int residenceId) async {
    final res = await _db.from('tranches').select('id, nom').eq('residence_id', residenceId).order('nom');
    return List<Map<String, dynamic>>.from(res);
  }

  // 2. Liste des immeubles d'une tranche
  Future<List<Map<String, dynamic>>> getImmeublesByTranche(int trancheId) async {
    final res = await _db.from('immeubles').select('id, nom').eq('tranche_id', trancheId).order('nom');
    return List<Map<String, dynamic>>.from(res);
  }

  // 3. Historique des mandats
  Future<List<AffectationHistoryModel>> getMandates(int trancheId) async {
    final res = await _db.from('historique_affectations')
        .select('*, inter_syndic:inter_syndic_id(nom, prenom)')
        .eq('tranche_id', trancheId)
        .order('date_debut', ascending: false);
    return (res as List).map((m) => AffectationHistoryModel.fromJson(m)).toList();
  }

  // 4. Détails complets (Inclut maintenant les dépenses globales divisées)
  Future<Map<String, dynamic>> getMandateAuditDetails(int mandateId, int trancheId) async {
    // A. Récupérer l'ID de la résidence
    final trancheInfo = await _db.from('tranches').select('residence_id').eq('id', trancheId).single();
    final int residenceId = trancheInfo['residence_id'];

    // B. Récupérer le nombre total de tranches dans cette résidence
    final allTranches = await _db.from('tranches').select('id').eq('residence_id', residenceId);
    final int totalTranchesCount = (allTranches as List).length;

    // C. Requêtes parallèles
    final res = await Future.wait([
      // Dépenses de la tranche
      _db.from('depenses').select('*, categories(nom)').eq('tranche_id', trancheId).order('date'),
      
      // Dépenses globales (sans tranche_id) ajoutées par le SG
      _db.from('depenses').select('*, categories(nom)').eq('residence_id', residenceId).isFilter('tranche_id', null).order('date'),

      // Paiements
      _db.from('paiements').select('*, resident:resident_id(nom, prenom), appartements(id, numero, immeuble_id)').eq('mandat_id', mandateId),
      
      // Appartements
      _db.from('appartements').select('id, numero, immeuble_id, immeubles!inner(tranche_id)').eq('immeubles.tranche_id', trancheId),
    ]);

    final List<Map<String, dynamic>> trancheExpenses = List<Map<String, dynamic>>.from(res[0] as List);
    final List<Map<String, dynamic>> globalExpenses = List<Map<String, dynamic>>.from(res[1] as List);

    // D. Transformer les dépenses globales pour n'afficher que la part de cette tranche
    final List<Map<String, dynamic>> dividedGlobalExpenses = globalExpenses.map((e) {
      double fullAmount = (e['montant'] as num).toDouble();
      return {
        ...e,
        'montant': fullAmount / (totalTranchesCount > 0 ? totalTranchesCount : 1),
        'is_global': true,
        'original_montant': fullAmount,
      };
    }).toList();

    // E. Fusionner les deux listes de dépenses
    final List<Map<String, dynamic>> allExpenses = [...trancheExpenses, ...dividedGlobalExpenses];
    allExpenses.sort((a, b) => (a['date'] ?? '').compareTo(b['date'] ?? ''));

    return {
      'expenses': allExpenses,
      'payments': List<Map<String, dynamic>>.from(res[2] as List),
      'apartments': List<Map<String, dynamic>>.from(res[3] as List),
    };
  }
}