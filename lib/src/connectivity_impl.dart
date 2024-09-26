part of '../connection_checker.dart';

/// This is a singleton that can be accessed like a regular constructor
/// i.e. [ConnectionChecker()] always returns the same instance.
class ConnectionChecker {
  /// This is a singleton that can be accessed like a regular constructor
  /// i.e. ConnectionChecker() always returns the same instance.
  factory ConnectionChecker(
      {Duration? timeout,
      Duration? timeInterval,
      List<AddressOption>? addresses,
      bool useDefaultOptions = true,
      bool useConnectivityPlus = false}) {
    _instance ??= ConnectionChecker._(
        addresses: addresses,
        useConnectivityPlus: useConnectivityPlus,
        useDefaultOptions: useDefaultOptions,
        timeout: timeout ?? _defaultTimeout,
        timeInterval: timeInterval ?? _defaultInterval);
    return _instance!;
  }

  /// Creates an instance of the [ConnectionChecker]. This can be
  /// registered in any dependency injection framework with custom values for
  /// the [checkTimeout] and [checkInterval].
  ConnectionChecker._(
      {this.timeout = _defaultTimeout,
      this.timeInterval = _defaultInterval,
      List<AddressOption>? addresses,
      bool useDefaultOptions = true,
      this.useConnectivityPlus = false})
      : assert(
          useDefaultOptions || addresses?.isNotEmpty == true,
          'You must provide a list of options if you are not using the '
          'default ones.',
        ) {
    _useDefaultAddress = useDefaultOptions;
    _addresses = [];
    if (_useDefaultAddress) {
      _addresses.addAll(
        _defaultCheckOptions.map((AddressOption e) {
          return e is SocketOption
              ? SocketOption(
                  hostname: e.host,
                  port: e.port,
                  timeout: timeout,
                )
              : e is HttpOption
                  ? HttpOption(
                      uri: e.uri,
                      // port: e.port,
                      timeout: timeout,
                    )
                  : throw ArgumentError(
                      'Unsupported AddressOption type: ${e.runtimeType}');
        }).toList(),
      );
    }
    if (addresses != null) {
      _addresses.addAll(addresses);
    }

    // start sending status updates to onConnectivityChanged when there are listeners
    // (emits only if there's any change since the last status update)
    _statusController.onListen = () {
      _updateConnectionStatus();
    };

    // stop sending status updates when no one is listening
    _statusController.onCancel = () {
      _handleStatusChangeCancel();
    };
  }

  static ConnectionChecker newInstance(
      {Duration? timeout,
      Duration? timeInterval,
      List<AddressOption>? addresses,
      bool useDefaultOptions = true,
      bool useConnectivityPlus = false}) {
    return ConnectionChecker._(
        addresses: addresses,
        useConnectivityPlus: useConnectivityPlus,
        useDefaultOptions: useDefaultOptions,
        timeout: timeout ?? _defaultTimeout,
        timeInterval: timeInterval ?? _defaultInterval);
  }

  /// Addresses:
  /// | Address        | Provider   | Info                                            |
  /// |:---------------|:-----------|:------------------------------------------------|
  /// | 1.1.1.1        | CloudFlare | https://1.1.1.1                                 |
  /// | 8.8.8.8        | Google     | https://developers.google.com/speed/public-dns/ |

  /// | URI                                                 | Description                                             |
  /// | :-------------------------------------------------- | :------------------------------------------------------ |
  /// | `https://api.coindesk.com/v1/bpi/currentprice.json` | CORS enabled, no-cache                                  |
  /// | `https://icanhazip.com`                             | CORS enabled, no-cache                   |
  /// | `https://reqres.in/api/users/1`                     | CORS enabled, no-cache                   |
  /// | `https://fast.com`                                  | CORS enabled, no-cache                   |

