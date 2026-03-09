// lib/models/parking_model.dart

enum StatutEspaceEnum { disponible, occupe }

class ParkingModel {
  final int id;
  final String numero;
  final int residenceId;
  final int? trancheId;
  final double prixAnnuel;
  final StatutEspaceEnum statut;
  final int? beneficiaireId;
  final DateTime? createdAt;

  // Données jointes
  final String? trancheNom;
  final String? beneficiaireNom;
  final String? beneficiairePrenom;
  final bool? beneficiaireEstResident;

  ParkingModel({
    required this.id,
    required this.numero,
    required this.residenceId,
    this.trancheId,
    required this.prixAnnuel,
    required this.statut,
    this.beneficiaireId,
    this.createdAt,
    this.trancheNom,
    this.beneficiaireNom,
    this.beneficiairePrenom,
    this.beneficiaireEstResident,
  });

  bool get estDisponible => statut == StatutEspaceEnum.disponible;
  bool get estOccupe => statut == StatutEspaceEnum.occupe;

  String get statutLabel => estOccupe ? 'occupé' : 'disponible';

  double get prixMensuel => prixAnnuel / 12;
  String get prixMensuelStr => '${prixMensuel.toStringAsFixed(0)} DH/mois';

  String get nomCompletBeneficiaire =>
      '${beneficiairePrenom ?? ''} ${beneficiaireNom ?? ''}'.trim();

  String get typeBeneficiaire =>
      (beneficiaireEstResident ?? false) ? 'Résident' : 'Externe';

  factory ParkingModel.fromJson(Map<String, dynamic> j) {
    final tranche = j['tranches'] as Map<String, dynamic>?;
    final benef = j['beneficiaires'] as Map<String, dynamic>?;

    return ParkingModel(
      id: j['id'],
      numero: j['numero'] ?? '',
      residenceId: j['residence_id'],
      trancheId: j['tranche_id'],
      prixAnnuel: double.parse((j['prix_annuel'] ?? 0).toString()),
      statut: StatutEspaceEnum.values.firstWhere(
            (e) => e.name == (j['statut'] ?? 'disponible'),
        orElse: () => StatutEspaceEnum.disponible,
      ),
      beneficiaireId: j['beneficiaire_id'],
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'])
          : null,
      trancheNom: tranche?['nom'],
      beneficiaireNom: benef?['nom'],
      beneficiairePrenom: benef?['prenom'],
      beneficiaireEstResident: benef?['resident_id'] != null,
    );
  }

  Map<String, dynamic> toJson() => {
    'numero': numero,
    'residence_id': residenceId,
    'tranche_id': trancheId,
    'prix_annuel': prixAnnuel,
    'statut': statut.name,
    'beneficiaire_id': beneficiaireId,
  };
}