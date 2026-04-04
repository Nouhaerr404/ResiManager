import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyndicCollaboratorService {
  final _db = Supabase.instance.client;

  // --- UTILITAIRE : Génération mot de passe aléatoire ---
  String _generateRandomPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789@#!';
    final rng = Random.secure();
    return List.generate(12, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // --- UTILITAIRE : Hachage (pour la compatibilité avec votre système) ---
  Future<String> _hashPassword(String password) async {
    try {
      final result = await _db.rpc('crypt', params: {'password': password, 'salt': 'bf'});
      return result;
    } catch (e) {
      return password;
    }
  }

  // --- 1. LECTURE (RESTAURÉ) ---
  Future<List<Map<String, dynamic>>> getMyInterSyndics(int myId, int residenceId) async {
    try {
      await checkAndDisableExpiredMandates();
      final response = await _db.from('liens_syndics').select('''
            inter_syndic:users!inter_syndic_id (
              *,
              tranches(nom, residence_id)
            )
          ''')
          .eq('syndic_general_id', myId)
          .eq('residence_id', residenceId);

      final List data = response as List;
      return data
          .where((item) => item['inter_syndic'] != null)
          .map((item) => item['inter_syndic'] as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Erreur lecture: $e");
      return [];
    }
  }

  // --- 2. CRÉATION (Avec mot de passe aléatoire automatique) ---
  Future<bool> createAndInviteSyndic({
    required String email,
    required String nom,
    required String prenom,
    required String telephone,
    required int mySyndicGeneralId,
    required int residenceId,
  }) async {
    try {
      final String tempPassword = _generateRandomPassword();
      final String hashedPassword = await _hashPassword(tempPassword);

      // Inscription Auth avec métadonnées role
      await _db.auth.signUp(
        email: email.trim(), 
        password: tempPassword,
        data: {
          'temp_pass': tempPassword,
          'nom': nom.trim(),
          'prenom': prenom.trim(),
          'role': 'inter_syndic',
        }
      );

      // Insertion dans 'users'
      final newUser = await _db.from('users').insert({
        'nom': nom.trim(),
        'prenom': prenom.trim(),
        'email': email.trim().toLowerCase(),
        'telephone': telephone.trim(),
        'role': 'inter_syndic',
        'statut': 'actif',
        'password': hashedPassword,
      }).select('id').single();

      await _db.from('liens_syndics').insert({
        'syndic_general_id': mySyndicGeneralId,
        'inter_syndic_id': newUser['id'],
        'residence_id': residenceId,
      });

      return true; 
    } catch (e) {
      print("Erreur création: $e");
      return false;
    }
  }

  // --- 3. MODIFICATION (RESTAURÉ) ---
  Future<void> updateInterSyndic(int id, String nom, String prenom, String email, String phone) async {
    await _db.from('users').update({
      'nom': nom, 
      'prenom': prenom, 
      'email': email,
      'telephone': phone
    }).eq('id', id);
  }

  // --- 4. ACTIVATION / DÉSACTIVATION (RESTAURÉ) ---
  Future<void> toggleStatus(int id, String currentStatus) async {
    String newStatus = (currentStatus == 'actif') ? 'inactif' : 'actif';
    await _db.from('users').update({'statut': newStatus}).eq('id', id);

    if (newStatus == 'inactif') {
      try {
        await _db.from('tranches').update({'inter_syndic_id': null}).eq('inter_syndic_id', id);
      } catch (_) {}
    }
  }

  // --- 5. VÉRIFICATION EXPIRATION (RESTAURÉ) ---
  Future<void> checkAndDisableExpiredMandates() async {
    final now = DateTime.now().toIso8601String().split('T')[0];
    try {
      final expiredRes = await _db.from('historique_affectations').select('inter_syndic_id').lt('date_fin', now);
      final Set<int> potentialUserIds = (expiredRes as List).map((m) => m['inter_syndic_id'] as int).toSet();

      for (int userId in potentialUserIds) {
        final userCheck = await _db.from('users').select('statut').eq('id', userId).maybeSingle();
        if (userCheck == null || userCheck['statut'] != 'actif') continue;

        final activeMandatesRes = await _db.from('historique_affectations').select('id').eq('inter_syndic_id', userId).gte('date_fin', now);
        if ((activeMandatesRes as List).isEmpty) {
          await toggleStatus(userId, 'actif');
        }
      }
    } catch (_) {}
  }
}