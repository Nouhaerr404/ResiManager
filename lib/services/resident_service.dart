// lib/services/resident_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resident_model.dart';

class ResidentService {
  final _db = Supabase.instance.client;
  final int annee = DateTime.now().year;

  Future<List<ResidentModel>> getResidentsByTranche(int trancheId) async {
    try {
      // ÉTAPE 1 : Récupérer les immeubles de la tranche
      final immeubles = await _db
          .from('immeubles')
          .select('id')
          .eq('tranche_id', trancheId);

      if ((immeubles as List).isEmpty) return [];

      final immeubleIds = immeubles.map((i) => i['id']).toList();

      // ÉTAPE 2 : Récupérer les appartements de ces immeubles
      final appartements = await _db
          .from('appartements')
          .select('id, numero, immeuble_id, resident_id, immeubles(nom)')
          .inFilter('immeuble_id', immeubleIds);

      if ((appartements as List).isEmpty) return [];

      final appartementIds = appartements.map((a) => a['id']).toList();

      // ÉTAPE 3 : Récupérer les résidents de ces appartements
      final residents = await _db
          .from('residents')
          .select('id, user_id, appartement_id, type, statut, users(nom, prenom, email, telephone)')
          .inFilter('appartement_id', appartementIds);

      if ((residents as List).isEmpty) return [];

      final residentUserIds = residents.map((r) => r['user_id']).toList();

      // ÉTAPE 4 : Récupérer les paiements
      final paiements = await _db
          .from('paiements')
          .select('resident_id, montant_total, montant_paye, statut, annee')
          .inFilter('resident_id', residentUserIds)
          .eq('annee', DateTime.now().year);

      // ÉTAPE 5 : Assembler les données
      return residents.map((r) {
        final appart = appartements.firstWhere(
              (a) => a['id'] == r['appartement_id'],
          orElse: () => {},
        );
        final paiement = (paiements as List).firstWhere(
              (p) => p['resident_id'] == r['user_id'],
          orElse: () => null,
        );

        return ResidentModel(
          id: r['id'],
          userId: r['user_id'],
          appartementId: r['appartement_id'],
          type: r['type'] ?? 'proprietaire',
          statut: r['statut'] ?? 'actif',
          nom: r['users']?['nom'] ?? '',
          prenom: r['users']?['prenom'] ?? '',
          email: r['users']?['email'] ?? '',
          telephone: r['users']?['telephone'],
          appartementNumero: appart['numero'],
          immeubleName: appart['immeubles']?['nom'],
          montantTotal: double.parse(
              (paiement?['montant_total'] ?? 3000).toString()),
          montantPaye: double.parse(
              (paiement?['montant_paye'] ?? 0).toString()),
          statutPaiement: paiement?['statut'] ?? 'impaye',
          anneePaiement: paiement?['annee'] ?? DateTime.now().year,
        );
      }).toList();

    } catch (e) {
      print('Erreur getResidentsByTranche: $e');
      return [];
    }
  }
  // Ajouter un résident (crée user + resident)
  Future<void> addResident({
    required String nom,
    required String prenom,
    required String email,
    String? telephone,
    required String type,
    required int trancheId,
    required double montantTotal,
  }) async {
    // 1. Créer le user
    final userResponse = await _db
        .from('users')
        .insert({
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'password': 'changeme123',
      'role': 'resident',
      'statut': 'actif',
    })
        .select()
        .single();

    final userId = userResponse['id'];

    // 2. Créer le resident
    final residentResponse = await _db
        .from('residents')
        .insert({
      'user_id': userId,
      'type': type,
      'statut': 'actif',
      'date_arrivee': DateTime.now().toIso8601String(),
    })
        .select()
        .single();

    final residentId = residentResponse['id'];

    // 3. Créer le paiement initial
    await _db.from('paiements').insert({
      'resident_id': userId,
      'appartement_id': 1, // à adapter selon affectation
      'depense_id': 1,
      'inter_syndic_id': 1,
      'residence_id': 1,
      'montant_total': montantTotal,
      'montant_paye': 0,
      'type_paiement': 'charges',
      'statut': 'impaye',
      'annee': annee,
    });
  }

  // Enregistrer un paiement
  Future<void> enregistrerPaiement({
    required int residentUserId,
    required int appartementId,
    required double montantAjoute,
    required double montantDejaPane,
    required double montantTotal,
  }) async {
    final nouveauMontant = montantDejaPane + montantAjoute;
    String statut;
    if (nouveauMontant >= montantTotal) {
      statut = 'complet';
    } else if (nouveauMontant > 0) {
      statut = 'partiel';
    } else {
      statut = 'impaye';
    }

    // Mettre à jour le paiement existant
    await _db
        .from('paiements')
        .update({
      'montant_paye': nouveauMontant,
      'statut': statut,
      'date_paiement': DateTime.now().toIso8601String(),
    })
        .eq('resident_id', residentUserId)
        .eq('annee', annee);

    // Ajouter dans l'historique
    await _db.from('historique_paiements').insert({
      'resident_id': residentUserId,
      'montant': montantAjoute,
      'date': DateTime.now().toIso8601String(),
      'type': 'charges',
      'description': 'Paiement charges $annee',
    });
  }

  // Supprimer un résident
  Future<void> deleteResident(int userId) async {
    await _db.from('users').delete().eq('id', userId);
  }
}