  final List<AddressOption> _defaultCheckOptions =
      List<AddressOption>.unmodifiable(
    <AddressOption>[
      SocketOption(
        hostname: '1.1.1.1', // CloudFlare
      ),
      SocketOption(
        hostname: '8.8.4.4',
        // Google
      ),
      // SocketOption(
      //   hostname: '192.0.43.8', // IANA
      //   // port: 443,
      // ),
      // SocketOption(
      //   hostname: '208.69.38.205', // OPENDNS
      //   // port: 443,
      // ),
      HttpOption(
        // https://icanhazip.com/
        uri: Uri(scheme: 'https', host: 'icanhazip.com', port: 443),
      ),
      HttpOption(
        // https://reqres.in/api/users/1
        uri: Uri(
            scheme: 'https',
            host: 'reqres.in',
            port: 443,
            path: '/api/users/1'),
      ),
      HttpOption(
        // https://api.coindesk.com/v1/bpi/currentprice.json
        uri: Uri(
            scheme: 'https',
            host: 'api.coindesk.com',
            port: 443,
            path: '/v1/bpi/currentprice.json'),
      ),
      HttpOption(
        // https://fast.com
        uri: Uri(
          scheme: 'https',
          host: 'fast.com',
          port: 443,
        ),
      ),
    ],
  );
  // final List<AddressOption> ipv6AddressOptions =
  //     List<AddressOption>.unmodifiable(<AddressOption>[
  //   SocketOption(
  //     IPv6_Address: '2606:4700:4700::1111', // CloudFlare
  //   ),
  //   SocketOption(
  //     IPv6_Address: '2001:4860:4860::8888', // Google
  //   ),
  //   SocketOption(
  //     IPv6_Address: '::ffff:c000:2b08', // IANA
  //   ),
  //   SocketOption(
  //     IPv6_Address: '::ffff:d045:26cd', // OPENDNS
  //   ),
  // ]);

  /// Default Interval is 1 seconds.
  /// Interval is the time between automatic checks
  /// Periodic checks are
  /// only made if there's an attached listener to [onConnectivityChanged].
  /// If that's the case [onConnectivityChanged] emits an update only if
  /// there's change from the previous status.
  static const Duration _defaultInterval = Duration(seconds: 1);

  /// Default timeout is 10 seconds.
  ///
  /// Timeout is the number of seconds before a request is dropped
  /// and an address is considered unreachable
  static const Duration _defaultTimeout = Duration(seconds: 10);

  late List<AddressOption> _addresses;

  // /// A list of internet addresses (with port and timeout) to ping.
  // ///
  // /// These should be globally available destinations.
  // /// Default is [DEFAULT_ADDRESSES].
  // ///
  // /// When [hasConnection] or [connectionStatus] is called,
  // /// this utility class tries to ping every address in this list.
  // ///
  // /// The provided addresses should be good enough to test for data connection
  // /// but you can, of course, supply your own.
  // ///
  // /// See [AddressOptions] for more info.
  // List<AddressOption> get addresses => _addresses;

  bool _useDefaultAddress = true;

  /// Set a list of CheckOptions to the address
  /// Once set other previous options will be removed
  /// and only the new options will be used
  /// If the list is empty, the default options will be used
  set addresses(List<AddressOption> value) {
    if (value.isEmpty && _useDefaultAddress == false) {
      setDefaultOptionsTrue();
      debugPrint('Address list cannot be empty, Default options will be used');
    } else {
      _useDefaultAddress = false;
      _addresses = List<AddressOption>.unmodifiable(value);
    }
    _updateConnectionStatus();
  }

  /// Adds the Default CheckOptions to the addresses
  void setDefaultOptionsTrue() {
    if (!_useDefaultAddress) {
      _addresses.addAll(
        _defaultCheckOptions.map((AddressOption e) {
          return e is SocketOption
              ? SocketOption(
                  hostname: e.host,
                  port: e.port,
                  timeout: timeout,
                )
              : e is HttpOption
                  ? HttpOption(
                      uri: e.uri,
                      // port: e.port,
                      timeout: timeout,
                    )
                  : throw ArgumentError(
                      'Unsupported AddressOption type: ${e.runtimeType}');
        }).toList(),
      );
      _useDefaultAddress = true;
      _updateConnectionStatus();
    }
  }

