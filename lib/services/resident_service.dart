import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resident_model.dart';

class ResidentService {
  final _db = Supabase.instance.client;

  // ─────────────────────────────────────────
  // GET résidents par tranche
  // ─────────────────────────────────────────
  Future<List<ResidentModel>> getResidentsByTranche(
      int trancheId) async {
    try {
      print('>>> DEBUT tranche=$trancheId');

      final immeublesRes =
      await _db.from('immeubles').select('id, nom, tranche_id');
      final immeubles = (immeublesRes as List)
          .where((i) => i['tranche_id'] == trancheId)
          .toList();
      print('>>> Immeubles: ${immeubles.length}');
      if (immeubles.isEmpty) return [];

      final immeubleIds =
      immeubles.map((i) => i['id'] as int).toList();

      final appartementsRes = await _db
          .from('appartements')
          .select('id, numero, immeuble_id, statut')
          .inFilter('immeuble_id', immeubleIds);
      final appartements = appartementsRes as List;
      print('>>> Appartements: ${appartements.length}');
      if (appartements.isEmpty) return [];

      final appartementIds =
      appartements.map((a) => a['id'] as int).toList();

      final residentsRes = await _db
          .from('residents')
          .select('id, user_id, appartement_id, type, statut')
          .inFilter('appartement_id', appartementIds);
      final residents = residentsRes as List;
      print('>>> Residents: ${residents.length}');
      if (residents.isEmpty) return [];

      final userIds =
      residents.map((r) => r['user_id'] as int).toList();

      final usersRes = await _db
          .from('users')
          .select('id, nom, prenom, email, telephone')
          .inFilter('id', userIds);
      final users = usersRes as List;
      print('>>> Users: ${users.length}');

      final paiementsRes = await _db
          .from('paiements')
          .select(
          'id, appartement_id, montant_total, montant_paye, statut, date_paiement')
          .inFilter('appartement_id', appartementIds);
      final paiements = paiementsRes as List;
      print('>>> Paiements: ${paiements.length}');

      final List<ResidentModel> result = [];

      for (final r in residents) {
        final user = users.firstWhere(
              (u) => u['id'] == r['user_id'],
          orElse: () => <String, dynamic>{},
        ) as Map;
        if (user.isEmpty) continue;

        final appart = appartements.firstWhere(
              (a) => a['id'] == r['appartement_id'],
          orElse: () => <String, dynamic>{},
        ) as Map;

        final immeuble = immeubles.firstWhere(
              (i) => i['id'] == appart['immeuble_id'],
          orElse: () => <String, dynamic>{},
        ) as Map;

        final paiement = paiements.firstWhere(
              (p) => p['appartement_id'] == r['appartement_id'],
          orElse: () => <String, dynamic>{},
        ) as Map;

        print(
            '>>> ${user['prenom']} ${user['nom']}: paiement=${paiement.isNotEmpty ? paiement['id'] : 'AUCUN'}');

        result.add(ResidentModel(
          id: r['id'] as int,
          userId: r['user_id'] as int,
          appartementId: r['appartement_id'] as int?,
          type: r['type'].toString(),
          statut: r['statut'].toString(),
          nom: user['nom']?.toString() ?? '',
          prenom: user['prenom']?.toString() ?? '',
          email: user['email']?.toString() ?? '',
          telephone: user['telephone']?.toString(),
          appartementNumero: appart['numero']?.toString() ?? '',
          immeubleName: immeuble['nom']?.toString() ?? '',
          paiementId: paiement.isNotEmpty
              ? paiement['id'] as int?
              : null,
          montantTotal: paiement.isNotEmpty
              ? double.parse(paiement['montant_total'].toString())
              : 3000.0,
          montantPaye: paiement.isNotEmpty
              ? double.parse(paiement['montant_paye'].toString())
              : 0.0,
          statutPaiement: paiement.isNotEmpty
              ? paiement['statut'].toString()
              : 'impaye',
          anneePaiement: DateTime.now().year,
        ));
      }

      print('>>> FINAL: ${result.length} résidents');
      return result;
    } catch (e, s) {
      print('>>> ERREUR: $e\n$s');
      return [];
    }
  }

