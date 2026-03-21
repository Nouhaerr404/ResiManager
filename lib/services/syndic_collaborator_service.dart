import 'package:supabase_flutter/supabase_flutter.dart';

class SyndicCollaboratorService {
  final _db = Supabase.instance.client;

  // --- 1. LECTURE (Celle qui manquait et qui répare l'affichage) ---
  Future<List<Map<String, dynamic>>> getMyInterSyndics(int myId) async {
    try {
      // On va chercher dans la table associative
      final response = await _db.from('liens_syndics').select('''
            inter_syndic:users!inter_syndic_id (
              *,
              tranches(nom, residence_id)
            )
          ''').eq('syndic_general_id', myId);

      final List data = response as List;
      // On "aplatit" la liste pour que le Screen reçoive directement les profils
      return data.map((item) => item['inter_syndic'] as Map<String, dynamic>).toList();
    } catch (e) {
      print("Erreur getMyInterSyndics: $e");
      return [];
    }
  }

  // --- 2. CRÉATION (Corrigée pour remplir les DEUX tables) ---
  Future<void> createAndInviteSyndic({
    required String email,
    required String nom,
    required String prenom,
    required String telephone,
    required int mySyndicGeneralId, // ID du créateur
  }) async {
    // A. Inscription Auth (pour la connexion)
    await _db.auth.signUp(email: email, password: "TEMP_PASSWORD_123!");

    // B. Création dans la table 'users' et récupération de l'ID généré
    final newUser = await _db.from('users').insert({
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'role': 'inter_syndic',
      'statut': 'actif',
      'password': 'A_REDEFINIR',
    }).select('id').single();

    final int newInterSyndicId = newUser['id'];

    // C. CRÉATION DU LIEN DANS LA TABLE ASSOCIATIVE
    await _db.from('liens_syndics').insert({
      'syndic_general_id': mySyndicGeneralId,
      'inter_syndic_id': newInterSyndicId,
    });
  }

  Future<void> updateInterSyndic(int id, String nom, String prenom, String phone) async {
    await _db.from('users').update({'nom': nom, 'prenom': prenom, 'telephone': phone}).eq('id', id);
  }

  Future<void> toggleStatus(int id, String currentStatus) async {
    String newStatus = (currentStatus == 'actif') ? 'inactif' : 'actif';
    await _db.from('users').update({'statut': newStatus}).eq('id', id);
  }
}