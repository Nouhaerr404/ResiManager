enum StatutReunionEnum { planifiee, confirmee, terminee, annulee }
enum ConfirmationEnum { en_attente, confirme, absent }

class ReunionModel {
  final int id;
  final String titre;
  final String? description;
  final DateTime date;
  final String heure;
  final String lieu;
  final int? trancheId;
  final int interSyndicId;
  final StatutReunionEnum statut;
  final DateTime? createdAt;
  final int? nbParticipants;
  final int? nbConfirmes;

  ReunionModel({
    required this.id,
    required this.titre,
    this.description,
    required this.date,
    required this.heure,
    required this.lieu,
    this.trancheId,
    required this.interSyndicId,
    required this.statut,
    this.createdAt,
    this.nbParticipants,
    this.nbConfirmes,
  });

  bool get estPlanifiee => statut == StatutReunionEnum.planifiee;
  bool get estConfirmee => statut == StatutReunionEnum.confirmee;
  bool get estTerminee  => statut == StatutReunionEnum.terminee;
  bool get estAnnulee   => statut == StatutReunionEnum.annulee;
  bool get estFuture    => date.isAfter(DateTime.now());
  bool get peutConvoquer => estPlanifiee || estConfirmee;

  String get statutLabel {
    switch (statut) {
      case StatutReunionEnum.planifiee: return 'Planifiée';
      case StatutReunionEnum.confirmee: return 'Confirmée';
      case StatutReunionEnum.terminee:  return 'Terminée';
      case StatutReunionEnum.annulee:   return 'Annulée';
    }
  }

  String get heureFormatee {
    // heure stockée en DB comme "14:30:00" → afficher "14:30"
    try {
      return heure.substring(0, 5);
    } catch (_) {
      return heure;
    }
  }

  String get dateFormatee =>
      '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';

  String get dateISO =>
      '${date.year}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

  factory ReunionModel.fromJson(Map<String, dynamic> j) {
    return ReunionModel(
      id:            j['id'] as int,
      titre:         j['titre']?.toString() ?? '',
      description:   j['description']?.toString(),
      date:          DateTime.parse(j['date'].toString()),
      heure:         j['heure']?.toString() ?? '00:00:00',
      lieu:          j['lieu']?.toString() ?? '',
      trancheId:     j['tranche_id'] as int?,
      interSyndicId: j['inter_syndic_id'] as int,
      statut: StatutReunionEnum.values.firstWhere(
            (e) => e.name == (j['statut']?.toString() ?? 'planifiee'),
        orElse: () => StatutReunionEnum.planifiee,
      ),
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString())
          : null,
      nbParticipants: j['nb_participants'] as int?,
      nbConfirmes:    j['nb_confirmes'] as int?,
    );
  }

  Map<String, dynamic> toInsertJson({
    required int trancheId,
    required int interSyndicId,
  }) =>
      {
        'titre':           titre,
        'description':     description,
        'date':            dateISO,
        'heure':           heure,
        'lieu':            lieu,
        'tranche_id':      trancheId,
        'inter_syndic_id': interSyndicId,
        'statut':          'planifiee',
      };
}

// ── Participation résident ──────────────────────────────────────
class ReunionResidentModel {
  final int id;
  final int reunionId;
  final int residentId;  // → référence users.id (FK fk_rr_resident)
  final ConfirmationEnum confirmation;
  final DateTime? createdAt;

  // Données jointes depuis users
  final String? nom;
  final String? prenom;

  ReunionResidentModel({
    required this.id,
    required this.reunionId,
    required this.residentId,
    required this.confirmation,
    this.createdAt,
    this.nom,
    this.prenom,
  });

  String get nomComplet => '$prenom $nom'.trim();

  String get confirmationLabel {
    switch (confirmation) {
      case ConfirmationEnum.en_attente: return 'En attente';
      case ConfirmationEnum.confirme:   return 'Confirmé';
      case ConfirmationEnum.absent:     return 'Absent';
    }
  }

  factory ReunionResidentModel.fromJson(Map<String, dynamic> j) {
    final user = j['users'] as Map<String, dynamic>?;
    return ReunionResidentModel(
      id:         j['id'] as int,
      reunionId:  j['reunion_id'] as int,
      residentId: j['resident_id'] as int,
      confirmation: ConfirmationEnum.values.firstWhere(
            (e) => e.name == (j['confirmation']?.toString() ?? 'en_attente'),
        orElse: () => ConfirmationEnum.en_attente,
      ),
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString())
          : null,
      nom:    user?['nom']?.toString(),
      prenom: user?['prenom']?.toString(),
    );
  }
}