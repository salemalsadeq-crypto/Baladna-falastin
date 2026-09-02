import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getGovernorates() async {
    final response = await _client
        .from('regions')
        .select()
        .eq('type', 'governorate')
        .order('sort_order');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getCategories({int upToVersion = 1}) async {
    final response = await _client
        .from('categories')
        .select()
        .eq('is_active', true)
        .lte('version_added', upToVersion)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getListings({
    String? categoryId,
    String? regionId,
    int limit = 20,
  }) async {
    var query = _client.from('listings').select().eq('status', 'approved');
    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (regionId != null) query = query.eq('region_id', regionId);
    final response = await query.order('created_at', ascending: false).limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addListing({
    required String title,
    required String categoryId,
    required String regionId,
    String? description,
    String? phone,
  }) async {
    await _client.from('listings').insert({
      'title': title,
      'category_id': categoryId,
      'region_id': regionId,
      'description': description,
      'phone': phone,
      'status': 'pending',
    });
  }
}
