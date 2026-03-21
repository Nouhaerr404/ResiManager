import 'package:supabase_flutter/supabase_flutter.dart';

class ResidenceService {
  final _db = Supabase.instance.client;

  // Récupère toutes les résidences d'un Syndic Général
  Future<List<Map<String, dynamic>>> getResidences(int syndicGeneralId) async {
    // On demande à Supabase de ne donner QUE les lignes
    // où la colonne syndic_general_id correspond à TOI.
    final response = await _db
        .from('residences')
        .select()
        .eq('syndic_general_id', syndicGeneralId); // <--- LE FILTRE ESSENTIEL

    return List<Map<String, dynamic>>.from(response);
  }

  // Crée une nouvelle résidence
  Future<void> createResidence(String nom, String adresse, int syndicGeneralId) async {
    await _db.from('residences').insert({
      'nom': nom,
      'adresse': adresse,
      'syndic_general_id': syndicGeneralId,
      // Les compteurs sont à 0 par défaut
    });
  }
}