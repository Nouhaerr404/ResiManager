import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/immeuble_model.dart';

class ImmeubleService {
  final _db = Supabase.instance.client;

  Future<List<ImmeubleModel>> getImmeublesByTranche(int trancheId) async {
    try {
      final res = await _db
          .from('immeubles')
          .select('*, tranches!inner(*)')
          .eq('tranche_id', trancheId)
          .order('nom', ascending: true);

      return (res as List)
          .map((e) => ImmeubleModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('DEBUG: Error in getImmeublesByTranche: $e');
      return [];
    }
  }

  Future<ImmeubleModel?> getImmeubleById(int id) async {
    try {
      final res = await _db
          .from('immeubles')
          .select('*, tranches!inner(*)')
          .eq('id', id)
          .maybeSingle();

      if (res == null) return null;
      return ImmeubleModel.fromJson(Map<String, dynamic>.from(res));
    } catch (e) {
      print('DEBUG: Error in getImmeubleById: $e');
      return null;
    }
  }
  Future<void> createImmeuble(Map<String, dynamic> data) async {
    try {
      // 1. Récupérer les informations de la tranche et de la résidence pour la nomenclature
      final trancheId = data['tranche_id'];
      final trancheRes = await _db
          .from('tranches')
          .select('nom, residences(nom)')
          .eq('id', trancheId)
          .single();

      final String trancheNom = trancheRes['nom'] ?? 'X';
      final String residenceNom = trancheRes['residences']?['nom'] ?? 'X';
      final String immeubleNom = data['nom'] ?? 'X';
      final int nbApparts = data['nombre_appartements'] ?? 0;

      // 2. Insérer l'immeuble et récupérer son ID
      final inserted = await _db.from('immeubles').insert(data).select('id').single();
      final int immeubleId = inserted['id'];

      // 3. Créer automatiquement les appartements
      if (nbApparts > 0) {
        final List<Map<String, dynamic>> apparts = [];
        for (int i = 1; i <= nbApparts; i++) {
          // Format standard : RResidence-TTranche-ImmImmeuble-Num
          // Ex: R1-T1-ImmA1-1
          final String numStr = i.toString().padLeft(2, '0');
          final String nomComplet = "R$residenceNom-T$trancheNom-Imm$immeubleNom-$numStr";
          
          apparts.add({
            'immeuble_id': immeubleId,
            'numero': nomComplet,
            'statut': 'libre',
          });
        }
        
        if (apparts.isNotEmpty) {
          await _db.from('appartements').insert(apparts);
        }
      }
    } catch (e) {
      print('DEBUG: Error in createImmeuble: $e');
      rethrow;
    }
  }

  Future<void> updateImmeuble(int id, Map<String, dynamic> data) async {
    try {
      await _db.from('immeubles').update(data).eq('id', id);
    } catch (e) {
      print('DEBUG: Error in updateImmeuble: $e');
      rethrow;
    }
  }

  Future<void> deleteImmeuble(int id) async {
    try {
      // 1. Trouver les IDs de tous les appartements liés à cet immeuble
      final appartements = await _db
          .from('appartements')
          .select('id')
          .eq('immeuble_id', id);
      
      final List<int> appartIds = (appartements as List)
          .map((a) => a['id'] as int)
          .toList();

      if (appartIds.isNotEmpty) {
        // 2. Supprimer les paiements liés à ces appartements
        await _db.from('paiements').delete().inFilter('appartement_id', appartIds);
        
        // 3. Désassigner les résidents de ces appartements (mettre appartement_id à null)
        await _db.from('residents').update({'appartement_id': null}).inFilter('appartement_id', appartIds);

        // 4. Supprimer tous les appartements liés
        await _db.from('appartements').delete().eq('immeuble_id', id);
      }

      // 5. Supprimer l'immeuble
      await _db.from('immeubles').delete().eq('id', id);
    } catch (e) {
      print('DEBUG: Error in deleteImmeuble: $e');
      rethrow;
    }
  }
}
