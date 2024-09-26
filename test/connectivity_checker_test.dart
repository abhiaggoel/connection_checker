// Flutter Packages
import 'package:flutter_test/flutter_test.dart';

// This Package
import 'package:connection_checker/connection_checker.dart';

// Mocks
import '_mocks_/http_client_test.dart';

void main() {
  group('ConnectionChecker', () {
    group('hasConnection', () {
      test('returns true for valid URIs', () async {
        final checker = ConnectionChecker();
        expect(await checker.hasConnection, true);
      });

      test('returns false for invalid URIs', () async {
        final checker = ConnectionChecker(
          addresses: [
            HttpOption(
              uri: Uri.parse('https://www.a.com/nonexistent-pag'),
            ),
          ],
          useDefaultOptions: false,
        );
        expect(await checker.hasConnection, false);
      });

      test('invokes responseStatusFn to determine success', () async {
        const expectedStatus = true;
        final checker = ConnectionChecker(
          addresses: [
            HttpOption(
              uri: Uri.parse('https://www.example.com/nonexistent-page'),
              responseStatusFn: (response) => expectedStatus,
            ),
          ],
          useDefaultOptions: false,
        );

        expect(await checker.hasConnection, expectedStatus);
      });

      test('sends custom headers on request', () async {
        await TestHttpClient.run((client) async {
          const expectedStatus = true;
          const expectedHeaders = {'Authorization': 'Bearer token'};

          client.responseBuilder = (req) {
            for (final header in expectedHeaders.entries) {
              final key = header.key;
              if (!req.headers.containsKey(key) ||
                  req.headers[key] != header.value) {
                return TestHttpClient.createResponse(statusCode: 500);
              }
            }
            return TestHttpClient.createResponse(statusCode: 200);
          };
          final checker = ConnectionChecker(
            addresses: [
              HttpOption(
                uri: Uri.parse('https://www.example.com'),
                headers: expectedHeaders,
              ),
            ],
            useDefaultOptions: false,
          );

          expect(await checker.hasConnection, expectedStatus);
        });
      });
    });

    test('main constructor returns the same instance', () {
      final checker = ConnectionChecker();
      expect(checker, ConnectionChecker());
    });

    test('static newInstance method returns new instances', () {
      final checker = ConnectionChecker();
      expect(checker, isNot(ConnectionChecker.newInstance()));
    });
  });
}
