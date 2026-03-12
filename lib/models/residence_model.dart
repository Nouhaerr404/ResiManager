// lib/models/residence_model.dart

class ResidenceModel {
  final int id;
  final String nom;
  final String adresse;
  final int nombreTranches;
  final int? syndicGeneralId; // Mis en optionnel (?)
  final DateTime? createdAt;
  final String? syndicNom;
  final int totalImmeubles;
  final int totalAppartements;
  final String statut;

  ResidenceModel({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.nombreTranches,
    this.syndicGeneralId,
    this.createdAt,
    this.syndicNom,
    this.totalImmeubles = 0,
    this.totalAppartements = 0,
    this.statut = 'Active',
  });

  factory ResidenceModel.fromJson(Map<String, dynamic> j) {
    final syndic = j['users'] as Map<String, dynamic>?;

    int sumImmeubles = 0;
    int sumApparts = 0;
    if (j['tranches'] != null) {
      for (var t in (j['tranches'] as List)) {
        sumImmeubles += (t['nombre_immeubles'] as int? ?? 0);
        sumApparts += (t['nombre_appartements'] as int? ?? 0);
      }
    }

    return ResidenceModel(
      id: j['id'] ?? 0,
      nom: j['nom'] ?? '',
      adresse: j['adresse'] ?? '',
      nombreTranches: j['nombre_tranches'] ?? 0,
      syndicGeneralId: j['syndic_general_id'], // Peut être null maintenant
      createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at']) : null,
      syndicNom: syndic != null ? "${syndic['prenom']} ${syndic['nom']}" : "Non assigné",
      totalImmeubles: sumImmeubles,
      totalAppartements: sumApparts,
      statut: j['statut'] ?? 'Active',
    );
  }
}