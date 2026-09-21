import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:psgmx_mobile/core/supabase_config.dart';
import 'package:psgmx_mobile/services/trusted_api_response.dart';

void main() {
  group('trusted API origin', () {
    test('routes frontend-only production hosts to the web API', () {
      for (final value in [
        'https://psgmx.tech',
        'https://app.psgmx.tech/',
        'https://psgmxians.web.app',
        'https://psgmxians.firebaseapp.com/',
      ]) {
        expect(
          SupabaseConfig.normalizeAppApiUrl(value),
          'https://www.psgmx.tech',
        );
      }
    });

    test('preserves local and custom API origins without trailing slash', () {
      expect(
        SupabaseConfig.normalizeAppApiUrl('http://localhost:3000/'),
        'http://localhost:3000',
      );
    });
  });

  group('trusted API response', () {
    test('decodes valid JSON objects', () {
      final response = http.Response(
        '{"ok":true}',
        200,
        headers: {'content-type': 'application/json'},
      );
      expect(decodeTrustedJson(response)['ok'], isTrue);
    });

    test('never exposes a frontend HTML document as a parser error', () {
      final response = http.Response(
        '<!DOCTYPE html><html><body>app</body></html>',
        200,
        headers: {'content-type': 'text/html'},
      );
      expect(
        () => decodeTrustedJson(response),
        throwsA(
          isA<TrustedApiException>().having(
            (error) => error.message,
            'message',
            contains('outdated service address'),
          ),
        ),
      );
    });
  });
}
