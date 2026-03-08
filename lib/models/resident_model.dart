// lib/models/resident_model.dart

enum TypeResidentEnum { proprietaire, locataire }

class ResidentModel {
  final int id;
  final int userId;
  final int? appartementId;
  final TypeResidentEnum type;
  final String statut;
  final DateTime? dateArrivee;

  // Données jointes depuis users
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;

  // Données jointes depuis appartements + immeubles
  final String? appartementNumero;
  final String? immeubleName;

  // Données paiement
  final double montantTotal;
  final double montantPaye;
  final String statutPaiement; // 'complet' | 'partiel' | 'impaye'
  final int anneePaiement;

  ResidentModel({
    required this.id,
    required this.userId,
    this.appartementId,
    required this.type,
    required this.statut,
    this.dateArrivee,
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
  });

  // ── Getters utiles
  String get nomComplet => '$prenom $nom';

  String get typeLabel =>
      type == TypeResidentEnum.proprietaire ? 'Propriétaire' : 'Locataire';

  bool get estProprietaire => type == TypeResidentEnum.proprietaire;

  double get pourcentagePaiement =>
      montantTotal > 0 ? (montantPaye / montantTotal).clamp(0.0, 1.0) : 0;

  double get resteAPayer =>
      (montantTotal - montantPaye).clamp(0, double.infinity);

  String get adresseAppart =>
      '${immeubleName ?? ''} • App. ${appartementNumero ?? ''}';

  String get pourcentageLabel =>
      '${(pourcentagePaiement * 100).toInt()}%';

  factory ResidentModel.fromJson(Map<String, dynamic> j) {
    final user = j['users'] as Map<String, dynamic>? ?? {};
    final appart = j['appartements'] as Map<String, dynamic>? ?? {};
    final immeuble = appart['immeubles'] as Map<String, dynamic>? ?? {};
    final paiements = j['paiements'] as List?;
    final paiement = (paiements != null && paiements.isNotEmpty)
        ? paiements.first as Map<String, dynamic>
        : null;

    return ResidentModel(
      id: j['id'],
      userId: j['user_id'],
      appartementId: j['appartement_id'],
      type: TypeResidentEnum.values.firstWhere(
            (e) => e.name == (j['type'] ?? 'proprietaire'),
        orElse: () => TypeResidentEnum.proprietaire,
      ),
      statut: j['statut'] ?? 'actif',
      dateArrivee: j['date_arrivee'] != null
          ? DateTime.tryParse(j['date_arrivee'])
          : null,
      nom: user['nom'] ?? '',
      prenom: user['prenom'] ?? '',
      email: user['email'] ?? '',
      telephone: user['telephone'],
      appartementNumero: appart['numero'],
      immeubleName: immeuble['nom'],
      montantTotal:
      double.parse((paiement?['montant_total'] ?? 3000).toString()),
      montantPaye:
      double.parse((paiement?['montant_paye'] ?? 0).toString()),
      statutPaiement: paiement?['statut'] ?? 'impaye',
      anneePaiement: paiement?['annee'] ?? DateTime.now().year,
    );
  }
}