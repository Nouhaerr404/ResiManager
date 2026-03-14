// lib/models/appartement_model.dart

enum StatutAppartEnum { occupe, libre }

class AppartementModel {
  final int id;
  final String numero;
  final int immeubleId;
  final StatutAppartEnum statut;
  final int? residentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Données jointes optionnelles
  final String? immeubleNom;
  final String? residentNomComplet;
  final String? residenceNom; // Ajouté
  final String? trancheNom; // Ajouté

  // Champs calculés depuis le numéro (R{res}-T{tranche}-Imm{imm}-{num})
  // Retournent String pour accepter varchar comme demandé par l'utilisateur
  String get residence => _parseNumeroPart(0, 'R');
  String get tranche => _parseNumeroPart(1, 'T');
  String get immeubleNum => _parseNumeroPart(2, 'Imm');
  String get numeroAppartement => _parseNumeroPart(3, '');

  AppartementModel({
    required this.id,
    required this.numero,
    required this.immeubleId,
    required this.statut,
    this.residentId,
    this.createdAt,
    this.updatedAt,
    this.immeubleNom,
    this.residentNomComplet,
    this.residenceNom,
    this.trancheNom,
  });

  String _parseNumeroPart(int index, String prefix) {
    try {
      final parts = numero.split('-');
      if (parts.length > index) {
        String part = parts[index];
        if (prefix.isNotEmpty && part.startsWith(prefix)) {
          part = part.substring(prefix.length);
        }
        return part;
      }
    } catch (_) {}
    return '';
  }

  bool get estLibre => statut == StatutAppartEnum.libre;
  bool get estOccupe => statut == StatutAppartEnum.occupe;

  String get statutLabel => estOccupe ? 'Occupé' : 'Libre';

  /// Titre lisible qui remplace les IDs par les vrais noms si disponibles.
  /// Ex: "RRésidence A-TTranche 1-ImmImmeuble A1-201"
  String get titreAffichage {
    final res = residenceNom ?? residence;
    final tr  = trancheNom ?? tranche;
    final imm = immeubleNom ?? immeubleNum;
    final num = numeroAppartement;
    if (res.isEmpty && tr.isEmpty) return numero; // fallback
    return 'R$res-T$tr-Imm$imm-$num';
  }

  factory AppartementModel.fromJson(Map<String, dynamic> j) {
    final immeuble = j['immeubles'] as Map<String, dynamic>?;
    final resident = j['users'] as Map<String, dynamic>?;
    
    // Noms joints via tranches et residences
    final tranche = immeuble?['tranches'] as Map<String, dynamic>?;
    final residence = tranche?['residences'] as Map<String, dynamic>?;

    // Gestion du statut (le format peut varier entre 'libre'/'occupe' et 'vacant'/'occupied')
    final statutRaw = (j['statut'] ?? '').toString().toLowerCase();
    StatutAppartEnum statut;
    if (statutRaw.contains('lib') || statutRaw == 'vacant' || statutRaw == 'libre') {
      statut = StatutAppartEnum.libre;
    } else {
      statut = StatutAppartEnum.occupe;
    }

    return AppartementModel(
      id: j['id'] is int ? j['id'] : int.parse(j['id'].toString()),
      numero: j['numero'] ?? '',
      immeubleId: j['immeuble_id'] is int ? j['immeuble_id'] : int.parse(j['immeuble_id'].toString()),
      statut: statut,
      residentId: j['resident_id'],
      createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at']) : null,
      updatedAt: j['updated_at'] != null ? DateTime.tryParse(j['updated_at']) : null,
      immeubleNom: immeuble?['nom'],
      residentNomComplet: resident != null ? '${resident['prenom']} ${resident['nom']}' : null,
      residenceNom: residence?['nom'],
      trancheNom: tranche?['nom'],
    );
  }

  Map<String, dynamic> toJson() => {
    'numero': numero,
    'immeuble_id': immeubleId,
    'statut': statut == StatutAppartEnum.libre ? 'libre' : 'occupe',
    'resident_id': residentId,
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };

  // Changé immeuble et numeroApt en dynamic pour accepter String/int
  static String generateNumero(dynamic residence, dynamic tranche, dynamic immeuble, dynamic numeroApt) {
    return "R$residence-T$tranche-Imm$immeuble-$numeroApt";
  }
}