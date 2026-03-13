import 'package:supabase_flutter/supabase_flutter.dart';

class ResidenceService {
  final _db = Supabase.instance.client;

  // Récupère toutes les résidences d'un Syndic Général
  Future<List<Map<String, dynamic>>> getResidences(int syndicGeneralId) async {
    final response = await _db
        .from('residences')
        .select()
        .eq('syndic_general_id', syndicGeneralId);
    return List<Map<String, dynamic>>.from(response);
  }

  // Crée une nouvelle résidence
  Future<void> createResidence(String nom, String adresse, int syndicGeneralId) async {
    await _db.from('residences').insert({
      'nom': nom,
      'adresse': adresse,
      'syndic_general_id': syndicGeneralId,
    });
  }

  // Met à jour une résidence

  Future<void> updateResidence(int id, String nom, String adresse) async {
    await _db.from('residences').update({
      'nom': nom,
      'adresse': adresse,
    }).eq('id', id);
  }

  // Supprime une résidence
  Future<void> deleteResidence(int id) async {
    await _db.from('residences').delete().eq('id', id);
  }
}