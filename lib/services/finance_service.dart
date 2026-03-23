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

  // 7. Pour le dashboard Inter-Syndic (MIS À JOUR AVEC QUOTE-PART)
  Future<Map<String, dynamic>> getInterSyndicFinances(int interSyndicId, int residenceId, {int? annee}) async {
    // 1. Récupérer les tranches gérées par cet inter-syndic
    final tranchesManaged = await _db.from('tranches')
        .select('id, nom')
        .eq('inter_syndic_id', interSyndicId)
        .eq('residence_id', residenceId);
    final tranchesManagedIds = (tranchesManaged as List).map((t) => t['id'] as int).toList();
    final int nbrTranchesManaged = tranchesManagedIds.length;

    // 2. Récupérer le nombre TOTAL de tranches de la résidence (pour le partage)
    final allTranchesRes = await _db.from('tranches')
        .select('id')
        .eq('residence_id', residenceId);
    final int totalTranchesInResidence = (allTranchesRes as List).isEmpty ? 1 : allTranchesRes.length;

    if (nbrTranchesManaged == 0) {
      return {'total_depenses': 0, 'total_revenus': 0, 'objectif_annuel': 0, 'solde': 0, 'recent_expenses': [], 'depenses_par_tranche': []};
    }

    var depQuery = _db.from('depenses')
        .select('montant, tranche_id, syndic_general_id, inter_syndic_id')
        .eq('residence_id', residenceId);
    if (annee != null) depQuery = depQuery.eq('annee', annee);

    final allDepenses = await depQuery;

    double totalDepensesSpecifiques = 0;
    double totalDepensesGlobalesQuotePart = 0;
    Map<int, double> depByTranche = {};

    for (var d in allDepenses) {
      double val = double.parse(d['montant'].toString());
      
      // Si c'est une dépense de l'inter-syndic actuel
      if (d['inter_syndic_id'] == interSyndicId) {
        totalDepensesSpecifiques += val;
        if (d['tranche_id'] != null) {
          int tId = d['tranche_id'];
          depByTranche[tId] = (depByTranche[tId] ?? 0) + val;
        }
      } 
      // Si c'est une dépense globale du syndic général -> Calculer la quote-part
      else if (d['syndic_general_id'] != null) {
        double quotePart = (val / totalTranchesInResidence) * nbrTranchesManaged;
        totalDepensesGlobalesQuotePart += quotePart;
      }
    }

    var payQuery = _db.from('paiements')
        .select('montant_paye, montant_total')
        .eq('inter_syndic_id', interSyndicId)
        .eq('residence_id', residenceId);
    if (annee != null) payQuery = payQuery.eq('annee', annee);

    final paiementsRes = await payQuery;

    double totalRevenus = 0;
    double totalObjectif = 0;
    for (var p in paiementsRes) {
      totalRevenus += double.parse(p['montant_paye'].toString());
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

    final recentExpenses = (depensesRes as List).map((d) {
      double rawAmount = double.parse(d['montant'].toString());
      bool isGlobal = d['inter_syndic_id'] == null;
      
      // Si c'est global, on affiche la quote-part dans le tableau
      double displayAmount = isGlobal 
          ? (rawAmount / totalTranchesInResidence) * nbrTranchesManaged
          : rawAmount;

      return {
        'id': d['id'],
        'montant': displayAmount,
        'montant_original': rawAmount, // Garder l'original au cas où
        'date': d['date'],
        'description': isGlobal ? "[Quote-part] ${d['description'] ?? ''}" : (d['description'] ?? ''),
        'categorie_nom': d['categories']?['nom'] ?? 'Inconnue',
        'type': !isGlobal ? 'Spécifique' : 'Globale',
        'facture_path': d['facture_path'],
        'tranche': d['tranches']?['nom'] ?? 'Général',
        'categorie_id': d['categorie_id'],
        'tranche_id': d['tranche_id'],
      };
    }).toList();

    return {
      'total_depenses': totalDepensesSpecifiques,
      'total_depenses_globales': totalDepensesGlobalesQuotePart,
      'total_revenus': totalRevenus,
      'objectif_annuel': totalObjectif,
      'solde': totalRevenus - (totalDepensesSpecifiques + totalDepensesGlobalesQuotePart),
      'recent_expenses': recentExpenses,
      'depenses_par_tranche': tranchesManaged.map((t) => {
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

  // 7c. Supprimer une dépense Inter-Syndic (RESTAURÉ & ROBUSTIFIÉ)
  Future<void> deleteInterSyndicExpense(int expenseId, double montant) async {
    try {
      final depense = await _db.from('depenses').select('*').eq('id', expenseId).single();
      int? tId = depense['tranche_id'];
      int resId = depense['residence_id'];
      int isId = depense['inter_syndic_id'];
      int annee = depense['annee'];
      int mois = depense['mois'];

      // Wrap charge adjustment in try-catch to avoid blocking the deletion
      try {
        List<int> tranchesIds = [];
        if (tId != null) {
          tranchesIds = [tId];
        } else {
          final resTranches = await _db.from('tranches')
              .select('id')
              .eq('inter_syndic_id', isId)
              .eq('residence_id', resId);
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
      } catch (e) {
        print('>>> ERROR adjusting payments during expense deletion: $e');
        // We continue to delete the expense anyway
      }
    } catch (e) {
       print('>>> ERROR fetching expense for deletion: $e');
       // This might happen if expense already deleted, we still try to delete by id below
    }

    // ALWAYS try to delete the expense record at the end
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

  // MODIFICATION DE LA MÉTHODE DE MISE À JOUR
  Future<void> updateGlobalExpense({
    required int expenseId,
    required double montant,
    required int categorieId,
    required int annee,
    String? description,
    String? facturePath, // <--- BIEN VÉRIFIER QUE C'EST LÀ
  }) async {
    final Map<String, dynamic> data = {
      'montant': montant,
      'categorie_id': categorieId,
      'annee': annee,
      'description': description,
    };

    // On n'ajoute la facture que si une nouvelle a été choisie
    if (facturePath != null && facturePath.isNotEmpty) {
      data['facture_path'] = facturePath;
    }

    await _db.from('depenses').update(data).eq('id', expenseId);
  }

  // Upload simplifié
  Future<String?> uploadInvoice(String fileName, dynamic fileBytesOrPath) async {
    try {
      // 1. NETTOYAGE DU NOM (Supprime espaces, accents, parenthèses, apostrophes)
      // On ne garde que les lettres, les chiffres et le point de l'extension
      String sanitizedName = fileName
          .replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_') // Remplace tout le "bizarre" par _
          .replaceAll('__', '_'); // Évite les doubles __

      final String uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
      final String path = 'factures/$uniqueName';

      print(">>> TENTATIVE UPLOAD AVEC NOM NETTOYÉ : $path");

      if (kIsWeb) {
        await _db.storage.from('resimanager_bucket').uploadBinary(
          path,
          fileBytesOrPath,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
      } else {
        // SUR WINDOWS
        final file = File(fileBytesOrPath);
        await _db.storage.from('resimanager_bucket').upload(
          path,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
      }

      final String publicUrl = _db.storage.from('resimanager_bucket').getPublicUrl(path);
      print(">>> SUCCÈS ! URL : $publicUrl");
      return publicUrl;

    } catch (e) {
      print(">>> ERREUR SUPABASE STORAGE : $e");
      return null;
    }
  }
}