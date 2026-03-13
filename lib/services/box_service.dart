import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/box_model.dart';

class BoxService {
  final _db = Supabase.instance.client;

  Future<List<BoxModel>> getBoxesByTranche(int trancheId) async {
    final response = await _db
        .from('boxes')
        .select('''
          *,
          tranches(nom),
          immeubles(nom),
          beneficiaires(nom, prenom, resident_id)
        ''')
        .eq('tranche_id', trancheId)
        .order('numero');

    return (response as List)
        .map((e) => BoxModel.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> getBoxStats(int trancheId) async {
    final boxes = await getBoxesByTranche(trancheId);
    final total = boxes.length;
    final disponibles = boxes.where((p) => p.statut == StatutEspaceEnum.disponible).length;
    final revenuMensuel = boxes
        .where((p) => p.statut == StatutEspaceEnum.occupe)
        .fold(0.0, (sum, p) => sum + p.prixAnnuel / 12);

    return {
      'total': total,
      'disponibles': disponibles,
      'occupes': total - disponibles,
      'revenuMensuel': revenuMensuel,
    };
  }

  Future<String?> addBox({
    required String numero,
    required int trancheId,
    required int residenceId,
    required double prixAnnuel,
    int? immeubleId,
  }) async {
    try {
      await _db.from('boxes').insert({
        'numero': numero,
        'tranche_id': trancheId,
        'residence_id': residenceId,
        'prix_annuel': prixAnnuel,
        'statut': 'disponible',
        if (immeubleId != null) 'immeuble_id': immeubleId,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> addBoxWithAssignment({
    required String numero,
    required int trancheId,
    required int residenceId,
    required double prixAnnuel,
    required String nom,
    required String prenom,
    String? telephone,
    int? residentId,
    int? immeubleId,
  }) async {
    try {
      final benef = await _db.from('beneficiaires').insert({
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'tranche_id': trancheId,
        if (residentId != null) 'resident_id': residentId,
      }).select('id').single();

      await _db.from('boxes').insert({
        'numero': numero,
        'tranche_id': trancheId,
        'residence_id': residenceId,
        'prix_annuel': prixAnnuel,
        'statut': 'occupe',
        'beneficiaire_id': benef['id'],
        if (immeubleId != null) 'immeuble_id': immeubleId,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateBox({
    required int boxId,
    required String numero,
    required double prixAnnuel,
    int? immeubleId,
  }) async {
    try {
      await _db.from('boxes').update({
        'numero': numero,
        'prix_annuel': prixAnnuel,
        'immeuble_id': immeubleId,
      }).eq('id', boxId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteBox(int boxId) async {
    try {
      await _db.from('boxes').delete().eq('id', boxId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> assignerBox({
    required int boxId,
    required String nom,
    required String prenom,
    String? telephone,
    required int trancheId,
  }) async {
    try {
      // Créer bénéficiaire
      final benef = await _db.from('beneficiaires').insert({
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'tranche_id': trancheId,
      }).select('id').single();

      // Assigner box
      await _db.from('boxes').update({
        'statut': 'occupe',
        'beneficiaire_id': benef['id'],
      }).eq('id', boxId);

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> libererBox(int boxId) async {
    try {
      await _db.from('boxes').update({
        'statut': 'disponible',
        'beneficiaire_id': null,
      }).eq('id', boxId);
    } catch (e) {
      print('>>> ERREUR libererBox: $e');
    }
  }
}
