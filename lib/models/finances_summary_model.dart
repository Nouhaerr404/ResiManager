// lib/models/finances_summary_model.dart

class FinancesSummaryModel {
  final int id;
  final int trancheId;
  final double revenusCharges;
  final double revenusParkings;
  final double revenusGarages;
  final double revenusBoxes;
  final double revenusTotal;
  final double depensesPersonnel;
  final double depensesEntretien;
  final double depensesTotal;
  final double solde;
  final DateTime? updatedAt;

  FinancesSummaryModel({
    required this.id,
    required this.trancheId,
    required this.revenusCharges,
    required this.revenusParkings,
    required this.revenusGarages,
    required this.revenusBoxes,
    required this.revenusTotal,
    required this.depensesPersonnel,
    required this.depensesEntretien,
    required this.depensesTotal,
    required this.solde,
    this.updatedAt,
  });

  bool get estPositif => solde >= 0;

  String get soldeStr =>
      '${estPositif ? '+' : ''}${solde.toStringAsFixed(0)} DH';

  String get revenusTotalStr =>
      '+${revenusTotal.toStringAsFixed(0)} DH';

  String get depensesTotalStr =>
      '-${depensesTotal.toStringAsFixed(0)} DH';

  factory FinancesSummaryModel.fromJson(Map<String, dynamic> j) =>
      FinancesSummaryModel(
        id: j['id'],
        trancheId: j['tranche_id'],
        revenusCharges:
        double.parse((j['revenus_charges'] ?? 0).toString()),
        revenusParkings:
        double.parse((j['revenus_parkings'] ?? 0).toString()),
        revenusGarages:
        double.parse((j['revenus_garages'] ?? 0).toString()),
        revenusBoxes:
        double.parse((j['revenus_boxes'] ?? 0).toString()),
        revenusTotal:
        double.parse((j['revenus_total'] ?? 0).toString()),
        depensesPersonnel:
        double.parse((j['depenses_personnel'] ?? 0).toString()),
        depensesEntretien:
        double.parse((j['depenses_entretien'] ?? 0).toString()),
        depensesTotal:
        double.parse((j['depenses_total'] ?? 0).toString()),
        solde: double.parse((j['solde'] ?? 0).toString()),
        updatedAt: j['updated_at'] != null
            ? DateTime.tryParse(j['updated_at'])
            : null,
      );
}