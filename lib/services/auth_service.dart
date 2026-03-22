// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _db = Supabase.instance.client;

  // ✅ Fonction pour hacher le mot de passe avec bcrypt
  Future<String> _hashPassword(String password) async {
    try {
      final result = await _db.rpc('crypt', params: {'password': password, 'salt': 'bf'});
      return result;
    } catch (e) { return password; }
  }

  // ✅ LOGIN
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      // 1. Vérifier le statut AVANT de connecter
      final res = await _db.from('users')
          .select('id, role, statut')
          .eq('email', email.trim())
          .maybeSingle();

      if (res == null) return {'error': 'Email introuvable.'};

      // ✅ VÉRIFICATION STATUT AVANT AUTH
      if (res['statut'] == 'inactif') {
        return {'error': 'Compte désactivé. Contactez l\'administrateur.'};
      }

      // 2. Connexion via Supabase Auth seulement si actif
      final authRes = await _db.auth.signInWithPassword(
          email: email.trim(), password: password);

      if (authRes.user != null) {
        return {'id': res['id'], 'role': res['role']};
      }

    } catch (e) {
      // Fallback anciens comptes
      try {
        final res = await _db.from('users')
            .select()
            .eq('email', email.trim())
            .maybeSingle();
        if (res == null) return {'error': 'Email introuvable.'};

        // ✅ VÉRIFICATION STATUT DANS FALLBACK AUSSI
        if (res['statut'] == 'inactif') {
          return {'error': 'Compte désactivé. Contactez l\'administrateur.'};
        }

        final isValid = await _db.rpc('check_password',
            params: {'password': password, 'hash': res['password']});
        if (isValid) return {'id': res['id'], 'role': res['role']};
      } catch (_) {}
    }
    return {'error': 'Identifiants incorrects.'};
  }
  Future<void> signOut() async { await _db.auth.signOut(); }

  // ✅ REGISTER
  Future<Map<String, dynamic>> register({required String nom, required String prenom, required String email, required String password, String? telephone}) async {
    try {
      final authRes = await _db.auth.signUp(email: email.trim(), password: password);
      if (authRes.user == null) return {'error': 'Erreur Auth'};
      final hashedPassword = await _hashPassword(password);
      
      await _db.from('users').insert({
        'nom': nom.trim(), 'prenom': prenom.trim(), 'email': email.trim(),
        'telephone': telephone?.trim(), 'password': hashedPassword,
        'role': 'syndic_general', 'statut': 'actif',
      });
      return {'success': true};
    } catch (e) { return {'error': e.toString()}; }
  }

  Future<bool> sendResetCode(String email) async {
    try {
      final userExists = await _db.from('users').select('id').eq('email', email.trim()).maybeSingle();
      if (userExists == null) return false;
      await _db.auth.resetPasswordForEmail(email.trim());
      return true;
    } catch (e) { return false; }
  }

  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    try {
      final res = await _db.auth.verifyOTP(email: email.trim(), token: code, type: OtpType.recovery);
      if (res.session != null) return {'success': true, 'userId': res.user?.id};
      return {'success': false, 'error': 'Code incorrect ou expiré.'};
    } catch (e) { return {'success': false, 'error': 'Erreur de vérification'}; }
  }

  Future<Map<String, dynamic>> resetPasswordWithCode({required String email, required String newPassword}) async {
    try {
      await _db.auth.updateUser(UserAttributes(password: newPassword));
      final hashedPassword = await _hashPassword(newPassword);
      await _db.from('users').update({'password': hashedPassword}).eq('email', email.trim());
      return {'success': true};
    } catch (e) { return {'success': false, 'error': e.toString()}; }
  }

  Future<Map<String, dynamic>> resetPassword(String newPassword, {String? accessToken}) async {
    try {
      final currentUser = _db.auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        return {'success': false, 'error': 'Session expirée ou utilisateur non authentifié.'};
      }
      
      await _db.auth.updateUser(UserAttributes(password: newPassword));
      final hashedPassword = await _hashPassword(newPassword);
      await _db.from('users').update({'password': hashedPassword}).eq('email', currentUser.email!);
      return {'success': true};
    } catch (e) { return {'success': false, 'error': e.toString()}; }
  }

  Future<String?> soumettreDemandeInscription({required String nom, required String prenom, required String email, required String password, String? telephone}) async {
    try {
      final hashedPassword = await _hashPassword(password);
      await _db.from('demandes_inscription').insert({
        'nom': nom.trim(), 'prenom': prenom.trim(), 'email': email.trim(),
        'telephone': telephone?.trim(), 'password': hashedPassword, 'statut': 'en_attente',
      });
      return null;
    } catch (e) { return e.toString(); }
  }
}