  static ConnectionChecker? _instance;

  /// Ping a single address. See [AddressOption] for
  /// info on the accepted argument.
  Future<AdressConnectionResult> checkConnectivity(
    AddressOption options,
  ) async {
    if (options is SocketOption) {
      Socket? sock;
      try {
        sock = await
            // compute((callback) {
            //   return
            Socket.connect(
          // If hostname is null, the [SocketOptions] constructor will have
          // asserted that ipv4 address or ipv6 address must not be null.

          // If port wasnt given then default port will be used
          options.host ?? options.ipv4 ?? options.ipv6,
          options.port!,
          timeout: options.timeout,
        )
              // ;}, null, debugLabel: "ConnectionChecker.checkConnectivity")?
              ..destroy();

        return AdressConnectionResult(
          options,
          isSuccess: true,
        );
      } on Exception catch (e) {
        sock?.destroy();
        debugPrint("SocketOption: $e");
        return AdressConnectionResult(
          options,
          isSuccess: false,
        );
      }
    } else if (options is HttpOption) {
      try {
        final response = await
            // compute((callback) {
            //   return
            http
                .head(options.uri!, headers: options.headers)
                .timeout(options.timeout);
        // }, null, debugLabel: "ConnectionChecker.checkConnectivity");

        return AdressConnectionResult(
          options,
          isSuccess: options.responseStatusFn(response),
        );
      } on Exception catch (e) {
        debugPrint("HttpOption: $e");

        return AdressConnectionResult(
          options,
          isSuccess: false,
        );
      }
    } else {
      throw ArgumentError(
        'Unsupported AddressOption type: ${options.runtimeType}',
      );
    }
  }

  /// Initiates a request to each address in [addresses].
  /// If at least one of the addresses is reachable
  /// we assume an internet connection is available and return `true`.
  /// `false` otherwise.
  Future<bool> get hasConnection async {
    final Completer<bool> result = Completer<bool>();
    int length = _addresses.length;

    for (final AddressOption addressOptions in _addresses) {
      unawaited(checkConnectivity(addressOptions).then(
        (AdressConnectionResult request) {
          length -= 1;
          if (!result.isCompleted) {
            if (request.isSuccess) {
              result.complete(true);
            } else if (length == 0) {
              result.complete(false);
            }
          } else {
            return;
          }
        },
      ));
    }

    return result.future;
  }

  /// Initiates a request to each address in [addresses].
  /// If at least one of the addresses is reachable
  /// we assume an internet connection is available and return
  /// [ConnectionStatus.connected].
  /// [ConnectionStatus.disconnected] otherwise.
  Future<ConnectionStatus> get connectionStatus async {
    return await hasConnection
        ? ConnectionStatus.connected
        : ConnectionStatus.disconnected;
  }

  /// Interval is the time between automatic checks
  /// Periodic checks are only made if there's an attached
  /// listener to [onConnectivityChanged]. If that's the case
  /// [onConnectivityChanged] emits an update only if
  /// there's change from the previous status.
  ///
  /// Defaults to (1 seconds).
  Duration timeInterval;

  /// Defaults to (10 seconds).
  /// If set then timeout will be used for all default
  /// address checks.
  /// Can provide different for each address individually.
  Duration timeout;

