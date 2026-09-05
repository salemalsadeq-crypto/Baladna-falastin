import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// يعالج مشكلة فشل الاتصال على بعض الأجهزة اللي عندها خلل بنظام
/// تحليل أسماء النطاقات (DNS) الخاص بالنظام، رغم إن المتصفح يشتغل
/// بشكل طبيعي على نفس الجهاز (لأن المتصفح يستخدم DNS خاص فيه).
///
/// يحاول أولاً الطريقة العادية، ولو فشلت يستخدم DNS عبر HTTPS
/// (خدمة جوجل العامة) كبديل، ثم يتصل مباشرة بالعنوان الناتج.
class DnsFallbackHttpOverrides extends HttpOverrides {
  static final Map<String, InternetAddress> _cache = {};

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionFactory = (Uri uri, String? proxyHost, int? proxyPort) async {
      InternetAddress? address = _cache[uri.host];

      if (address == null) {
        try {
          final results =
              await InternetAddress.lookup(uri.host).timeout(const Duration(seconds: 4));
          if (results.isNotEmpty) address = results.first;
        } catch (_) {
          // فشلت الطريقة العادية، بنجرب البديل تحت
        }
      }

      address ??= await _resolveViaDoH(uri.host);

      if (address == null) {
        throw SocketException('تعذر الوصول للخادم: ${uri.host}');
      }

      _cache[uri.host] = address;

      final socket = await Socket.connect(address, uri.port,
          timeout: const Duration(seconds: 8));
      return ConnectionTask.fromSocket(socket, () => socket.destroy());
    };
    return client;
  }

  Future<InternetAddress?> _resolveViaDoH(String host) async {
    try {
      final dohSocket = await SecureSocket.connect(
        '8.8.8.8',
        443,
        timeout: const Duration(seconds: 5),
      );
      final request = 'GET /resolve?name=$host&type=A HTTP/1.1\r\n'
          'Host: dns.google\r\n'
          'Connection: close\r\n\r\n';
      dohSocket.write(request);
      await dohSocket.flush();

      final responseBytes = <int>[];
      await for (final chunk in dohSocket) {
        responseBytes.addAll(chunk);
      }
      dohSocket.destroy();

      final response = utf8.decode(responseBytes, allowMalformed: true);
      final bodyStart = response.indexOf('\r\n\r\n');
      if (bodyStart == -1) return null;
      final body = response.substring(bodyStart + 4);
      final jsonStart = body.indexOf('{');
      if (jsonStart == -1) return null;
      final data = jsonDecode(body.substring(jsonStart));
      final answers = data['Answer'] as List?;
      if (answers == null || answers.isEmpty) return null;
      for (final a in answers) {
        if (a['type'] == 1) {
          return InternetAddress(a['data']);
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
