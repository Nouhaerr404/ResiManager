import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserService {
  final _db = Supabase.instance.client;

  // Récupère les utilisateurs par rôle
  Future<List<UserModel>> getUsersByRole(RoleEnum role) async {
    final response = await _db
        .from('users')
        .select()
        .eq('role', role.name);
    return (response as List).map((json) => UserModel.fromJson(json)).toList();
  }

  // Crée un nouvel utilisateur
  Future<void> createUser(String nom, String prenom, String email, String? telephone, RoleEnum role) async {
    await _db.from('users').insert({
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'role': role.name,
      'statut': 'actif',
    });
  }

  // Met à jour un utilisateur
  Future<void> updateUser(int id, String nom, String prenom, String email, String? telephone, StatutUserEnum statut) async {
    await _db.from('users').update({
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'statut': statut.name,
    }).eq('id', id);
  }

  // Supprime un utilisateur
  Future<void> deleteUser(int id) async {
    await _db.from('users').delete().eq('id', id);
  }
}
