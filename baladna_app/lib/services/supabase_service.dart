import 'package:supabase_flutter/supabase_flutter.dart';

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
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw AppException('البريد الإلكتروني أو كلمة السر غير صحيحة.');
      }
      if (e.message.contains('already registered')) {
        throw AppException('هذا البريد مسجّل من قبل. جرّب تسجيل الدخول.');
      }
      throw AppException(e.message);
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
    String? price,
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
        'owner_id': currentUser?.id,
        'status': 'pending',
        if (price != null && price.trim().isNotEmpty) 'custom_fields': {'price': price.trim()},
      }).timeout(const Duration(seconds: 12));
    });
  }

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

  Future<void> incrementViews(String listingId, int currentViews) async {
    try {
      await _client.from('listings').update({'views_count': currentViews + 1}).eq('id', listingId);
    } catch (_) {}
  }

  // ==== أنشطتي الخاصة ====

  Future<List<Map<String, dynamic>>> getMyListings() {
    return _run(() async {
      final uid = currentUser?.id;
      if (uid == null) return <Map<String, dynamic>>[];
      final response = await _client
          .from('listings')
          .select('*, categories(name_ar, icon), regions(name_ar)')
          .eq('owner_id', uid)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 12));
      return List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> updateListing(String id, Map<String, dynamic> fields) {
    return _run(() async {
      await _client.from('listings').update(fields).eq('id', id);
    });
  }

  Future<void> deleteListing(String id) {
    return _run(() async {
      await _client.from('listings').delete().eq('id', id);
    });
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
      final listing = await _client.from('listings').select('owner_id, title').eq('id', id).maybeSingle();
      await _client.from('listings').update({'status': 'approved'}).eq('id', id);
      if (listing != null && listing['owner_id'] != null) {
        await _addNotification(
          listing['owner_id'],
          'تمت الموافقة على نشاطك ✅',
          'نشاطك "${listing['title']}" صار ظاهر للجميع الآن.',
        );
      }
    });
  }

  Future<void> rejectListing(String id) {
    return _run(() async {
      final listing = await _client.from('listings').select('owner_id, title').eq('id', id).maybeSingle();
      await _client.from('listings').update({'status': 'rejected'}).eq('id', id);
      if (listing != null && listing['owner_id'] != null) {
        await _addNotification(
          listing['owner_id'],
          'تم رفض نشاطك',
          'نشاطك "${listing['title']}" لم يجتز المراجعة. تواصل معنا لمزيد من التفاصيل.',
        );
      }
    });
  }

  // ==== إحصائيات المدير ====

  Future<Map<String, dynamic>> getAdminStats() {
    return _run(() async {
      final listings = await _client.from('listings').select('status, views_count');
      final users = await _client.from('profiles').select('id');
      int approved = 0, pending = 0, rejected = 0, totalViews = 0;
      for (final l in listings) {
        final s = l['status'];
        if (s == 'approved') approved++;
        if (s == 'pending') pending++;
        if (s == 'rejected') rejected++;
        totalViews += (l['views_count'] as int? ?? 0);
      }
      return {
        'approved': approved,
        'pending': pending,
        'rejected': rejected,
        'totalViews': totalViews,
        'totalUsers': (users as List).length,
        'totalListings': (listings as List).length,
      };
    });
  }

  // ==== المصادقة والحساب ====

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signUp({required String email, required String password, String? fullName}) {
    return _run(() async {
      final res = await _client.auth.signUp(email: email, password: password);
      if (res.user != null) {
        await _client.from('profiles').upsert({'id': res.user!.id, 'full_name': fullName});
        await _addNotification(
          res.user!.id,
          'أهلاً فيك بتطبيق بلدنا فلسطين 🇵🇸',
          'مبسوطين انك انضممت الينا. استكشف الأقسام وأضف نشاطك الأول!',
        );
      }
    });
  }

  Future<void> signIn({required String email, required String password}) {
    return _run(() async {
      await _client.auth.signInWithPassword(email: email, password: password);
    });
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ==== المفضلة ====

  Future<bool> isFavorite(String listingId) async {
    final uid = currentUser?.id;
    if (uid == null) return false;
    try {
      final res = await _client
          .from('favorites')
          .select()
          .eq('user_id', uid)
          .eq('listing_id', listingId)
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleFavorite(String listingId, bool currentlyFavorite) {
    return _run(() async {
      final uid = currentUser?.id;
      if (uid == null) throw AppException('سجّل دخولك أولاً لإضافة المفضلة');
      if (currentlyFavorite) {
        await _client.from('favorites').delete().eq('user_id', uid).eq('listing_id', listingId);
      } else {
        await _client.from('favorites').insert({'user_id': uid, 'listing_id': listingId});
      }
    });
  }

  Future<List<Map<String, dynamic>>> getFavoriteListings() {
    return _run(() async {
      final uid = currentUser?.id;
      if (uid == null) return <Map<String, dynamic>>[];
      final response = await _client
          .from('favorites')
          .select('listing_id, listings(*)')
          .eq('user_id', uid)
          .timeout(const Duration(seconds: 12));
      return List<Map<String, dynamic>>.from(response)
          .where((r) => r['listings'] != null)
          .map((r) => Map<String, dynamic>.from(r['listings']))
          .toList();
    });
  }

  // ==== التقييمات ====

  Future<List<Map<String, dynamic>>> getRatings(String listingId) {
    return _run(() async {
      final response = await _client
          .from('ratings')
          .select()
          .eq('listing_id', listingId)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 12));
      return List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> addOrUpdateRating(String listingId, int rating, String? comment) {
    return _run(() async {
      final uid = currentUser?.id;
      if (uid == null) throw AppException('سجّل دخولك أولاً لإضافة تقييم');
      await _client.from('ratings').upsert(
        {
          'listing_id': listingId,
          'user_id': uid,
          'rating': rating,
          'comment': comment,
        },
        onConflict: 'listing_id,user_id',
      );
    });
  }

  // ==== الإشعارات ====

  Future<int> getUnreadNotificationsCount() async {
    final uid = currentUser?.id;
    if (uid == null) return 0;
    try {
      final res = await _client.from('notifications').select('id').eq('user_id', uid).eq('is_read', false);
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications() {
    return _run(() async {
      final uid = currentUser?.id;
      if (uid == null) return <Map<String, dynamic>>[];
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 12));
      return List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> markNotificationRead(String id) async {
    try {
      await _client.from('notifications').update({'is_read': true}).eq('id', id);
    } catch (_) {}
  }

  Future<void> _addNotification(String userId, String title, String body) async {
    try {
      await _client.from('notifications').insert({'user_id': userId, 'title': title, 'body': body});
    } catch (_) {}
  }
}
