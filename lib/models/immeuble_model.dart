// lib/models/immeuble_model.dart

class ImmeubleModel {
  final int id;
  final String nom;
  final String? adresse;
  final int trancheId;
  final int nombreAppartements;
  final double chargesGenerales;
  final double prixAnnuel;
  final DateTime? createdAt;

  // Données jointes optionnelles
  final String? trancheNom;

  ImmeubleModel({
    required this.id,
    required this.nom,
    this.adresse,
    required this.trancheId,
    required this.nombreAppartements,
    required this.chargesGenerales,
    required this.prixAnnuel,
    this.createdAt,
    this.trancheNom,
  });

  double get chargeParAppartement =>
      nombreAppartements > 0 ? chargesGenerales / nombreAppartements : 0;

  String get chargeParAppartementStr =>
      '${chargeParAppartement.toStringAsFixed(0)} DH';

  factory ImmeubleModel.fromJson(Map<String, dynamic> j) {
    final tranche = j['tranches'] as Map<String, dynamic>?;

    return ImmeubleModel(
      id: j['id'],
      nom: j['nom'] ?? '',
      adresse: j['adresse'],
      trancheId: j['tranche_id'],
      nombreAppartements: j['nombre_appartements'] ?? 0,
      chargesGenerales:
      double.parse((j['charges_generales'] ?? 0).toString()),
      prixAnnuel: double.parse((j['prix_annuel'] ?? 0).toString()),
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'])
          : null,
      trancheNom: tranche?['nom'],
    );
  }

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'adresse': adresse,
    'tranche_id': trancheId,
    'nombre_appartements': nombreAppartements,
    'charges_generales': chargesGenerales,
    'prix_annuel': prixAnnuel,
  };
}