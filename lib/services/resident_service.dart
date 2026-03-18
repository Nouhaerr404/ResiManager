import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resident_model.dart';

class ResidentService {
  final _db = Supabase.instance.client;

  // ═══════════════════════════════════════════════════════════════════
  // SECTION ADMIN (Hajar)
  // ═══════════════════════════════════════════════════════════════════

  // ─────────────────────────────────────────
  // GET résidents par tranche
  // ─────────────────────────────────────────
  Future<List<ResidentModel>> getResidentsByTranche(int trancheId) async {
    try {
      print('>>> DEBUT tranche=$trancheId');

      final immeublesRes =
          await _db.from('immeubles').select('id, nom, tranche_id').eq('tranche_id', trancheId);
      final immeubles = (immeublesRes as List);
      print('>>> Immeubles filtered by tranche: ${immeubles.length}');
      if (immeubles.isEmpty) return [];

      final immeubleIds = immeubles.map((i) => i['id'] as int).toList();
      print('>>> Immeuble IDs: $immeubleIds');

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

      final userIds = residents.map((r) => r['user_id'] as int).toList();

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
          paiementId: paiement.isNotEmpty ? paiement['id'] as int? : null,
          montantTotal: paiement.isNotEmpty
              ? double.parse(paiement['montant_total'].toString())
              : 3000.0,
          montantPaye: paiement.isNotEmpty
              ? double.parse(paiement['montant_paye'].toString())
              : 0.0,
          statutPaiement:
          paiement.isNotEmpty ? paiement['statut'].toString() : 'impaye',
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
  // SEARCH résidents pour autocomplete
  // ─────────────────────────────────────────
  Future<List<ResidentModel>> searchResidents(String query) async {
    if (query.isEmpty) return [];
    try {
      final q = query.toLowerCase().trim();
      
      // On cherche dans la table users par nom ou prénom ou email
      final usersRes = await _db
          .from('users')
          .select('id, nom, prenom, email, telephone')
          .or('nom.ilike.%$q%,prenom.ilike.%$q%,email.ilike.%$q%')
          .limit(10);
      
      final users = usersRes as List;
      if (users.isEmpty) return [];
      
      final userIds = users.map((u) => u['id'] as int).toList();
      
      // On récupère les entrées résidents correspondantes
      final residentsRes = await _db
          .from('residents')
          .select('id, user_id, appartement_id, type, statut')
          .inFilter('user_id', userIds);
      
      final residents = residentsRes as List;
      if (residents.isEmpty) return [];

      final List<ResidentModel> result = [];
      for (final r in residents) {
        final user = users.firstWhere((u) => u['id'] == r['user_id']);
        
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
          montantTotal: 0,
          montantPaye: 0,
          statutPaiement: '—',
          anneePaiement: DateTime.now().year,
        ));
      }
      return result;
    } catch (e) {
      print('>>> ERREUR searchResidents: $e');
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
        'description': 'Paiement charges ${DateTime.now().year}',
      });

