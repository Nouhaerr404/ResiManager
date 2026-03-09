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

  Future<String?> assignerGarage({
    required int garageId,
    required String nom,
    required String prenom,
    String? telephone,
    required String type,
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

      // Assigner garage
      await _db.from('garages').update({
        'statut': 'occupe',
        'beneficiaire_id': benef['id'],
      }).eq('id', garageId);

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