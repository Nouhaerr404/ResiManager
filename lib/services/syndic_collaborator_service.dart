import 'package:supabase_flutter/supabase_flutter.dart';

class SyndicCollaboratorService {
  final _db = Supabase.instance.client;

  // 1. LIRE + RECHERCHER
  Future<List<Map<String, dynamic>>> getInterSyndics({String? query}) async {
    var request = _db.from('users').select('*, tranches(nom)').eq('role', 'inter_syndic');

    if (query != null && query.isNotEmpty) {
      request = request.or('nom.ilike.%$query%,prenom.ilike.%$query%,email.ilike.%$query%');
    }

    final response = await request.order('nom');
    return List<Map<String, dynamic>>.from(response);
  }

  // 2. CRÉER
  Future<void> createAndInviteSyndic({
    required String email,
    required String nom,
    required String prenom,
    required String telephone,
  }) async {
    // 1. On "inscrit" le syndic (Autorisé sur Edge avec la clé anon)
    await _db.auth.signUp(
      email: email,
      password: "TEMP_PASSWORD_123!", // Mot de passe temporaire
    );

    // 2. On enregistre ses infos dans ta table SQL
    await _db.from('users').insert({
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'role': 'inter_syndic',
      'statut': 'actif',
      'password': 'A_REDEFINIR',
    });
  }

  // 3. MODIFIER
  Future<void> updateInterSyndic(int id, String nom, String prenom, String phone) async {
    await _db.from('users').update({
      'nom': nom, 'prenom': prenom, 'telephone': phone,
    }).eq('id', id);
  }

  // 4. SUSPENDRE / ACTIVER
  Future<void> toggleStatus(int id, String currentStatus) async {
    String newStatus = (currentStatus == 'actif') ? 'inactif' : 'actif';
    await _db.from('users').update({'statut': newStatus}).eq('id', id);
  }
}