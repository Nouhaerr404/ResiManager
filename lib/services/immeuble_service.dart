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
      await _db.from('immeubles').insert(data);
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
      await _db.from('immeubles').delete().eq('id', id);
    } catch (e) {
      print('DEBUG: Error in deleteImmeuble: $e');
      rethrow;
    }
  }
}