  // ─────────────────────────────────────────
  // GET appartements libres
  // ─────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAppartementsLibres(
      int trancheId) async {
    try {
      final immeublesRes = await _db
          .from('immeubles')
          .select('id, nom')
          .eq('tranche_id', trancheId);

      final immeubleIds = (immeublesRes as List)
          .map((i) => i['id'] as int)
          .toList();
      if (immeubleIds.isEmpty) return [];

      final res = await _db
          .from('appartements')
          .select('id, numero, immeuble_id, immeubles(nom)')
          .inFilter('immeuble_id', immeubleIds)
          .eq('statut', 'libre');

      return (res as List).map((a) => {
        'id': a['id'],
        'numero': a['numero'],
        'label':
        '${a['immeubles']?['nom'] ?? ''} • App. ${a['numero']}',
      }).toList();
    } catch (e) {
      print('>>> ERREUR getAppartementsLibres: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────
  // GET historique paiements
  // ─────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getHistoriquePaiements(
      int residentUserId) async {
    try {
      final res = await _db
          .from('historique_paiements')
          .select('id, montant, date, description, type')
          .eq('resident_id', residentUserId)
          .order('date', ascending: false);

      return (res as List)
          .map((h) => Map<String, dynamic>.from(h))
          .toList();
    } catch (e) {
      print('>>> ERREUR historique: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────
  // AJOUTER résident
  // ─────────────────────────────────────────
  Future<String?> addResident({
    required String nom,
    required String prenom,
    required String email,
    String? telephone,
    required String type,
    required int trancheId,
    required int appartementId,
    required double montantTotal,
  }) async {
    try {
      final existing = await _db
          .from('users')
          .select('id')
          .eq('email', email.trim());
      if ((existing as List).isNotEmpty) {
        return 'Cet email existe déjà';
      }

      final userRes = await _db.from('users').insert({
        'nom': nom.trim(),
        'prenom': prenom.trim(),
        'email': email.trim(),
        'telephone': telephone?.trim(),
        'password': 'changeme123',
        'role': 'resident',
        'statut': 'actif',
      }).select('id').single();

      final userId = userRes['id'] as int;
      print('>>> User créé: $userId');

      await _db.from('residents').insert({
        'user_id': userId,
        'appartement_id': appartementId,
        'type': type,
        'statut': 'actif',
        'date_arrivee':
        DateTime.now().toIso8601String().substring(0, 10),
      });

      await _db.from('appartements').update({
        'statut': 'occupe',
        'resident_id': userId,
      }).eq('id', appartementId);

      await _db.from('paiements').insert({
        'appartement_id': appartementId,
        'depense_id': 1,
        'inter_syndic_id': 1,
        'montant_total': montantTotal,
        'montant_paye': 0,
        'type_paiement': 'charges',
        'statut': 'impaye',
      });

      print('>>> Résident ajouté');
      return null;
    } catch (e) {
      print('>>> ERREUR addResident: $e');
      return e.toString();
    }
  }

  // ─────────────────────────────────────────
  // ENREGISTRER paiement
  // ─────────────────────────────────────────
  Future<String?> enregistrerPaiement({
    required int paiementId,
    required int residentUserId,
    required double montantAjoute,
    required double montantDejaPane,
    required double montantTotal,
  }) async {
    try {
      final nouveauMontant = montantDejaPane + montantAjoute;
      String statut;
      if (nouveauMontant >= montantTotal) {
        statut = 'complet';
      } else if (nouveauMontant > 0) {
        statut = 'partiel';
      } else {
        statut = 'impaye';
      }

      await _db.from('paiements').update({
        'montant_paye': nouveauMontant,
        'statut': statut,
        'date_paiement':
        DateTime.now().toIso8601String().substring(0, 10),
      }).eq('id', paiementId);

      await _db.from('historique_paiements').insert({
        'resident_id': residentUserId,
        'paiement_id': paiementId,
        'montant': montantAjoute,
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'type': 'charges',
        'description':
        'Paiement charges ${DateTime.now().year}',
      });

      print(
          '>>> Paiement enregistré: $nouveauMontant DH ($statut)');
      return null;
    } catch (e) {
      print('>>> ERREUR enregistrerPaiement: $e');
      return e.toString();
    }
  }

  // ─────────────────────────────────────────
  // MODIFIER résident
  // ─────────────────────────────────────────
  Future<String?> updateResident({
    required int userId,
    required String nom,
    required String prenom,
    String? telephone,
    required String type,
  }) async {
    try {
      await _db.from('users').update({
        'nom': nom.trim(),
        'prenom': prenom.trim(),
        'telephone': telephone?.trim(),
      }).eq('id', userId);

      await _db.from('residents').update({
        'type': type,
      }).eq('user_id', userId);

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────
  // SUPPRIMER résident
  // ─────────────────────────────────────────
  Future<String?> deleteResident(
      int userId, int? appartementId) async {
    try {
      if (appartementId != null) {
        await _db.from('appartements').update({
          'statut': 'libre',
          'resident_id': null,
        }).eq('id', appartementId);

        await _db
            .from('paiements')
            .delete()
            .eq('appartement_id', appartementId);
      }

      await _db
          .from('historique_paiements')
          .delete()
          .eq('resident_id', userId);
      await _db
          .from('residents')
          .delete()
          .eq('user_id', userId);
      await _db.from('users').delete().eq('id', userId);

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}