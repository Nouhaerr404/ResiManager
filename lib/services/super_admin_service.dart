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

      // Compte les demandes en attente pour le badge
      final demandes = await _supabase
          .from('demandes_inscription')
          .select('id')
          .eq('statut', 'en_attente');
      final int nbDemandesEnAttente = (demandes as List).length;

      return {
        'residences_totales':      resResidences.length,
        'syndics_totaux':          resSyndics.length,
        'syndics_actifs':          actifs,
        'residences_sans_syndic':  sansSyndic,
        'immeubles_totaux':        resImmeubles.length,
        'appartements_totaux':     resApparts.length,
        'demandes_en_attente':     nbDemandesEnAttente,
      };
    } catch (e) {
      print('Erreur Stats: $e');
      return {
        'residences_totales':     0,
        'syndics_totaux':         0,
        'syndics_actifs':         0,
        'residences_sans_syndic': 0,
        'immeubles_totaux':       0,
        'appartements_totaux':    0,
        'demandes_en_attente':    0,
      };
    }
  }

  // ─────────────────────────────────────────
  // RÉSIDENCES
  // ─────────────────────────────────────────
  Future<List<ResidenceModel>> getAllResidences() async {
    try {
      final response = await _supabase
          .from('residences')
          .select('*, users(nom, prenom, statut), tranches(nombre_immeubles, nombre_appartements)');
      return (response as List).map((json) => ResidenceModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────
  // SYNDICS GÉNÉRAUX
  // ─────────────────────────────────────────
  Future<List<UserModel>> getSyndicsGeneraux() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', 'syndic_general')
          .order('nom');
      return (response as List).map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> toggleSyndicStatus(int id, String currentStatus) async {
    try {
      final newStatus = currentStatus == 'actif' ? 'inactif' : 'actif';
      await _supabase.from('users').update({'statut': newStatus}).eq('id', id);
    } catch (e) {
      print('Erreur toggleSyndicStatus: $e');
    }
  }

  // ─────────────────────────────────────────
  // DEMANDES D'INSCRIPTION
  // ─────────────────────────────────────────

  /// Retourne toutes les demandes (filtrées par statut si précisé)
  Future<List<Map<String, dynamic>>> getDemandesInscription({
    String? statut,
  }) async {
    try {
      // ← eq() AVANT order()
      var query = _supabase
          .from('demandes_inscription')
          .select('id, nom, prenom, email, telephone, statut, motif_refus, created_at');

      if (statut != null) {
        final res = await query
            .eq('statut', statut)
            .order('created_at', ascending: false);
        return (res as List).map((d) => Map<String, dynamic>.from(d)).toList();
      } else {
        final res = await query
            .order('created_at', ascending: false);
        return (res as List).map((d) => Map<String, dynamic>.from(d)).toList();
      }
    } catch (e) {
      print('Erreur getDemandesInscription: $e');
      return [];
    }
  }

  /// Compte les demandes en attente (pour le badge)
  Future<int> getNbDemandesEnAttente() async {
    try {
      final res = await _supabase
          .from('demandes_inscription')
          .select('id')
          .eq('statut', 'en_attente');
      return (res as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Accepte une demande → crée le compte syndic dans users
  Future<String?> accepterDemande(int demandeId) async {
    try {
      // 1. Récupérer la demande
      final demande = await _supabase
          .from('demandes_inscription')
          .select()
          .eq('id', demandeId)
          .single();

      // 2. Vérifier que l'email n'existe pas déjà dans users
      final existing = await _supabase
          .from('users')
          .select('id')
          .eq('email', demande['email']);
      if ((existing as List).isNotEmpty) {
        // Marquer quand même comme accepté
        await _supabase
            .from('demandes_inscription')
            .update({'statut': 'accepte'})
            .eq('id', demandeId);
        return 'Compte déjà existant pour cet email.';
      }

      // 3. Créer le compte dans users
      await _supabase.from('users').insert({
        'nom':       demande['nom'],
        'prenom':    demande['prenom'],
        'email':     demande['email'],
        'telephone': demande['telephone'],
        'password':  demande['password'],
        'role':      'syndic_general',
        'statut':    'actif',
      });

      // 4. Mettre à jour le statut de la demande
      await _supabase
          .from('demandes_inscription')
          .update({'statut': 'accepte'})
          .eq('id', demandeId);

      return null; // succès
    } catch (e) {
      print('Erreur accepterDemande: $e');
      return e.toString();
    }
  }

  /// Refuse une demande avec un motif optionnel
  Future<String?> refuserDemande(int demandeId, {String? motif}) async {
    try {
      await _supabase
          .from('demandes_inscription')
          .update({
        'statut':       'refuse',
        'motif_refus':  motif?.trim(),
      })
          .eq('id', demandeId);
      return null;
    } catch (e) {
      print('Erreur refuserDemande: $e');
      return e.toString();
    }
  }
}