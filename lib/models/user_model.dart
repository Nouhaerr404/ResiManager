// lib/models/user_model.dart

enum RoleEnum { super_admin, syndic_general, inter_syndic, resident }
enum StatutUserEnum { actif, inactif }

class UserModel {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final RoleEnum role;
  final StatutUserEnum statut;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    required this.role,
    required this.statut,
    this.createdAt,
  });

  String get nomComplet => '$prenom $nom';

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'],
    nom: j['nom'] ?? '',
    prenom: j['prenom'] ?? '',
    email: j['email'] ?? '',
    telephone: j['telephone'],
    role: RoleEnum.values.firstWhere(
          (e) => e.name == j['role'],
      orElse: () => RoleEnum.resident,
    ),
    statut: StatutUserEnum.values.firstWhere(
          (e) => e.name == j['statut'],
      orElse: () => StatutUserEnum.actif,
    ),
    createdAt: j['created_at'] != null
        ? DateTime.tryParse(j['created_at'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'telephone': telephone,
    'role': role.name,
    'statut': statut.name,
  };
}