import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resident_model.dart';
import '../models/paiement_model.dart';
import 'dart:typed_data';

class ResidentService {
  final _db = Supabase.instance.client;

  // ═══════════════════════════════════════════════════════════════════
  // SECTION ADMIN
  // ═══════════════════════════════════════════════════════════════════

  Future<List<ResidentModel>> getResidentsByTranche(dynamic trancheId) async {
    try {
      final immeublesRes = await _db.from('immeubles').select('id, nom, tranche_id').eq('tranche_id', trancheId);
      final List immeubles = immeublesRes as List? ?? [];
      if (immeubles.isEmpty) return [];
      final immeubleIds = immeubles.map((i) => i['id']).toList();
      final appartementsRes = await _db.from('appartements').select('id, numero, immeuble_id, statut').inFilter('immeuble_id', immeubleIds);
      final List appartements = appartementsRes as List? ?? [];
      if (appartements.isEmpty) return [];
      final appartementIds = appartements.map((a) => a['id']).toList();
      final residentsRes = await _db.from('residents').select('id, user_id, appartement_id, type, statut').inFilter('appartement_id', appartementIds);
      final List residents = residentsRes as List? ?? [];
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
          'id, appartement_id, montant_total, montant_paye, statut, date_paiement, type_paiement')
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

        // On filtre TOUS les paiements de ce résident
        final residentPaiements = paiements.where(
              (p) => p['appartement_id'] == r['appartement_id'],
        ).toList();

        double totalM = 0;
        double payeM = 0;
        bool hasImpaye = false;
        bool hasPartiel = false;
        int? mainPaiementId;

        if (residentPaiements.isNotEmpty) {
          for (final p in residentPaiements) {
            totalM += double.parse((p['montant_total'] ?? 0).toString());
            payeM += double.parse((p['montant_paye'] ?? 0).toString());
            if (p['statut'] == 'impaye') hasImpaye = true;
            if (p['statut'] == 'partiel') hasPartiel = true;
            
            // On considère les "charges" comme le paiement principal par défaut
            if (p['type_paiement'] == 'charges') {
              mainPaiementId = p['id'] as int;
            }
          }
          // Si pas de charges, on prend n'importe quel ID pour le paiement par défaut
          mainPaiementId ??= residentPaiements.first['id'] as int;
        }

        // Calcul du statut global
        String globalStatut = 'complet';
        if (hasImpaye) {
          globalStatut = payeM > 0 ? 'partiel' : 'impaye';
        } else if (hasPartiel) {
          globalStatut = 'partiel';
        }

        print('>>> ${user['prenom']} ${user['nom']}: globalStatut=$globalStatut, total=$totalM');

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
          paiementId: mainPaiementId,
          montantTotal: residentPaiements.isNotEmpty ? totalM : 3000.0,
          montantPaye: payeM,
          statutPaiement: residentPaiements.isNotEmpty ? globalStatut : 'impaye',
          anneePaiement: DateTime.now().year,
          paiements: residentPaiements.map((p) => PaiementModel(
            id: p['id'],
            residentId: r['user_id'],
            appartementId: r['appartement_id'],
            depenseId: 0,
            interSyndicId: 0,
            residenceId: immeuble['residence_id'] ?? 0,
            montantTotal: double.parse((p['montant_total'] ?? 0).toString()),
            montantPaye: double.parse((p['montant_paye'] ?? 0).toString()),
            typePaiement: TypePaiementEnum.values.firstWhere(
                  (e) => e.name == (p['type_paiement'] ?? 'charges'),
              orElse: () => TypePaiementEnum.charges,
            ),
            statut: StatutPaiementEnum.values.firstWhere(
                  (e) => e.name == (p['statut'] ?? 'impaye'),
              orElse: () => StatutPaiementEnum.impaye,
            ),
            annee: DateTime.now().year,
          )).toList(),
        ));
      }
      return result;
    } catch (e) { return []; }
  }

  Future<List<ResidentModel>> searchResidents(String query) async {
    if (query.isEmpty) return [];
    try {
      final q = query.toLowerCase().trim();
      final usersRes = await _db.from('users').select('id, nom, prenom, email, telephone').or('nom.ilike.%$q%,prenom.ilike.%$q%,email.ilike.%$q%').limit(10);
      final List users = usersRes as List? ?? [];
      if (users.isEmpty) return [];
      final userIds = users.map((u) => u['id']).toList();
      final residentsRes = await _db.from('residents').select('id, user_id, appartement_id, type, statut').inFilter('user_id', userIds);
      final List residents = residentsRes as List? ?? [];
      if (residents.isEmpty) return [];
      final List<ResidentModel> result = [];
      for (final r in residents) {
        final user = users.firstWhere((u) => u['id'] == r['user_id'], orElse: () => null);
        if (user == null) continue;
        result.add(ResidentModel(
          id: r['id'] is int ? r['id'] : 0, userId: r['user_id'] is int ? r['user_id'] : 0, appartementId: r['appartement_id'] is int ? r['appartement_id'] : null,
          type: r['type'].toString(), statut: r['statut'].toString(),
          nom: user['nom']?.toString() ?? '', prenom: user['prenom']?.toString() ?? '',
          email: user['email']?.toString() ?? '', telephone: user['telephone']?.toString(),
          montantTotal: 0, montantPaye: 0, statutPaiement: '—', anneePaiement: DateTime.now().year,
        ));
      }
      return result;
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> getAppartementsLibres(dynamic trancheId) async {
    try {
      final immeublesRes = await _db.from('immeubles').select('id, nom').eq('tranche_id', trancheId);
      final List immeubles = immeublesRes as List? ?? [];
      final immeubleIds = immeubles.map((i) => i['id']).toList();
      if (immeubleIds.isEmpty) return [];
      final res = await _db.from('appartements').select('id, numero, immeuble_id, immeubles(nom)').inFilter('immeuble_id', immeubleIds).eq('statut', 'libre');
      final List list = res as List? ?? [];
      return list.map((a) => { 'id': a['id'], 'numero': a['numero'], 'label': '${a['immeubles']?['nom'] ?? ''} • App. ${a['numero']}', }).toList();
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> getHistoriquePaiements(dynamic residentUserId) async {
    try {
      final res = await _db.from('historique_paiements').select('id, montant, date, description, type').eq('resident_id', residentUserId).order('date', ascending: false);
      final List list = res as List? ?? [];
      return list.map((h) => Map<String, dynamic>.from(h)).toList();
    } catch (e) { return []; }
  }

  Future<String?> addResident({required String nom, required String prenom, required String email, String? telephone, required String type, required dynamic trancheId, required dynamic appartementId, required double montantTotal}) async {
    try {
      try { await _db.auth.signUp(email: email.trim(), password: 'changeme123'); } on AuthException catch (_) {}
      final userRes = await _db.from('users').insert({ 'nom': nom.trim(), 'prenom': prenom.trim(), 'email': email.trim(), 'telephone': telephone?.trim(), 'password': 'changeme123', 'role': 'resident', 'statut': 'actif', }).select('id').single();
      final dynamic userId = userRes['id'];
      await _db.from('residents').insert({ 'user_id': userId, 'appartement_id': appartementId, 'type': type, 'statut': 'actif', 'date_arrivee': DateTime.now().toIso8601String().substring(0, 10), });
      await _db.from('appartements').update({'statut': 'occupe', 'resident_id': userId}).eq('id', appartementId);
      await _db.from('paiements').insert({ 'appartement_id': appartementId, 'depense_id': 1, 'inter_syndic_id': 1, 'montant_total': montantTotal, 'montant_paye': 0, 'type_paiement': 'charges', 'statut': 'impaye', 'annee': DateTime.now().year, });
      return null;
    } catch (e) { return e.toString(); }
  }

  Future<String?> enregistrerPaiement({required dynamic paiementId, required dynamic residentUserId, required double montantAjoute, required double montantDejaPane, required double montantTotal}) async {
    try {
      final nouveauMontant = montantDejaPane + montantAjoute;
      String statut = nouveauMontant >= montantTotal ? 'complet' : (nouveauMontant > 0 ? 'partiel' : 'impaye');
      await _db.from('paiements').update({'montant_paye': nouveauMontant, 'statut': statut, 'date_paiement': DateTime.now().toIso8601String().substring(0, 10)}).eq('id', paiementId);
      await _db.from('historique_paiements').insert({'resident_id': residentUserId, 'paiement_id': paiementId, 'montant': montantAjoute, 'date': DateTime.now().toIso8601String().substring(0, 10), 'type': 'charges', 'description': 'Paiement charges ${DateTime.now().year}'});
      return null;
    } catch (e) { return e.toString(); }
  }

  // ─────────────────────────────────────────
  // CRÉER un paiement de ressource (Box, Parking, Garage)
  // ─────────────────────────────────────────
  Future<void> createResourcePayment({
    required int residentId,
    required int trancheId,
    required int residenceId,
    required double montant,
    required String type,
  }) async {
    try {
      // 1. Récupérer l'appartement_id du résident
      final resData = await _db
          .from('residents')
          .select('appartement_id')
          .eq('user_id', residentId)
          .maybeSingle();
      
      final int? appartId = resData?['appartement_id'];
      if (appartId == null) return;

      // 2. Récupérer l'inter_syndic_id de la tranche
      final trancheData = await _db
          .from('tranches')
          .select('inter_syndic_id')
          .eq('id', trancheId)
          .maybeSingle();
      
      final int isId = trancheData?['inter_syndic_id'] ?? 1;

      // 3. Insérer le paiement
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
      print('>>> Paiement ressource créé: $type, $montant DH');
    } catch (e) {
      print('>>> ERREUR createResourcePayment: $e');
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
      await _db.from('users').update({'nom': nom.trim(), 'prenom': prenom.trim(), 'telephone': telephone?.trim()}).eq('id', userId);
      await _db.from('residents').update({'type': type}).eq('user_id', userId);
      return null;
    } catch (e) { return e.toString(); }
  }

  Future<String?> deleteResident(dynamic userId, dynamic appartementId) async {
    try {
      if (appartementId != null) {
        await _db.from('appartements').update({'statut': 'libre', 'resident_id': null}).eq('id', appartementId);
        await _db.from('paiements').delete().eq('appartement_id', appartementId);
      }
      await _db.from('historique_paiements').delete().eq('resident_id', userId);
      await _db.from('residents').delete().eq('user_id', userId);
      await _db.from('users').delete().eq('id', userId);
      return null;
    } catch (e) { return e.toString(); }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION RÉSIDENT
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getChargesData(dynamic userId, int annee) async {
    try {
      final resRow = await _db.from('residents').select('id, appartements ( id, numero, immeubles ( id, nom, nombre_appartements, tranches ( id, nom ) ) )').eq('user_id', userId).maybeSingle();
      if (resRow == null) return _err('Profil introuvable');
      final appart = resRow['appartements'] as Map<String, dynamic>?;
      final imm = appart?['immeubles'] as Map<String, dynamic>?;
      final tranche = imm?['tranches'] as Map<String, dynamic>?;
      if (appart == null || imm == null || tranche == null) return _err('Données incomplètes');
      final dynamic appartId = appart['id'];
      final dynamic trancheId = tranche['id'];
      final int nbApparts = (imm['nombre_appartements'] as int?) ?? 1;
      final depRows = await _db.from('depenses').select('id, montant, date, mois, annee, facture_path, categories ( id, nom, type )').eq('tranche_id', trancheId).eq('annee', annee).order('mois', ascending: true);
      final List list = depRows as List? ?? [];
      final List<Map<String, dynamic>> charges = [];
      for (final d in list) {
        final total = (d['montant'] as num?)?.toDouble() ?? 0.0;
        final part = nbApparts > 0 ? total / nbApparts : 0.0;
        charges.add({
          'depense_id': d['id'], 'categorie': d['categories']?['nom'] ?? 'Divers', 'type': d['categories']?['type'] ?? 'individuelle',
          'mois': d['mois'], 'date': d['date'], 'montant_tranche': total, 'nb_apparts': nbApparts, 'votre_part': part,
          'montant_paye': 0.0, 'montant_reste': part, 'statut': 'impaye', 'facture_path': d['facture_path'],
        });
      }
      return {'resident': {'num_appart': appart['numero'], 'immeuble_nom': imm['nom'], 'tranche_nom': tranche['nom'], 'nb_apparts': nbApparts}, 'charges': charges, 'solde': {'total_annee': 0.0, 'paye_annee': 0.0, 'reste_annee': 0.0, 'nb_impaye': 0, 'nb_partiel': 0}};
    } catch (e) { return _err(e.toString()); }
  }

  Future<Map<String, dynamic>> getAnnoncesAndReunions(dynamic userId) async {
    try {
      final resData = await _db.from('residents').select('appartement_id').eq('user_id', userId).maybeSingle();
      if (resData == null || resData['appartement_id'] == null) return {'annonces': [], 'reunions': [], 'tranche_id': null};
      final appartData = await _db.from('appartements').select('immeuble_id').eq('id', resData['appartement_id']).maybeSingle();
      final immData = await _db.from('immeubles').select('tranche_id').eq('id', appartData?['immeuble_id']).maybeSingle();
      final dynamic trancheId = immData?['tranche_id'];
      if (trancheId == null) return {'annonces': [], 'reunions': [], 'tranche_id': null};
      final annonces = await _db.from('annonces').select().eq('tranche_id', trancheId).eq('statut', 'publiee');
      final reunions = await _db.from('reunions').select().eq('tranche_id', trancheId).order('date', ascending: true);
      return {'annonces': annonces as List? ?? [], 'reunions': reunions as List? ?? [], 'tranche_id': trancheId};
    } catch (e) { return {'annonces': [], 'reunions': [], 'tranche_id': null}; }
  }

  Future<Map<String, dynamic>> getTrancheExpensesDetailed(dynamic userId, int annee) async {
    try {
      print("=== DEBUG userId: $userId, annee: $annee ===");

      final resData = await _db.from('residents').select('appartement_id').eq('user_id', userId).maybeSingle();
      print("=== resData: $resData ===");
      if (resData == null || resData['appartement_id'] == null) return {'depenses': [], 'total': 0.0};

      final appart = await _db.from('appartements').select('immeuble_id').eq('id', resData['appartement_id']).maybeSingle();
      print("=== appart: $appart ===");

      final immeuble = await _db.from('immeubles').select('tranche_id').eq('id', appart?['immeuble_id']).maybeSingle();
      print("=== immeuble: $immeuble ===");

      final dynamic trancheId = immeuble?['tranche_id'];
      print("=== trancheId: $trancheId ===");

      final tranche = await _db.from('tranches').select('residence_id, nom').eq('id', trancheId).maybeSingle();
      print("=== tranche: $tranche ===");

      final dynamic residenceId = tranche?['residence_id'];
      print("=== residenceId: $residenceId ===");

      final countRes = await _db.from('tranches').select('id').eq('residence_id', residenceId);
      final int nbTranches = (countRes as List).length;
      print("=== nbTranches: $nbTranches ===");

      final resTranche = await _db.from('depenses').select('*, categories(*)').eq('tranche_id', trancheId).eq('annee', annee);
      final List depsTranche = resTranche as List? ?? [];
      print("=== depsTranche count: ${depsTranche.length} ===");

      final resResidence = await _db
          .from('depenses')
          .select('*, categories(*)')
          .eq('residence_id', residenceId)
          .eq('annee', annee)
          .isFilter('tranche_id', null);
      final List depsResidence = resResidence as List? ?? [];
      print("=== depsResidence count: ${depsResidence.length} ===");

      final List allDeps = [...depsTranche, ...depsResidence];
      print("=== allDeps total: ${allDeps.length} ===");

      final List<Map<String, dynamic>> processedDeps = [];
      double totalResident = 0;
      double payeesResident = 0;

      for (var d in allDeps) {
        double montantSaisi = (d['montant'] as num?)?.toDouble() ?? 0.0;
        String typeCat = d['categories']?['type']?.toString().toLowerCase() ?? 'individuelle';

        double montantFinal;
        if (typeCat == 'globale') {
          montantFinal = montantSaisi / nbTranches;
        } else {
          montantFinal = montantSaisi;
        }

        processedDeps.add({
          ...Map<String, dynamic>.from(d),
          'montant': montantFinal.toStringAsFixed(2),
          'montant_original': montantSaisi,
          'type_affichage': typeCat == 'globale' ? 'Commune' : 'Individuelle'
        });

        totalResident += montantFinal;
        if (d['facture_path'] != null) payeesResident += montantFinal;
      }

      return {
        'tranche_nom': tranche?['nom'] ?? "Ma Tranche",
        'depenses': processedDeps,
        'total': totalResident,
        'payees': payeesResident,
        'attente': totalResident - payeesResident,
      };
    } catch (e) {
      print("=== ERREUR: $e ===");
      return {'depenses': [], 'total': 0.0};
    }
  }
  Future<Map<String, dynamic>> getResidentDashboardData(dynamic userId) async {
    try {
      final userRow = await _db.from('users').select('nom, prenom').eq('id', userId).maybeSingle();
      final resData = await _db.from('residents').select('appartement_id').eq('user_id', userId).maybeSingle();
      dynamic trancheId;
      dynamic appartNumero = '—';
      dynamic immeubleNom = '—';
      dynamic trancheNom = '—';
      dynamic appartId;
      if (resData != null && resData['appartement_id'] != null) {
        appartId = resData['appartement_id'];
        final appart = await _db.from('appartements').select('numero, immeuble_id, immeubles(nom, tranche_id, tranches(nom))').eq('id', appartId).maybeSingle();
        if (appart != null) {
          appartNumero = appart['numero']?.toString() ?? '—';
          final imm = appart['immeubles'];
          if (imm != null) {
            immeubleNom = imm['nom']?.toString() ?? '—';
            trancheId = imm['tranche_id'];
            if (imm['tranches'] != null) { trancheNom = imm['tranches']['nom']?.toString() ?? '—'; }
          }
        }
      }
      double soldeDu = 0.0;
      if (appartId != null) {
        final pais = await _db.from('paiements').select('montant_total, montant_paye').eq('appartement_id', appartId).inFilter('statut', ['impaye', 'partiel']);
        final List list = pais as List? ?? [];
        for (final p in list) { soldeDu += ((p['montant_total'] as num) - (p['montant_paye'] as num)).toDouble(); }
      }
      int nbAnn = 0, nbReu = 0;
      if (trancheId != null) {
        final a = await _db.from('annonces').select('id').eq('tranche_id', trancheId).eq('statut', 'publiee');
        nbAnn = (a as List? ?? []).length;
        final r = await _db.from('reunions').select('id').eq('tranche_id', trancheId).inFilter('statut', ['planifiee', 'confirmee']);
        nbReu = (r as List? ?? []).length;
      }
      final rec = await _db.from('reclamations').select('id').eq('resident_id', userId).eq('statut', 'en_cours');
      final nots = await _db.from('notifications').select('id').eq('user_id', userId).eq('lu', false);
      return { 'nom': userRow?['nom'] ?? '—', 'prenom': userRow?['prenom'] ?? '—', 'num_appart': appartNumero, 'immeuble_nom': immeubleNom, 'tranche_nom': trancheNom, 'solde_du': soldeDu, 'nb_annonces': nbAnn, 'nb_reunions': nbReu, 'nb_reclamations_ouvertes': (rec as List? ?? []).length, 'notifications_non_lues': (nots as List? ?? []).length };
    } catch (e) { print("Erreur getDashboard: $e"); return {}; }
  }

  Future<Map<String, dynamic>> getPaiementOverview(dynamic userId, int annee) async {
    try {
      final resRow = await _db.from('residents').select('id, appartements(id, numero, immeubles(id, nom, tranches(id, nom)))').eq('user_id', userId).maybeSingle();
      if (resRow == null) return {'num_appart': '—', 'total_annee': 0.0, 'paye_annee': 0.0, 'reste_annee': 0.0, 'statut': 'impaye'};
      final dynamic appartId = resRow['appartements']?['id'];
      final paiements = await _db.from('paiements').select('montant_total, montant_paye, statut').eq('appartement_id', appartId).eq('annee', annee);
      double total = 0, paye = 0;
      if (paiements is List) { for (var p in paiements) { total += (p['montant_total'] as num).toDouble(); paye += (p['montant_paye'] as num).toDouble(); } }
      return {'num_appart': resRow['appartements']['numero'], 'immeuble_nom': resRow['appartements']['immeubles']['nom'], 'tranche_nom': resRow['appartements']['immeubles']['tranches']['nom'], 'total_annee': total, 'paye_annee': paye, 'reste_annee': total - paye, 'statut': paye >= total ? 'complet' : (paye > 0 ? 'partiel' : 'impaye')};
    } catch (e) { return {'total_annee': 0.0}; }
  }

  Future<Map<String, dynamic>> getHistoriquePaiementsComplet(dynamic userId) async {
    try {
      final resRow = await _db.from('residents').select('appartement_id').eq('user_id', userId).maybeSingle();
      final dynamic appartId = resRow?['appartement_id'];
      if (appartId == null) return {'total_verse': 0.0, 'historique': []};
      final paiements = await _db.from('paiements').select().eq('appartement_id', appartId).order('date_paiement', ascending: false);
      double total = 0;
      List<Map<String, dynamic>> hist = [];
      if (paiements is List) { for (var p in paiements) { total += (p['montant_paye'] as num).toDouble(); hist.add(Map<String, dynamic>.from(p)); } }
      return {'total_verse': total, 'historique': hist};
    } catch (e) { return {'total_verse': 0.0, 'historique': []}; }
  }

  Future<String?> envoyerReclamation({required dynamic residentUserId, required String titre, required String description, dynamic fichier, String? nomFichier}) async {
    try {
      final res = await _db.from('residents').select('appartement_id').eq('user_id', residentUserId).maybeSingle();
      dynamic trancheId;
      if (res != null && res['appartement_id'] != null) {
        final app = await _db.from('appartements').select('immeuble_id').eq('id', res['appartement_id']).maybeSingle();
        final imm = app != null ? await _db.from('immeubles').select('tranche_id').eq('id', app['immeuble_id']).maybeSingle() : null;
        trancheId = imm?['tranche_id'];
      }
      String? documentPath;
      if (fichier != null && nomFichier != null) {
        final String extension = nomFichier.split('.').last;
        final String safeName = "${DateTime.now().millisecondsSinceEpoch}.$extension";
        final String path = 'reclamations/$residentUserId/$safeName';
        await _db.storage.from('reclamations').uploadBinary(path, fichier as Uint8List, fileOptions: const FileOptions(upsert: true));
        documentPath = path;
      }
      await _db.from('reclamations').insert({ 'titre': titre, 'description': description, 'resident_id': residentUserId, 'tranche_id': trancheId, 'statut': 'en_cours', 'document_path': documentPath });
      return null;
    } catch (e) { print("Erreur envoi reclamation: $e"); return e.toString(); }
  }

  Future<List<Map<String, dynamic>>> getMesReclamations(dynamic residentUserId) async {
    try {
      final res = await _db.from('reclamations').select().eq('resident_id', residentUserId).order('created_at', ascending: false);
      final List list = res as List? ?? [];
      return list.map((r) {
        final map = Map<String, dynamic>.from(r);
        if (map['document_path'] != null) { map['document_url'] = _db.storage.from('reclamations').getPublicUrl(map['document_path']); }
        return map;
      }).toList();
    } catch (e) { return []; }
  }

  Map<String, dynamic> _err(String msg) => {
    'error': msg, 'resident': {'num_appart': '—', 'immeuble_nom': '—', 'tranche_nom': '—', 'nb_apparts': 1},
    'charges': <Map>[], 'solde': {'total_annee': 0.0, 'paye_annee': 0.0, 'reste_annee': 0.0, 'nb_impaye': 0, 'nb_partiel': 0},
  };
}
