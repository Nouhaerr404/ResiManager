// lib/models/tranche_model.dart

class TrancheModel {
  final int id;
  final String nom;
  final String? description;
  final int residenceId;
  final int? interSyndicId;
  final int nombreImmeubles;
  final int nombreAppartements;
  final int nombreParkings;
  final int nombreGarages;
  final int nombreBoxes;
  final DateTime? createdAt;

  // Données jointes optionnelles
  final String? residenceNom;
  final String? interSyndicNom;

  TrancheModel({
    required this.id,
    required this.nom,
    this.description,
    required this.residenceId,
    this.interSyndicId,
    required this.nombreImmeubles,
    required this.nombreAppartements,
    required this.nombreParkings,
    required this.nombreGarages,
    required this.nombreBoxes,
    this.createdAt,
    this.residenceNom,
    this.interSyndicNom,
  });

  factory TrancheModel.fromJson(Map<String, dynamic> j) {
    final residence = j['residences'] as Map<String, dynamic>?;
    final interSyndic = j['users'] as Map<String, dynamic>?;

    return TrancheModel(
      id: j['id'],
      nom: j['nom'] ?? '',
      description: j['description'],
      residenceId: j['residence_id'],
      interSyndicId: j['inter_syndic_id'],
      nombreImmeubles: j['nombre_immeubles'] ?? 0,
      nombreAppartements: j['nombre_appartements'] ?? 0,
      nombreParkings: j['nombre_parkings'] ?? 0,
      nombreGarages: j['nombre_garages'] ?? 0,
      nombreBoxes: j['nombre_boxes'] ?? 0,
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'])
          : null,
      residenceNom: residence?['nom'],
      interSyndicNom: interSyndic != null
          ? '${interSyndic['prenom']} ${interSyndic['nom']}'
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'description': description,
    'residence_id': residenceId,
    'inter_syndic_id': interSyndicId,
    'nombre_immeubles': nombreImmeubles,
    'nombre_appartements': nombreAppartements,
    'nombre_parkings': nombreParkings,
    'nombre_garages': nombreGarages,
    'nombre_boxes': nombreBoxes,
  };
}