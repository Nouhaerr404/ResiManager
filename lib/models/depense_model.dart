// lib/models/depense_model.dart

class DepenseModel {
  final int id;
  final double montant;
  final int? categorieId;
  final int residenceId;
  final int? syndicGeneralId;
  final int? interSyndicId;
  final int? trancheId;
  final int? immeubleId;
  final int? personnelId;
  final DateTime date;
  final int annee;
  final int? mois;
  final String? facturePath;
  final DateTime? createdAt;

  // Données jointes
  final String? categorieNom;
  final String? categorieType;   // 'globale' | 'individuelle'
  final String? trancheNom;
  final String? immeubleNom;
  final String? personnelNomComplet;

  DepenseModel({
    required this.id,
    required this.montant,
    this.categorieId,
    required this.residenceId,
    this.syndicGeneralId,
    this.interSyndicId,
    this.trancheId,
    this.immeubleId,
    this.personnelId,
    required this.date,
    required this.annee,
    this.mois,
    this.facturePath,
    this.createdAt,
    this.categorieNom,
    this.categorieType,
    this.trancheNom,
    this.immeubleNom,
    this.personnelNomComplet,
  });

  bool get estGlobale => categorieType == 'globale';

  bool get aFacture => facturePath != null && facturePath!.isNotEmpty;

  String get montantStr => '${montant.toStringAsFixed(0)} DH';

  String get moisLabel {
    if (mois == null) return '';
    const moisNoms = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return mois! > 0 && mois! <= 12 ? moisNoms[mois!] : '';
  }

  factory DepenseModel.fromJson(Map<String, dynamic> j) {
    final categorie = j['categories'] as Map<String, dynamic>?;
    final tranche = j['tranches'] as Map<String, dynamic>?;
    final immeuble = j['immeubles'] as Map<String, dynamic>?;
    final personnel = j['personnel'] as Map<String, dynamic>?;

    return DepenseModel(
      id: j['id'],
      montant: double.parse((j['montant'] ?? 0).toString()),
      categorieId: j['categorie_id'],
      residenceId: j['residence_id'],
      syndicGeneralId: j['syndic_general_id'],
      interSyndicId: j['inter_syndic_id'],
      trancheId: j['tranche_id'],
      immeubleId: j['immeuble_id'],
      personnelId: j['personnel_id'],
      date: DateTime.parse(j['date']),
      annee: j['annee'],
      mois: j['mois'],
      facturePath: j['facture_path'],
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'])
          : null,
      categorieNom: categorie?['nom'],
      categorieType: categorie?['type'],
      trancheNom: tranche?['nom'],
      immeubleNom: immeuble?['nom'],
      personnelNomComplet: personnel != null
          ? '${personnel['prenom']} ${personnel['nom']}'
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'montant': montant,
    'categorie_id': categorieId,
    'residence_id': residenceId,
    'inter_syndic_id': interSyndicId,
    'tranche_id': trancheId,
    'immeuble_id': immeubleId,
    'personnel_id': personnelId,
    'date': date.toIso8601String().split('T').first,
    'annee': annee,
    'mois': mois,
    'facture_path': facturePath,
  };
}