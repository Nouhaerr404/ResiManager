// lib/models/paiement_model.dart

enum TypePaiementEnum { charges, parking, garage, box }
enum StatutPaiementEnum { complet, partiel, impaye }

class PaiementModel {
  final int id;
  final int residentId;
  final int appartementId;
  final int depenseId;
  final int interSyndicId;
  final int residenceId;
  final double montantTotal;
  final double montantPaye;
  final TypePaiementEnum typePaiement;
  final DateTime? datePaiement;
  final StatutPaiementEnum statut;
  final int annee;
  final int? mois;
  final DateTime? createdAt;

  // Donnees jointes
  final String? residentNomComplet;
  final String? appartementNumero;

  // Numero de la ressource (garage, parking, box) pour affichage dans le label
  final String? reference;

  PaiementModel({
    required this.id,
    required this.residentId,
    required this.appartementId,
    required this.depenseId,
    required this.interSyndicId,
    required this.residenceId,
    required this.montantTotal,
    required this.montantPaye,
    required this.typePaiement,
    this.datePaiement,
    required this.statut,
    required this.annee,
    this.mois,
    this.createdAt,
    this.residentNomComplet,
    this.appartementNumero,
    this.reference,
  });

  double get resteAPayer =>
      (montantTotal - montantPaye).clamp(0, double.infinity);

  double get pourcentage =>
      montantTotal > 0 ? (montantPaye / montantTotal).clamp(0.0, 1.0) : 0;

  String get pourcentageLabel => '${(pourcentage * 100).toInt()}%';

  String get statutLabel {
    switch (statut) {
      case StatutPaiementEnum.complet:
        return 'Complet';
      case StatutPaiementEnum.partiel:
        return 'Partiel';
      case StatutPaiementEnum.impaye:
        return 'Impaye';
    }
  }

  bool get estComplet => statut == StatutPaiementEnum.complet;
  bool get estPartiel => statut == StatutPaiementEnum.partiel;
  bool get estImpaye  => statut == StatutPaiementEnum.impaye;

  factory PaiementModel.fromJson(Map<String, dynamic> j) {
    final user   = j['users']        as Map<String, dynamic>?;
    final appart = j['appartements'] as Map<String, dynamic>?;

    return PaiementModel(
      id:            j['id'],
      residentId:    j['resident_id'],
      appartementId: j['appartement_id'],
      depenseId:     j['depense_id'] ?? 0,
      interSyndicId: j['inter_syndic_id'] ?? 0,
      residenceId:   j['residence_id'] ?? 0,
      montantTotal:  double.parse((j['montant_total'] ?? 0).toString()),
      montantPaye:   double.parse((j['montant_paye']  ?? 0).toString()),
      typePaiement: TypePaiementEnum.values.firstWhere(
            (e) => e.name == (j['type_paiement'] ?? 'charges'),
        orElse: () => TypePaiementEnum.charges,
      ),
      datePaiement: j['date_paiement'] != null
          ? DateTime.tryParse(j['date_paiement'])
          : null,
      statut: StatutPaiementEnum.values.firstWhere(
            (e) => e.name == (j['statut'] ?? 'impaye'),
        orElse: () => StatutPaiementEnum.impaye,
      ),
      annee:    j['annee'] ?? DateTime.now().year,
      mois:     j['mois'],
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'])
          : null,
      residentNomComplet: user != null
          ? '${user['prenom']} ${user['nom']}'
          : null,
      appartementNumero: appart?['numero'],
      reference: null, // Rempli manuellement dans ResidentService
    );
  }

  Map<String, dynamic> toJson() => {
    'resident_id':     residentId,
    'appartement_id':  appartementId,
    'depense_id':      depenseId,
    'inter_syndic_id': interSyndicId,
    'residence_id':    residenceId,
    'montant_total':   montantTotal,
    'montant_paye':    montantPaye,
    'type_paiement':   typePaiement.name,
    'date_paiement':   datePaiement?.toIso8601String().split('T').first,
    'statut':          statut.name,
    'annee':           annee,
    'mois':            mois,
  };
}