  // Checks the current status, compares it with the last and emits
  // an event only if there's a change and there are attached listeners
  //
  // If there are listeners, a timer is started which runs this function again
  // after the specified time in 'checkInterval'
  Future<void> _updateConnectionStatus() async {
    _connectivityPlusSubscription();
    // just in case
    _timerHandle?.cancel();

    final ConnectionStatus currentStatus = await connectionStatus;

    // start new timer only if there are listeners
    if (!_statusController.hasListener) return;

    // only send status update if last status differs from current
    // and if someone is actually listening
    if (_lastStatus != currentStatus && _statusController.hasListener) {
      _statusController.add(currentStatus);
    }

    _timerHandle = Timer(timeInterval, _updateConnectionStatus);

    // update last status
    _lastStatus = currentStatus;
  }

  void _handleStatusChangeCancel() {
    if (_statusController.hasListener) return;

    _connectivitySubscription?.cancel().then((_) {
      _connectivitySubscription = null;
    });
    _timerHandle?.cancel();
    _timerHandle = null;
    _lastStatus = null;
  }

  // _lastStatus should only be set by _updateConnectionStatus()
  // and the _statusController's.onCancel event handler
  ConnectionStatus? _lastStatus;

  ConnectionStatus? get lastStatus => _lastStatus;
  Timer? _timerHandle;

  // controller for the exposed 'onConnectivityChanged' Stream
  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();

  /// Subscribe to this stream to receive events whenever the
  /// [ConnectionStatus] changes. When a listener is attached
  /// a check is performed immediately and the status ([ConnectionStatus])
  /// is emitted. After that a timer starts which performs
  /// checks with the specified interval - [checkInterval].
  /// Default is [default_Interval].
  ///
  /// *As long as there's an attached listener, checks are being performed,
  /// so remember to dispose of the subscriptions when they're no longer needed.*
  ///
  /// Example:
  ///
  /// ```dart
  /// var listener = ConnectionChecker().onConnectivityChanged.listen((status) {
  ///   switch(status) {
  ///     case ConnectionStatus.connected:
  ///       print('Data connection is available.');
  ///       break;
  ///     case ConnectionStatus.disconnected:
  ///       print('You are disconnected from the internet.');
  ///       break;
  ///   }
  /// });
  /// ```
  ///
  /// *Note: Remember to dispose of any listeners,
  /// when they're not needed anymore,
  /// e.g. in a* `StatefulWidget`'s *dispose() method*
  ///
  /// ```dart
  /// ...
  /// @override
  /// void dispose() {
  ///   listener.cancel();
  ///   super.dispose();
  /// }
  /// ...
  /// ```
  ///
  /// For as long as there's an attached listener, requests are
  /// being made with an interval of `checkInterval`. The timer stops
  /// when an automatic check is currently executed, so this interval
  /// is a bit longer actually (the maximum would be `checkInterval` +
  /// the maximum timeout for an address in `addresses`). This is by design
  /// to prevent multiple automatic calls to `connectionStatus`, which
  /// would wreck havoc.
  ///
  /// You can, of course, override this behavior by implementing your own
  /// variation of time-based checks and calling either `connectionStatus`
  /// or `hasConnection` as many times as you want.
  ///
  /// When all the listeners are removed from `onConnectivityChanged`, the internal
  /// timer is cancelled and the stream does not emit events.
  Stream<ConnectionStatus> get onConnectivityChanged =>
      _statusController.stream;

  /// Returns true if there are any listeners attached to [onConnectivityChanged]
  bool get hasListeners => _statusController.hasListener;

  // /// Alias for [hasListeners]
  // bool get isActivelyChecking => _statusController.hasListener;

  bool useConnectivityPlus;
  void _connectivityPlusSubscription() {
    if (useConnectivityPlus) {
      _startListeningToConnectivityChanges();
    }
  }

  /// Connectivity subscription.
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Starts listening to connectivity changes from [connectivity_plus] package
  /// using the [Connectivity.onConnectivityChanged] stream.
  ///
  /// [connectivity_plus]: https://pub.dev/packages/connectivity_plus
  void _startListeningToConnectivityChanges() {
    if (_connectivitySubscription != null) return;
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (_) {
        if (_statusController.hasListener) {
          _updateConnectionStatus();
        }
      },
    );
  }
}
