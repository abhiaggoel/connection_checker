// Flutter Packages
import 'package:flutter_test/flutter_test.dart';

// This Package
import 'package:connection_checker/connection_checker.dart';

void main() {
  group('AdressConnectionResult', () {
    test('toString() returns correct string representation', () {
      HttpOption option = HttpOption(
        uri: Uri.parse('https://example.com'),
        timeout: const Duration(seconds: 3),
      );
      AdressConnectionResult result = AdressConnectionResult(
        option,
        isSuccess: true,
      );

      String expectedString = 'AdressConnectionResult(\n'
          '  option: HttpOption(\n'
          '    uri: https://example.com,\n'
          '    timeout: 0:00:03.000000,\n'
          '    headers: {}\n'
          '  ),\n'
          '  isSuccess: true\n'
          ')';

      expect(result.toString(), expectedString);
    });

    test('with different options are not equal', () {
      HttpOption option1 = HttpOption(
        uri: Uri.parse('https://example.com'),
        timeout: const Duration(seconds: 3),
      );
      HttpOption option2 = HttpOption(
        uri: Uri.parse('https://example.org'),
        timeout: const Duration(seconds: 5),
      );
      AdressConnectionResult result1 = AdressConnectionResult(
         option1,
        isSuccess: true,
      );
      AdressConnectionResult result2 = AdressConnectionResult(
        option2,
        isSuccess: true,
      );

      expect(result1, isNot(equals(result2)));
    });
  });
}
