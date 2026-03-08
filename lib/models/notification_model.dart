// lib/models/notification_model.dart

enum TypeNotifEnum { annonce, reunion, paiement, reclamation, general }

class NotificationModel {
  final int id;
  final int userId;
  final String titre;
  final String message;
  final TypeNotifEnum type;
  final bool lu;
  final int? annonceId;
  final int? reunionId;
  final int? paiementId;
  final int? reclamationId;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.titre,
    required this.message,
    required this.type,
    required this.lu,
    this.annonceId,
    this.reunionId,
    this.paiementId,
    this.reclamationId,
    this.createdAt,
  });

  bool get estNonLue => !lu;

  String get typeLabel {
    switch (type) {
      case TypeNotifEnum.annonce:
        return 'Annonce';
      case TypeNotifEnum.reunion:
        return 'Réunion';
      case TypeNotifEnum.paiement:
        return 'Paiement';
      case TypeNotifEnum.reclamation:
        return 'Réclamation';
      case TypeNotifEnum.general:
        return 'Général';
    }
  }

  String get dateStr {
    if (createdAt == null) return '';
    return '${createdAt!.day.toString().padLeft(2, '0')}/'
        '${createdAt!.month.toString().padLeft(2, '0')}/'
        '${createdAt!.year}';
  }

  factory NotificationModel.fromJson(Map<String, dynamic> j) =>
      NotificationModel(
        id: j['id'],
        userId: j['user_id'],
        titre: j['titre'] ?? '',
        message: j['message'] ?? '',
        type: TypeNotifEnum.values.firstWhere(
              (e) => e.name == (j['type'] ?? 'general'),
          orElse: () => TypeNotifEnum.general,
        ),
        lu: j['lu'] ?? false,
        annonceId: j['annonce_id'],
        reunionId: j['reunion_id'],
        paiementId: j['paiement_id'],
        reclamationId: j['reclamation_id'],
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'titre': titre,
    'message': message,
    'type': type.name,
    'lu': lu,
    'annonce_id': annonceId,
    'reunion_id': reunionId,
    'paiement_id': paiementId,
    'reclamation_id': reclamationId,
  };
}