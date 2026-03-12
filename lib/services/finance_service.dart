import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceService {
  final _db = Supabase.instance.client;

  // 1. Pour afficher le tableau (Tableau de bord financier)
  Future<List<Map<String, dynamic>>> getResidenceExpenses({
    required int residenceId,
    int? mois,
    int? annee,
  }) async {
    try {
      var query = _db.from('depenses').select('''
        id, montant, date, mois, annee, facture_path,
        categories!inner(nom, type),
        tranches(nom)
      ''').eq('residence_id', residenceId);

      if (mois != null) query = query.eq('mois', mois);
      if (annee != null) query = query.eq('annee', annee);

      final response = await query.order('date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // 2. Pour récupérer les catégories (Utilisé par tes deux écrans)
  Future<List<Map<String, dynamic>>> getCategories(String type) async {
    final res = await _db.from('categories').select('id, nom').eq('type', type);
    return List<Map<String, dynamic>>.from(res);
  }

  // 3. Pour récupérer TOUTES les catégories sans filtre
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final response = await _db.from('categories').select('id, nom, type');
    return List<Map<String, dynamic>>.from(response);
  }

  // 4. Pour l'upload de la facture
  Future<String?> uploadInvoice(String fileName, dynamic fileBytesOrPath) async {
    try {
      final String path = 'factures/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      if (kIsWeb) {
        await _db.storage.from('resimanager_bucket').uploadBinary(path, fileBytesOrPath);
      } else {
        await _db.storage.from('resimanager_bucket').upload(path, File(fileBytesOrPath));
      }
      return _db.storage.from('resimanager_bucket').getPublicUrl(path);
    } catch (e) {
      return null;
    }
  }

  // 5. Pour enregistrer la dépense (Syndic Général)
  Future<void> addGlobalExpense({
    required int residenceId,
    required double montant,
    required int categorieId,
    required DateTime date,
    required int syndicId,
    String? facturePath,
    String? description,
  }) async {
    await _db.from('depenses').insert({
      'residence_id': residenceId,
      'montant': montant,
      'categorie_id': categorieId,
      'date': date.toIso8601String().split('T').first,
      'annee': date.year,
      'mois': date.month,
      'syndic_general_id': syndicId,
      'facture_path': facturePath,
      'description': description,
    });
  }

  // 6. Pour enregistrer une dépense Inter-Syndic (Globale ou Spécifique)
  Future<void> addInterSyndicExpense({
    required int residenceId,
    required int interSyndicId,
    required double montant,
    required int categorieId,
    required DateTime date,
    int? trancheId,
    String? facturePath,
    String? description,
  }) async {
    final expenseRes = await _db.from('depenses').insert({
      'residence_id': residenceId,
      'inter_syndic_id': interSyndicId,
      'montant': montant,
      'categorie_id': categorieId,
      'tranche_id': trancheId,
      'date': date.toIso8601String().split('T').first,
      'annee': date.year,
      'mois': date.month,
      'facture_path': facturePath,
      'description': description,
    }).select().single();

    final int expenseId = expenseRes['id'];

    List<int> tranchesIds = [];
    if (trancheId != null) {
      tranchesIds = [trancheId];
    } else {
      final res = await _db.from('tranches')
          .select('id')
          .eq('inter_syndic_id', interSyndicId)
          .eq('residence_id', residenceId);
      tranchesIds = (res as List).map((t) => t['id'] as int).toList();
    }

    if (tranchesIds.isEmpty) return;

    final immeublesRes = await _db.from('immeubles')
        .select('id')
        .inFilter('tranche_id', tranchesIds);
    final listImmIds = (immeublesRes as List).map((i) => i['id'] as int).toList();

    if (listImmIds.isEmpty) return;

    final appartRes = await _db.from('appartements')
        .select('id')
        .inFilter('immeuble_id', listImmIds);
    final listAppartIds = (appartRes as List).map((a) => a['id'] as int).toList();

    if (listAppartIds.isEmpty) return;

    double share = montant / listAppartIds.length;

    for (int appartId in listAppartIds) {
      final existingPaiement = await _db.from('paiements')
          .select()
          .eq('appartement_id', appartId)
          .eq('annee', date.year)
          .eq('mois', date.month)
          .maybeSingle();

      if (existingPaiement != null) {
        double currentTotal = double.parse(existingPaiement['montant_total'].toString());
        await _db.from('paiements').update({
          'montant_total': currentTotal + share,
          'statut': (double.parse(existingPaiement['montant_paye'].toString()) >= (currentTotal + share)) ? 'complet' : 'partiel',
        }).eq('id', existingPaiement['id']);
      } else {
        final appartInfo = await _db.from('appartements').select('resident_id').eq('id', appartId).single();
        if (appartInfo['resident_id'] != null) {
          await _db.from('paiements').insert({
            'appartement_id': appartId,
            'resident_id': appartInfo['resident_id'],
            'residence_id': residenceId,
            'inter_syndic_id': interSyndicId,
            'depense_id': expenseId,
            'montant_total': share,
            'montant_paye': 0,
            'type_paiement': 'charges',
            'statut': 'impaye',
            'annee': date.year,
            'mois': date.month,
          });
        }
      }
    }
  }

  // 7. Pour le dashboard Inter-Syndic
  Future<Map<String, dynamic>> getInterSyndicFinances(int interSyndicId, int residenceId) async {
    final tranches = await _db.from('tranches')
        .select('id, nom')
        .eq('inter_syndic_id', interSyndicId)
        .eq('residence_id', residenceId);
    final tranchesIds = (tranches as List).map((t) => t['id'] as int).toList();

    if (tranchesIds.isEmpty) {
      return {'total_depenses': 0, 'total_revenus': 0, 'solde': 0, 'depenses_par_tranche': []};
    }

    final depensesInter = await _db.from('depenses')
        .select('montant, tranche_id')
        .eq('inter_syndic_id', interSyndicId);

    double totalDepenses = 0;
    Map<int, double> depByTranche = {};
    for (var d in depensesInter) {
      double val = double.parse(d['montant'].toString());
      totalDepenses += val;
      if (d['tranche_id'] != null) {
        int tId = d['tranche_id'];
        depByTranche[tId] = (depByTranche[tId] ?? 0) + val;
      }
    }

    final paiementsRes = await _db.from('paiements')
        .select('montant_paye')
        .eq('inter_syndic_id', interSyndicId);
    
    double totalRevenus = 0;
    for (var p in paiementsRes) {
      totalRevenus += double.parse(p['montant_paye'].toString());
    }

    return {
      'total_depenses': totalDepenses,
      'total_revenus': totalRevenus,
      'solde': totalRevenus - totalDepenses,
      'depenses_par_tranche': tranches.map((t) => {
        'nom': t['nom'],
        'montant': depByTranche[t['id']] ?? 0,
      }).toList(),
    };
  }

  // 8. Récupérer le résumé financier pour les cartes de couleur
  // 8. RÉCUPÉRATION DES VALEURS RÉELLES DEPUIS LA DB
  Future<Map<String, double>> getFinanceSummary(int residenceId, int annee) async {
    try {
      // A. Récupérer le total que la résidence DOIT payer (Factures fournisseurs)
      final depensesRes = await _db
          .from('depenses')
          .select('montant')
          .eq('residence_id', residenceId)
          .eq('annee', annee);

      double totalDepenses = 0;
      for (var row in depensesRes) {
        totalDepenses += (row['montant'] as num).toDouble();
      }

      // B. Récupérer l'état des collectes auprès des résidents (Table paiements)
      final paiementsRes = await _db
          .from('paiements')
          .select('montant_total, montant_paye')
          .eq('residence_id', residenceId)
          .eq('annee', annee);

      double totalAttendu = 0;
      double totalRecolte = 0;

      for (var row in paiementsRes) {
        totalAttendu += (row['montant_total'] as num).toDouble();
        totalRecolte += (row['montant_paye'] as num).toDouble();
      }

      // C. Retourner les vrais calculs
      return {
        'total': totalDepenses,      // Ce que la résidence a dépensé (Factures)
        'paye': totalRecolte,        // Ce que les résidents ont déjà payé
        'attente': totalAttendu - totalRecolte, // Ce qui reste à recouvrer
      };
    } catch (e) {
      print("Erreur Finance Summary: $e");
      return {'total': 0, 'paye': 0, 'attente': 0};
    }
  }

// Modifie ta fonction dans finance_service.dart
  Future<List<Map<String, dynamic>>> getMyExpenses({
    required int residenceId,
    required int mySyndicId,
    int? annee,
    int? mois, // AJOUT
    int? categorieId, // AJOUT
  }) async {
    try {
      var query = _db.from('depenses').select('''
        id, montant, date, annee, mois, description, facture_path,
        categories!inner(id, nom, type)
      ''')
          .eq('residence_id', residenceId)
          .eq('syndic_general_id', mySyndicId);

      if (annee != null) query = query.eq('annee', annee);
      if (mois != null) query = query.eq('mois', mois); // FILTRE SQL MOIS
      if (categorieId != null) query = query.eq('categorie_id', categorieId); // FILTRE SQL CATÉGORIE

      final response = await query.order('date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}