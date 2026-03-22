// lib/services/super_admin_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/residence_model.dart';
import '../models/user_model.dart';

class SuperAdminService {
  final _supabase = Supabase.instance.client;

  // ─────────────────────────────────────────
  // STATS GLOBALES
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> getGlobalStats() async {
    try {
      final resResidences = await _supabase.from('residences').select();
      final resSyndics    = await _supabase.from('users').select().eq('role', 'syndic_general');
      final resImmeubles  = await _supabase.from('immeubles').select();
      final resApparts    = await _supabase.from('appartements').select();

      int actifs     = resSyndics.where((u) => u['statut'] == 'actif').length;
      int sansSyndic = resResidences.where((r) => r['syndic_general_id'] == null).length;

      final demandes = await _supabase.from('demandes_inscription').select('id').eq('statut', 'en_attente');
      final int nbDemandesEnAttente = (demandes as List).length;

      return {
        'residences_totales':      resResidences.length, 'syndics_totaux': resSyndics.length,
        'syndics_actifs': actifs, 'residences_sans_syndic': sansSyndic,
        'immeubles_totaux': resImmeubles.length, 'appartements_totaux': resApparts.length,
        'demandes_en_attente': nbDemandesEnAttente,
      };
    } catch (e) { return {'residences_totales': 0, 'syndics_totaux': 0, 'demandes_en_attente': 0}; }
  }

  // ─────────────────────────────────────────
  // RÉSIDENCES
  // ─────────────────────────────────────────
  Future<List<ResidenceModel>> getAllResidences() async {
    try {
      final response = await _supabase.from('residences').select('*, users(nom, prenom, statut), tranches(nombre_immeubles, nombre_appartements)');
      return (response as List).map((json) => ResidenceModel.fromJson(json)).toList();
    } catch (e) { return []; }
  }

  // ─────────────────────────────────────────
  // SYNDICS GÉNÉRAUX
  // ─────────────────────────────────────────
  Future<List<UserModel>> getSyndicsGeneraux() async {
    try {
      final response = await _supabase.from('users').select().eq('role', 'syndic_general').order('nom');
      return (response as List).map((json) => UserModel.fromJson(json)).toList();
    } catch (e) { return []; }
  }

  Future<void> toggleSyndicStatus(dynamic id, String currentStatus) async {
    try {
      final newStatus = currentStatus == 'actif' ? 'inactif' : 'actif';
      await _supabase.from('users').update({'statut': newStatus}).eq('id', id);
    } catch (e) { print('Erreur toggleSyndicStatus: $e'); }
  }

  // ─────────────────────────────────────────
  // DEMANDES D'INSCRIPTION
  // ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getDemandesInscription({String? statut}) async {
    try {
      var query = _supabase.from('demandes_inscription').select('id, nom, prenom, email, telephone, statut, motif_refus, created_at');
      if (statut != null) {
        final res = await query.eq('statut', statut).order('created_at', ascending: false);
        return (res as List).map((d) => Map<String, dynamic>.from(d)).toList();
      } else {
        final res = await query.order('created_at', ascending: false);
        return (res as List).map((d) => Map<String, dynamic>.from(d)).toList();
      }
    } catch (e) { return []; }
  }

  Future<int> getNbDemandesEnAttente() async {
    try {
      final res = await _supabase.from('demandes_inscription').select('id').eq('statut', 'en_attente');
      return (res as List).length;
    } catch (e) { return 0; }
  }

  /// Accepte une demande → gère proprement le cas des doublons d'email
  Future<String?> accepterDemande(int demandeId) async {
    try {
      // 1. Récupérer la demande
      final demande = await _supabase.from('demandes_inscription').select().eq('id', demandeId).single();
      final String email = demande['email'].toString().trim();
      final String password = demande['password'];

      // 2. Vérifier si l'email existe déjà dans la table public.users (AVANT insertion)
      final existingUser = await _supabase.from('users').select('id').eq('email', email).maybeSingle();
      if (existingUser != null) {
        // L'utilisateur est déjà là, on marque juste la demande comme acceptée pour nettoyer la liste
        await _supabase.from('demandes_inscription').update({'statut': 'accepte'}).eq('id', demandeId);
        return "Cet utilisateur est déjà enregistré dans la base de données. La demande a été marquée comme acceptée.";
      }

      // 3. Créer l'utilisateur dans Supabase Auth (Déclenche l'email)
      try {
        await _supabase.auth.signUp(email: email, password: password);
      } on AuthException catch (e) {
        // Si déjà dans Auth, on continue quand même pour essayer d'insérer dans public.users
        if (!e.message.contains('already registered') && !e.message.contains('already exists')) {
          return "Erreur Auth: ${e.message}";
        }
      }

      // 4. Créer dans la table public.users
      await _supabase.from('users').insert({
        'nom':       demande['nom'],
        'prenom':    demande['prenom'],
        'email':     email,
        'telephone': demande['telephone'],
        'password':  password,
        'role':      'syndic_general',
        'statut':    'actif',
      });

      // 5. Marquer demande acceptée
      await _supabase.from('demandes_inscription').update({'statut': 'accepte'}).eq('id', demandeId);

      return null;
    } catch (e) {
      print('Erreur accepterDemande: $e');
      if (e.toString().contains('unique constraint') || e.toString().contains('already exists')) {
        return "Cet email est déjà lié à un compte existant.";
      }
      return e.toString();
    }
  }
  Future<String?> annulerRefus(int demandeId) async {
    try {
      await _supabase.from('demandes_inscription').update({
        'statut': 'en_attente',
        'motif_refus': null,
      }).eq('id', demandeId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
  Future<String?> refuserDemande(int demandeId, {String? motif}) async {
    try {
      await _supabase.from('demandes_inscription').update({
        'statut': 'refuse', 'motif_refus': motif?.trim(),
      }).eq('id', demandeId);
      return null;
    } catch (e) { return e.toString(); }
  }
}
