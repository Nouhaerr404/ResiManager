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

  // Libérer un garages
  Future<void> libererGarage(int garageId) async {
    await _db.from('garages').update({
      'beneficiaire_id': null,
      'statut': 'disponible',
    }).eq('id', garageId);
  }
}