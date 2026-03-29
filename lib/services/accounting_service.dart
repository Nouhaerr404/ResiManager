import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/affectation_history_model.dart';

class AccountingService {
  final _db = Supabase.instance.client;

  // 1. Liste des tranches
  Future<List<Map<String, dynamic>>> getTranchesList(int residenceId) async {
    final res = await _db.from('tranches').select('id, nom').eq('residence_id', residenceId).order('nom');
    return List<Map<String, dynamic>>.from(res);
  }

  // 2. NOUVELLE MÉTHODE : Liste des immeubles d'une tranche (Répare ton erreur)
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

  // 4. Détails complets
  Future<Map<String, dynamic>> getMandateAuditDetails(int mandateId, int trancheId) async {
    final res = await Future.wait([
      _db.from('depenses').select('*, categories(nom)').eq('tranche_id', trancheId).order('date'),
      _db.from('paiements').select('*, resident:resident_id(nom, prenom), appartements(id, numero, immeuble_id)').eq('mandat_id', mandateId),
      _db.from('appartements').select('id, numero, immeuble_id, immeubles!inner(tranche_id)').eq('immeubles.tranche_id', trancheId),
    ]);
    return {
      'expenses': List<Map<String, dynamic>>.from(res[0] as List),
      'payments': List<Map<String, dynamic>>.from(res[1] as List),
      'apartments': List<Map<String, dynamic>>.from(res[2] as List),
    };
  }
}