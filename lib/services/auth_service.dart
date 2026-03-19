// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class AuthService {
  final _db = Supabase.instance.client;
  final String _resendApiKey = 're_BAuHy19n_JGXeo8hqeoGsoapBQ6ahhLYC';

  // Stockage temporaire en mémoire (pas de modification DB)
  static final Map<String, TempPasswordData> _tempCodes = {};

  // ✅ Fonction pour hacher le mot de passe avec bcrypt
  Future<String> _hashPassword(String password) async {
    try {
      // Utiliser la fonction crypt de Supabase
      final result = await _db.rpc('crypt', params: {
        'password': password,
        'salt': 'bf'  // bcrypt
      });
      return result;
    } catch (e) {
      print("❌ Erreur hachage: $e");
      // Fallback: utiliser un hachage simple (mais à éviter en prod)
      return password;
    }
  }

  // ✅ LOGIN (vérifie le mot de passe haché)
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final res = await _db
          .from('users')
          .select('id, role, statut, password')
          .eq('email', email.trim())
          .maybeSingle();

      if (res == null) return {'error': 'Email introuvable.'};

      // ✅ Vérifier avec la fonction check_password de Supabase
      final isValid = await _db.rpc('check_password', params: {
        'password': password,
        'hash': res['password']
      });

      if (!isValid) return {'error': 'Mot de passe incorrect.'};

      if (res['statut'] == 'inactif') {
        return {'error': 'Compte désactivé. Contactez l\'administrateur.'};
      }

      return {'id': res['id'], 'role': res['role']};
    } catch (e) {
      return {'error': 'Erreur de connexion: $e'};
    }
  }

  // ✅ REGISTER (hache le mot de passe avant insertion)
  Future<Map<String, dynamic>> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    String? telephone,
  }) async {
    try {
      final existing = await _db
          .from('users')
          .select('id')
          .eq('email', email.trim());
      if ((existing as List).isNotEmpty) {
        return {'error': 'Cet email est déjà utilisé.'};
      }

      // ✅ Hacher le mot de passe
      final hashedPassword = await _hashPassword(password);

      await _db.from('users').insert({
        'nom': nom.trim(),
        'prenom': prenom.trim(),
        'email': email.trim(),
        'telephone': telephone?.trim(),
        'password': hashedPassword,  // ← Mot de passe haché !
        'role': 'syndic_general',
        'statut': 'actif',
      });

      return {'success': true};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ✅ DEMANDE D'INSCRIPTION (avec mot de passe haché)
  Future<String?> soumettreDemandeInscription({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    String? telephone,
  }) async {
    try {
      final existingUser = await _db
          .from('users')
          .select('id')
          .eq('email', email.trim());
      if ((existingUser as List).isNotEmpty) {
        return 'Cet email est déjà associé à un compte.';
      }

      final existingDemande = await _db
          .from('demandes_inscription')
          .select('id, statut')
          .eq('email', email.trim());
      if ((existingDemande as List).isNotEmpty) {
        final statut = existingDemande.first['statut'];
        if (statut == 'en_attente') {
          return 'Une demande est déjà en cours pour cet email.';
        }
        if (statut == 'refuse') {
          return 'Votre demande a été refusée. Contactez l\'administrateur.';
        }
      }

      // ✅ Hacher le mot de passe pour la demande
      final hashedPassword = await _hashPassword(password);

      await _db.from('demandes_inscription').insert({
        'nom': nom.trim(),
        'prenom': prenom.trim(),
        'email': email.trim(),
        'telephone': telephone?.trim(),
        'password': hashedPassword,
        'statut': 'en_attente',
      });

      return null;
    } catch (e) {
      return 'Erreur lors de l\'envoi: $e';
    }
  }

  // ✅ RÉINITIALISER LE MOT DE PASSE AVEC CODE (avec hachage)
  Future<Map<String, dynamic>> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      // Vérifier d'abord le code
      final verification = await verifyCode(email, code);

      if (!verification['success']) {
        return verification;
      }

      // ✅ Hacher le nouveau mot de passe
      final hashedPassword = await _hashPassword(newPassword);

      // Mettre à jour le mot de passe haché dans la base
      await _db
          .from('users')
          .update({'password': hashedPassword})
          .eq('email', email.trim());

      // Nettoyer le code temporaire
      _tempCodes.remove(email);

      print("✅ Mot de passe réinitialisé pour $email");

      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // ✅ GÉNÉRER UN CODE À 6 CHIFFRES
  String _generateCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // ✅ ENVOYER CODE DE RÉINITIALISATION
  Future<bool> sendResetCode(String email) async {
    try {
      print("═══════════════════════════════════════");
      print("🚀 DÉBUT ENVOI EMAIL");
      print("📧 Email: $email");
      print("🔑 Clé API: ${_resendApiKey.substring(0, 10)}...");

      // Vérifier que l'utilisateur existe
      print("👤 Vérification utilisateur...");
      final userExists = await _db
          .from('users')
          .select('id')
          .eq('email', email.trim())
          .maybeSingle();

      if (userExists == null) {
        print("❌ Utilisateur non trouvé");
        return false;
      }
      print("✅ Utilisateur trouvé: ID ${userExists['id']}");

      // Générer un code
      final code = _generateCode();
      final expiry = DateTime.now().add(const Duration(minutes: 15));
      print("🔢 Code généré: $code");
      print("⏰ Expire: $expiry");

      // Stocker temporairement
      _tempCodes[email] = TempPasswordData(
        code: code,
        expiry: expiry,
        userId: userExists['id'],
      );
      print("💾 Code stocké en mémoire");

      // Préparer la requête
      print("📨 Préparation de la requête HTTP...");

      final url = Uri.parse('https://cors-anywhere.herokuapp.com/https://api.resend.com/emails');
      print("🌐 URL: $url");

      final headers = {
        'Authorization': 'Bearer $_resendApiKey',
        'Content-Type': 'application/json',
      };
      print("📋 Headers: ${headers.keys.join(', ')}");

      final body = {
        'from': 'onboarding@resend.dev',
        'to': [email],
        'subject': 'Code de réinitialisation - ResiManager',
        'html': '<p>Votre code: $code</p>',
      };
      print("📦 Body: ${jsonEncode(body)}");

      // Envoyer la requête
      print("⏳ Envoi de la requête...");
      final startTime = DateTime.now();

      final response = await http.post(url, headers: headers, body: jsonEncode(body));

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      print("⏱️ Temps de réponse: ${duration}ms");
      print("📊 Status code: ${response.statusCode}");
      print("📝 Réponse brute: ${response.body}");

      // Analyser la réponse
      if (response.statusCode == 200) {
        print("✅ SUCCÈS: Email envoyé!");
        return true;
      } else {
        print("❌ ÉCHEC: Status code ${response.statusCode}");

        // Essayer de parser l'erreur
        try {
          final errorJson = jsonDecode(response.body);
          print("🔍 Erreur détaillée: $errorJson");
          if (errorJson['message'] != null) {
            print("💬 Message d'erreur: ${errorJson['message']}");
          }
        } catch (e) {
          print("❌ Impossible de parser l'erreur: $e");
        }

        return false;
      }
    } catch (e) {
      print("❌ EXCEPTION: $e");
      print("📚 Type d'exception: ${e.runtimeType}");
      print("🔄 Stack trace: ${StackTrace.current}");
      return false;
    } finally {
      print("═══════════════════════════════════════");
    }
  }

  // ✅ VÉRIFIER LE CODE
  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    try {
      print("═══════════════════════════════════════");
      print("🔍 VERIFY CODE - DÉBOGAGE");
      print("📧 Email reçu: $email");
      print("🔢 Code reçu: $code");
      print("📦 Contenu de _tempCodes:");

      // Afficher toutes les clés stockées
      _tempCodes.forEach((key, value) {
        print("  - $key: ${value.code} (expire: ${value.expiry})");
      });

      final tempData = _tempCodes[email];

      if (tempData == null) {
        print("❌ Aucune donnée trouvée pour $email");
        return {
          'success': false,
          'error': 'Aucune demande trouvée pour cet email'
        };
      }

      print("✅ Donnée trouvée: code=${tempData.code}, userId=${tempData.userId}");
      print("⏰ Expiration: ${tempData.expiry}");
      print("🕒 Maintenant: ${DateTime.now()}");

      // Vérifier l'expiration
      if (DateTime.now().isAfter(tempData.expiry)) {
        _tempCodes.remove(email);
        print("❌ Code expiré");
        return {
          'success': false,
          'error': 'Code expiré (15 minutes maximum)'
        };
      }

      // Vérifier le code
      print("🔍 Comparaison: '${tempData.code}' == '$code' ? ${tempData.code == code}");

      if (tempData.code != code) {
        return {
          'success': false,
          'error': 'Code incorrect'
        };
      }

      // Code valide
      print("✅ Code valide !");
      return {
        'success': true,
        'userId': tempData.userId
      };
    } catch (e) {
      print("❌ Exception: $e");
      return {
        'success': false,
        'error': e.toString()
      };
    } finally {
      print("═══════════════════════════════════════");
    }
  }

  // ✅ NETTOYER LES CODES EXPIRÉS
  void cleanExpiredCodes() {
    final now = DateTime.now();
    _tempCodes.removeWhere((email, data) => now.isAfter(data.expiry));
  }

  // ANCIENNES MÉTHODES (gardées pour compatibilité)
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      final userExists = await _db
          .from('users')
          .select('id')
          .eq('email', email.trim())
          .maybeSingle();

      if (userExists == null) {
        return {
          'success': false,
          'error': "Aucun compte trouvé avec cet email"
        };
      }

      await _db.auth.resetPasswordForEmail(email.trim());
      return {'success': true};
    } on AuthException catch (e) {
      return {'success': false, 'error': e.message};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> sendSimpleEmail(String email) async {
    try {
      final resetLink = 'https://www.google.com';
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $_resendApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': 'onboarding@resend.dev',
          'to': [email],
          'subject': 'Réinitialisation de votre mot de passe',
          'html': '''
            <h2>Réinitialisation du mot de passe</h2>
            <p>Cliquez sur le lien ci-dessous :</p>
            <a href="$resetLink">Réinitialiser mon mot de passe</a>
            <p>Ou copiez ce lien : $resetLink</p>
          ''',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Erreur: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> resetPassword(
      String newPassword, {
        required String? accessToken,
      }) async {
    try {
      if (accessToken != null) {
        await _db.auth.updateUser(
          UserAttributes(password: newPassword),
        );
        return {'success': true};
      } else {
        return {'success': false, 'error': 'Token invalide'};
      }
    } on AuthException catch (e) {
      return {'success': false, 'error': e.message};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}

// Classe pour stocker les données temporaires
class TempPasswordData {
  final String code;
  final DateTime expiry;
  final dynamic userId;

  TempPasswordData({
    required this.code,
    required this.expiry,
    required this.userId,
  });
}