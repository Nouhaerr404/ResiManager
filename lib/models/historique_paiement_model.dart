// lib/models/historique_paiement_model.dart

class HistoriquePaiementModel {
  final int id;
  final int residentId;
  final int? paiementId;
  final double montant;
  final DateTime date;
  final String type;       // 'charges' | 'parking' | 'garage' | 'box'
  final String? description;
  final DateTime? createdAt;

  // Données jointes
  final String? residentNomComplet;

  HistoriquePaiementModel({
    required this.id,
    required this.residentId,
    this.paiementId,
    required this.montant,
    required this.date,
    required this.type,
    this.description,
    this.createdAt,
    this.residentNomComplet,
  });

  String get montantStr => '${montant.toStringAsFixed(0)} DH';

  String get dateStr {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  factory HistoriquePaiementModel.fromJson(Map<String, dynamic> j) {
    final user = j['users'] as Map<String, dynamic>?;

    return HistoriquePaiementModel(
      id: j['id'],
      residentId: j['resident_id'],
      paiementId: j['paiement_id'],
      montant: double.parse((j['montant'] ?? 0).toString()),
      date: DateTime.parse(j['date']),
      type: j['type'] ?? 'charges',
      description: j['description'],
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'])
          : null,
      residentNomComplet: user != null
          ? '${user['prenom']} ${user['nom']}'
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'resident_id': residentId,
    'paiement_id': paiementId,
    'montant': montant,
    'date': date.toIso8601String().split('T').first,
    'type': type,
    'description': description,
  };
}