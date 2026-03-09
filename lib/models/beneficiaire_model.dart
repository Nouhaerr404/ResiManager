// lib/models/beneficiaire_model.dart

class BeneficiaireModel {
  final int id;
  final String nom;
  final String prenom;
  final String? telephone;
  final int? residentId;   // null = externe (pas résident de la résidence)
  final int? trancheId;
  final DateTime? createdAt;

  BeneficiaireModel({
    required this.id,
    required this.nom,
    required this.prenom,
    this.telephone,
    this.residentId,
    this.trancheId,
    this.createdAt,
  });

  String get nomComplet => '$prenom $nom';

  // true = résident de la résidence, false = personne externe
  bool get estResident => residentId != null;

  String get typeLabel => estResident ? 'Résident' : 'Externe';

  factory BeneficiaireModel.fromJson(Map<String, dynamic> j) =>
      BeneficiaireModel(
        id: j['id'],
        nom: j['nom'] ?? '',
        prenom: j['prenom'] ?? '',
        telephone: j['telephone'],
        residentId: j['resident_id'],
        trancheId: j['tranche_id'],
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'prenom': prenom,
    'telephone': telephone,
    'resident_id': residentId,
    'tranche_id': trancheId,
  };
}