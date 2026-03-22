import 'package:supabase_flutter/supabase_flutter.dart';

class SyndicCollaboratorService {
  final _db = Supabase.instance.client;

  // --- 1. LECTURE (Filtrée par Résidence) ---
  Future<List<Map<String, dynamic>>> getMyInterSyndics(int myId, int residenceId) async {
    try {
      print(">>> DEBUG : Recherche syndics pour SG: $myId et RES: $residenceId");

      final response = await _db.from('liens_syndics').select('''
            inter_syndic:users!inter_syndic_id (
              *,
              tranches(nom, residence_id)
            )
          ''')
          .eq('syndic_general_id', myId)
          .eq('residence_id', residenceId);

      final List data = response as List;
      print(">>> DEBUG : ${data.length} entrées trouvées dans liens_syndics");

      // Filtrer les entrées où l'utilisateur lié n'a pas pu être récupéré (jointure vide ou utilisateur supprimé)
      final results = data
          .where((item) => item['inter_syndic'] != null)
          .map((item) => item['inter_syndic'] as Map<String, dynamic>)
          .toList();

      print(">>> DEBUG : ${results.length} syndics valides après filtrage");
      return results;
    } catch (e) {
      print("Erreur critique getMyInterSyndics: $e");
      return [];
    }
  }

  // --- 2. CRÉATION (Lien avec la résidence) ---
  Future<void> createAndInviteSyndic({
    required String email,
    required String nom,
    required String prenom,
    required String telephone,
    required int mySyndicGeneralId,
    required int residenceId,
  }) async {
    // A. Inscription Auth
    await _db.auth.signUp(email: email, password: "TEMP_PASSWORD_123!");

    // B. Création dans 'users'
    final newUser = await _db.from('users').insert({
      'nom': nom, 'prenom': prenom, 'email': email,
      'telephone': telephone, 'role': 'inter_syndic',
      'statut': 'actif', 'password': 'A_REDEFINIR',
    }).select('id').single();

    final int newInterSyndicId = newUser['id'];

    // C. CRÉATION DU LIEN COMPLET (SG + SYNDIC + RÉSIDENCE)
    await _db.from('liens_syndics').insert({
      'syndic_general_id': mySyndicGeneralId,
      'inter_syndic_id': newInterSyndicId,
      'residence_id': residenceId,
    });
  }

  // Mise à jour complète de l'utilisateur
  Future<void> updateInterSyndic(int id, String nom, String prenom, String email, String phone) async {
    await _db.from('users').update({
      'nom': nom, 
      'prenom': prenom, 
      'email': email,
      'telephone': phone
    }).eq('id', id);
  }

  Future<void> toggleStatus(int id, String currentStatus) async {
    String newStatus = (currentStatus == 'actif') ? 'inactif' : 'actif';
    
    // 1. Mettre à jour le statut dans la table users
    await _db.from('users').update({'statut': newStatus}).eq('id', id);

    // 2. Si on désactive le syndic, on le retire de toutes ses tranches affectées
    if (newStatus == 'inactif') {
      try {
        await _db
            .from('tranches')
            .update({'inter_syndic_id': null})
            .eq('inter_syndic_id', id);
        print(">>> SUCCESS : Syndic $id retiré de ses tranches (désactivation)");
      } catch (e) {
        print(">>> ERREUR lors du retrait des tranches : $e");
      }
    }
  }
}