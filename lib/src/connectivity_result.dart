part of '../connection_checker.dart';

/// Helper class that contains the address options and indicates whether
/// opening a socket to it succeeded.
class AdressConnectionResult {
  /// [AdressConnectionResult] constructor
  AdressConnectionResult(
    this.option, {
    required this.isSuccess,
  });

  /// AddressOption
  final AddressOption option;

  /// bool val to store result
  final bool isSuccess;

  @override
  String toString() {
    return 'AdressConnectionResult(\n'
        '   ${option.toString().replaceAll('\n', '\n  ')},\n'
        '  isSuccess: $isSuccess\n'
        ')';
  }
}
