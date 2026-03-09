// lib/models/categorie_model.dart

enum TypeDepenseEnum { globale, individuelle }

class CategorieModel {
  final int id;
  final String nom;
  final String? description;
  final TypeDepenseEnum type;

  CategorieModel({
    required this.id,
    required this.nom,
    this.description,
    required this.type,
  });

  String get typeLabel =>
      type == TypeDepenseEnum.globale ? 'Globale' : 'Individuelle';

  factory CategorieModel.fromJson(Map<String, dynamic> j) => CategorieModel(
    id: j['id'],
    nom: j['nom'] ?? '',
    description: j['description'],
    type: TypeDepenseEnum.values.firstWhere(
          (e) => e.name == (j['type'] ?? 'individuelle'),
      orElse: () => TypeDepenseEnum.individuelle,
    ),
  );

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'description': description,
    'type': type.name,
  };
}