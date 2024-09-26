// Flutter Packages
import 'package:flutter_test/flutter_test.dart';

// This Package
import 'package:connection_checker/connection_checker.dart';

void main() {
  group('HttpOption', () {
    test('toString() returns correct string representation', () {
      final options = HttpOption(
        uri: Uri.parse('https://example.com'),
        timeout: const Duration(seconds: 5),
      );

      const expectedString = 'HttpOption(\n'
          '  uri: https://example.com,\n'
          '  timeout: 0:00:05.000000,\n'
          '  headers: {}\n'
          ')';

      expect(options.toString(), expectedString);
    });

    group('headers', () {
      test('are empty if not set', () {
        final options = HttpOption(
          uri: Uri.parse('https://example.com'),
        );

        expect(options.headers, {});
      });

      test('are set correctly', () {
        const headers = {'key': 'value'};

        final options = HttpOption(
          uri: Uri.parse('https://example.com'),
          headers: headers,
        );

        expect(options.headers, headers);
      });
    });

    group('responseStatusFn', () {
      test('is equal to defaultResponseStatusFn if not set', () {
        final options1 = HttpOption(
          uri: Uri.parse('https://example.com'),
        );

        expect(
          options1.responseStatusFn,
          equals(HttpOption.defaultResponseStatusFn),
        );
      });

      test('is set correctly', () {
        customResponseStatusFn(response) => true;

        final options1 = HttpOption(
          uri: Uri.parse('https://example.com'),
          responseStatusFn: customResponseStatusFn,
        );

        expect(options1.responseStatusFn, equals(customResponseStatusFn));
        expect(
          options1.responseStatusFn,
          isNot(equals(HttpOption.defaultResponseStatusFn)),
        );
      });
    });

    group('defaultResponseStatusFn', () {
      test('can be overriden', () {
        final options = HttpOption(
          uri: Uri.parse('https://example.com'),
        );

        HttpOption.defaultResponseStatusFn = (response) => true;

        expect(
          options.responseStatusFn,
          isNot(equals(HttpOption.defaultResponseStatusFn)),
        );
      });

      test('override is used', () {
        customResponseStatusFn(response) => true;

        HttpOption.defaultResponseStatusFn = customResponseStatusFn;

        final options = HttpOption(
          uri: Uri.parse('https://example.com'),
        );

        expect(options.responseStatusFn, equals(customResponseStatusFn));
      });
    });
  });
}