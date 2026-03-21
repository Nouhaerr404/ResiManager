import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/garage_model.dart';

class GarageService {
  final _db = Supabase.instance.client;

  Future<List<GarageModel>> getGaragesByTranche(int trancheId) async {
    final response = await _db
        .from('garages')
        .select('''
          *,
          tranches(nom),
          beneficiaires(nom, prenom, resident_id)
        ''')
        .eq('tranche_id', trancheId)
        .order('numero');

    return (response as List)
        .map((e) => GarageModel.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> getGarageStats(int trancheId) async {
    final garages = await getGaragesByTranche(trancheId);
    final total = garages.length;
    final disponibles = garages.where((g) => g.statut == 'disponible').length;
    final revenuMensuel = garages
        .where((g) => g.statut == 'occupe')
        .fold(0.0, (sum, g) => sum + g.prixAnnuel / 12);

    return {
      'total': total,
      'disponibles': disponibles,
      'occupes': total - disponibles,
      'revenuMensuel': revenuMensuel,
    };
  }

  // Assigner un bénéficiaire à un garages
  Future<void> assignerBeneficiaire(int garageId, int beneficiaireId) async {
    await _db.from('garages').update({
      'beneficiaire_id': beneficiaireId,
      'statut': 'occupe',
    }).eq('id', garageId);
  }



  Future<String?> addGarage({
    required String numero,
    required int trancheId,
    required int residenceId,
    required double prixAnnuel,
  }) async {
    try {
      await _db.from('garages').insert({
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

  Future<String?> updateGarage({
    required int garageId,
    required String numero,
    required double prixAnnuel,
  }) async {
    try {
      await _db.from('garages').update({
        'numero': numero,
        'prix_annuel': prixAnnuel,
      }).eq('id', garageId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> addGarageWithAssignment({
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

      await _db.from('garages').insert({
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
          type: 'garage',
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
    try {
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
    } catch (e) {
      print('>>> ERREUR _createPayment Garage: $e');
    }
  }

  Future<String?> assignerGarage({
    required int garageId,
    required String nom,
    required String prenom,
    String? telephone,
    required String type,
    required int trancheId,
    int? residentId, // AJOUTÉ
  }) async {
    try {
      // Récupérer les infos du garage pour le prix et la résidence
      final gInfo = await _db.from('garages').select('prix_annuel, residence_id').eq('id', garageId).single();
      final double prix = double.parse(gInfo['prix_annuel'].toString());
      final int resId = gInfo['residence_id'];

      // Créer bénéficiaire
      final benef = await _db.from('beneficiaires').insert({
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'tranche_id': trancheId,
        if (residentId != null) 'resident_id': residentId,
      }).select('id').single();

      // Assigner garage
      await _db.from('garages').update({
        'statut': 'occupe',
        'beneficiaire_id': benef['id'],
      }).eq('id', garageId);

      // CRÉATION DU PAIEMENT si c'est un résident
      if (residentId != null) {
        await _createPayment(
          residentId: residentId,
          trancheId: trancheId,
          residenceId: resId,
          montant: prix,
          type: 'garage',
        );
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> libererGarage(int garageId) async {
    try {
      await _db.from('garages').update({
        'statut': 'disponible',
        'beneficiaire_id': null,
      }).eq('id', garageId);
    } catch (e) {
      print('>>> ERREUR libererGarage: $e');
    }
  }
}