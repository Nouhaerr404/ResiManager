// lib/services/super_admin_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/residence_model.dart';
import '../models/user_model.dart';

class SuperAdminService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getGlobalStats() async {
    try {
      final resResidences = await _supabase.from('residences').select();
      final resSyndics = await _supabase.from('users').select().eq('role', 'syndic_general');
      final resImmeubles = await _supabase.from('immeubles').select();
      final resApparts = await _supabase.from('appartements').select();

      // Calculs dynamiques
      int actifs = resSyndics.where((u) => u['statut'] == 'actif').length;
      // On compte les résidences où le syndic est null
      int sansSyndic = resResidences.where((r) => r['syndic_general_id'] == null).length;

      return {
        'residences_totales': resResidences.length,
        'syndics_totaux': resSyndics.length, // Ajouté
        'syndics_actifs': actifs,
        'residences_sans_syndic': sansSyndic, // Ajouté
        'immeubles_totaux': resImmeubles.length,
        'appartements_totaux': resApparts.length,
      };
    } catch (e) {
      print("Erreur Stats: $e");
      // Retourne des zéros pour éviter l'écran rouge (Null error)
      return {
        'residences_totales': 0,
        'syndics_totaux': 0,
        'syndics_actifs': 0,
        'residences_sans_syndic': 0,
        'immeubles_totaux': 0,
        'appartements_totaux': 0,
      };
    }
  }

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

  Future<List<UserModel>> getSyndicsGeneraux() async {
    try {
      final response = await _supabase.from('users').select().eq('role', 'syndic_general').order('nom');
      return (response as List).map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> toggleSyndicStatus(int id, String currentStatus) async {
    try {
      String newStatus = (currentStatus == 'actif') ? 'inactif' : 'actif';
      await _supabase.from('users').update({'statut': newStatus}).eq('id', id);
    } catch (e) {
      print("Erreur : $e");
    }
  }
}