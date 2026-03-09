// lib/models/annonce_model.dart

enum TypeAnnonceEnum { normale, urgente, information }
enum StatutAnnonceEnum { publiee, archivee }

class AnnonceModel {
  final int id;
  final String titre;
  final String contenu;
  final TypeAnnonceEnum type;
  final int? trancheId;
  final int interSyndicId;
  final DateTime? dateExpiration;
  final StatutAnnonceEnum statut;
  final DateTime? createdAt;

  // Données jointes
  final String? trancheNom;
  final String? interSyndicNomComplet;

  AnnonceModel({
    required this.id,
    required this.titre,
    required this.contenu,
    required this.type,
    this.trancheId,
    required this.interSyndicId,
    this.dateExpiration,
    required this.statut,
    this.createdAt,
    this.trancheNom,
    this.interSyndicNomComplet,
  });

  bool get estPubliee => statut == StatutAnnonceEnum.publiee;
  bool get estUrgente => type == TypeAnnonceEnum.urgente;
  bool get estExpiree =>
      dateExpiration != null &&
          dateExpiration!.isBefore(DateTime.now());

  String get typeLabel {
    switch (type) {
      case TypeAnnonceEnum.normale:
        return 'Normale';
      case TypeAnnonceEnum.urgente:
        return 'Urgente';
      case TypeAnnonceEnum.information:
        return 'Information';
    }
  }

  String get dateStr {
    if (createdAt == null) return '';
    return '${createdAt!.day.toString().padLeft(2, '0')}/'
        '${createdAt!.month.toString().padLeft(2, '0')}/'
        '${createdAt!.year}';
  }

  factory AnnonceModel.fromJson(Map<String, dynamic> j) {
    final tranche = j['tranches'] as Map<String, dynamic>?;
    final interSyndic = j['users'] as Map<String, dynamic>?;

    return AnnonceModel(
      id: j['id'],
      titre: j['titre'] ?? '',
      contenu: j['contenu'] ?? '',
      type: TypeAnnonceEnum.values.firstWhere(
            (e) => e.name == (j['type'] ?? 'normale'),
        orElse: () => TypeAnnonceEnum.normale,
      ),
      trancheId: j['tranche_id'],
      interSyndicId: j['inter_syndic_id'],
      dateExpiration: j['date_expiration'] != null
          ? DateTime.tryParse(j['date_expiration'])
          : null,
      statut: StatutAnnonceEnum.values.firstWhere(
            (e) => e.name == (j['statut'] ?? 'publiee'),
        orElse: () => StatutAnnonceEnum.publiee,
      ),
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'])
          : null,
      trancheNom: tranche?['nom'],
      interSyndicNomComplet: interSyndic != null
          ? '${interSyndic['prenom']} ${interSyndic['nom']}'
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'titre': titre,
    'contenu': contenu,
    'type': type.name,
    'tranche_id': trancheId,
    'inter_syndic_id': interSyndicId,
    'date_expiration':
    dateExpiration?.toIso8601String().split('T').first,
    'statut': statut.name,
  };
}