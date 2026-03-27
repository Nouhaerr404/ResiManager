// lib/models/affectation_history_model.dart

class AffectationHistoryModel {
  final int id;
  final int trancheId;
  final int interSyndicId;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final DateTime? createdAt;

  // Données jointes
  final String? interSyndicNom;
  final String? interSyndicPrenom;

  AffectationHistoryModel({
    required this.id,
    required this.trancheId,
    required this.interSyndicId,
    required this.dateDebut,
    this.dateFin,
    this.createdAt,
    this.interSyndicNom,
    this.interSyndicPrenom,
  });

  String get interSyndicNomComplet =>
      interSyndicNom != null ? "$interSyndicPrenom $interSyndicNom" : "Inconnu";

  bool get isCurrent => dateFin == null;

  factory AffectationHistoryModel.fromJson(Map<String, dynamic> j) {
    final isUser = j['inter_syndic'] as Map<String, dynamic>?;

    return AffectationHistoryModel(
      id: j['id'],
      trancheId: j['tranche_id'],
      interSyndicId: j['inter_syndic_id'],
      dateDebut: DateTime.parse(j['date_debut']),
      dateFin: j['date_fin'] != null ? DateTime.parse(j['date_fin']) : null,
      createdAt: j['created_at'] != null ? DateTime.parse(j['created_at']) : null,
      interSyndicNom: isUser?['nom'],
      interSyndicPrenom: isUser?['prenom'],
    );
  }

  Map<String, dynamic> toJson() => {
    'tranche_id': trancheId,
    'inter_syndic_id': interSyndicId,
    'date_debut': dateDebut.toIso8601String().split('T')[0],
    'date_fin': dateFin?.toIso8601String().split('T')[0],
  };
}
