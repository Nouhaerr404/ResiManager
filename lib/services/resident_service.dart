import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentService {
  final _db = Supabase.instance.client;

  // ═══════════════════════════════════════════════════════════════════
  // getChargesData
  // Toutes les charges de la tranche du résident pour une année donnée.
  // Chaque charge = dépense tranche + part du résident + son paiement.
  // ═══════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> getChargesData(int userId, int annee) async {

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

    final appart  = resRow['appartements']   as Map<String, dynamic>?;
    final imm     = appart?['immeubles']     as Map<String, dynamic>?;
    final tranche = imm?['tranches']         as Map<String, dynamic>?;

    if (appart == null || imm == null || tranche == null) {
      return _err('Appartement ou tranche non assigné');
    }

    final int appartId  = appart['id']  as int;
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

    // 3. Tous les paiements de l'appartement
    final paiRows = await _db
        .from('paiements')
        .select('''
          id, montant_total, montant_paye, statut, date_paiement,
          depenses ( id, annee, mois )
        ''')
        .eq('appartement_id', appartId);

    // Index paiements par depense_id
    final Map<int, Map<String, dynamic>> paiByDep = {};
    for (final p in paiRows as List) {
      final d = p['depenses'] as Map<String, dynamic>?;
      if (d != null && d['annee'] == annee) {
        paiByDep[d['id'] as int] = Map<String, dynamic>.from(p as Map);
      }
    }

    // 4. Construire la liste unifiée
    final List<Map<String, dynamic>> charges = [];
    for (final d in depRows as List) {
      final cat     = d['categories']  as Map<String, dynamic>?;
      final depId   = d['id']          as int;
      final total   = (d['montant']    as num).toDouble();
      final part    = total / nbApparts;
      final pai     = paiByDep[depId];

      final double paye   = (pai?['montant_paye'] as num?)?.toDouble() ?? 0.0;
      final double reste  = (part - paye).clamp(0.0, double.infinity);
      final String statut = (pai?['statut']        as String?) ?? 'impaye';

      charges.add({
        'depense_id'     : depId,
        'paiement_id'    : pai?['id'],
        'categorie'      : cat?['nom']  ?? 'Divers',
        'type'           : cat?['type'] ?? 'individuelle',
        'mois'           : d['mois']   as int?,
        'date'           : d['date']   as String?,
        'montant_tranche': total,
        'nb_apparts'     : nbApparts,
        'votre_part'     : part,
        'montant_paye'   : paye,
        'montant_reste'  : reste,
        'statut'         : statut,
        'date_paiement'  : pai?['date_paiement'] as String?,
        'facture_path'   : d['facture_path']     as String?,
      });
    }

    // 5. Calculs globaux
    double totalAnnee = 0, payeAnnee = 0;
    int nbImpaye = 0, nbPartiel = 0;
    for (final c in charges) {
      totalAnnee += c['votre_part']   as double;
      payeAnnee  += c['montant_paye'] as double;
      if (c['statut'] == 'impaye')  nbImpaye++;
      if (c['statut'] == 'partiel') nbPartiel++;
    }

    return {
      'resident': {
        'num_appart'  : appart['numero']?.toString() ?? '—',
        'immeuble_nom': imm['nom']?.toString()       ?? '—',
        'tranche_nom' : tranche['nom']?.toString()   ?? '—',
        'nb_apparts'  : nbApparts,
      },
      'charges': charges,
      'solde': {
        'total_annee': totalAnnee,
        'paye_annee' : payeAnnee,
        'reste_annee': totalAnnee - payeAnnee,
        'nb_impaye'  : nbImpaye,
        'nb_partiel' : nbPartiel,
      },
    };
  }

  // lib/services/resident_service.dart

  Future<Map<String, dynamic>> getAnnoncesAndReunions(int userId) async {
    try {
      // 1. Trouver la tranche du résident
      final resData = await _db.from('residents').select('appartement_id').eq('user_id', userId).single();
      final appartData = await _db.from('appartements').select('immeuble_id').eq('id', resData['appartement_id']).single();
      final immData = await _db.from('immeubles').select('tranche_id').eq('id', appartData['immeuble_id']).single();
      final int trancheId = immData['tranche_id'];

      // 2. Récupérer les annonces
      final annonces = await _db.from('annonces').select().eq('tranche_id', trancheId).eq('statut', 'publiee');

      // 3. Récupérer les réunions
      final reunions = await _db.from('reunions').select().eq('tranche_id', trancheId).order('date', ascending: true);

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
  Future<Map<String, dynamic>> getTransparencyData(int userId, int mois, int annee) async {
    // 1. Infos du résident et de son entourage
    final res = await _db.from('residents')
        .select('*, appartements(*, immeubles(*, tranches(*)))')
        .eq('user_id', userId).single();

    final int nbAppartsImmeuble = res['appartements']['immeubles']['nombre_appartements'] ?? 1;
    final int nbAppartsTranche = res['appartements']['immeubles']['tranches']['nombre_appartements'] ?? 1;
    final int immeubleId = res['appartements']['immeuble_id'];
    final int trancheId = res['appartements']['immeubles']['tranche_id'];

    // 2. Dépenses IMMEUBLE (ex: Nettoyage escalier)
    final depImmeuble = await _db.from('depenses').select().eq('immeuble_id', immeubleId).eq('mois', mois).eq('annee', annee);

    // 3. Dépenses TRANCHE (ex: Sécurité générale, Espace vert)
    final depTranche = await _db.from('depenses').select().eq('tranche_id', trancheId).eq('mois', mois).eq('annee', annee);

    // 4. Statut Paiement Personnel
    final paiement = await _db.from('paiements').select().eq('resident_id', userId).eq('mois', mois).eq('annee', annee).maybeSingle();

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
// lib/services/resident_service.dart

  Future<Map<String, dynamic>> getTrancheExpensesDetailed(int userId, int annee) async {
    try {
      // 1. Infos de base
      final res = await _db.from('residents').select('appartement_id').eq('user_id', userId).maybeSingle();
      final app = await _db.from('appartements').select('immeuble_id').eq('id', res?['appartement_id']).maybeSingle();
      final imm = await _db.from('immeubles').select('tranche_id, nom').eq('id', app?['immeuble_id']).maybeSingle();
      final tra = await _db.from('tranches').select('nom').eq('id', imm?['tranche_id']).maybeSingle();

      final int trancheId = imm?['tranche_id'] ?? 0;

      // 2. Toutes les dépenses de la tranche
      final List depenses = await _db
          .from('depenses')
          .select('*, categories(*)')
          .eq('tranche_id', trancheId)
          .eq('annee', annee)
          .order('date', ascending: false);

      // 3. Calculs pour les cartes
      double total = 0;
      double payees = 0;
      for (var d in depenses) {
        double m = (double.tryParse(d['montant'].toString()) ?? 0.0);
        total += m;
        if (d['facture_path'] != null) payees += m; // Logique métier : facture présente = payée
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
  // lib/services/resident_service.dart

  // 1. Récupérer toutes les notifications d'un utilisateur
  Future<List<Map<String, dynamic>>> getNotifications(int userId) async {
    final response = await _db
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // 2. Marquer une notification comme lue
  Future<void> markAsRead(int notifId) async {
    await _db.from('notifications').update({'lu': true}).eq('id', notifId);
  }

  // 3. Tout marquer comme lu
  Future<void> markAllAsRead(int userId) async {
    await _db.from('notifications').update({'lu': true}).eq('user_id', userId);
  }

  // 4. Supprimer une notification
  Future<void> deleteNotification(int notifId) async {
    await _db.from('notifications').delete().eq('id', notifId);
  }
  // --- CONFIRMER LA PRÉSENCE À UNE RÉUNION ---
  Future<void> updateMeetingAttendance(int userId, int reunionId, String status) async {
    try {
      // On utilise upsert : si ça existe on modifie, sinon on crée
      await _db.from('reunion_resident').upsert({
        'reunion_id': reunionId,
        'resident_id': userId,
        'confirmation': status, // 'confirme' ou 'absent'
      });
    } catch (e) {
      print("Erreur participation: $e");
    }
  }

  // Récupérer le statut actuel de l'utilisateur pour une réunion
  Future<String> getMyAttendance(int userId, int reunionId) async {
    final response = await _db
        .from('reunion_resident')
        .select('confirmation')
        .eq('reunion_id', reunionId)
        .eq('resident_id', userId)
        .maybeSingle();
    return response?['confirmation'] ?? 'en_attente';
  }
  // ═══════════════════════════════════════════════════════════════════
  // getResidentDashboardData
  // ═══════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> getResidentDashboardData(int userId) async {
    final annee = DateTime.now().year;

    final userRow = await _db.from('users')
        .select('nom, prenom').eq('id', userId).maybeSingle();

    final resRow = await _db.from('residents').select('''
      id,
      appartements (
        id, numero,
        immeubles ( id, nom, tranches ( id, nom ) )
      )
    ''').eq('user_id', userId).maybeSingle();

    if (resRow == null) return {
      'nom':'—','prenom':'—','num_appart':'—','immeuble_nom':'—','tranche_nom':'—',
      'solde_du':0.0,'nb_annonces':0,'nb_reunions':0,
      'nb_reclamations_ouvertes':0,'notifications_non_lues':0,
    };

    final appart    = resRow['appartements'] as Map<String, dynamic>?;
    final imm       = appart?['immeubles']   as Map<String, dynamic>?;
    final tranche   = imm?['tranches']       as Map<String, dynamic>?;
    final appartId  = appart?['id']          as int?;
    final trancheId = tranche?['id']         as int?;

    double soldeDu = 0.0;
    if (appartId != null) {
      final pais = await _db.from('paiements')
          .select('montant_total, montant_paye, depenses(annee)')
          .eq('appartement_id', appartId)
          .inFilter('statut', ['impaye', 'partiel']);
      for (final p in pais) {
        final d = p['depenses'] as Map<String, dynamic>?;
        if (d?['annee'] == annee) {
          soldeDu += ((p['montant_total'] as num) - (p['montant_paye'] as num)).toDouble();
        }
      }
    }

    int nbAnn = 0, nbReu = 0;
    if (trancheId != null) {
      final a = await _db.from('annonces').select('id')
          .eq('tranche_id', trancheId).eq('statut', 'publiee');
      nbAnn = (a as List).length;
      final r = await _db.from('reunions').select('id')
          .eq('tranche_id', trancheId)
          .inFilter('statut', ['planifiee', 'confirmee']);
      nbReu = (r as List).length;
    }

    final rec  = await _db.from('reclamations').select('id')
        .eq('resident_id', userId).eq('statut', 'en_cours');
    final nots = await _db.from('notifications').select('id')
        .eq('user_id', userId).eq('lu', false);

    return {
      'nom'                     : userRow?['nom']?.toString()    ?? '—',
      'prenom'                  : userRow?['prenom']?.toString() ?? '—',
      'num_appart'              : appart?['numero']?.toString()  ?? '—',
      'immeuble_nom'            : imm?['nom']?.toString()        ?? '—',
      'tranche_nom'             : tranche?['nom']?.toString()    ?? '—',
      'solde_du'                : soldeDu,
      'nb_annonces'             : nbAnn,
      'nb_reunions'             : nbReu,
      'nb_reclamations_ouvertes': (rec  as List).length,
      'notifications_non_lues'  : (nots as List).length,
    };
  }
// 1. Récupérer les réunions avec le statut actuel du résident (Ahmed)
  Future<List<Map<String, dynamic>>> getReunionsWithStatus(int userId) async {
    try {
      // On récupère d'abord l'appartement pour trouver la tranche
      final resData = await _db.from('residents').select('appartement_id').eq('user_id', userId).single();
      final int appartId = resData['appartement_id'];

      final appartData = await _db.from('appartements').select('immeuble_id').eq('id', appartId).single();
      final immData = await _db.from('immeubles').select('tranche_id').eq('id', appartData['immeuble_id']).single();
      final int trancheId = immData['tranche_id'];

      // On récupère les réunions de la tranche
      final List reunionsRaw = await _db.from('reunions').select().eq('tranche_id', trancheId).order('date');

      // On récupère les choix du résident
      final List participationRaw = await _db.from('reunion_resident').select().eq('resident_id', userId);

      // ✅ LA CORRECTION EST ICI : On force le type Map<String, dynamic>
      return reunionsRaw.map((r) {
        final Map<String, dynamic> reunion = Map<String, dynamic>.from(r);

        // On cherche si une participation existe
        final participation = participationRaw.firstWhere(
                (p) => p['reunion_id'] == reunion['id'],
            orElse: () => null
        );

        return {
          ...reunion,
          'mon_statut': participation != null ? participation['confirmation'] : 'en_attente',
        };
      }).toList().cast<Map<String, dynamic>>(); // On cast la liste finale

    } catch (e) {
      print("Erreur Fetch Réunions: $e");
      return [];
    }
  }
  Map<String, dynamic> _err(String msg) => {
    'error'   : msg,
    'resident': {'num_appart':'—','immeuble_nom':'—','tranche_nom':'—','nb_apparts':1},
    'charges' : <Map>[],
    'solde'   : {'total_annee':0.0,'paye_annee':0.0,'reste_annee':0.0,'nb_impaye':0,'nb_partiel':0},
  };
}