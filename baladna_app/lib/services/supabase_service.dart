import 'package:supabase_flutter/supabase_flutter.dart';

/// استثناء ودّي يعرض رسالة عربية مفهومة بدل رسائل الأخطاء التقنية
class AppException implements Exception {
  final String message;
  AppException(this.message);
  @override
  String toString() => message;
}

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') || msg.contains('Failed host lookup')) {
        throw AppException('تعذر الاتصال بالإنترنت. تأكد من الاتصال وحاول مرة أخرى.');
      }
      if (msg.contains('TimeoutException')) {
        throw AppException('استغرق الطلب وقتًا طويلاً. حاول مرة أخرى.');
      }
      throw AppException('صار خطأ غير متوقع. حاول مرة أخرى.');
    }
  }

  Future<List<Map<String, dynamic>>> getGovernorates() {
    return _run(() async {
      final response = await _client
          .from('regions')
          .select()
          .eq('type', 'governorate')
          .order('sort_order')
          .timeout(const Duration(seconds: 12));
      return List<Map<String, dynamic>>.from(response);
    });
  }

  Future<List<Map<String, dynamic>>> getCategories({int upToVersion = 2}) {
    return _run(() async {
      final response = await _client
          .from('categories')
          .select()
          .eq('is_active', true)
          .lte('version_added', upToVersion)
          .order('sort_order')
          .timeout(const Duration(seconds: 12));
      return List<Map<String, dynamic>>.from(response);
    });
  }

  Future<List<Map<String, dynamic>>> getListings({
    String? categoryId,
    String? regionId,
    int limit = 20,
  }) {
    return _run(() async {
      var query = _client.from('listings').select().eq('status', 'approved');
      if (categoryId != null) query = query.eq('category_id', categoryId);
      if (regionId != null) query = query.eq('region_id', regionId);
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(const Duration(seconds: 12));
      return List<Map<String, dynamic>>.from(response);
    });
  }

  /// بحث عن الأنشطة بالاسم أو الوصف
  Future<List<Map<String, dynamic>>> searchListings(String query, {int limit = 30}) {
    return _run(() async {
      if (query.trim().isEmpty) return <Map<String, dynamic>>[];
      final response = await _client
          .from('listings')
          .select()
          .eq('status', 'approved')
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(const Duration(seconds: 12));
      return List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> addListing({
    required String title,
    required String categoryId,
    required String regionId,
    String? description,
    String? phone,
    String? whatsapp,
    String? addressText,
  }) {
    return _run(() async {
      await _client.from('listings').insert({
        'title': title,
        'category_id': categoryId,
        'region_id': regionId,
        'description': description,
        'phone': phone,
        'whatsapp': whatsapp ?? phone,
        'address_text': addressText,
        'status': 'pending',
      }).timeout(const Duration(seconds: 12));
    });
  }

  /// صور النشاط
  Future<List<Map<String, dynamic>>> getListingImages(String listingId) {
    return _run(() async {
      final response = await _client
          .from('listing_images')
          .select()
          .eq('listing_id', listingId)
          .order('sort_order')
          .timeout(const Duration(seconds: 12));
      return List<Map<String, dynamic>>.from(response);
    });
  }

  /// ساعات عمل النشاط
  Future<List<Map<String, dynamic>>> getListingHours(String listingId) {
    return _run(() async {
      final response = await _client
          .from('listing_hours')
          .select()
          .eq('listing_id', listingId)
          .order('day_of_week')
          .timeout(const Duration(seconds: 12));
      return List<Map<String, dynamic>>.from(response);
    });
  }

  /// زيادة عداد المشاهدات (بدون انتظار أو إظهار أخطاء للمستخدم)
  Future<void> incrementViews(String listingId, int currentViews) async {
    try {
      await _client
          .from('listings')
          .update({'views_count': currentViews + 1})
          .eq('id', listingId);
    } catch (_) {
      // تجاهل أي خطأ هنا، هذا إجراء ثانوي غير حرج
    }
  }

  // ==== إدارة العناصر قيد المراجعة ====

  Future<List<Map<String, dynamic>>> getPendingListings() {
    return _run(() async {
      final response = await _client
          .from('listings')
          .select('*, categories(name_ar, icon), regions(name_ar)')
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 12));
      return List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> approveListing(String id) {
    return _run(() async {
      await _client.from('listings').update({'status': 'approved'}).eq('id', id);
    });
  }

  Future<void> rejectListing(String id) {
    return _run(() async {
      await _client.from('listings').update({'status': 'rejected'}).eq('id', id);
    });
  }
}
