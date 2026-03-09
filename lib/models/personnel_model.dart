// lib/models/personnel_model.dart

enum TypePersonnelEnum { gardien, jardinier, femme_de_menage, securite, autre }
enum StatutPersonnelEnum { actif, inactif }

class PersonnelModel {
  final int id;
  final String nom;
  final String prenom;
  final String? telephone;
  final TypePersonnelEnum type;
  final int residenceId;
  final int? trancheId;
  final double salaireAnnuel;
  final StatutPersonnelEnum statut;
  final DateTime? dateEmbauche;
  final DateTime? createdAt;

  // Données jointes
  final String? trancheNom;

  PersonnelModel({
    required this.id,
    required this.nom,
    required this.prenom,
    this.telephone,
    required this.type,
    required this.residenceId,
    this.trancheId,
    required this.salaireAnnuel,
    required this.statut,
    this.dateEmbauche,
    this.createdAt,
    this.trancheNom,
  });

  String get nomComplet => '$prenom $nom';

  bool get estActif => statut == StatutPersonnelEnum.actif;

  double get salaireMensuel => salaireAnnuel / 12;
  String get salaireMensuelStr =>
      '${salaireMensuel.toStringAsFixed(0)} DH/mois';

  String get typeLabel {
    switch (type) {
      case TypePersonnelEnum.gardien:
        return 'Gardien';
      case TypePersonnelEnum.jardinier:
        return 'Jardinier';
      case TypePersonnelEnum.femme_de_menage:
        return 'Femme de ménage';
      case TypePersonnelEnum.securite:
        return 'Sécurité';
      case TypePersonnelEnum.autre:
        return 'Autre';
    }
  }

  factory PersonnelModel.fromJson(Map<String, dynamic> j) {
    final tranche = j['tranches'] as Map<String, dynamic>?;

    return PersonnelModel(
      id: j['id'],
      nom: j['nom'] ?? '',
      prenom: j['prenom'] ?? '',
      telephone: j['telephone'],
      type: TypePersonnelEnum.values.firstWhere(
            (e) => e.name == (j['type'] ?? 'autre'),
        orElse: () => TypePersonnelEnum.autre,
      ),
      residenceId: j['residence_id'],
      trancheId: j['tranche_id'],
      salaireAnnuel:
      double.parse((j['salaire_annuel'] ?? 0).toString()),
      statut: StatutPersonnelEnum.values.firstWhere(
            (e) => e.name == (j['statut'] ?? 'actif'),
        orElse: () => StatutPersonnelEnum.actif,
      ),
      dateEmbauche: j['date_embauche'] != null
          ? DateTime.tryParse(j['date_embauche'])
          : null,
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'])
          : null,
      trancheNom: tranche?['nom'],
    );
  }

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'prenom': prenom,
    'telephone': telephone,
    'type': type.name,
    'residence_id': residenceId,
    'tranche_id': trancheId,
    'salaire_annuel': salaireAnnuel,
    'statut': statut.name,
    'date_embauche': dateEmbauche?.toIso8601String(),
  };
}