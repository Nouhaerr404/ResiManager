// lib/models/reunion_model.dart

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

  // Données jointes
  final String? trancheNom;
  final String? interSyndicNomComplet;
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
    this.trancheNom,
    this.interSyndicNomComplet,
    this.nbParticipants,
    this.nbConfirmes,
  });

  bool get estPlanifiee => statut == StatutReunionEnum.planifiee;
  bool get estConfirmee => statut == StatutReunionEnum.confirmee;
  bool get estTerminee => statut == StatutReunionEnum.terminee;
  bool get estAnnulee => statut == StatutReunionEnum.annulee;

  bool get estFuture => date.isAfter(DateTime.now());

  String get statutLabel {
    switch (statut) {
      case StatutReunionEnum.planifiee:
        return 'Planifiée';
      case StatutReunionEnum.confirmee:
        return 'Confirmée';
      case StatutReunionEnum.terminee:
        return 'Terminée';
      case StatutReunionEnum.annulee:
        return 'Annulée';
    }
  }

  String get dateStr =>
      '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';

  factory ReunionModel.fromJson(Map<String, dynamic> j) {
    final tranche = j['tranches'] as Map<String, dynamic>?;
    final interSyndic = j['users'] as Map<String, dynamic>?;
    final participants = j['reunion_resident'] as List?;

    return ReunionModel(
      id: j['id'],
      titre: j['titre'] ?? '',
      description: j['description'],
      date: DateTime.parse(j['date']),
      heure: j['heure'] ?? '',
      lieu: j['lieu'] ?? '',
      trancheId: j['tranche_id'],
      interSyndicId: j['inter_syndic_id'],
      statut: StatutReunionEnum.values.firstWhere(
            (e) => e.name == (j['statut'] ?? 'planifiee'),
        orElse: () => StatutReunionEnum.planifiee,
      ),
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'])
          : null,
      trancheNom: tranche?['nom'],
      interSyndicNomComplet: interSyndic != null
          ? '${interSyndic['prenom']} ${interSyndic['nom']}'
          : null,
      nbParticipants: participants?.length,
      nbConfirmes: participants
          ?.where((p) => p['confirmation'] == 'confirme')
          .length,
    );
  }

  Map<String, dynamic> toJson() => {
    'titre': titre,
    'description': description,
    'date': date.toIso8601String().split('T').first,
    'heure': heure,
    'lieu': lieu,
    'tranche_id': trancheId,
    'inter_syndic_id': interSyndicId,
    'statut': statut.name,
  };
}

// ── Modèle pour la participation d'un résident à une réunion
class ReunionResidentModel {
  final int id;
  final int reunionId;
  final int residentId;
  final ConfirmationEnum confirmation;

  // Données jointes
  final String? residentNomComplet;

  ReunionResidentModel({
    required this.id,
    required this.reunionId,
    required this.residentId,
    required this.confirmation,
    this.residentNomComplet,
  });

  String get confirmationLabel {
    switch (confirmation) {
      case ConfirmationEnum.en_attente:
        return 'En attente';
      case ConfirmationEnum.confirme:
        return 'Confirmé';
      case ConfirmationEnum.absent:
        return 'Absent';
    }
  }

  factory ReunionResidentModel.fromJson(Map<String, dynamic> j) {
    final user = j['users'] as Map<String, dynamic>?;

    return ReunionResidentModel(
      id: j['id'],
      reunionId: j['reunion_id'],
      residentId: j['resident_id'],
      confirmation: ConfirmationEnum.values.firstWhere(
            (e) => e.name == (j['confirmation'] ?? 'en_attente'),
        orElse: () => ConfirmationEnum.en_attente,
      ),
      residentNomComplet: user != null
          ? '${user['prenom']} ${user['nom']}'
          : null,
    );
  }
}