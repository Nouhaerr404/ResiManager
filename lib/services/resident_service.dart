// ignore_for_file: avoid_multiple_underscores_for_members
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resident_model.dart';
import '../models/paiement_model.dart';
import 'parking_service.dart';
import 'box_service.dart';
import 'garage_service.dart';
import 'dart:typed_data';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResidentService {
  final _db = Supabase.instance.client;

  // ═══════════════════════════════════════════════════════════════════
  // UTILITAIRE : Génération mot de passe aléatoire
  // ═══════════════════════════════════════════════════════════════════

  String _generatePassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    final rng = Random.secure();
    return List.generate(10, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // ═══════════════════════════════════════════════════════════════════
  // UTILITAIRE : Hachage mot de passe — même logique que SyndicCollaboratorService
  // ═══════════════════════════════════════════════════════════════════

  Future<String> _hashPassword(String password) async {
    try {
      final result = await _db.rpc('crypt', params: {'password': password, 'salt': 'bf'});
      return result;
    } catch (e) {
      return password;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // UTILITAIRE : Envoi email via Resend API
  // ═══════════════════════════════════════════════════════════════════

  Future<bool> _sendWelcomeEmail({
    required String toEmail,
    required String prenom,
    required String nom,
    required String password,
    required String residenceName,
    required String trancheName,
  }) async {
    try {
      // Remplacez par votre clé API Resend
      const resendApiKey = 'YOUR_RESEND_API_KEY';
      const fromEmail = 'noreply@yourdomain.com'; // Remplacez par votre domaine vérifié sur Resend

      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $resendApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': fromEmail,
          'to': [toEmail],
          'subject': 'Bienvenue sur ResiManager - Vos identifiants de connexion',
          'html': '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; background: #F5F6F8; margin: 0; padding: 0; }
    .container { max-width: 560px; margin: 40px auto; background: #fff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.08); }
    .header { background: #D86233; padding: 32px 24px; text-align: center; }
    .header h1 { color: #fff; margin: 0; font-size: 24px; font-weight: 800; letter-spacing: -0.5px; }
    .header p { color: rgba(255,255,255,0.8); margin: 6px 0 0; font-size: 14px; }
    .body { padding: 32px 24px; }
    .greeting { font-size: 16px; color: #111827; font-weight: 700; margin-bottom: 12px; }
    .text { font-size: 14px; color: #6B7280; line-height: 1.6; margin-bottom: 20px; }
    .credentials-box { background: #FDF1E6; border: 1.5px solid #FAD CC2; border-radius: 12px; padding: 20px 24px; margin: 20px 0; }
    .cred-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
    .cred-row:last-child { margin-bottom: 0; }
    .cred-label { font-size: 12px; color: #9CA3AF; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; }
    .cred-value { font-size: 14px; color: #111827; font-weight: 700; background: #fff; padding: 6px 12px; border-radius: 8px; border: 1px solid #E5E7EB; }
    .info-box { background: #EFF6FF; border: 1px solid #BFDBFE; border-radius: 10px; padding: 14px 16px; margin: 16px 0; }
    .info-box p { margin: 0; font-size: 13px; color: #3B82F6; }
    .footer { background: #F9FAFB; padding: 20px 24px; text-align: center; border-top: 1px solid #E5E7EB; }
    .footer p { margin: 0; font-size: 12px; color: #9CA3AF; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🏠 ResiManager</h1>
      <p>Votre espace résident est prêt</p>
    </div>
    <div class="body">
      <p class="greeting">Bonjour $prenom $nom,</p>
      <p class="text">
        Vous avez été enregistré(e) en tant que résident(e) de <strong>$residenceName</strong> 
        (tranche <strong>$trancheName</strong>). Voici vos identifiants pour accéder à votre espace personnel.
      </p>
      <div class="credentials-box">
        <div class="cred-row">
          <span class="cred-label">📧 Email</span>
          <span class="cred-value">$toEmail</span>
        </div>
        <div class="cred-row">
          <span class="cred-label">🔑 Mot de passe</span>
          <span class="cred-value">$password</span>
        </div>
      </div>
      <div class="info-box">
        <p>💡 Pour votre sécurité, nous vous recommandons de changer votre mot de passe dès votre première connexion.</p>
      </div>
      <p class="text">
        Depuis votre espace, vous pourrez consulter vos paiements, les annonces de votre résidence, 
        les réunions à venir, et soumettre vos réclamations.
      </p>
    </div>
    <div class="footer">
      <p>ResiManager · Gestion de résidence intelligente</p>
      <p style="margin-top: 4px;">Si vous n'êtes pas concerné(e), ignorez cet email.</p>
    </div>
  </div>
</body>
</html>
          ''',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('>>> Email envoyé avec succès à $toEmail');
        return true;
      } else {
        debugPrint('>>> Erreur Resend [${response.statusCode}]: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('>>> ERREUR envoi email: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // UTILITAIRE : Vérification droits inter-syndic sur le mandat
  // ═══════════════════════════════════════════════════════════════════

  Future<bool> isMandatOwnedByInterSyndic({
    required int mandatId,
    required int interSyndicId,
  }) async {
    try {
      final res = await _db
          .from('historique_affectations')
          .select('id')
          .eq('id', mandatId)
          .eq('inter_syndic_id', interSyndicId)
          .maybeSingle();
      return res != null;
    } catch (e) {
      debugPrint('>>> ERREUR isMandatOwnedByInterSyndic: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // GET RESIDENTS BY TRANCHE — filtré par mandat_id
  // ═══════════════════════════════════════════════════════════════════

  /// [mandatId] : si fourni, filtre les paiements par mandat.
  /// Si null, charge tous les paiements de la tranche (vue lecture seule historique).
  Future<List<ResidentModel>> getResidentsByTranche(
      dynamic trancheId, {
        int? annee,
        int? mandatId,
      }) async {
    final int anneeFiltre = annee ?? DateTime.now().year;
    try {
      final trancheRes = await _db
          .from('tranches')
          .select('prix_annuel')
          .eq('id', trancheId)
          .maybeSingle();
      final rawPrix = trancheRes?['prix_annuel'] ?? 0;
      final double tranchePrixAnnuel =
          double.tryParse(rawPrix.toString()) ?? 0.0;

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
          .or(
          'appartement_id.in.(${appartementIds.join(",")}),appartement_id.is.null');
      final List residents = residentsRes as List? ?? [];
      if (residents.isEmpty) return [];

      final userIds = residents.map((r) => r['user_id'] as int).toList();
      final usersRes = await _db
          .from('users')
          .select('id, nom, prenom, email, telephone')
          .inFilter('id', userIds);
      final users = usersRes as List;

      // ── Paiements filtrés par mandat si fourni, sinon par année
      var paiQuery = _db
          .from('paiements')
          .select(
          'id, appartement_id, resident_id, montant_total, montant_paye, statut, date_paiement, type_paiement, annee')
          .inFilter('appartement_id', appartementIds);

      if (mandatId != null) {
        // Filtrer par mandat spécifique
        paiQuery = paiQuery.eq('mandat_id', mandatId);
      } else {
        // Fallback : filtrer par année (vue historique sans mandat)
        paiQuery = paiQuery.eq('annee', anneeFiltre);
      }

      final paiementsRes = await paiQuery;
      final paiements = paiementsRes as List;

      // ── Récupérer numéros garage/parking/box
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
              benefToResident[b['id'].toString()] =
                  b['resident_id'].toString();
            }
          }

          final Map<String, List<Map<String, String>>> residentResources = {};
          for (final g in gRes as List? ?? []) {
            final resId =
            benefToResident[g['beneficiaire_id']?.toString()];
            if (resId != null && g['numero'] != null) {
              residentResources
                  .putIfAbsent(resId, () => [])
                  .add({'type': 'garage', 'numero': g['numero'].toString()});
            }
          }
          for (final pk in pkRes as List? ?? []) {
            final resId =
            benefToResident[pk['beneficiaire_id']?.toString()];
            if (resId != null && pk['numero'] != null) {
              residentResources
                  .putIfAbsent(resId, () => [])
                  .add(
                  {'type': 'parking', 'numero': pk['numero'].toString()});
            }
          }
          for (final bx in bxRes as List? ?? []) {
            final resId =
            benefToResident[bx['beneficiaire_id']?.toString()];
            if (resId != null && bx['numero'] != null) {
              residentResources
                  .putIfAbsent(resId, () => [])
                  .add({'type': 'box', 'numero': bx['numero'].toString()});
            }
          }

          final Map<String, Map<String, int>> typeCounters = {};
          for (final p in paiements) {
            final pType = p['type_paiement']?.toString() ?? '';
            final pResId = p['resident_id']?.toString();
            final pId = p['id']?.toString();
            if (pType == 'charges' || pResId == null || pId == null) continue;

            final resources = residentResources[pResId] ?? [];
            final typed =
            resources.where((r) => r['type'] == pType).toList();
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

        // Exclure les résidents sans paiement pour ce mandat/année
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
          anneePaiement: anneeFiltre,
          paiements: residentPaiements
              .map((p) {
            final type = p['type_paiement']?.toString() ?? 'charges';
            final pId = p['id']?.toString() ?? '';
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
          final residentTrancheId =
          r['appartements']?['immeubles']?['tranche_id'];
          if (residentTrancheId != trancheId) continue;
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
        '${a['immeubles']?['nom'] ?? ''} - App. ${a['numero']}'
      })
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // HISTORIQUE PAIEMENTS — filtré par mandat
  // ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getHistoriquePaiements(
      dynamic residentUserId, {
        int? mandatId,
      }) async {
    try {
      var query = _db
          .from('historique_paiements')
          .select(
          'id, montant, date, description, type, paiement_id, paiements(annee, type_paiement, mandat_id)')
          .eq('resident_id', residentUserId)
          .order('date', ascending: false);

      final List list = (await query) as List? ?? [];

      // Filtrer par mandat si spécifié
      final filtered = mandatId != null
          ? list.where((h) {
        final paiData = h['paiements'];
        final hMandatId = paiData?['mandat_id'];
        return hMandatId == mandatId;
      }).toList()
          : list;

      return filtered.map((h) {
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

  // ═══════════════════════════════════════════════════════════════════
  // ADD RESIDENT — avec envoi email automatique
  // ═══════════════════════════════════════════════════════════════════

  /// Retourne (erreur, emailEnvoyé)
  Future<(String?, bool)> addResident({
    required String nom,
    required String prenom,
    required String email,
    String? telephone,
    required String type,
    required dynamic trancheId,
    required dynamic appartementId,
    required double montantTotal,
    required int mandatId,
    required int interSyndicId,
    int? parkingId,
    int? boxId,
    int? garageId,
  }) async {
    bool emailSent = false;
    try {
      // ── 0. Vérification droits sur le mandat ─────────────────────
      final isOwner = await isMandatOwnedByInterSyndic(
        mandatId: mandatId,
        interSyndicId: interSyndicId,
      );
      if (!isOwner) {
        return (
        'Vous n\'êtes pas autorisé à ajouter un résident dans ce mandat.',
        false
        );
      }

      // ── 1. Infos tranche ──────────────────────────────────────────
      final trData = await _db
          .from('tranches')
          .select('residence_id, inter_syndic_id, prix_annuel, nom, residences(nom)')
          .eq('id', trancheId)
          .maybeSingle();
      final residenceId = trData?['residence_id'] ?? 1;
      final isId = trData?['inter_syndic_id'] ?? 1;
      final double tranchePrix =
          double.tryParse((trData?['prix_annuel'] ?? 0).toString()) ?? 0.0;
      final double montantEffectif =
      montantTotal > 0 ? montantTotal : tranchePrix;
      final String trancheName = trData?['nom']?.toString() ?? '';
      final String residenceName =
          trData?['residences']?['nom']?.toString() ?? '';

      // ── 2. Résident existant ou nouveau ? ────────────────────────
      final existingUser = await _db
          .from('users')
          .select('id')
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();

      dynamic userId;
      final bool isNewUser = existingUser == null;
      String generatedPassword = '';

      if (isNewUser) {
        // ── 2a. NOUVEAU résident ──────────────────────────────────
        generatedPassword = _generatePassword();
        debugPrint(
            '>>> Mot de passe généré pour ${email.trim()}: $generatedPassword');

        // ── Inscription Auth + envoi email — même logique que SyndicCollaboratorService ──
        // auth.signUp() avec data {temp_pass, nom, prenom} :
        // Supabase envoie automatiquement l'email de bienvenue via le template
        // configuré (Resend), qui inclut le mot de passe provisoire.
        try {
          await _db.auth.signUp(
            email: email.trim(),
            password: generatedPassword,
            data: {
              'temp_pass': generatedPassword,
              'nom': nom.trim(),
              'prenom': prenom.trim(),
            },
          );
          emailSent = true;
          debugPrint('>>> auth.signUp OK — email envoyé à ${email.trim()}');
        } catch (authError) {
          debugPrint('>>> AVERTISSEMENT auth.signUp (non bloquant): $authError');
          emailSent = false;
        }

        // Insérer dans users avec le même mot de passe
        final String hashedPassword = await _hashPassword(generatedPassword);
        final userRes = await _db
            .from('users')
            .insert({
          'nom': nom.trim(),
          'prenom': prenom.trim(),
          'email': email.trim().toLowerCase(),
          'telephone': telephone?.trim(),
          'password': hashedPassword,
          'role': 'resident',
          'statut': 'actif',
        })
            .select('id')
            .single();

        userId = userRes['id'];

        // Insérer dans residents
        await _db.from('residents').insert({
          'user_id': userId,
          'appartement_id': appartementId,
          'type': type,
          'statut': 'actif',
          'date_arrivee':
          DateTime.now().toIso8601String().substring(0, 10),
        });

        // Marquer l'appartement comme occupé
        await _db
            .from('appartements')
            .update({'statut': 'occupe', 'resident_id': userId}).eq(
            'id', appartementId);
      } else {
        // ── 2b. RÉSIDENT EXISTANT ─────────────────────────────────
        userId = existingUser['id'];

        await _db.from('users').update({
          'nom': nom.trim(),
          'prenom': prenom.trim(),
          'telephone': telephone?.trim(),
        }).eq('id', userId);

        final existingResident = await _db
            .from('residents')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();

        if (existingResident != null) {
          await _db.from('residents').update({
            'appartement_id': appartementId,
            'type': type,
            'statut': 'actif',
          }).eq('user_id', userId);
        } else {
          await _db.from('residents').insert({
            'user_id': userId,
            'appartement_id': appartementId,
            'type': type,
            'statut': 'actif',
            'date_arrivee':
            DateTime.now().toIso8601String().substring(0, 10),
          });
        }

        await _db
            .from('appartements')
            .update({'statut': 'occupe', 'resident_id': userId}).eq(
            'id', appartementId);
      }

      // ── 3. Créer paiement pour CE mandat avec montant_paye = 0 ───
      final existingPaiement = await _db
          .from('paiements')
          .select('id')
          .eq('appartement_id', appartementId)
          .eq('type_paiement', 'charges')
          .eq('mandat_id', mandatId)
          .maybeSingle();

      if (existingPaiement == null) {
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
          'mandat_id': mandatId,
        });
      }

      // ── 4. Ressources optionnelles ────────────────────────────────
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
        await createResourcePayment(
          residentId: int.parse(userId.toString()),
          trancheId: int.parse(trancheId.toString()),
          residenceId: (trData?['residence_id'] as int?) ?? 1,
          montant: 0,
          type: 'parking',
          mandatId: mandatId,
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
        await createResourcePayment(
          residentId: int.parse(userId.toString()),
          trancheId: int.parse(trancheId.toString()),
          residenceId: (trData?['residence_id'] as int?) ?? 1,
          montant: 0,
          type: 'box',
          mandatId: mandatId,
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
        await createResourcePayment(
          residentId: int.parse(userId.toString()),
          trancheId: int.parse(trancheId.toString()),
          residenceId: (trData?['residence_id'] as int?) ?? 1,
          montant: 0,
          type: 'garage',
          mandatId: mandatId,
        );
      }

      return (null, emailSent); // succès
    } catch (e) {
      debugPrint('>>> ERREUR addResident: $e');
      return (e.toString(), false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // ENREGISTRER PAIEMENT — avec vérification mandat
  // ═══════════════════════════════════════════════════════════════════

  Future<String?> enregistrerPaiement({
    required dynamic paiementId,
    required dynamic residentUserId,
    required double montantAjoute,
    required double montantDejaPane,
    required double montantTotal,
    required int interSyndicId,
  }) async {
    try {
      final paiementData = await _db
          .from('paiements')
          .select('mandat_id')
          .eq('id', paiementId)
          .maybeSingle();

      final int? mandatId = paiementData?['mandat_id'] as int?;

      if (mandatId == null) {
        return 'Ce paiement n\'est lié à aucun mandat.';
      }

      final isOwner = await isMandatOwnedByInterSyndic(
        mandatId: mandatId,
        interSyndicId: interSyndicId,
      );
      if (!isOwner) {
        return 'Action non autorisée : ce paiement appartient à un mandat qui ne vous est pas affecté.';
      }

      final nouveauMontant = montantDejaPane + montantAjoute;
      final statut = nouveauMontant >= montantTotal
          ? 'complet'
          : (nouveauMontant > 0 ? 'partiel' : 'impaye');

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

      return null;
    } catch (e) {
      return 'Erreur lors de l\'enregistrement : ${e.toString()}';
    }
  }

  Future<(int?, String?)> initPaiementMandatWithError({
    required int residentUserId,
    required int appartementId,
    required int mandatId,
    required double montantTotal,
    required int interSyndicId,
  }) async {
    try {
      final isOwner = await isMandatOwnedByInterSyndic(
        mandatId: mandatId,
        interSyndicId: interSyndicId,
      );
      if (!isOwner) {
        return (
        null,
        'Action non autorisée : ce mandat ne vous est pas affecté.'
        );
      }

      final appartData = await _db
          .from('appartements')
          .select('immeuble_id')
          .eq('id', appartementId)
          .maybeSingle();

      if (appartData == null) {
        return (null, 'Appartement introuvable.');
      }

      final immeubleId = appartData['immeuble_id'];

      final immeubleData = await _db
          .from('immeubles')
          .select('tranche_id')
          .eq('id', immeubleId)
          .maybeSingle();

      final trancheId = immeubleData?['tranche_id'];

      int residenceId = 1;
      int isId = 1;
      if (trancheId != null) {
        final trData = await _db
            .from('tranches')
            .select('residence_id, inter_syndic_id')
            .eq('id', trancheId)
            .maybeSingle();
        residenceId = (trData?['residence_id'] as int?) ?? 1;
        isId = (trData?['inter_syndic_id'] as int?) ?? 1;
      }

      final existingPai = await _db
          .from('paiements')
          .select('id')
          .eq('appartement_id', appartementId)
          .eq('type_paiement', 'charges')
          .eq('mandat_id', mandatId)
          .maybeSingle();

      if (existingPai != null) {
        return (existingPai['id'] as int, null);
      }

      final res = await _db
          .from('paiements')
          .insert({
        'resident_id': residentUserId,
        'appartement_id': appartementId,
        'residence_id': residenceId,
        'inter_syndic_id': isId,
        'montant_total': montantTotal,
        'montant_paye': 0,
        'type_paiement': 'charges',
        'statut': 'impaye',
        'annee': DateTime.now().year,
        'mois': DateTime.now().month,
        'mandat_id': mandatId,
      })
          .select('id')
          .single();

      return (res['id'] as int, null);
    } catch (e) {
      debugPrint('>>> ERREUR initPaiementMandat: $e');
      return (
      null,
      'Erreur lors de la création du paiement : ${e.toString()}'
      );
    }
  }

  Future<int?> initPaiementMandat({
    required int residentUserId,
    required int appartementId,
    required int mandatId,
    required double montantTotal,
    required int interSyndicId,
  }) async {
    final (id, _) = await initPaiementMandatWithError(
      residentUserId: residentUserId,
      appartementId: appartementId,
      mandatId: mandatId,
      montantTotal: montantTotal,
      interSyndicId: interSyndicId,
    );
    return id;
  }

  Future<void> createResourcePayment({
    required int residentId,
    required int trancheId,
    required int residenceId,
    required double montant,
    required String type,
    required int mandatId,
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

      final existing = await _db
          .from('paiements')
          .select('id')
          .eq('appartement_id', appartId)
          .eq('type_paiement', type)
          .eq('mandat_id', mandatId)
          .maybeSingle();
      if (existing != null) return;

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
        'mandat_id': mandatId,
      });
    } catch (e) {
      debugPrint('>>> ERREUR createResourcePayment: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // UPDATE RESIDENT — avec vérification mandat
  // ═══════════════════════════════════════════════════════════════════

  Future<String?> updateResident({
    required int userId,
    required String nom,
    required String prenom,
    String? telephone,
    required String type,
    double? montantTotal,
    int? annee,
    int? mandatId,
    required int interSyndicId,
  }) async {
    try {
      if (mandatId != null) {
        final isOwner = await isMandatOwnedByInterSyndic(
          mandatId: mandatId,
          interSyndicId: interSyndicId,
        );
        if (!isOwner) {
          return 'Action non autorisée : vous ne pouvez modifier que les résidents de votre propre mandat.';
        }
      }

      await _db.from('users').update({
        'nom': nom.trim(),
        'prenom': prenom.trim(),
        'telephone': telephone?.trim(),
      }).eq('id', userId);

      await _db
          .from('residents')
          .update({'type': type}).eq('user_id', userId);

      if (montantTotal != null && montantTotal > 0 && mandatId != null) {
        final targetAnnee = annee ?? DateTime.now().year;
        final existingPaiement = await _db
            .from('paiements')
            .select('id, montant_paye')
            .eq('resident_id', userId)
            .eq('type_paiement', 'charges')
            .eq('annee', targetAnnee)
            .eq('mandat_id', mandatId)
            .maybeSingle();
        if (existingPaiement != null) {
          final double paid =
              double.tryParse(existingPaiement['montant_paye'].toString()) ??
                  0.0;
          final String nouveauStatut = paid >= montantTotal
              ? 'complet'
              : (paid > 0 ? 'partiel' : 'impaye');
          await _db.from('paiements').update(
              {'montant_total': montantTotal, 'statut': nouveauStatut}).eq(
              'id', existingPaiement['id']);
        }
      }

      return null;
    } catch (e) {
      return 'Erreur lors de la modification : ${e.toString()}';
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // DELETE RESIDENT — avec vérification mandat
  // ═══════════════════════════════════════════════════════════════════

  Future<String?> deleteResident(
      dynamic userId,
      dynamic appartementId, {
        required int interSyndicId,
        int? mandatId,
      }) async {
    try {
      if (mandatId != null) {
        final isOwner = await isMandatOwnedByInterSyndic(
          mandatId: mandatId,
          interSyndicId: interSyndicId,
        );
        if (!isOwner) {
          return 'Action non autorisée : vous ne pouvez supprimer que les résidents de votre propre mandat.';
        }
      }

      if (appartementId != null) {
        await _db
            .from('appartements')
            .update({'statut': 'libre', 'resident_id': null}).eq(
            'id', appartementId);
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
      return 'Erreur lors de la suppression : ${e.toString()}';
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION RESIDENT (méthodes inchangées)
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getChargesData(
      dynamic userId, int annee) async {
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
      if (appart == null || imm == null || tranche == null)
        return _err('Données incomplètes');
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
          'nb_apparts': nbApparts
        },
        'charges': charges,
        'solde': {
          'total_annee': 0.0,
          'paye_annee': 0.0,
          'reste_annee': 0.0,
          'nb_impaye': 0,
          'nb_partiel': 0
        },
      };
    } catch (e) {
      return _err(e.toString());
    }
  }

  Future<Map<String, dynamic>> getAnnoncesPaginated({
    required dynamic userId,
    DateTime? startDate,
    DateTime? endDate,
    String? typeAnnonce,
    int? mandatId,
    String? searchQuery,
    int page = 0,
    int pageSize = 10,
  }) async {
    try {
      final resData = await _db
          .from('residents')
          .select('appartement_id, created_at')
          .eq('user_id', userId)
          .maybeSingle();

      if (resData == null || resData['appartement_id'] == null) {
        return {'annonces': [], 'hasMore': false};
      }

      final DateTime residentJoined =
      DateTime.parse(resData['created_at']);
      DateTime effectiveStart = startDate ?? residentJoined;
      if (effectiveStart.isBefore(residentJoined))
        effectiveStart = residentJoined;
      DateTime effectiveEnd =
          endDate ?? DateTime.now().add(const Duration(days: 365));

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
      if (trancheId == null) return {'annonces': [], 'hasMore': false};

      final from = page * pageSize;
      final to = from + pageSize - 1;

      var query = _db
          .from('annonces')
          .select()
          .eq('tranche_id', trancheId)
          .eq('statut', 'publiee')
          .gte('created_at', effectiveStart.toIso8601String())
          .lte('created_at', effectiveEnd.toIso8601String());
      if (mandatId != null) {
        query = query.eq('mandat_id', mandatId);
      }
      if (typeAnnonce != null && typeAnnonce != 'tous') {
        query = query.eq('type', typeAnnonce);
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        query = query.or('titre.ilike.%$q%,contenu.ilike.%$q%');
      }

      final res = await query
          .order('created_at', ascending: false)
          .range(from, to);

      final List list = res as List? ?? [];

      return {
        'annonces': list,
        'hasMore': list.length == pageSize,
        'resident_joined_at': residentJoined,
      };
    } catch (e) {
      debugPrint('>>> ERREUR getAnnoncesPaginated: $e');
      return {'annonces': [], 'hasMore': false};
    }
  }

  Future<Map<String, dynamic>> getAnnoncesAndReunions(
      dynamic userId) async {
    final res = await getAnnoncesPaginated(userId: userId, pageSize: 50);
    final reunions = await _db
        .from('reunions')
        .select()
        .order('date', ascending: true);

    return {
      'annonces': res['annonces'],
      'reunions': reunions as List? ?? [],
      'tranche_id': 0,
    };
  }

  Future<Map<String, dynamic>> getTrancheExpensesDetailed(
      dynamic userId, int annee) async {
    try {
      final resData = await _db
          .from('residents')
          .select('appartement_id')
          .eq('user_id', userId)
          .maybeSingle();
      if (resData == null || resData['appartement_id'] == null)
        return {'depenses': [], 'total': 0.0};
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
          .select(', categories()')
          .eq('tranche_id', trancheId)
          .eq('annee', annee);
      final resResidence = await _db
          .from('depenses')
          .select(', categories()')
          .eq('residence_id', residenceId)
          .eq('annee', annee)
          .isFilter('tranche_id', null);
      final List allDeps = [
        ...(resTranche as List? ?? []),
        ...(resResidence as List? ?? [])
      ];
      final List<Map<String, dynamic>> processedDeps = [];
      double totalResident = 0, payeesResident = 0;
      for (final d in allDeps) {
        final double montantSaisi =
            (d['montant'] as num?)?.toDouble() ?? 0.0;
        final String typeCat =
            d['categories']?['type']?.toString().toLowerCase() ??
                'individuelle';
        final double montantFinal =
        typeCat == 'globale' ? montantSaisi / nbTranches : montantSaisi;
        processedDeps.add({
          ...Map<String, dynamic>.from(d),
          'montant': montantFinal.toStringAsFixed(2),
          'montant_original': montantSaisi,
          'type_affichage':
          typeCat == 'globale' ? 'Commune' : 'Individuelle'
        });
        totalResident += montantFinal;
        if (d['facture_path'] != null) payeesResident += montantFinal;
      }
      return {
        'tranche_nom': tranche?['nom'] ?? 'Ma Tranche',
        'depenses': processedDeps,
        'total': totalResident,
        'payees': payeesResident,
        'attente': totalResident - payeesResident
      };
    } catch (e) {
      debugPrint('>>> ERREUR getTrancheExpensesDetailed: $e');
      return {'depenses': [], 'total': 0.0};
    }
  }

  Future<Map<String, dynamic>> getResidentDashboardData(
      dynamic userId) async {
    try {
      final userRow = await _db
          .from('users')
          .select('nom, prenom')
          .eq('id', userId)
          .maybeSingle();

      final resData = await _db
          .from('residents')
          .select('appartement_id, created_at')
          .eq('user_id', userId)
          .maybeSingle();

      dynamic trancheId;
      dynamic appartNumero = '-';
      dynamic immeubleNom = '-';
      dynamic trancheNom = '-';
      dynamic appartId;
      String? residentCreatedAt = resData?['created_at'];

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
        final int currentYear = DateTime.now().year;
        var annQuery = _db
            .from('annonces')
            .select('id')
            .eq('tranche_id', trancheId)
            .eq('statut', 'publiee')
            .gte('created_at', '$currentYear-01-01');

        if (residentCreatedAt != null) {
          annQuery = annQuery.gte('created_at', residentCreatedAt);
        }

        final a = await annQuery;
        nbAnn = (a as List? ?? []).length;

        final r = await _db
            .from('reunions')
            .select('id')
            .eq('tranche_id', trancheId)
            .gte('date', '$currentYear-01-01')
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
          .select(
          'id, appartements(id, numero, immeubles(id, nom, tranches(id, nom)))')
          .eq('user_id', userId)
          .maybeSingle();
      if (resRow == null) {
        return {
          'num_appart': '-',
          'total_annee': 0.0,
          'paye_annee': 0.0,
          'reste_annee': 0.0,
          'statut': 'impaye',
          'lignes': []
        };
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
        paye += mp;

        lignes.add({
          'type': p['type_paiement']?.toString() ?? 'charges',
          'reference': null,
          'montant_total': mt,
          'montant_paye': mp,
          'reste': mt - mp,
          'statut': p['statut']?.toString() ?? 'impaye',
        });
      }

      return {
        'num_appart': resRow['appartements']['numero'],
        'immeuble_nom': resRow['appartements']['immeubles']['nom'],
        'tranche_nom': resRow['appartements']['immeubles']['tranches']['nom'],
        'total_annee': total,
        'paye_annee': paye,
        'reste_annee': total - paye,
        'statut': paye >= total
            ? 'complet'
            : (paye > 0 ? 'partiel' : 'impaye'),
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

  Future<List<Map<String, dynamic>>> getMandatsVecus(dynamic userId) async {
    try {
      final resData = await _db
          .from('residents')
          .select('date_arrivee, created_at, appartement_id')
          .eq('user_id', userId)
          .maybeSingle();
      if (resData == null || resData['appartement_id'] == null) return [];

      final String? rawDate =
          resData['date_arrivee'] ?? resData['created_at'];
      final DateTime? dateArrivee = DateTime.tryParse(rawDate ?? '');
      if (dateArrivee == null) return [];

      final appart = await _db
          .from('appartements')
          .select('immeuble_id')
          .eq('id', resData['appartement_id'])
          .maybeSingle();
      final imm = await _db
          .from('immeubles')
          .select('tranche_id')
          .eq('id', appart?['immeuble_id'])
          .maybeSingle();
      final dynamic trancheId = imm?['tranche_id'];
      if (trancheId == null) return [];

      final mandats = await _db
          .from('historique_affectations')
          .select(
          'id, date_debut, date_fin, inter_syndic_id, users!inter_syndic_id(nom, prenom)')
          .eq('tranche_id', trancheId)
          .order('date_debut', ascending: false);

      final List mandatsEnCours = (mandats as List? ?? [])
          .where((m) => m['date_fin'] == null)
          .toList();

      Map<String, dynamic>? seulMandatEnCours;
      if (mandatsEnCours.isNotEmpty) {
        seulMandatEnCours = mandatsEnCours.reduce((a, b) {
          final da =
              DateTime.tryParse(a['date_debut'] ?? '') ?? DateTime(2000);
          final db =
              DateTime.tryParse(b['date_debut'] ?? '') ?? DateTime(2000);
          return da.isAfter(db) ? a : b;
        });
      }

      final List<Map<String, dynamic>> mandatsVecus = [];

      for (final m in mandats as List? ?? []) {
        final DateTime? finMandat =
        m['date_fin'] != null ? DateTime.tryParse(m['date_fin']) : null;

        if (finMandat == null && seulMandatEnCours?['id'] != m['id'])
          continue;

        final DateTime? debutMandat =
        DateTime.tryParse(m['date_debut'] ?? '');

        final String debutCourt = debutMandat != null
            ? '${debutMandat.day.toString().padLeft(2, '0')}/${debutMandat.month.toString().padLeft(2, '0')}/${debutMandat.year.toString().substring(2)}'
            : '?';
        final String finCourt = finMandat != null
            ? '${finMandat.day.toString().padLeft(2, '0')}/${finMandat.month.toString().padLeft(2, '0')}/${finMandat.year.toString().substring(2)}'
            : 'En cours';

        final syndic = m['users'];
        final String nomSyndic = syndic != null
            ? '${syndic['prenom'] ?? ''} ${syndic['nom'] ?? ''}'.trim()
            : 'Syndic';

        mandatsVecus.add({
          'id': m['id'],
          'date_debut': m['date_debut'],
          'label': '$debutCourt → $finCourt',
          'syndic_nom': nomSyndic,
          'est_en_cours': finMandat == null,
        });
      }

      return mandatsVecus;
    } catch (e) {
      debugPrint('>>> ERREUR getMandatsVecus: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getHistoriquePaiementsParMandat(
      dynamic userId, {
        dynamic mandatId,
      }) async {
    try {
      final resRow = await _db
          .from('residents')
          .select('appartement_id')
          .eq('user_id', userId)
          .maybeSingle();
      final dynamic appartId = resRow?['appartement_id'];
      if (appartId == null) return {'total_verse': 0.0, 'historique': []};

      var query = _db
          .from('paiements')
          .select()
          .eq('appartement_id', appartId);

      if (mandatId != null) {
        query = query.eq('mandat_id', mandatId);
      }

      final paiements =
      await query.order('date_paiement', ascending: false);

      double total = 0;
      final List<Map<String, dynamic>> hist = [];
      for (final p in paiements as List) {
        total += (p['montant_paye'] as num).toDouble();
        hist.add(Map<String, dynamic>.from(p));
      }
      return {'total_verse': total, 'historique': hist};
    } catch (e) {
      debugPrint('>>> ERREUR getHistoriquePaiementsParMandat: $e');
      return {'total_verse': 0.0, 'historique': []};
    }
  }

  Future<Map<String, dynamic>> getTrancheExpensesDetailedByMandat(
      dynamic userId, {
        String? dateDebut,
        String? dateFin,
      }) async {
    try {
      final resData = await _db
          .from('residents')
          .select('appartement_id')
          .eq('user_id', userId)
          .maybeSingle();
      if (resData == null || resData['appartement_id'] == null) {
        return {
          'depenses': [],
          'total': 0.0,
          'payees': 0.0,
          'attente': 0.0,
          'tranche_nom': ''
        };
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

      var queryTranche = _db
          .from('depenses')
          .select('*, categories(*)')
          .eq('tranche_id', trancheId);
      if (dateDebut != null) queryTranche = queryTranche.gte('date', dateDebut);
      if (dateFin != null) queryTranche = queryTranche.lte('date', dateFin);

      var queryResidence = _db
          .from('depenses')
          .select('*, categories(*)')
          .eq('residence_id', residenceId)
          .isFilter('tranche_id', null);
      if (dateDebut != null)
        queryResidence = queryResidence.gte('date', dateDebut);
      if (dateFin != null) queryResidence = queryResidence.lte('date', dateFin);

      final List depsTranche = await queryTranche as List? ?? [];
      final List depsResidence = await queryResidence as List? ?? [];
      final List allDeps = [...depsTranche, ...depsResidence];

      final List<Map<String, dynamic>> processedDeps = [];
      double totalResident = 0;
      double payeesResident = 0;

      for (final d in allDeps) {
        final double montantSaisi =
            (d['montant'] as num?)?.toDouble() ?? 0.0;
        final String typeCat =
            d['categories']?['type']?.toString().toLowerCase() ??
                'individuelle';
        final double montantFinal =
        typeCat == 'globale' ? montantSaisi / nbTranches : montantSaisi;

        processedDeps.add({
          ...Map<String, dynamic>.from(d),
          'montant': montantFinal.toStringAsFixed(2),
          'montant_original': montantSaisi,
          'type_affichage':
          typeCat == 'globale' ? 'Commune' : 'Individuelle',
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
      debugPrint('=== ERREUR getTrancheExpensesDetailedByMandat: $e ===');
      return {
        'depenses': [],
        'total': 0.0,
        'payees': 0.0,
        'attente': 0.0,
        'tranche_nom': ''
      };
    }
  }

  Future<String?> updatePassword(dynamic userId, String newPassword) async {
    try {
      try {
        await _db.auth.updateUser(UserAttributes(password: newPassword));
      } catch (authError) {
        debugPrint('>>> Auth update skipped: $authError');
      }

      String hashedPassword = newPassword;
      try {
        hashedPassword = await _db.rpc('crypt', params: {
          'password': newPassword,
          'salt': 'bf',
        });
      } catch (_) {}

      await _db
          .from('users')
          .update({'password': hashedPassword}).eq('id', userId);

      return null;
    } catch (e) {
      debugPrint('>>> ERREUR updatePassword: $e');
      return e.toString();
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