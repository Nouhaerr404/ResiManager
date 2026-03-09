// lib/models/appartement_model.dart

enum StatutAppartEnum { occupe, libre }

class AppartementModel {
  final int id;
  final String numero;
  final int immeubleId;
  final StatutAppartEnum statut;
  final int? residentId;
  final DateTime? createdAt;

  // Données jointes optionnelles
  final String? immeubleNom;
  final String? residentNomComplet;

  AppartementModel({
    required this.id,
    required this.numero,
    required this.immeubleId,
    required this.statut,
    this.residentId,
    this.createdAt,
    this.immeubleNom,
    this.residentNomComplet,
  });

  bool get estLibre => statut == StatutAppartEnum.libre;
  bool get estOccupe => statut == StatutAppartEnum.occupe;

  String get statutLabel => estOccupe ? 'Occupé' : 'Libre';

  factory AppartementModel.fromJson(Map<String, dynamic> j) {
    final immeuble = j['immeubles'] as Map<String, dynamic>?;
    final resident = j['users'] as Map<String, dynamic>?;

    return AppartementModel(
      id: j['id'],
      numero: j['numero'] ?? '',
      immeubleId: j['immeuble_id'],
      statut: StatutAppartEnum.values.firstWhere(
            (e) => e.name == j['statut'],
        orElse: () => StatutAppartEnum.libre,
      ),
      residentId: j['resident_id'],
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'])
          : null,
      immeubleNom: immeuble?['nom'],
      residentNomComplet: resident != null
          ? '${resident['prenom']} ${resident['nom']}'
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'numero': numero,
    'immeuble_id': immeubleId,
    'statut': statut.name,
    'resident_id': residentId,
  };
}