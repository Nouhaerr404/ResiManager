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

  // 2. Pour récupérer les catégories
  Future<List<Map<String, dynamic>>> getCategories(String type) async {
    final res = await _db.from('categories').select('id, nom').eq('type', type);
    return List<Map<String, dynamic>>.from(res);
  }

  // 3. Pour récupérer TOUTES les catégories
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final response = await _db.from('categories').select('id, nom, type');
    return List<Map<String, dynamic>>.from(response);
  }

  // 5. Pour enregistrer la dépense (Syndic Général)
  Future<void> addGlobalExpense({
    required int residenceId,
    required double montant,
    required int categorieId,
    required int annee,
    required int syndicId,
    String? facturePath,
    String? description,
  }) async {
    await _db.from('depenses').insert({
      'residence_id': residenceId,
      'montant': montant,
      'categorie_id': categorieId,
      'annee': annee,
      'date': DateTime.now().toIso8601String().split('T').first,
      'mois': DateTime.now().month,
      'syndic_general_id': syndicId,
      'facture_path': facturePath,
      'description': description,
    });
  }

  // 6. Pour enregistrer une dépense Inter-Syndic (RESTAURÉ)
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

  // 7. Pour le dashboard Inter-Syndic (RESTAURÉ)
  Future<Map<String, dynamic>> getInterSyndicFinances(int interSyndicId, int residenceId, {int? annee}) async {
    final tranches = await _db.from('tranches')
        .select('id, nom')
        .eq('inter_syndic_id', interSyndicId)
        .eq('residence_id', residenceId);
    final tranchesIds = (tranches as List).map((t) => t['id'] as int).toList();

    if (tranchesIds.isEmpty) {
      return {'total_depenses': 0, 'total_revenus': 0, 'objectif_annuel': 0, 'solde': 0, 'recent_expenses': [], 'depenses_par_tranche': []};
    }

    var depQuery = _db.from('depenses')
        .select('montant, tranche_id')
        .eq('inter_syndic_id', interSyndicId);
    if (annee != null) depQuery = depQuery.eq('annee', annee);

    final depensesInter = await depQuery;

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

    var payQuery = _db.from('paiements')
        .select('montant_paye')
        .eq('inter_syndic_id', interSyndicId);
    if (annee != null) payQuery = payQuery.eq('annee', annee);

    final paiementsRes = await payQuery;

    double totalRevenus = 0;
    for (var p in paiementsRes) {
      totalRevenus += double.parse(p['montant_paye'].toString());
    }

    var objQuery = _db.from('paiements')
        .select('montant_total')
        .eq('inter_syndic_id', interSyndicId);
    if (annee != null) objQuery = objQuery.eq('annee', annee);

    final targetRes = await objQuery;

    double totalObjectif = 0;
    for (var p in targetRes) {
      totalObjectif += double.parse(p['montant_total'].toString());
    }

    var detailedQuery = _db.from('depenses')
        .select('''
          id, montant, date, mois, annee, description, facture_path, inter_syndic_id, tranche_id, categorie_id,
          categories!inner(nom, type),
          tranches(nom)
        ''')
        .or('inter_syndic_id.eq.$interSyndicId,syndic_general_id.not.is.null')
        .eq('residence_id', residenceId);

    if (annee != null) detailedQuery = detailedQuery.eq('annee', annee);

    final depensesRes = await detailedQuery.order('date', ascending: false);

    final recentExpenses = (depensesRes as List).map((d) => {
      'id': d['id'],
      'montant': double.parse(d['montant'].toString()),
      'date': d['date'],
      'description': d['description'] ?? '',
      'categorie_nom': d['categories']?['nom'] ?? 'Inconnue',
      'type': d['inter_syndic_id'] != null ? 'Spécifique' : 'Globale',
      'facture_path': d['facture_path'],
      'tranche': d['tranches']?['nom'] ?? 'Général',
      'categorie_id': d['categorie_id'],
      'tranche_id': d['tranche_id'],
    }).toList();

    return {
      'total_depenses': totalDepenses,
      'total_revenus': totalRevenus,
      'objectif_annuel': totalObjectif,
      'solde': totalRevenus - totalDepenses,
      'recent_expenses': recentExpenses,
      'depenses_par_tranche': tranches.map((t) => {
        'nom': t['nom'],
        'montant': depByTranche[t['id']] ?? 0,
      }).toList(),
    };
  }

  // 7b. Modifier une dépense Inter-Syndic (RESTAURÉ)
  Future<void> updateInterSyndicExpense({
    required int expenseId,
    required double oldMontant,
    required double newMontant,
    required int categorieId,
    required DateTime date,
    String? description,
    String? facturePath,
  }) async {
    final updateData = {
      'montant': newMontant,
      'categorie_id': categorieId,
      'description': description,
      'date': date.toIso8601String().split('T').first,
      'annee': date.year,
      'mois': date.month,
    };
    if (facturePath != null) updateData['facture_path'] = facturePath;

    await _db.from('depenses').update(updateData).eq('id', expenseId);

    final depense = await _db.from('depenses').select('tranche_id, residence_id, inter_syndic_id').eq('id', expenseId).single();
    int? tId = depense['tranche_id'];
    int resId = depense['residence_id'];
    int isId = depense['inter_syndic_id'];

    List<int> tranchesIds = [];
    if (tId != null) {
      tranchesIds = [tId];
    } else {
      final resTranches = await _db.from('tranches').select('id').eq('inter_syndic_id', isId).eq('residence_id', resId);
      tranchesIds = (resTranches as List).map((t) => t['id'] as int).toList();
    }

    if (tranchesIds.isEmpty) return;

    final immeublesRes = await _db.from('immeubles').select('id').inFilter('tranche_id', tranchesIds);
    final listImmIds = (immeublesRes as List).map((i) => i['id'] as int).toList();
    if (listImmIds.isEmpty) return;

    final appartRes = await _db.from('appartements').select('id').inFilter('immeuble_id', listImmIds);
    final listAppartIds = (appartRes as List).map((a) => a['id'] as int).toList();
    if (listAppartIds.isEmpty) return;

    double diffShare = (newMontant - oldMontant) / listAppartIds.length;

    for (int appartId in listAppartIds) {
      final pRes = await _db.from('paiements')
          .select('id, montant_total, montant_paye')
          .eq('appartement_id', appartId)
          .eq('annee', date.year)
          .eq('mois', date.month)
          .maybeSingle();

      if (pRes != null) {
        double currentTotal = double.parse(pRes['montant_total'].toString());
        double paid = double.parse(pRes['montant_paye'].toString());
        double updatedTotal = currentTotal + diffShare;

        await _db.from('paiements').update({
          'montant_total': updatedTotal,
          'statut': (paid >= updatedTotal) ? 'complet' : (paid > 0 ? 'partiel' : 'impaye'),
        }).eq('id', pRes['id']);
      }
    }
  }

  // 7c. Supprimer une dépense Inter-Syndic (RESTAURÉ)
  Future<void> deleteInterSyndicExpense(int expenseId, double montant) async {
    final depense = await _db.from('depenses').select('*').eq('id', expenseId).single();
    int? tId = depense['tranche_id'];
    int resId = depense['residence_id'];
    int isId = depense['inter_syndic_id'];
    int annee = depense['annee'];
    int mois = depense['mois'];

    List<int> tranchesIds = [];
    if (tId != null) {
      tranchesIds = [tId];
    } else {
      final resTranches = await _db.from('tranches').select('id').eq('inter_syndic_id', isId).eq('residence_id', resId);
      tranchesIds = (resTranches as List).map((t) => t['id'] as int).toList();
    }

    if (tranchesIds.isNotEmpty) {
      final immeublesRes = await _db.from('immeubles').select('id').inFilter('tranche_id', tranchesIds);
      final listImmIds = (immeublesRes as List).map((i) => i['id'] as int).toList();

      if (listImmIds.isNotEmpty) {
        final appartRes = await _db.from('appartements').select('id').inFilter('immeuble_id', listImmIds);
        final listAppartIds = (appartRes as List).map((a) => a['id'] as int).toList();

        if (listAppartIds.isNotEmpty) {
          double shareToDelete = montant / listAppartIds.length;

          for (int appartId in listAppartIds) {
            final pRes = await _db.from('paiements')
                .select('id, montant_total, montant_paye')
                .eq('appartement_id', appartId)
                .eq('annee', annee)
                .eq('mois', mois)
                .maybeSingle();

            if (pRes != null) {
              double currentTotal = double.parse(pRes['montant_total'].toString());
              double paid = double.parse(pRes['montant_paye'].toString());
              double updatedTotal = (currentTotal - shareToDelete).clamp(0, double.infinity);

              await _db.from('paiements').update({
                'montant_total': updatedTotal,
                'statut': (updatedTotal <= 0) ? 'complet' : (paid >= updatedTotal ? 'complet' : (paid > 0 ? 'partiel' : 'impaye')),
              }).eq('id', pRes['id']);
            }
          }
        }
      }
    }

    await _db.from('depenses').delete().eq('id', expenseId);
  }

  // 7d. Catégories (RESTAURÉ)
  Future<void> addExpenseCategory(String nom) async {
    await _db.from('categories').insert({'nom': nom, 'type': 'individuelle'});
  }

  Future<void> deleteExpenseCategory(int categoryId) async {
    await _db.from('categories').delete().eq('id', categoryId);
  }

  // 8. Résumé financier
  Future<Map<String, double>> getFinanceSummary(int residenceId, int annee) async {
    try {
      final depensesRes = await _db.from('depenses').select('montant').eq('residence_id', residenceId).eq('annee', annee);
      double totalDepenses = 0;
      for (var row in depensesRes) { totalDepenses += (row['montant'] as num).toDouble(); }
      final paiementsRes = await _db.from('paiements').select('montant_total, montant_paye').eq('residence_id', residenceId).eq('annee', annee);
      double totalAttendu = 0; double totalRecolte = 0;
      for (var row in paiementsRes) {
        totalAttendu += (row['montant_total'] as num).toDouble();
        totalRecolte += (row['montant_paye'] as num).toDouble();
      }
      return {'total': totalDepenses, 'paye': totalRecolte, 'attente': totalAttendu - totalRecolte};
    } catch (e) { return {'total': 0, 'paye': 0, 'attente': 0}; }
  }

  // Dépenses Syndic Général
  Future<List<Map<String, dynamic>>> getMyExpenses({
    required int residenceId,
    required int mySyndicId, // On passe l'ID récupéré à la connexion
    int? annee,
    int? mois,
    int? categorieId,
  }) async {
    try {
      var query = _db.from('depenses').select('''
        id, montant, date, annee, mois, description, facture_path, categorie_id,
        categories!inner(id, nom, type)
      ''')
          .eq('residence_id', residenceId)
          .eq('syndic_general_id', mySyndicId); // Filtre dynamique

      if (annee != null) query = query.eq('annee', annee);
      if (mois != null) query = query.eq('mois', mois);
      if (categorieId != null) query = query.eq('categorie_id', categorieId);

      final response = await query.order('date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Erreur SQL getMyExpenses: $e");
      return [];
    }
  }

  Future<void> deleteExpense(int id) async {
    await _db.from('depenses').delete().eq('id', id);
  }

  Future<void> updateGlobalExpense({
    required int expenseId,
    required double montant,
    required int categorieId,
    required int annee,
    String? description,
    String? facturePath,
  }) async {
    final Map<String, dynamic> data = {
      'montant': montant, 'categorie_id': categorieId, 'annee': annee, 'description': description,
    };
    if (facturePath != null) data['facture_path'] = facturePath;
    await _db.from('depenses').update(data).eq('id', expenseId);
  }

  // Upload simplifié
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
      return fileName; // Retourne le nom simple en cas d'erreur de bucket
    }
  }
  // Cette fonction trouve l'ID (integer) de l'utilisateur connecté via son email
  Future<int> getCurrentUserId() async {
    final userEmail = _db.auth.currentUser?.email;
    if (userEmail == null) throw Exception("Non connecté");

    final res = await _db
        .from('users')
        .select('id')
        .eq('email', userEmail)
        .single();

    return res['id'] as int;
  }
}