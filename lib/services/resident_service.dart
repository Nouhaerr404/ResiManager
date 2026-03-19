import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resident_model.dart';
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
      final userIds = residents.map((r) => r['user_id']).toList();
      final usersRes = await _db.from('users').select('id, nom, prenom, email, telephone').inFilter('id', userIds);
      final List users = usersRes as List? ?? [];
      final paiementsRes = await _db.from('paiements').select('id, appartement_id, montant_total, montant_paye, statut, date_paiement').inFilter('appartement_id', appartementIds);
      final List paiements = paiementsRes as List? ?? [];
      final List<ResidentModel> result = [];
      for (final r in residents) {
        final user = users.firstWhere((u) => u['id'] == r['user_id'], orElse: () => null);
        if (user == null) continue;
        final appart = appartements.firstWhere((a) => a['id'] == r['appartement_id'], orElse: () => null);
        final immeuble = appart != null ? immeubles.firstWhere((i) => i['id'] == appart['immeuble_id'], orElse: () => null) : null;
        final paiement = paiements.firstWhere((p) => p['appartement_id'] == r['appartement_id'], orElse: () => null);
        result.add(ResidentModel(
          id: r['id'] is int ? r['id'] : 0, 
          userId: r['user_id'] is int ? r['user_id'] : 0, 
          appartementId: r['appartement_id'] is int ? r['appartement_id'] : null,
          type: r['type'].toString(), statut: r['statut'].toString(),
          nom: user['nom']?.toString() ?? '', prenom: user['prenom']?.toString() ?? '',
          email: user['email']?.toString() ?? '', telephone: user['telephone']?.toString(),
          appartementNumero: appart?['numero']?.toString() ?? '', immeubleName: immeuble?['nom']?.toString() ?? '',
          paiementId: paiement != null ? paiement['id'] as int? : null,
          montantTotal: paiement != null ? double.parse(paiement['montant_total'].toString()) : 3000.0,
          montantPaye: paiement != null ? double.parse(paiement['montant_paye'].toString()) : 0.0,
          statutPaiement: paiement != null ? paiement['statut'].toString() : 'impaye',
          anneePaiement: DateTime.now().year,
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
      // 1. Créer dans Supabase Auth (pour mail)
      try {
        await _db.auth.signUp(email: email.trim(), password: 'changeme123');
      } on AuthException catch (_) {}

      // 2. Créer dans la table users (laisser l'ID auto-incrémenter bigint)
      final userRes = await _db.from('users').insert({
        'nom': nom.trim(), 'prenom': prenom.trim(), 'email': email.trim(),
        'telephone': telephone?.trim(), 'password': 'changeme123',
        'role': 'resident', 'statut': 'actif',
      }).select('id').single();

      final dynamic userId = userRes['id'];

      // 3. Lier au résident et appartement
      await _db.from('residents').insert({
        'user_id': userId, 'appartement_id': appartementId, 'type': type, 'statut': 'actif', 'date_arrivee': DateTime.now().toIso8601String().substring(0, 10),
      });
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

  Future<String?> updateResident({required dynamic userId, required String nom, required String prenom, String? telephone, required String type}) async {
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
      if (resData == null) return {'annonces': [], 'reunions': [], 'tranche_id': null};
      final appartData = await _db.from('appartements').select('immeuble_id').eq('id', resData['appartement_id']).maybeSingle();
      final immData = await _db.from('immeubles').select('tranche_id').eq('id', appartData?['immeuble_id']).maybeSingle();
      final dynamic trancheId = immData?['tranche_id'] ?? 0;
      final annonces = await _db.from('annonces').select().eq('tranche_id', trancheId).eq('statut', 'publiee');
      final reunions = await _db.from('reunions').select().eq('tranche_id', trancheId).order('date', ascending: true);
      return {'annonces': annonces as List? ?? [], 'reunions': reunions as List? ?? [], 'tranche_id': trancheId};
    } catch (e) { return {'annonces': [], 'reunions': [], 'tranche_id': null}; }
  }

  Future<Map<String, dynamic>> getTrancheExpensesDetailed(dynamic userId, int annee) async {
    try {
      final res = await _db.from('residents').select('appartement_id').eq('user_id', userId).maybeSingle();
      if (res == null || res['appartement_id'] == null) return {'depenses': [], 'total': 0.0};
      final app = await _db.from('appartements').select('immeuble_id').eq('id', res['appartement_id']).maybeSingle();
      if (app == null || app['immeuble_id'] == null) return {'depenses': [], 'total': 0.0};
      final imm = await _db.from('immeubles').select('tranche_id, nom').eq('id', app['immeuble_id']).maybeSingle();
      if (imm == null || imm['tranche_id'] == null) return {'depenses': [], 'total': 0.0};
      final dynamic trancheId = imm['tranche_id'];
      final response = await _db.from('depenses').select('*, categories(*)').eq('tranche_id', trancheId).eq('annee', annee).order('date', ascending: false);
      final List depenses = response as List? ?? [];
      double total = 0, payees = 0;
      for (var d in depenses) {
        double m = double.tryParse(d['montant'].toString()) ?? 0.0;
        total += m;
        if (d['facture_path'] != null) payees += m;
      }
      return {'tranche_nom': imm['nom'] ?? "Tranche", 'depenses': depenses, 'total': total, 'payees': payees, 'attente': total - payees};
    } catch (e) { return {'depenses': [], 'total': 0.0}; }
  }

  Future<Map<String, dynamic>> getResidentDashboardData(dynamic userId) async {
    try {
      final userRow = await _db.from('users').select('nom, prenom').eq('id', userId).maybeSingle();
      final resRow = await _db.from('residents').select('id, appartements ( id, numero, immeubles ( id, nom, tranches ( id, nom ) ) )').eq('user_id', userId).maybeSingle();
      if (resRow == null) return {'nom': userRow?['nom'] ?? '—', 'prenom': userRow?['prenom'] ?? '—', 'num_appart': '—', 'solde_du': 0.0, 'nb_annonces': 0, 'nb_reunions': 0, 'nb_reclamations_ouvertes': 0, 'notifications_non_lues': 0};
      final appart = resRow['appartements'] as Map?;
      final imm = appart?['immeubles'] as Map?;
      final tranche = imm?['tranches'] as Map?;
      final dynamic appartId = appart?['id'];
      final dynamic trancheId = tranche?['id'];
      double soldeDu = 0.0;
      if (appartId != null) {
        final pais = await _db.from('paiements').select('montant_total, montant_paye').eq('appartement_id', appartId).inFilter('statut', ['impaye', 'partiel']);
        final List list = pais as List? ?? [];
        for (final p in list) { soldeDu += ((p['montant_total'] as num) - (p['montant_paye'] as num)).toDouble(); }
      }
      final rec = await _db.from('reclamations').select('id').eq('resident_id', userId).eq('statut', 'en_cours');
      final nots = await _db.from('notifications').select('id').eq('user_id', userId).eq('lu', false);
      return {'nom': userRow?['nom'] ?? '—', 'prenom': userRow?['prenom'] ?? '—', 'num_appart': appart?['numero'] ?? '—', 'immeuble_nom': imm?['nom'] ?? '—', 'tranche_nom': tranche?['nom'] ?? '—', 'solde_du': soldeDu, 'nb_annonces': 0, 'nb_reunions': 0, 'nb_reclamations_ouvertes': (rec as List? ?? []).length, 'notifications_non_lues': (nots as List? ?? []).length};
    } catch (e) { return {}; }
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

        await _db.storage.from('reclamations').uploadBinary(
          path, 
          fichier as Uint8List,
          fileOptions: const FileOptions(upsert: true)
        );
        documentPath = path;
      }

      await _db.from('reclamations').insert({
        'titre': titre, 
        'description': description, 
        'resident_id': residentUserId, 
        'tranche_id': trancheId,
        'statut': 'en_cours', 
        'document_path': documentPath
      });
      return null;
    } catch (e) { 
      print("Erreur envoi reclamation: $e");
      return e.toString(); 
    }
  }

  Future<List<Map<String, dynamic>>> getMesReclamations(dynamic residentUserId) async {
    try {
      final res = await _db.from('reclamations').select().eq('resident_id', residentUserId).order('created_at', ascending: false);
      final List list = res as List? ?? [];
      
      return list.map((r) {
        final map = Map<String, dynamic>.from(r);
        if (map['document_path'] != null) {
          map['document_url'] = _db.storage.from('reclamations').getPublicUrl(map['document_path']);
        }
        return map;
      }).toList();
    } catch (e) { return []; }
  }

  Map<String, dynamic> _err(String msg) => {
    'error': msg, 'resident': {'num_appart': '—', 'immeuble_nom': '—', 'tranche_nom': '—', 'nb_apparts': 1},
    'charges': <Map>[], 'solde': {'total_annee': 0.0, 'paye_annee': 0.0, 'reste_annee': 0.0, 'nb_impaye': 0, 'nb_partiel': 0},
  };
}
