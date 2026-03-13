import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceService {
  final _db = Supabase.instance.client;

  // 1. Pour afficher le tableau (Tableau de bord financier Syndic Général)
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
      ''')
      .eq('residence_id', residenceId)
      .isFilter('tranche_id', null); // Uniquement les dépenses parentes

      if (mois != null) query = query.eq('mois', mois);
      if (annee != null) query = query.eq('annee', annee);

      final response = await query.order('date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // 1b. Pour afficher les dépenses d'une tranche (Inter-Syndic & Résident)
  Future<List<Map<String, dynamic>>> getTrancheExpenses({
    required int trancheId,
    int? mois,
    int? annee,
  }) async {
    try {
      var query = _db.from('depenses').select('''
        id, montant, date, mois, annee, facture_path, description,
        categories!inner(nom, type)
      ''').eq('tranche_id', trancheId);

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
    // A. Enregistrer la dépense PARENTE (Résidence)
    final parentRes = await _db.from('depenses').insert({
      'residence_id': residenceId,
      'montant': montant,
      'categorie_id': categorieId,
      'date': date.toIso8601String().split('T').first,
      'annee': date.year,
      'mois': date.month,
      'syndic_general_id': syndicId,
      'facture_path': facturePath,
      'description': description,
    }).select().single();

    final int parentId = parentRes['id'];

    // B. Récupérer les tranches
    final tranchesRes = await _db.from('tranches')
        .select('id')
        .eq('residence_id', residenceId);
    final tranches = List<Map<String, dynamic>>.from(tranchesRes);

    if (tranches.isEmpty) return;

    // C. Calculer la part par tranche
    double share = montant / tranches.length;

    // D. Diffuser aux tranches
    for (var t in tranches) {
      int tId = t['id'];
      
      // 1. Créer la dépense DIFFUSÉE (Enfant)
      // On utilise le même categorieId
      await _db.from('depenses').insert({
        'residence_id': residenceId,
        'tranche_id': tId,
        'montant': share,
        'categorie_id': categorieId,
        'date': date.toIso8601String().split('T').first,
        'annee': date.year,
        'mois': date.month,
        'description': "Part dépense globale (réf: #$parentId)",
        'facture_path': facturePath, // Optionnel: laisser le résident voir la facture ?
      });

      // 2. Mettre à jour le solde de la tranche (finances_summary)
      final summary = await _db.from('finances_summary')
          .select()
          .eq('tranche_id', tId)
          .maybeSingle();

      if (summary != null) {
        double currentDep = double.parse(summary['depenses_total'].toString());
        double currentSolde = double.parse(summary['solde'].toString());
        await _db.from('finances_summary').update({
          'depenses_total': currentDep + share,
          'solde': currentSolde - share,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', summary['id']);
      }
    }
  }

  // 6. Pour enregistrer une dépense Inter-Syndic (Spécifique)
  Future<void> addInterSyndicExpense({
    required int residenceId,
    required int interSyndicId,
    required double montant,
    required int categorieId,
    required DateTime date,
    required int trancheId, // Obligatoire maintenant
    String? facturePath,
    String? description,
  }) async {
    // 1. Insérer la dépense spécifique
    await _db.from('depenses').insert({
      'residence_id': residenceId,
      'inter_syndic_id': interSyndicId,
      'tranche_id': trancheId,
      'montant': montant,
      'categorie_id': categorieId,
      'date': date.toIso8601String().split('T').first,
      'annee': date.year,
      'mois': date.month,
      'facture_path': facturePath,
      'description': description,
    });

    // 2. Mettre à jour le solde de la tranche
    final summary = await _db.from('finances_summary')
        .select()
        .eq('tranche_id', trancheId)
        .maybeSingle();

    if (summary != null) {
      double currentDep = double.parse(summary['depenses_total'].toString());
      double currentSolde = double.parse(summary['solde'].toString());
      await _db.from('finances_summary').update({
        'depenses_total': currentDep + montant,
        'solde': currentSolde - montant,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', summary['id']);
    }
  }

  // 7. Pour le dashboard Inter-Syndic
  Future<Map<String, dynamic>> getInterSyndicFinances(int interSyndicId, int residenceId) async {
    // A. Récupérer les tranches de cet inter-syndic
    final tranches = await _db.from('tranches')
        .select('id, nom')
        .eq('inter_syndic_id', interSyndicId)
        .eq('residence_id', residenceId);
    final tranchesIds = (tranches as List).map((t) => t['id'] as int).toList();

    if (tranchesIds.isEmpty) {
      return {'total_depenses': 0, 'total_revenus': 0, 'solde': 0, 'depenses_par_tranche': []};
    }

    // B. Récupérer le sommaire financier cumulé pour ces tranches
    final summaries = await _db.from('finances_summary')
        .select()
        .inFilter('tranche_id', tranchesIds);

    double totalDep = 0;
    double totalRev = 0;
    double totalSolde = 0;

    for (var s in summaries) {
      totalDep += double.parse(s['depenses_total'].toString());
      totalRev += double.parse(s['revenus_total'].toString());
      totalSolde += double.parse(s['solde'].toString());
    }

    // C. Répartition des dépenses par tranche (pour le graphique)
    List<Map<String, dynamic>> depByTranche = [];
    for (var t in tranches) {
      final s = (summaries as List).firstWhere((s) => s['tranche_id'] == t['id'], orElse: () => null);
      depByTranche.add({
        'nom': t['nom'],
        'montant': s != null ? double.parse(s['depenses_total'].toString()) : 0,
      });
    }

    return {
      'total_depenses': totalDep,
      'total_revenus': totalRev,
      'solde': totalSolde,
      'depenses_par_tranche': depByTranche,
    };
  }

  // 8. Stats pour graphiques (Syndic Général)
  Future<List<Map<String, dynamic>>> getResidenceExpenseStats(int residenceId) async {
    final res = await _db.from('depenses')
        .select('montant, categories(nom)')
        .eq('residence_id', residenceId)
        .isFilter('tranche_id', null);
    
    Map<String, double> stats = {};
    for (var d in res) {
      String cat = (d['categories'] as Map)['nom'] ?? 'Autre';
      double val = double.parse(d['montant'].toString());
      stats[cat] = (stats[cat] ?? 0) + val;
    }

    if (stats.isEmpty) return []; // Éviter erreur si vide
    return stats.entries.map((e) => {'category': e.key, 'amount': e.value}).toList();
  }

  // 9. Récupérer toutes les dépenses (Spécifiques + Diffusées) pour un Inter-Syndic
  Future<List<Map<String, dynamic>>> getInterSyndicRecentExpenses(int interSyndicId) async {
    // 1. Trouver les tranches
    final tranchesRes = await _db.from('tranches').select('id').eq('inter_syndic_id', interSyndicId);
    final tranchesIds = (tranchesRes as List).map((t) => t['id'] as int).toList();
    
    if (tranchesIds.isEmpty) return [];

    // 2. Récupérer les dépenses liées à ces tranches
    final res = await _db.from('depenses').select('''
      id, montant, date, description, inter_syndic_id, tranche_id, categorie_id,
      categories(nom, type),
      tranches(nom)
    ''').inFilter('tranche_id', tranchesIds).order('date', ascending: false).limit(10);
    
    return List<Map<String, dynamic>>.from(res);
  }
  
  // 10. Update Inter-Syndic Expense
  Future<void> updateInterSyndicExpense({
    required int expenseId,
    required double oldMontant,
    required double newMontant,
    required int categorieId,
    required DateTime date,
    required int trancheId,
    String? facturePath,
    String? description,
  }) async {
    // 1. Update the expense record
    await _db.from('depenses').update({
      'montant': newMontant,
      'categorie_id': categorieId,
      'date': date.toIso8601String().split('T').first,
      'annee': date.year,
      'mois': date.month,
      'facture_path': facturePath,
      'description': description,
    }).eq('id', expenseId);

    // 2. Adjust the finances_summary
    final double diff = newMontant - oldMontant;
    if (diff != 0) {
      final summary = await _db.from('finances_summary')
          .select()
          .eq('tranche_id', trancheId)
          .maybeSingle();

      if (summary != null) {
        double currentDep = double.parse(summary['depenses_total'].toString());
        double currentSolde = double.parse(summary['solde'].toString());
        await _db.from('finances_summary').update({
          'depenses_total': currentDep + diff,
          'solde': currentSolde - diff,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', summary['id']);
      }
    }
  }

  // 11. Delete Inter-Syndic Expense
  Future<void> deleteInterSyndicExpense({
    required int expenseId,
    required double montant,
    required int trancheId,
  }) async {
    // 1. Delete the expense record
    await _db.from('depenses').delete().eq('id', expenseId);

    // 2. Adjust the finances_summary
    final summary = await _db.from('finances_summary')
        .select()
        .eq('tranche_id', trancheId)
        .maybeSingle();

    if (summary != null) {
      double currentDep = double.parse(summary['depenses_total'].toString());
      double currentSolde = double.parse(summary['solde'].toString());
      await _db.from('finances_summary').update({
        'depenses_total': currentDep - montant,
        'solde': currentSolde + montant,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', summary['id']);
    }
  }

  // --- Category CRUD ---

  Future<void> addCategory({required String nom, required String type, String? description}) async {
    await _db.from('categories').insert({
      'nom': nom,
      'type': type,
      'description': description,
    });
  }

  Future<void> updateCategory({required int id, required String nom, String? description}) async {
    await _db.from('categories').update({
      'nom': nom,
      'description': description,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> deleteCategory(int id) async {
    await _db.from('categories').delete().eq('id', id);
  }
}