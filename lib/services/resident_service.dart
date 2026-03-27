// ignore_for_file: avoid_multiple_underscores_for_members
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resident_model.dart';
import '../models/paiement_model.dart';
import 'parking_service.dart';
import 'box_service.dart';
import 'garage_service.dart';
import 'dart:typed_data';

class ResidentService {
  final _db = Supabase.instance.client;

  // ═══════════════════════════════════════════════════════════════════
  // SECTION ADMIN
  // ═══════════════════════════════════════════════════════════════════

  Future<List<ResidentModel>> getResidentsByTranche(dynamic trancheId, {String? dateDebut, String? dateFin}) async {
    try {
      // Recuperer le prix annuel de la tranche
      final trancheRes = await _db
          .from('tranches')
          .select('prix_annuel')
          .eq('id', trancheId)
          .maybeSingle();
      final rawPrix = trancheRes?['prix_annuel'] ?? 0;
      final double tranchePrixAnnuel = double.tryParse(rawPrix.toString()) ?? 0.0;

      final immeublesRes = await _db
          .from('immeubles')
          .select('id, nom, tranche_id')
          .eq('tranche_id', trancheId);
      final List immeubles = immeublesRes as List? ?? [];
      if (immeubles.isEmpty) return [];

      final immeubleIds = immeubles.map((i) => i['id']).toList();
      final appartementsRes = await _db
          .from('appartements')
          .select(
          'id, numero, immeuble_id, statut, immeubles!inner(id, nom, tranches!inner(nom, residences!inner(nom)))')
          .inFilter('immeuble_id', immeubleIds);
      final List appartements = appartementsRes as List? ?? [];
      if (appartements.isEmpty) return [];

      final appartementIds = appartements.map((a) => a['id']).toList();
      final residentsRes = await _db
          .from('residents')
          .select('id, user_id, appartement_id, type, statut')
          .or('appartement_id.in.(${appartementIds.join(",")}),appartement_id.is.null');
      final List residents = residentsRes as List? ?? [];
      if (residents.isEmpty) return [];

      final userIds = residents.map((r) => r['user_id'] as int).toList();
      final usersRes = await _db
          .from('users')
          .select('id, nom, prenom, email, telephone')
          .inFilter('id', userIds);
      final users = usersRes as List;

      // ── Paiements filtres par mandat
      var paiementsQuery = _db
          .from('paiements')
          .select(
          'id, appartement_id, resident_id, montant_total, montant_paye, statut, date_paiement, type_paiement, annee, created_at')
          .inFilter('appartement_id', appartementIds);

      if (dateDebut != null) {
        paiementsQuery = paiementsQuery.gte('created_at', dateDebut);
      }
      if (dateFin != null) {
        // Ajouter la fin de journée pour inclure tout le dernier jour
        paiementsQuery = paiementsQuery.lte('created_at', '${dateFin}T23:59:59');
      }
      final paiementsRes = await paiementsQuery;
      final paiements = paiementsRes as List;

      // ── Recuperer les numeros garage/parking/box
      final residentUserIds = residents.map((r) => r['user_id']).toList();
      final Map<String, String> paiementNumero = {};

      try {
        final benefRes = await _db
            .from('beneficiaires')
            .select('id, resident_id')
            .inFilter('resident_id', residentUserIds);
        final List benefList = benefRes as List? ?? [];

        if (benefList.isNotEmpty) {
          final benefIds = benefList.map((b) => b['id']).toList();

          final gRes = await _db
              .from('garages')
              .select('numero, beneficiaire_id')
              .inFilter('beneficiaire_id', benefIds);
          final pkRes = await _db
              .from('parkings')
              .select('numero, beneficiaire_id')
              .inFilter('beneficiaire_id', benefIds);
          final bxRes = await _db
              .from('boxes')
              .select('numero, beneficiaire_id')
              .inFilter('beneficiaire_id', benefIds);

          final Map<String, String> benefToResident = {};
          for (final b in benefList) {
            if (b['id'] != null && b['resident_id'] != null) {
              benefToResident[b['id'].toString()] = b['resident_id'].toString();
            }
          }

          final Map<String, List<Map<String, String>>> residentResources = {};
          for (final g in gRes as List? ?? []) {
            final resId = benefToResident[g['beneficiaire_id']?.toString()];
            if (resId != null && g['numero'] != null) {
              residentResources.putIfAbsent(resId, () => [])
                  .add({'type': 'garage', 'numero': g['numero'].toString()});
            }
          }
          for (final pk in pkRes as List? ?? []) {
            final resId = benefToResident[pk['beneficiaire_id']?.toString()];
            if (resId != null && pk['numero'] != null) {
              residentResources.putIfAbsent(resId, () => [])
                  .add({'type': 'parking', 'numero': pk['numero'].toString()});
            }
          }
          for (final bx in bxRes as List? ?? []) {
            final resId = benefToResident[bx['beneficiaire_id']?.toString()];
            if (resId != null && bx['numero'] != null) {
              residentResources.putIfAbsent(resId, () => [])
                  .add({'type': 'box', 'numero': bx['numero'].toString()});
            }
          }

          final Map<String, Map<String, int>> typeCounters = {};

          for (final p in paiements) {
            final pType    = p['type_paiement']?.toString() ?? '';
            final pResId   = p['resident_id']?.toString();
            final pId      = p['id']?.toString();
            if (pType == 'charges' || pResId == null || pId == null) continue;

            final resources = residentResources[pResId] ?? [];
            final typed = resources.where((r) => r['type'] == pType).toList();
            if (typed.isEmpty) continue;

            typeCounters.putIfAbsent(pResId, () => {});
            final idx = typeCounters[pResId]![pType] ?? 0;
            if (idx < typed.length) {
              paiementNumero[pId] = typed[idx]['numero']!;
              typeCounters[pResId]![pType] = idx + 1;
            }
          }
        }
      } catch (e) {
        debugPrint('>>> ERREUR fetch numeros ressources: $e');
      }

      final List<ResidentModel> result = [];
      for (final r in residents) {
        final user = users.firstWhere(
              (u) => u['id'] == r['user_id'],
          orElse: () => <String, dynamic>{},
        ) as Map;
        if (user.isEmpty) continue;

        final appart = r['appartement_id'] != null
            ? appartements.firstWhere(
                (a) => a['id'] == r['appartement_id'],
            orElse: () => <String, dynamic>{})
            : <String, dynamic>{};

        final immeuble = (appart.isNotEmpty && appart['immeuble_id'] != null)
            ? immeubles.firstWhere(
                (i) => i['id'] == appart['immeuble_id'],
            orElse: () => <String, dynamic>{})
            : <String, dynamic>{};

        String displayNumero = appart['numero']?.toString() ?? '';
        if (displayNumero.isNotEmpty && appart['immeubles'] != null) {
          final immRaw = appart['immeubles'];
          final trNom = immRaw['tranches']?['nom'] ?? '';
          final resNom = immRaw['tranches']?['residences']?['nom'] ?? '';
          final immNom = immRaw['nom'] ?? '';
          final parts = displayNumero.split('-');
          final numApt = parts.isNotEmpty ? parts.last : '';
          displayNumero = 'R$resNom-T$trNom-Imm$immNom-$numApt';
        }

        final residentPaiements = paiements
            .where((p) => p['appartement_id'] == r['appartement_id'])
            .toList();

        // ── FILTRE CLÉ : n'afficher que les résidents ayant un paiement
        // dans le mandat sélectionné. Les résidents sans ligne de paiement
        // pour ce mandat sont exclus de la liste.
        if (residentPaiements.isEmpty) continue;

        double totalM = 0;
        double payeM = 0;
        bool hasImpaye = false;
        bool hasPartiel = false;
        int? mainPaiementId;

        for (final p in residentPaiements) {
          totalM += double.parse((p['montant_total'] ?? 0).toString());
          payeM += double.parse((p['montant_paye'] ?? 0).toString());
          if (p['statut'] == 'impaye') hasImpaye = true;
          if (p['statut'] == 'partiel') hasPartiel = true;
          if (p['type_paiement'] == 'charges') {
            mainPaiementId = p['id'] as int;
          }
        }
        if (residentPaiements.isNotEmpty) {
          mainPaiementId ??= residentPaiements.first['id'] as int;
        }

        String globalStatut = 'complet';
        if (hasImpaye) {
          globalStatut = payeM > 0 ? 'partiel' : 'impaye';
        } else if (hasPartiel) {
          globalStatut = 'partiel';
        }

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
          appartementNumero: displayNumero,
          immeubleName: immeuble['nom']?.toString() ?? '',
          paiementId: mainPaiementId,
          montantTotal: totalM,
          montantPaye: payeM,
          statutPaiement: globalStatut,
          anneePaiement: DateTime.now().year,
          paiements: residentPaiements
              .map((p) {
            final type = p['type_paiement']?.toString() ?? 'charges';
            final pId  = p['id']?.toString() ?? '';
            final refNumero = paiementNumero[pId];
            return PaiementModel(
              id: p['id'] as int,
              residentId: r['user_id'] as int,
              appartementId: r['appartement_id'] as int,
              depenseId: 0,
              interSyndicId: 0,
              residenceId: (immeuble['residence_id'] ?? 0) as int,
              montantTotal:
              double.parse((p['montant_total'] ?? 0).toString()),
              montantPaye:
              double.parse((p['montant_paye'] ?? 0).toString()),
              typePaiement: TypePaiementEnum.values.firstWhere(
                    (e) => e.name == type,
                orElse: () => TypePaiementEnum.charges,
              ),
              statut: StatutPaiementEnum.values.firstWhere(
                    (e) => e.name == (p['statut'] ?? 'impaye'),
                orElse: () => StatutPaiementEnum.impaye,
              ),
              annee: (p['annee'] ?? DateTime.now().year) as int,
              reference: refNumero,
            );
          })
              .toList(),
        ));
      }
      return result;
    } catch (e) {
      debugPrint('>>> ERREUR getResidentsByTranche: $e');
      return [];
    }
  }

  Future<List<ResidentModel>> searchResidents(String query,
      {int? trancheId}) async {
    if (query.isEmpty) return [];
    try {
      final q = query.toLowerCase().trim();
      final usersRes = await _db
          .from('users')
          .select('id, nom, prenom, email, telephone')
          .or('nom.ilike.%$q%,prenom.ilike.%$q%,email.ilike.%$q%')
          .limit(20);
      final List users = usersRes as List? ?? [];
      if (users.isEmpty) return [];
      final userIds = users.map((u) => u['id']).toList();

      final residentsRes = await _db
          .from('residents')
          .select(
          'id, user_id, appartement_id, type, statut, appartements(id, immeubles(id, tranche_id))')
          .inFilter('user_id', userIds);
      final List residents = residentsRes as List? ?? [];
      if (residents.isEmpty) return [];

      final List<ResidentModel> result = [];
      for (final r in residents) {
        Map<String, dynamic>? user;
        try {
          user = users.firstWhere((u) => u['id'] == r['user_id']);
        } catch (_) {
          user = null;
        }
        if (user == null) continue;

        if (trancheId != null) {
          final residentAppartId = r['appartement_id'];
          final residentTrancheId =
          r['appartements']?['immeubles']?['tranche_id'];
          if (residentAppartId != null && residentTrancheId != trancheId) {
            continue;
          }
        }

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
          statutPaiement: '-',
          anneePaiement: DateTime.now().year,
        ));
      }
      return result;
    } catch (e) {
      debugPrint('>>> ERREUR searchResidents: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAppartementsLibres(
      dynamic trancheId) async {
    try {
      final immeublesRes = await _db
          .from('immeubles')
          .select('id, nom')
          .eq('tranche_id', trancheId);
      final List immeubles = immeublesRes as List? ?? [];
      final immeubleIds = immeubles.map((i) => i['id']).toList();
      if (immeubleIds.isEmpty) return [];
      final res = await _db
          .from('appartements')
          .select('id, numero, immeuble_id, immeubles(nom)')
          .inFilter('immeuble_id', immeubleIds)
          .eq('statut', 'libre');
      final List list = res as List? ?? [];
      return list
          .map((a) => {
        'id': a['id'],
        'numero': a['numero'],
        'label':
        '${a['immeubles']?['nom'] ?? ''} - App. ${a['numero']}',
      })
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // HISTORIQUE PAIEMENTS — joint avec paiements pour avoir annee + type_paiement
  // ─────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getHistoriquePaiements(
      dynamic residentUserId, {String? dateDebut, String? dateFin}) async {
    try {
      // Construire la requête de base — PAS encore de .order() ni .select() final
      var query = _db
          .from('historique_paiements')
          .select(
          'id, montant, date, description, type, paiement_id, paiements(annee, type_paiement)')
          .eq('resident_id', residentUserId);

      // Filtres mandat — AVANT .order() pour rester sur PostgrestFilterBuilder
      if (dateDebut != null) {
        query = query.gte('date', dateDebut);
      }
      if (dateFin != null) {
        query = query.lte('date', '${dateFin}T23:59:59');
      }

      // .order() en dernier
      final res = await query.order('date', ascending: false);
      final List list = res as List? ?? [];

      return list.map((h) {
        final map = Map<String, dynamic>.from(h);
        final paiementData = h['paiements'];
        final int? anneeFromPaiement = paiementData?['annee'] as int?;
        final String? typeFromPaiement =
        paiementData?['type_paiement']?.toString();

        int? anneeCalculee = anneeFromPaiement;
        if (anneeCalculee == null) {
          final dateStr = h['date']?.toString() ?? '';
          if (dateStr.length >= 4) {
            anneeCalculee = int.tryParse(dateStr.substring(0, 4));
          }
        }

        map['annee_paiement'] = anneeCalculee;
        map['type_paiement'] =
            typeFromPaiement ?? h['type']?.toString() ?? 'charges';
        return map;
      }).toList();
    } catch (e) {
      debugPrint('>>> ERREUR getHistoriquePaiements: $e');
      return [];
    }
  }
  // ─────────────────────────────────────────────────────────────────
  // ADD RESIDENT
  // ─────────────────────────────────────────────────────────────────
  Future<String?> addResident({
    required String nom,
    required String prenom,
    required String email,
    String? telephone,
    required String password,
    required String type,
    required dynamic trancheId,
    required dynamic appartementId,
    required double montantTotal,
    int? parkingId,
    int? boxId,
    int? garageId,
  }) async {
    try {
      // ── 1. Créer le compte Supabase Auth avec le mot de passe fourni
      // On ignore les erreurs (compte déjà existant, réseau, TLS, etc.)
      try {
        await _db.auth.signUp(email: email.trim(), password: password);
      } catch (_) {}

      // ── 2. Envoyer un email de réinitialisation de mot de passe (fire & forget)
      // Le résident reçoit un lien sécurisé pour définir son propre mot de passe
      // Même mécanisme que "mot de passe oublié" dans Supabase Auth
      try {
        await _db.auth.resetPasswordForEmail(
          email.trim(),
          redirectTo: 'io.supabase.resimanager://reset-callback/',
        );
        debugPrint('>>> Email de réinitialisation envoyé à ${email.trim()}');
      } catch (e) {
        // L'échec de l'email ne bloque pas la création du résident
        debugPrint('>>> AVERTISSEMENT reset email non envoyé: $e');
      }

      final userRes = await _db
          .from('users')
          .insert({
        'nom': nom.trim(),
        'prenom': prenom.trim(),
        'email': email.trim(),
        'telephone': telephone?.trim(),
        'password': password,
        'role': 'resident',
        'statut': 'actif',
      })
          .select('id')
          .single();

      final dynamic userId = userRes['id'];

      await _db.from('residents').insert({
        'user_id': userId,
        'appartement_id': appartementId,
        'type': type,
        'statut': 'actif',
        'date_arrivee': DateTime.now().toIso8601String().substring(0, 10),
      });

      await _db
          .from('appartements')
          .update({'statut': 'occupe', 'resident_id': userId})
          .eq('id', appartementId);

      final trData = await _db
          .from('tranches')
          .select('residence_id, inter_syndic_id, prix_annuel')
          .eq('id', trancheId)
          .maybeSingle();
      final residenceId = trData?['residence_id'] ?? 1;
      final isId = trData?['inter_syndic_id'] ?? 1;
      final rawPrix = trData?['prix_annuel'] ?? 0;
      final double tranchePrix = double.tryParse(rawPrix.toString()) ?? 0.0;
      final double montantEffectif = montantTotal > 0 ? montantTotal : tranchePrix;

      await _db.from('paiements').insert({
        'resident_id': userId,
        'appartement_id': appartementId,
        'residence_id': residenceId,
        'inter_syndic_id': isId,
        'montant_total': montantEffectif,
        'montant_paye': 0,
        'type_paiement': 'charges',
        'statut': 'impaye',
        'annee': DateTime.now().year,
        'mois': DateTime.now().month,
      });

      if (parkingId != null) {
        await ParkingService().assignerParking(
          parkingId: parkingId,
          nom: nom.trim(),
          prenom: prenom.trim(),
          telephone: telephone?.trim(),
          type: type,
          trancheId: int.parse(trancheId.toString()),
          residentId: int.parse(userId.toString()),
        );
      }

      if (boxId != null) {
        await BoxService().assignerBox(
          boxId: boxId,
          nom: nom.trim(),
          prenom: prenom.trim(),
          telephone: telephone?.trim(),
          trancheId: int.parse(trancheId.toString()),
          residentId: int.parse(userId.toString()),
        );
      }

      if (garageId != null) {
        await GarageService().assignerGarage(
          garageId: garageId,
          nom: nom.trim(),
          prenom: prenom.trim(),
          telephone: telephone?.trim(),
          type: type,
          trancheId: int.parse(trancheId.toString()),
          residentId: int.parse(userId.toString()),
        );
      }

      return null;
    } catch (e) {
      debugPrint('>>> ERREUR addResident: $e');
      return e.toString();
    }
  }

  Future<String?> enregistrerPaiement({
    required dynamic paiementId,
    required dynamic residentUserId,
    required double montantAjoute,
    required double montantDejaPane,
    required double montantTotal,
  }) async {
    try {
      final nouveauMontant = montantDejaPane + montantAjoute;
      final statut = nouveauMontant >= montantTotal
          ? 'complet'
          : (nouveauMontant > 0 ? 'partiel' : 'impaye');
      await _db.from('paiements').update({
        'montant_paye': nouveauMontant,
        'statut': statut,
        'date_paiement': DateTime.now().toIso8601String().substring(0, 10),
      }).eq('id', paiementId);
      await _db.from('historique_paiements').insert({
        'resident_id': residentUserId,
        'paiement_id': paiementId,
        'montant': montantAjoute,
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'type': 'charges',
        'description': 'Paiement charges ${DateTime.now().year}',
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> createResourcePayment({
    required int residentId,
    required int trancheId,
    required int residenceId,
    required double montant,
    required String type,
  }) async {
    try {
      final resData = await _db
          .from('residents')
          .select('appartement_id')
          .eq('user_id', residentId)
          .maybeSingle();
      final int? appartId = resData?['appartement_id'] as int?;
      if (appartId == null) return;

      final trancheData = await _db
          .from('tranches')
          .select('inter_syndic_id')
          .eq('id', trancheId)
          .maybeSingle();
      final int isId = (trancheData?['inter_syndic_id'] as int?) ?? 1;

      await _db.from('paiements').insert({
        'resident_id': residentId,
        'appartement_id': appartId,
        'residence_id': residenceId,
        'inter_syndic_id': isId,
        'montant_total': montant,
        'montant_paye': 0,
        'type_paiement': type,
        'statut': 'impaye',
        'annee': DateTime.now().year,
        'mois': DateTime.now().month,
      });
    } catch (e) {
      debugPrint('>>> ERREUR createResourcePayment: $e');
    }
  }

  Future<String?> updateResident({
    required int userId,
    required String nom,
    required String prenom,
    String? telephone,
    required String type,
    double? montantTotal,
    int? annee,
  }) async {
    try {
      await _db.from('users').update({
        'nom': nom.trim(),
        'prenom': prenom.trim(),
        'telephone': telephone?.trim(),
      }).eq('id', userId);

      await _db
          .from('residents')
          .update({'type': type}).eq('user_id', userId);

      if (montantTotal != null && montantTotal > 0) {
        final targetAnnee = annee ?? DateTime.now().year;

        final existingPaiement = await _db
            .from('paiements')
            .select('id, montant_paye')
            .eq('resident_id', userId)
            .eq('type_paiement', 'charges')
            .eq('annee', targetAnnee)
            .maybeSingle();

        if (existingPaiement != null) {
          final double paid =
              double.tryParse(existingPaiement['montant_paye'].toString()) ??
                  0.0;
          final String nouveauStatut = paid >= montantTotal
              ? 'complet'
              : (paid > 0 ? 'partiel' : 'impaye');

          await _db.from('paiements').update({
            'montant_total': montantTotal,
            'statut': nouveauStatut,
          }).eq('id', existingPaiement['id']);
        }
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteResident(dynamic userId, dynamic appartementId) async {
    try {
      if (appartementId != null) {
        await _db
            .from('appartements')
            .update({'statut': 'libre', 'resident_id': null})
            .eq('id', appartementId);
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
  // SECTION RESIDENT
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getChargesData(dynamic userId, int annee) async {
    try {
      final resRow = await _db
          .from('residents')
          .select(
          'id, appartements ( id, numero, immeubles ( id, nom, nombre_appartements, tranches ( id, nom ) ) )')
          .eq('user_id', userId)
          .maybeSingle();
      if (resRow == null) return _err('Profil introuvable');
      final appart = resRow['appartements'] as Map<String, dynamic>?;
      final imm = appart?['immeubles'] as Map<String, dynamic>?;
      final tranche = imm?['tranches'] as Map<String, dynamic>?;
      if (appart == null || imm == null || tranche == null) {
        return _err('Donnees incompletes');
      }
      final dynamic trancheId = tranche['id'];
      final int nbApparts = (imm['nombre_appartements'] as int?) ?? 1;
      final depRows = await _db
          .from('depenses')
          .select(
          'id, montant, date, mois, annee, facture_path, categories ( id, nom, type )')
          .eq('tranche_id', trancheId)
          .eq('annee', annee)
          .order('mois', ascending: true);
      final List list = depRows as List? ?? [];
      final List<Map<String, dynamic>> charges = [];
      for (final d in list) {
        final total = (d['montant'] as num?)?.toDouble() ?? 0.0;
        final part = nbApparts > 0 ? total / nbApparts : 0.0;
        charges.add({
          'depense_id': d['id'],
          'categorie': d['categories']?['nom'] ?? 'Divers',
          'type': d['categories']?['type'] ?? 'individuelle',
          'mois': d['mois'],
          'date': d['date'],
          'montant_tranche': total,
          'nb_apparts': nbApparts,
          'votre_part': part,
          'montant_paye': 0.0,
          'montant_reste': part,
          'statut': 'impaye',
          'facture_path': d['facture_path'],
        });
      }
      return {
        'resident': {
          'num_appart': appart['numero'],
          'immeuble_nom': imm['nom'],
          'tranche_nom': tranche['nom'],
          'nb_apparts': nbApparts,
        },
        'charges': charges,
        'solde': {
          'total_annee': 0.0,
          'paye_annee': 0.0,
          'reste_annee': 0.0,
          'nb_impaye': 0,
          'nb_partiel': 0,
        },
      };
    } catch (e) {
      return _err(e.toString());
    }
  }

  Future<Map<String, dynamic>> getAnnoncesAndReunions(dynamic userId) async {
    try {
      final resData = await _db
          .from('residents')
          .select('appartement_id')
          .eq('user_id', userId)
          .maybeSingle();
      if (resData == null || resData['appartement_id'] == null) {
        return {'annonces': [], 'reunions': [], 'tranche_id': null};
      }
      final appartData = await _db
          .from('appartements')
          .select('immeuble_id')
          .eq('id', resData['appartement_id'])
          .maybeSingle();
      final immData = await _db
          .from('immeubles')
          .select('tranche_id')
          .eq('id', appartData?['immeuble_id'])
          .maybeSingle();
      final dynamic trancheId = immData?['tranche_id'];
      if (trancheId == null) {
        return {'annonces': [], 'reunions': [], 'tranche_id': null};
      }
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
        'annonces': annonces as List? ?? [],
        'reunions': reunions as List? ?? [],
        'tranche_id': trancheId,
      };
    } catch (e) {
      return {'annonces': [], 'reunions': [], 'tranche_id': null};
    }
  }

  Future<Map<String, dynamic>> getTrancheExpensesDetailed(
      dynamic userId, int annee) async {
    try {
      final resData = await _db
          .from('residents')
          .select('appartement_id')
          .eq('user_id', userId)
          .maybeSingle();
      if (resData == null || resData['appartement_id'] == null) {
        return {'depenses': [], 'total': 0.0};
      }
      final appart = await _db
          .from('appartements')
          .select('immeuble_id')
          .eq('id', resData['appartement_id'])
          .maybeSingle();
      final immeuble = await _db
          .from('immeubles')
          .select('tranche_id')
          .eq('id', appart?['immeuble_id'])
          .maybeSingle();
      final dynamic trancheId = immeuble?['tranche_id'];
      final tranche = await _db
          .from('tranches')
          .select('residence_id, nom')
          .eq('id', trancheId)
          .maybeSingle();
      final dynamic residenceId = tranche?['residence_id'];
      final countRes = await _db
          .from('tranches')
          .select('id')
          .eq('residence_id', residenceId);
      final int nbTranches = (countRes as List).length;

      final resTranche = await _db
          .from('depenses')
          .select('*, categories(*)')
          .eq('tranche_id', trancheId)
          .eq('annee', annee);
      final List depsTranche = resTranche as List? ?? [];

      final resResidence = await _db
          .from('depenses')
          .select('*, categories(*)')
          .eq('residence_id', residenceId)
          .eq('annee', annee)
          .isFilter('tranche_id', null);
      final List depsResidence = resResidence as List? ?? [];

      final List allDeps = [...depsTranche, ...depsResidence];
      final List<Map<String, dynamic>> processedDeps = [];
      double totalResident = 0;
      double payeesResident = 0;

      for (final d in allDeps) {
        final double montantSaisi = (d['montant'] as num?)?.toDouble() ?? 0.0;
        final String typeCat =
            d['categories']?['type']?.toString().toLowerCase() ??
                'individuelle';
        final double montantFinal =
        typeCat == 'globale' ? montantSaisi / nbTranches : montantSaisi;

        processedDeps.add({
          ...Map<String, dynamic>.from(d),
          'montant': montantFinal.toStringAsFixed(2),
          'montant_original': montantSaisi,
          'type_affichage': typeCat == 'globale' ? 'Commune' : 'Individuelle',
        });

        totalResident += montantFinal;
        if (d['facture_path'] != null) payeesResident += montantFinal;
      }

      return {
        'tranche_nom': tranche?['nom'] ?? 'Ma Tranche',
        'depenses': processedDeps,
        'total': totalResident,
        'payees': payeesResident,
        'attente': totalResident - payeesResident,
      };
    } catch (e) {
      debugPrint('=== ERREUR getTrancheExpensesDetailed: $e ===');
      return {'depenses': [], 'total': 0.0};
    }
  }

  Future<Map<String, dynamic>> getResidentDashboardData(dynamic userId) async {
    try {
      final userRow = await _db
          .from('users')
          .select('nom, prenom')
          .eq('id', userId)
          .maybeSingle();
      final resData = await _db
          .from('residents')
          .select('appartement_id')
          .eq('user_id', userId)
          .maybeSingle();
      dynamic trancheId;
      dynamic appartNumero = '-';
      dynamic immeubleNom = '-';
      dynamic trancheNom = '-';
      dynamic appartId;

      if (resData != null && resData['appartement_id'] != null) {
        appartId = resData['appartement_id'];
        final appart = await _db
            .from('appartements')
            .select(
            'numero, immeuble_id, immeubles(nom, tranche_id, tranches(nom))')
            .eq('id', appartId)
            .maybeSingle();
        if (appart != null) {
          appartNumero = appart['numero']?.toString() ?? '-';
          final imm = appart['immeubles'];
          if (imm != null) {
            immeubleNom = imm['nom']?.toString() ?? '-';
            trancheId = imm['tranche_id'];
            if (imm['tranches'] != null) {
              trancheNom = imm['tranches']['nom']?.toString() ?? '-';
            }
          }
        }
      }

      double soldeDu = 0.0;
      if (appartId != null) {
        final pais = await _db
            .from('paiements')
            .select('montant_total, montant_paye')
            .eq('appartement_id', appartId)
            .inFilter('statut', ['impaye', 'partiel']);
        for (final p in pais as List? ?? []) {
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
        nbAnn = (a as List? ?? []).length;
        final r = await _db
            .from('reunions')
            .select('id')
            .eq('tranche_id', trancheId)
            .inFilter('statut', ['planifiee', 'confirmee']);
        nbReu = (r as List? ?? []).length;
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
        'nom': userRow?['nom'] ?? '-',
        'prenom': userRow?['prenom'] ?? '-',
        'num_appart': appartNumero,
        'immeuble_nom': immeubleNom,
        'tranche_nom': trancheNom,
        'solde_du': soldeDu,
        'nb_annonces': nbAnn,
        'nb_reunions': nbReu,
        'nb_reclamations_ouvertes': (rec as List? ?? []).length,
        'notifications_non_lues': (nots as List? ?? []).length,
      };
    } catch (e) {
      debugPrint('Erreur getDashboard: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getPaiementOverview(
      dynamic userId, int annee) async {
    try {
      final resRow = await _db
          .from('residents')
          .select('id, appartements(id, numero, immeubles(id, nom, tranches(id, nom)))')
          .eq('user_id', userId)
          .maybeSingle();
      if (resRow == null) {
        return {'num_appart': '-', 'total_annee': 0.0, 'paye_annee': 0.0, 'reste_annee': 0.0, 'statut': 'impaye', 'lignes': []};
      }

      final dynamic appartId = resRow['appartements']?['id'];

      final paiements = await _db
          .from('paiements')
          .select('id, montant_total, montant_paye, statut, type_paiement')
          .eq('appartement_id', appartId)
          .eq('annee', annee);

      double total = 0, paye = 0;
      final List<Map<String, dynamic>> lignes = [];

      for (final p in paiements as List) {
        final double mt = (p['montant_total'] as num).toDouble();
        final double mp = (p['montant_paye'] as num).toDouble();
        total += mt;
        paye  += mp;

        lignes.add({
          'type':          p['type_paiement']?.toString() ?? 'charges',
          'reference':     null,
          'montant_total': mt,
          'montant_paye':  mp,
          'reste':         mt - mp,
          'statut':        p['statut']?.toString() ?? 'impaye',
        });
      }

      return {
        'num_appart':   resRow['appartements']['numero'],
        'immeuble_nom': resRow['appartements']['immeubles']['nom'],
        'tranche_nom':  resRow['appartements']['immeubles']['tranches']['nom'],
        'total_annee':  total,
        'paye_annee':   paye,
        'reste_annee':  total - paye,
        'statut': paye >= total ? 'complet' : (paye > 0 ? 'partiel' : 'impaye'),
        'lignes': lignes,
      };
    } catch (e) {
      debugPrint('>>> ERREUR getPaiementOverview: $e');
      return {'total_annee': 0.0, 'lignes': []};
    }
  }

  Future<Map<String, dynamic>> getHistoriquePaiementsComplet(
      dynamic userId) async {
    try {
      final resRow = await _db
          .from('residents')
          .select('appartement_id')
          .eq('user_id', userId)
          .maybeSingle();
      final dynamic appartId = resRow?['appartement_id'];
      if (appartId == null) return {'total_verse': 0.0, 'historique': []};
      final paiements = await _db
          .from('paiements')
          .select()
          .eq('appartement_id', appartId)
          .order('date_paiement', ascending: false);
      double total = 0;
      final List<Map<String, dynamic>> hist = [];
      for (final p in paiements as List) {
        total += (p['montant_paye'] as num).toDouble();
        hist.add(Map<String, dynamic>.from(p));
      }
      return {'total_verse': total, 'historique': hist};
    } catch (e) {
      return {'total_verse': 0.0, 'historique': []};
    }
  }

  Future<String?> envoyerReclamation({
    required dynamic residentUserId,
    required String titre,
    required String description,
    dynamic fichier,
    String? nomFichier,
  }) async {
    try {
      final res = await _db
          .from('residents')
          .select('appartement_id')
          .eq('user_id', residentUserId)
          .maybeSingle();
      dynamic trancheId;
      if (res != null && res['appartement_id'] != null) {
        final app = await _db
            .from('appartements')
            .select('immeuble_id')
            .eq('id', res['appartement_id'])
            .maybeSingle();
        final imm = app != null
            ? await _db
            .from('immeubles')
            .select('tranche_id')
            .eq('id', app['immeuble_id'])
            .maybeSingle()
            : null;
        trancheId = imm?['tranche_id'];
      }
      String? documentPath;
      if (fichier != null && nomFichier != null) {
        final String extension = nomFichier.split('.').last;
        final String safeName =
            '${DateTime.now().millisecondsSinceEpoch}.$extension';
        final String path = 'reclamations/$residentUserId/$safeName';
        await _db.storage.from('reclamations').uploadBinary(
          path,
          fichier as Uint8List,
          fileOptions: const FileOptions(upsert: true),
        );
        documentPath = path;
      }
      await _db.from('reclamations').insert({
        'titre': titre,
        'description': description,
        'resident_id': residentUserId,
        'tranche_id': trancheId,
        'statut': 'en_cours',
        'document_path': documentPath,
      });
      return null;
    } catch (e) {
      debugPrint('Erreur envoi reclamation: $e');
      return e.toString();
    }
  }

  Future<List<Map<String, dynamic>>> getMesReclamations(
      dynamic residentUserId) async {
    try {
      final res = await _db
          .from('reclamations')
          .select()
          .eq('resident_id', residentUserId)
          .order('created_at', ascending: false);
      final List list = res as List? ?? [];
      return list.map((r) {
        final map = Map<String, dynamic>.from(r);
        if (map['document_path'] != null) {
          map['document_url'] = _db.storage
              .from('reclamations')
              .getPublicUrl(map['document_path']);
        }
        return map;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Map<String, dynamic> _err(String msg) => {
    'error': msg,
    'resident': {
      'num_appart': '-',
      'immeuble_nom': '-',
      'tranche_nom': '-',
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