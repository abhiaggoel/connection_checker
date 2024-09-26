part of '../connection_checker.dart';

/// Helper class that contains the address options and indicates whether
/// opening a socket to it succeeded.
class AddressConnectionResult {
  /// [AddressConnectionResult] constructor
  AddressConnectionResult(
    this.option, {
      this.exception,
    required this.isSuccess,
  });

  /// AddressOption
  final AddressOption option;

  /// bool val to store result
  final bool isSuccess;

  /// Gives the exception Result if successful connection
  /// wasn't made.
  final Exception? exception;

  @override
  String toString() {
    return 'AddressConnectionResult(\n'
        '   ${option.toString().replaceAll('\n', '\n  ')},\n'
        '  isSuccess: $isSuccess\n'
        ')';
  }
}