      print('>>> Paiement enregistré: $nouveauMontant DH ($statut)');
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
  Future<String?> deleteResident(int userId, int? appartementId) async {
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
      await _db.from('residents').delete().eq('user_id', userId);
      await _db.from('users').delete().eq('id', userId);

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION RÉSIDENT (Wiam)
  // ═══════════════════════════════════════════════════════════════════

  // ─────────────────────────────────────────
  // GET charges data (par année) - VERSION CORRIGÉE
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> getChargesData(int userId, int annee) async {
    try {
      // 1. Profil résident + appartement + immeuble + tranche
      final resRow = await _db
          .from('residents')
          .select('''
            id,
            appartements (
              id, numero,
              immeubles (
                id, nom, nombre_appartements,
                tranches ( id, nom )
              )
            )
          ''')
          .eq('user_id', userId)
          .maybeSingle();

      if (resRow == null) return _err('Profil résident introuvable');

      final appart = resRow['appartements'] as Map<String, dynamic>?;
      final imm = appart?['immeubles'] as Map<String, dynamic>?;
      final tranche = imm?['tranches'] as Map<String, dynamic>?;

      if (appart == null || imm == null || tranche == null) {
        return _err('Appartement ou tranche non assigné');
      }

      final int appartId = appart['id'] as int;
      final int trancheId = tranche['id'] as int;
      final int nbApparts = (imm['nombre_appartements'] as int?) ?? 1;

      // 2. Toutes les dépenses de la tranche pour cette année
      final depRows = await _db
          .from('depenses')
          .select('''
            id, montant, date, mois, annee, facture_path,
            categories ( id, nom, type )
          ''')
          .eq('tranche_id', trancheId)
          .eq('annee', annee)
          .order('mois', ascending: true);

      // 3. Récupérer les paiements SANS la jointure problématique
      final paiRows = await _db
          .from('paiements')
          .select('id, montant_total, montant_paye, statut, date_paiement')
          .eq('appartement_id', appartId);

      // 4. Construire la liste unifiée
      final List<Map<String, dynamic>> charges = [];

      for (final d in depRows as List) {
        final cat = d['categories'] as Map<String, dynamic>?;
        final depId = d['id'] as int;
        final total = (d['montant'] as num).toDouble();
        final part = total / nbApparts;

        // Trouver le paiement correspondant (si vous avez un lien)
        // Pour l'instant, on suppose que les paiements ne sont pas liés aux dépenses individuelles
        final double paye = 0.0; // À ajuster selon votre logique métier
        final double reste = part;
        final String statut = 'impaye';

        charges.add({
          'depense_id': depId,
          'paiement_id': null,
          'categorie': cat?['nom'] ?? 'Divers',
          'type': cat?['type'] ?? 'individuelle',
          'mois': d['mois'] as int?,
          'date': d['date'] as String?,
          'montant_tranche': total,
          'nb_apparts': nbApparts,
          'votre_part': part,
          'montant_paye': paye,
          'montant_reste': reste,
          'statut': statut,
          'date_paiement': null,
          'facture_path': d['facture_path'] as String?,
        });
      }

      // 5. Calculs globaux
      double totalAnnee = 0, payeAnnee = 0;
      int nbImpaye = 0, nbPartiel = 0;

      for (final c in charges) {
        totalAnnee += c['votre_part'] as double;
        payeAnnee += c['montant_paye'] as double;
        if (c['statut'] == 'impaye') nbImpaye++;
        if (c['statut'] == 'partiel') nbPartiel++;
      }

      return {
        'resident': {
          'num_appart': appart['numero']?.toString() ?? '—',
          'immeuble_nom': imm['nom']?.toString() ?? '—',
          'tranche_nom': tranche['nom']?.toString() ?? '—',
          'nb_apparts': nbApparts,
        },
        'charges': charges,
        'solde': {
          'total_annee': totalAnnee,
          'paye_annee': payeAnnee,
          'reste_annee': totalAnnee - payeAnnee,
          'nb_impaye': nbImpaye,
          'nb_partiel': nbPartiel,
        },
      };
    } catch (e) {
      print('Erreur dans getChargesData: $e');
      return _err('Erreur: $e');
    }
  }

  // ─────────────────────────────────────────
  // GET annonces & réunions
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> getAnnoncesAndReunions(int userId) async {
    try {
      final resData = await _db
          .from('residents')
          .select('appartement_id')
          .eq('user_id', userId)
          .single();
      final appartData = await _db
          .from('appartements')
          .select('immeuble_id')
          .eq('id', resData['appartement_id'])
          .single();
      final immData = await _db
          .from('immeubles')
          .select('tranche_id')
          .eq('id', appartData['immeuble_id'])
          .single();
      final int trancheId = immData['tranche_id'];

      final annonces = await _db
          .from('annonces')
          .select()
          .eq('tranche_id', trancheId)
          .eq('statut', 'publiee');

      final reunions = await _db
          .from('reunions')
          .select()
          .eq('tranche_id', trancheId)
          .order('date', ascending: true);

      return {
        'annonces': annonces,
        'reunions': reunions,
        'tranche_id': trancheId,
      };
    } catch (e) {
      print("Erreur Fetch: $e");
      rethrow;
    }
  }

  // ─────────────────────────────────────────
  // GET transparency data
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> getTransparencyData(
      int userId, int mois, int annee) async {
    final res = await _db
        .from('residents')
        .select('*, appartements(*, immeubles(*, tranches(*)))')
        .eq('user_id', userId)
        .single();

    final int nbAppartsImmeuble =
        res['appartements']['immeubles']['nombre_appartements'] ?? 1;
    final int nbAppartsTranche =
        res['appartements']['immeubles']['tranches']['nombre_appartements'] ?? 1;
    final int immeubleId = res['appartements']['immeuble_id'];
    final int trancheId = res['appartements']['immeubles']['tranche_id'];

    final depImmeuble = await _db
        .from('depenses')
        .select()
        .eq('immeuble_id', immeubleId)
        .eq('mois', mois)
        .eq('annee', annee);

    final depTranche = await _db
        .from('depenses')
        .select()
        .eq('tranche_id', trancheId)
        .eq('mois', mois)
        .eq('annee', annee);

    final paiement = await _db
        .from('paiements')
        .select()
        .eq('resident_id', userId)
        .eq('mois', mois)
        .eq('annee', annee)
        .maybeSingle();

    return {
      'immeuble_nom': res['appartements']['immeubles']['nom'],
      'tranche_nom': res['appartements']['immeubles']['tranches']['nom'],
      'paiement': paiement,
      'dep_immeuble': depImmeuble,
      'dep_tranche': depTranche,
      'nb_immeuble': nbAppartsImmeuble,
      'nb_tranche': nbAppartsTranche,
    };
  }

  // ─────────────────────────────────────────
  // GET dépenses tranche détaillées
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> getTrancheExpensesDetailed(
      int userId, int annee) async {
    try {
      final res = await _db
          .from('residents')
          .select('appartement_id')
          .eq('user_id', userId)
          .maybeSingle();
      final app = await _db
          .from('appartements')
          .select('immeuble_id')
          .eq('id', res?['appartement_id'])
          .maybeSingle();
      final imm = await _db
          .from('immeubles')
          .select('tranche_id, nom')
          .eq('id', app?['immeuble_id'])
          .maybeSingle();
      final tra = await _db
          .from('tranches')
          .select('nom')
          .eq('id', imm?['tranche_id'])
          .maybeSingle();

      final int trancheId = imm?['tranche_id'] ?? 0;

      final List depenses = await _db
          .from('depenses')
          .select('*, categories(*)')
          .eq('tranche_id', trancheId)
          .eq('annee', annee)
          .order('date', ascending: false);

      double total = 0, payees = 0;
      for (var d in depenses) {
        double m = double.tryParse(d['montant'].toString()) ?? 0.0;
        total += m;
        if (d['facture_path'] != null) payees += m;
      }

      return {
        'tranche_nom': tra?['nom'] ?? "Tranche A - Les Jardins",
        'depenses': depenses,
        'total': total,
        'payees': payees,
        'attente': total - payees,
      };
    } catch (e) {
      return Future.error(e);
    }
  }

  // ─────────────────────────────────────────
  // GET dashboard résident
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> getResidentDashboardData(int userId) async {
    try {
      final annee = DateTime.now().year;

      final userRow = await _db
          .from('users')
          .select('nom, prenom')
          .eq('id', userId)
          .maybeSingle();

      final resRow = await _db.from('residents').select('''
        id,
        appartements (
          id, numero,
          immeubles ( id, nom, tranches ( id, nom ) )
        )
      ''').eq('user_id', userId).maybeSingle();

      if (resRow == null) {
        return {
          'nom': '—',
          'prenom': '—',
          'num_appart': '—',
          'immeuble_nom': '—',
          'tranche_nom': '—',
          'solde_du': 0.0,
          'nb_annonces': 0,
          'nb_reunions': 0,
          'nb_reclamations_ouvertes': 0,
          'notifications_non_lues': 0,
        };
      }

      final appart = resRow['appartements'] as Map<String, dynamic>?;
      final imm = appart?['immeubles'] as Map<String, dynamic>?;
      final tranche = imm?['tranches'] as Map<String, dynamic>?;
      final appartId = appart?['id'] as int?;
      final trancheId = tranche?['id'] as int?;

      double soldeDu = 0.0;
      if (appartId != null) {
        final pais = await _db
            .from('paiements')
            .select('montant_total, montant_paye')
            .eq('appartement_id', appartId)
            .inFilter('statut', ['impaye', 'partiel']);
        for (final p in pais) {
          soldeDu += ((p['montant_total'] as num) -
              (p['montant_paye'] as num))
              .toDouble();
        }
      }

      int nbAnn = 0, nbReu = 0;
      if (trancheId != null) {
        final a = await _db
            .from('annonces')
            .select('id')
            .eq('tranche_id', trancheId)
            .eq('statut', 'publiee');
        nbAnn = (a as List).length;
        final r = await _db
            .from('reunions')
            .select('id')
            .eq('tranche_id', trancheId)
            .inFilter('statut', ['planifiee', 'confirmee']);
        nbReu = (r as List).length;
      }

      final rec = await _db
          .from('reclamations')
          .select('id')
          .eq('resident_id', userId)
          .eq('statut', 'en_cours');
      final nots = await _db
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('lu', false);

      return {
        'nom': userRow?['nom']?.toString() ?? '—',
        'prenom': userRow?['prenom']?.toString() ?? '—',
        'num_appart': appart?['numero']?.toString() ?? '—',
        'immeuble_nom': imm?['nom']?.toString() ?? '—',
        'tranche_nom': tranche?['nom']?.toString() ?? '—',
        'solde_du': soldeDu,
        'nb_annonces': nbAnn,
        'nb_reunions': nbReu,
        'nb_reclamations_ouvertes': (rec as List).length,
        'notifications_non_lues': (nots as List).length,
      };
    } catch (e) {
      print('Erreur dans getResidentDashboardData: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────
  // NOTIFICATIONS
  // ─────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getNotifications(int userId) async {
    final response = await _db
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> markAsRead(int notifId) async {
    await _db.from('notifications').update({'lu': true}).eq('id', notifId);
  }

  Future<void> markAllAsRead(int userId) async {
    await _db
        .from('notifications')
        .update({'lu': true})
        .eq('user_id', userId);
  }

  Future<void> deleteNotification(int notifId) async {
    await _db.from('notifications').delete().eq('id', notifId);
  }

  // ─────────────────────────────────────────
  // RÉUNIONS – présence
  // ─────────────────────────────────────────
  Future<void> updateMeetingAttendance(
      int userId, int reunionId, String status) async {
    try {
      await _db.from('reunion_resident').upsert({
        'reunion_id': reunionId,
        'resident_id': userId,
        'confirmation': status,
      });
    } catch (e) {
      print("Erreur participation: $e");
    }
  }

  Future<String> getMyAttendance(int userId, int reunionId) async {
    final response = await _db
        .from('reunion_resident')
        .select('confirmation')
        .eq('reunion_id', reunionId)
        .eq('resident_id', userId)
        .maybeSingle();
    return response?['confirmation'] ?? 'en_attente';
  }

  Future<List<Map<String, dynamic>>> getReunionsWithStatus(int userId) async {
    try {
      final resData = await _db
          .from('residents')
          .select('appartement_id')
          .eq('user_id', userId)
          .single();
      final int appartId = resData['appartement_id'];

      final appartData = await _db
          .from('appartements')
          .select('immeuble_id')
          .eq('id', appartId)
          .single();
      final immData = await _db
          .from('immeubles')
          .select('tranche_id')
          .eq('id', appartData['immeuble_id'])
          .single();
      final int trancheId = immData['tranche_id'];

      final List reunionsRaw = await _db
          .from('reunions')
          .select()
          .eq('tranche_id', trancheId)
          .order('date');

      final List participationRaw = await _db
          .from('reunion_resident')
          .select()
          .eq('resident_id', userId);

      return reunionsRaw.map((r) {
        final Map<String, dynamic> reunion = Map<String, dynamic>.from(r);
        final participation = participationRaw.firstWhere(
              (p) => p['reunion_id'] == reunion['id'],
          orElse: () => null,
        );
        return {
          ...reunion,
          'mon_statut': participation != null
              ? participation['confirmation']
              : 'en_attente',
        };
      }).toList().cast<Map<String, dynamic>>();
    } catch (e) {
      print("Erreur Fetch Réunions: $e");
      return [];
    }
  }
// ─────────────────────────────────────────
// GET paiement overview (pour l'onglet paiements)
// ─────────────────────────────────────────
  Future<Map<String, dynamic>> getPaiementOverview(int userId, int annee) async {
    try {
      // Récupérer les informations du résident
      final resRow = await _db
          .from('residents')
          .select('''
          id,
          appartements (
            id, numero,
            immeubles (
              id, nom,
              tranches ( id, nom )
            )
          )
        ''')
          .eq('user_id', userId)
          .maybeSingle();

      if (resRow == null) {
        return {
          'num_appart': '—',
          'immeuble_nom': '—',
          'tranche_nom': '—',
          'total_annee': 0.0,
          'paye_annee': 0.0,
          'reste_annee': 0.0,
          'statut': 'impaye',
        };
      }

      final appart = resRow['appartements'] as Map<String, dynamic>?;
      final imm = appart?['immeubles'] as Map<String, dynamic>?;
      final tranche = imm?['tranches'] as Map<String, dynamic>?;

      final int appartId = appart?['id'] as int? ?? 0;

      // Récupérer tous les paiements de l'appartement pour l'année
      final paiements = await _db
          .from('paiements')
          .select('montant_total, montant_paye, statut')
          .eq('appartement_id', appartId)
          .eq('annee', annee);

      double totalAnnee = 0;
      double payeAnnee = 0;
      String statut = 'impaye';

      if (paiements != null && paiements is List && paiements.isNotEmpty) {
        for (var p in paiements) {
          totalAnnee += (p['montant_total'] as num?)?.toDouble() ?? 0;
          payeAnnee += (p['montant_paye'] as num?)?.toDouble() ?? 0;
        }

        if (payeAnnee >= totalAnnee) {
          statut = 'complet';
        } else if (payeAnnee > 0) {
          statut = 'partiel';
        }
      }

      return {
        'num_appart': appart?['numero']?.toString() ?? '—',
        'immeuble_nom': imm?['nom']?.toString() ?? '—',
        'tranche_nom': tranche?['nom']?.toString() ?? '—',
        'total_annee': totalAnnee,
        'paye_annee': payeAnnee,
        'reste_annee': totalAnnee - payeAnnee,
        'statut': statut,
      };
    } catch (e) {
      print('Erreur dans getPaiementOverview: $e');
      return {
        'num_appart': '—',
        'immeuble_nom': '—',
        'tranche_nom': '—',
        'total_annee': 0.0,
        'paye_annee': 0.0,
        'reste_annee': 0.0,
        'statut': 'impaye',
      };
    }
  }

// ─────────────────────────────────────────
// GET historique complet des paiements
// ─────────────────────────────────────────
  // ─────────────────────────────────────────
// GET historique complet des paiements (RENOMMÉ)
// ─────────────────────────────────────────
  Future<Map<String, dynamic>> getHistoriquePaiementsComplet(int userId) async {
    try {
      // Récupérer l'ID de l'appartement
      final resRow = await _db
          .from('residents')
          .select('appartements(id)')
          .eq('user_id', userId)
          .maybeSingle();

      final appartId = resRow?['appartements']?['id'] as int? ?? 0;

      // Récupérer tous les paiements
      final paiements = await _db
          .from('paiements')
          .select('''
        id, montant_total, montant_paye, statut, date_paiement, annee, mois,
        facture_path
      ''')
          .eq('appartement_id', appartId)
          .order('date_paiement', ascending: false);

      double totalVerse = 0;
      Map<int, List<Map<String, dynamic>>> parAnnee = {};
      List<Map<String, dynamic>> historique = [];

      if (paiements != null && paiements is List) {
        for (var p in paiements) {
          if (p['statut'] != 'impaye') {
            final montantPaye = (p['montant_paye'] as num?)?.toDouble() ?? 0;
            totalVerse += montantPaye;

            final item = {
              'id': p['id'],
              'montant_paye': montantPaye,
              'date_paiement': p['date_paiement'],
              'annee': p['annee'],
              'mois': p['mois'],
              'statut': p['statut'],
              'facture_path': p['facture_path'],
            };

            historique.add(item);

            final annee = p['annee'] as int? ?? 0;
            if (!parAnnee.containsKey(annee)) {
              parAnnee[annee] = [];
            }
            parAnnee[annee]!.add(item);
          }
        }
      }

      return {
        'total_verse': totalVerse,
        'historique': historique,
        'par_annee': parAnnee,
      };
    } catch (e) {
      print('Erreur dans getHistoriquePaiementsComplet: $e');
      return {
        'total_verse': 0.0,
        'historique': [],
        'par_annee': {},
      };
    }
  }

// ─────────────────────────────────────────
// GET statut annuel des paiements (pour l'ancien écran)
// ─────────────────────────────────────────
  Future<Map<String, dynamic>> getYearlyPaymentStatus(int userId, int annee) async {
    try {
      final overview = await getPaiementOverview(userId, annee);
      final historique = await getHistoriquePaiementsComplet(userId); // ← APPEL CORRIGÉ

      final double totalAnnee = overview['total_annee'] as double;
      final double payeAnnee = overview['paye_annee'] as double;

      // Filtrer l'historique pour l'année en cours
      final historiqueAnnee = (historique['historique'] as List)
          .where((h) => h['annee'] == annee)
          .map((h) => {
        'description': 'Paiement charges ${annee}',
        'date': h['date_paiement'],
        'montant': h['montant_paye'],
      })
          .toList();

      return {
        'total_annuel': totalAnnee,
        'deja_paye': payeAnnee,
        'reste_a_payer': totalAnnee - payeAnnee,
        'progression': totalAnnee > 0 ? payeAnnee / totalAnnee : 0,
        'historique': historiqueAnnee,
      };
    } catch (e) {
      print('Erreur dans getYearlyPaymentStatus: $e');
      return {
        'total_annuel': 0,
        'deja_paye': 0,
        'reste_a_payer': 0,
        'progression': 0,
        'historique': [],
      };
    }
  }
  // ─────────────────────────────────────────
  // Utilitaire interne
  // ─────────────────────────────────────────
  Map<String, dynamic> _err(String msg) => {
    'error': msg,
    'resident': {
      'num_appart': '—',
      'immeuble_nom': '—',
      'tranche_nom': '—',
      'nb_apparts': 1,
    },
    'charges': <Map>[],
    'solde': {
      'total_annee': 0.0,
      'paye_annee': 0.0,
      'reste_annee': 0.0,
      'nb_impaye': 0,
      'nb_partiel': 0,
    },
  };
}