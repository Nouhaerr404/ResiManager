import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/parking_model.dart';

class ParkingService {
  final _db = Supabase.instance.client;

  Future<List<ParkingModel>> getParkingsByTranche(int trancheId) async {
    final response = await _db
        .from('parkings')
        .select('''
          *,
          tranches(nom),
          beneficiaires(nom, prenom, resident_id)
        ''')
        .eq('tranche_id', trancheId)
        .order('numero');

    return (response as List)
        .map((e) => ParkingModel.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> getParkingStats(int trancheId) async {
    final parkings = await getParkingsByTranche(trancheId);
    final total = parkings.length;
    final disponibles = parkings.where((p) => p.statut.name == 'disponible').length;
    final revenuMensuel = parkings
        .where((p) => p.statut.name == 'occupe')
        .fold(0.0, (sum, p) => sum + p.prixAnnuel / 12);

    return {
      'total': total,
      'disponibles': disponibles,
      'occupes': total - disponibles,
      'revenuMensuel': revenuMensuel,
    };
  }

  Future<String?> addParking({
    required String numero,
    required int trancheId,
    required int residenceId,
    required double prixAnnuel,
  }) async {
    try {
      await _db.from('parkings').insert({
        'numero': numero,
        'tranche_id': trancheId,
        'residence_id': residenceId,
        'prix_annuel': prixAnnuel,
        'statut': 'disponible',
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> addParkingWithAssignment({
    required String numero,
    required int trancheId,
    required int residenceId,
    required double prixAnnuel,
    required String nom,
    required String prenom,
    String? telephone,
    int? residentId,
  }) async {
    try {
      final benef = await _db.from('beneficiaires').insert({
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'tranche_id': trancheId,
        if (residentId != null) 'resident_id': residentId,
      }).select('id').single();

      await _db.from('parkings').insert({
        'numero': numero,
        'tranche_id': trancheId,
        'residence_id': residenceId,
        'prix_annuel': prixAnnuel,
        'statut': 'occupe',
        'beneficiaire_id': benef['id'],
      });

      // CRÉATION DU PAIEMENT si c'est un résident
      if (residentId != null) {
        await _createPayment(
          residentId: residentId,
          trancheId: trancheId,
          residenceId: residenceId,
          montant: prixAnnuel,
          type: 'parking',
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
  }) async {
    final resData = await _db.from('residents').select('appartement_id').eq('user_id', residentId).maybeSingle();
    final int? appartId = resData?['appartement_id'];
    if (appartId == null) return;

    final trancheData = await _db.from('tranches').select('inter_syndic_id').eq('id', trancheId).maybeSingle();
    final int isId = trancheData?['inter_syndic_id'] ?? 1;

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
    });
  }

  Future<String?> assignerParking({
    required int parkingId,
    required String nom,
    required String prenom,
    String? telephone,
    required String type,
    required int trancheId,
    int? residentId, // AJOUTÉ
  }) async {
    try {
      // Récupérer les infos du parking pour le prix et la résidence
      final pInfo = await _db.from('parkings').select('prix_annuel, residence_id').eq('id', parkingId).single();
      final double prix = double.parse(pInfo['prix_annuel'].toString());
      final int resId = pInfo['residence_id'];

      // Créer bénéficiaire
      final benef = await _db.from('beneficiaires').insert({
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'tranche_id': trancheId,
        if (residentId != null) 'resident_id': residentId,
      }).select('id').single();

      // Assigner parking
      await _db.from('parkings').update({
        'statut': 'occupe',
        'beneficiaire_id': benef['id'],
      }).eq('id', parkingId);

      // CRÉATION DU PAIEMENT si c'est un résident
      if (residentId != null) {
        await _createPayment(
          residentId: residentId,
          trancheId: trancheId,
          residenceId: resId,
          montant: prix,
          type: 'parking',
        );
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> libererParking(int parkingId) async {
    try {
      await _db.from('parkings').update({
        'statut': 'disponible',
        'beneficiaire_id': null,
      }).eq('id', parkingId);
    } catch (e) {
      print('>>> ERREUR libererParking: $e');
    }
  }

  Future<String?> updateParking({
    required int parkingId,
    required String numero,
    required double prixAnnuel,
  }) async {
    try {
      await _db.from('parkings').update({
        'numero': numero,
        'prix_annuel': prixAnnuel,
      }).eq('id', parkingId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteParking(int parkingId) async {
    try {
      await _db.from('parkings').delete().eq('id', parkingId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

