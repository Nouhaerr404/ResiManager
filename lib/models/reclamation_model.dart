// lib/models/reclamation_model.dart

enum StatutReclamEnum { en_cours, resolue, rejetee }

class ReclamationModel {
  final int id;
  final String titre;
  final String description;
  final int residentId;
  final int? interSyndicId;
  final int? trancheId;
  final StatutReclamEnum statut;
  final String? documentPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Données jointes
  final String? residentNomComplet;
  final String? trancheNom;

  ReclamationModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.residentId,
    this.interSyndicId,
    this.trancheId,
    required this.statut,
    this.documentPath,
    this.createdAt,
    this.updatedAt,
    this.residentNomComplet,
    this.trancheNom,
  });

  bool get estEnCours => statut == StatutReclamEnum.en_cours;
  bool get estResolue => statut == StatutReclamEnum.resolue;
  bool get estRejetee => statut == StatutReclamEnum.rejetee;

  bool get aDocument =>
      documentPath != null && documentPath!.isNotEmpty;

  String get statutLabel {
    switch (statut) {
      case StatutReclamEnum.en_cours:
        return 'En cours';
      case StatutReclamEnum.resolue:
        return 'Résolue';
      case StatutReclamEnum.rejetee:
        return 'Rejetée';
    }
  }

  String get dateStr {
    if (createdAt == null) return '';
    return '${createdAt!.day.toString().padLeft(2, '0')}/'
        '${createdAt!.month.toString().padLeft(2, '0')}/'
        '${createdAt!.year}';
  }

  factory ReclamationModel.fromJson(Map<String, dynamic> j) {
    final user = j['users'] as Map<String, dynamic>?;
    final tranche = j['tranches'] as Map<String, dynamic>?;

    return ReclamationModel(
      id: j['id'],
      titre: j['titre'] ?? '',
      description: j['description'] ?? '',
      residentId: j['resident_id'],
      interSyndicId: j['inter_syndic_id'],
      trancheId: j['tranche_id'],
      statut: StatutReclamEnum.values.firstWhere(
            (e) => e.name == (j['statut'] ?? 'en_cours'),
        orElse: () => StatutReclamEnum.en_cours,
      ),
      documentPath: j['document_path'],
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'])
          : null,
      updatedAt: j['updated_at'] != null
          ? DateTime.tryParse(j['updated_at'])
          : null,
      residentNomComplet: user != null
          ? '${user['prenom']} ${user['nom']}'
          : null,
      trancheNom: tranche?['nom'],
    );
  }

  Map<String, dynamic> toJson() => {
    'titre': titre,
    'description': description,
    'resident_id': residentId,
    'inter_syndic_id': interSyndicId,
    'tranche_id': trancheId,
    'statut': statut.name,
    'document_path': documentPath,
  };
}