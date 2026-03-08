class GarageModel {
  final int id;
  final String numero;
  final int residenceId;
  final int trancheId;
  final double prixAnnuel;
  final double? surface;
  final String statut; // 'disponible' | 'occupe'
  final int? beneficiaireId;

  // Données jointes
  final String? beneficiaireNom;
  final String? beneficiairePrenom;
  final String? trancheNom;
  final bool? isResident; // pour afficher "Résident" ou "Externe"

  GarageModel({
    required this.id,
    required this.numero,
    required this.residenceId,
    required this.trancheId,
    required this.prixAnnuel,
    this.surface,
    required this.statut,
    this.beneficiaireId,
    this.beneficiaireNom,
    this.beneficiairePrenom,
    this.trancheNom,
    this.isResident,
  });

  factory GarageModel.fromJson(Map<String, dynamic> j) => GarageModel(
    id: j['id'],
    numero: j['numero'],
    residenceId: j['residence_id'],
    trancheId: j['tranche_id'],
    prixAnnuel: double.parse(j['prix_annuel'].toString()),
    surface: j['surface'] != null
        ? double.parse(j['surface'].toString())
        : null,
    statut: j['statut'],
    beneficiaireId: j['beneficiaire_id'],
    beneficiaireNom: j['beneficiaires']?['nom'],
    beneficiairePrenom: j['beneficiaires']?['prenom'],
    trancheNom: j['tranches']?['nom'],
    isResident: j['beneficiaires']?['resident_id'] != null,
  );

  String get prixMensuel =>
      '${(prixAnnuel / 12).toStringAsFixed(0)} DH/mois';

  String get nomCompletBeneficiaire =>
      '$beneficiairePrenom $beneficiaireNom'.trim();
}