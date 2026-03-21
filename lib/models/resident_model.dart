import 'paiement_model.dart';

class ResidentModel {
  final int id;
  final int userId;
  final int? appartementId;
  final int? paiementId;      // ← nouveau
  final String type;
  final String statut;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final String? appartementNumero;
  final String? immeubleName;
  final double montantTotal;
  final double montantPaye;
  final String statutPaiement;
  final int anneePaiement;
  final List<PaiementModel> paiements; // ← Détail des lignes de paiement

  ResidentModel({
    required this.id,
    required this.userId,
    this.appartementId,
    this.paiementId,
    required this.type,
    required this.statut,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    this.appartementNumero,
    this.immeubleName,
    required this.montantTotal,
    required this.montantPaye,
    required this.statutPaiement,
    required this.anneePaiement,
    this.paiements = const [],
  });

  String get nomComplet => '$prenom $nom';
  double get pourcentagePaiement =>
      montantTotal > 0 ? (montantPaye / montantTotal) : 0;
  double get resteAPayer => montantTotal - montantPaye;
  String get adresseAppart => (appartementNumero != null && appartementNumero!.isNotEmpty)
      ? '$appartementNumero'
      : 'Non assigné';
}