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

  // 5. Pour enregistrer la dépense
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
      'date': date.toIso8601String(),
      'annee': date.year,
      'mois': date.month,
      'syndic_general_id': syndicId,
      'facture_path': facturePath,
      'description': description,
    });
  }
}