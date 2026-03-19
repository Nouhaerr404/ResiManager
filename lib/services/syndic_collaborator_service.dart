import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

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
  Future<void> createInterSyndic(String nom, String prenom, String email, String password, String phone) async {
    await _db.from('users').insert({
      'nom': nom, 'prenom': prenom, 'email': email,
      'password': password, 'telephone': phone,
      'role': 'inter_syndic', 'statut': 'actif',
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

  // 2. CRÉER ET PRÉPARER L'INVITATION
  Future<Map<String, String>> createAndInviteSyndic({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
  }) async {
    // On génère un mot de passe temporaire complexe que personne ne retiendra
    final String tempPassword = _generateRandomPassword();

    await _db.from('users').insert({
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'password': tempPassword, // L'utilisateur devra faire "Mot de passe oublié"
      'telephone': telephone,
      'role': 'inter_syndic',
      'statut': 'actif',
    });

    // On retourne les infos pour que l'écran puisse préparer le message WhatsApp
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
    };
  }

  // Petit outil privé pour générer un code aléatoire
  String _generateRandomPassword() {
    return Random().nextInt(999999).toString().padLeft(6, '0') + "Resi!";
  }
}