import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/box_model.dart';

class BoxService {
  final _db = Supabase.instance.client;

  /// Récupère le mandat actif (le plus récent non terminé, sinon le plus récent) pour une tranche.
  Future<int?> _getActiveMandatId(int trancheId) async {
    try {
      final enCours = await _db
          .from('historique_affectations')
          .select('id')
          .eq('tranche_id', trancheId)
          .isFilter('date_fin', null)
          .order('date_debut', ascending: false)
          .limit(1)
          .maybeSingle();
      if (enCours != null) return enCours['id'] as int?;
      final recent = await _db
          .from('historique_affectations')
          .select('id')
          .eq('tranche_id', trancheId)
          .order('date_debut', ascending: false)
          .limit(1)
          .maybeSingle();
      return recent?['id'] as int?;
    } catch (e) {
      print('>>> ERREUR _getActiveMandatId Box: $e');
      return null;
    }
  }

  Future<List<BoxModel>> getBoxesByTranche(int trancheId) async {
    final response = await _db
        .from('boxes')
        .select('''
          *,
          tranches(nom),
          immeubles(nom),
          beneficiaires(nom, prenom, telephone, resident_id)
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
    int? mandatId, // mandat explicite
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

      if (residentId != null) {
        await _createPayment(
          residentId: residentId,
          trancheId: trancheId,
          residenceId: residenceId,
          montant: prixAnnuel,
          type: 'box',
          mandatId: mandatId,
        );
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Helper pour la création du paiement
  Future<void> _createPayment({
    required int residentId,
    required int trancheId,
    required int residenceId,
    required double montant,
    required String type,
    int? mandatId,
  }) async {
    try {
      final resData = await _db.from('residents').select('appartement_id').eq('user_id', residentId).maybeSingle();
      final int? appartId = resData?['appartement_id'];
      if (appartId == null) return;

      final trancheData = await _db.from('tranches').select('inter_syndic_id').eq('id', trancheId).maybeSingle();
      final int isId = trancheData?['inter_syndic_id'] ?? 1;

      final int? resolvedMandatId = mandatId ?? await _getActiveMandatId(trancheId);

      var dupQuery = _db.from('paiements')
          .select('id')
          .eq('appartement_id', appartId)
          .eq('type_paiement', type);
      if (resolvedMandatId != null) {
        dupQuery = dupQuery.eq('mandat_id', resolvedMandatId);
      }
      final existing = await dupQuery.maybeSingle();
      if (existing != null) return;

      await _db.from('paiements').insert({
        'resident_id': residentId,
        'appartement_id': appartId,
        'residence_id': residenceId,
        'inter_syndic_id': isId,
        'montant_total': montant,
        'montant_paye': 0,
        'type_paiement': type,
        'statut': 'impaye',
        'annee': DateTime.now().year,
        'mois': DateTime.now().month,
        if (resolvedMandatId != null) 'mandat_id': resolvedMandatId,
      });
    } catch (e) {
      print('>>> ERREUR _createPayment Box: $e');
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
    int? residentId,
    int? mandatId, // mandat explicite
  }) async {
    try {
      final bInfo = await _db.from('boxes').select('prix_annuel, residence_id').eq('id', boxId).single();
      final double prix = double.parse(bInfo['prix_annuel'].toString());
      final int resId = bInfo['residence_id'];

      final benef = await _db.from('beneficiaires').insert({
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'tranche_id': trancheId,
        if (residentId != null) 'resident_id': residentId,
      }).select('id').single();

      await _db.from('boxes').update({
        'statut': 'occupe',
        'beneficiaire_id': benef['id'],
      }).eq('id', boxId);

      if (residentId != null) {
        await _createPayment(
          residentId: residentId,
          trancheId: trancheId,
          residenceId: resId,
          montant: prix, // ← vrai prix du box
          type: 'box',
          mandatId: mandatId,
        );
      }

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

  Future<String?> updateAllBoxesPrice(int trancheId, double nouvellePrix) async {
    try {
      await _db
          .from('boxes')
          .update({'prix_annuel': nouvellePrix})
          .eq('tranche_id', trancheId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}