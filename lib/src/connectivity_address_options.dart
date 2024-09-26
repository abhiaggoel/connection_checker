part of '../connection_checker.dart';

abstract interface class AddressOption {
  /// More info on why default port is 53
  /// here:
  /// - https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
  /// - https://www.google.com/search?q=dns+server+port
  static const int _defaultPort = 53;

  /// Default timeout is 10 seconds.
  ///
  /// Timeout is the number of seconds before a request is dropped
  /// and an address is considered unreachable
  static const Duration _defaultTimeout = Duration(seconds: 10);
}

class SocketOption implements AddressOption {
  /// Only works with scheme `http` and `https`
  /// and `ws` and `wss`
  SocketOption({
    /// eg: "https://google.com" , "https://amazon.com"
    String? hostname,

    /// eg: "2606:4700:4700::1111" , ["2606:4700:4700::1111"]
    String? ipv6address,

    /// eg: "1.1.1.1" , https://8.8.8.8
    String? ipv4Address,
    int? port,
    Duration? timeout,
  })  : port = port ?? AddressOption._defaultPort,
        timeout = timeout ?? AddressOption._defaultTimeout,
        assert(_exactlyOneNotNull(hostname, ipv4Address, ipv6address),
            "Exactly one of hostname, IPv4_Address, IPv6_Address must be provided") {
    try {
      String shortenhost =
          AddressUtils().validHostAddress((hostname ?? ipv4Address)!);

      if (hostname != null) {
        host = shortenhost;
      }

      if (ipv4Address != null) {
        ipv4 = InternetAddress(shortenhost, type: InternetAddressType.IPv4);
      }

      if (ipv6address != null) {
        ipv6 = InternetAddress(ipv6address, type: InternetAddressType.IPv6);
      }
    } on FormatException catch (e) {
      debugPrint(e.message);
      rethrow;
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
  static bool _exactlyOneNotNull(Object? a, Object? b, Object? c) {
    return (a != null ? 1 : 0) + (b != null ? 1 : 0) + (c != null ? 1 : 0) == 1;
  }

  // /// eg: "google.com" , "one.one.one.one"
  // final String? hostname;

  /// The hostname to use for this connection checker.
  /// Will be used to resolve an IP address to open the socket connection to.
  /// Can be used to verify against services that are not guaranteed to have
  /// a fixed IP address. Connecting via hostname also verifies that
  /// DNS resolution is working for the client.
  /// Either [ipv4] or [host] or [ipv6] must not be null.
  String? host;

  // /// eg: "2001:4860:4860::8888" , [2048:63a0:ffff:fe00::1001]
  // final String? IPv6_Address;

  InternetAddress? ipv6;

  // /// eg: "192.0.43.10" , https://192.0.43.10
  // final String? IPv4_Address;

  InternetAddress? ipv4;

  /// Default set to 53
  final int? port;

  /// Default set to 10 second
  final Duration timeout;

  @override
  String toString() {
    return 'SocketOptions(\n'
        '  Hostname: ${host ?? ipv4 ?? ipv6},\n'
        '  timeout: $timeout,\n'
        '  port: $port,\n'
        ')';
  }
}

/// Options for checking the internet connectivity to an address.
///
/// This class provides a way to specify options for checking the connectivity
/// of an address. It includes the URI to check and the timeout duration for
/// the HEAD request.
///
/// *Usage Example:*
///
/// ```dart
/// final options = HttpOption(
///   uri: Uri.parse('https://example.com'),
///   timeout: Duration(seconds: 5),
///   ///   headers: {
///      'Authorization': 'Bearer token',
///   },
/// );
/// ```
class HttpOption implements AddressOption {
  /// Creates an [HttpOption] instance.
  ///
  /// Options for checking the internet connectivity to an address.
  ///
  /// This class provides a way to specify options for checking the connectivity
  /// of an address. It includes the URI to check and the timeout duration for
  /// the HEAD request.
  ///
  /// *Usage Example: With custom `responseStatusFn` callback:*
  ///
  /// ```dart
  /// final options = HttpOption(
  ///   uri: Uri.parse('https://example.com'),
  ///   timeout: Duration(seconds: 5),
  ///   headers: {
  ///      'Authorization': 'Bearer token',
  ///   },
  ///   responseStatusFn: (response) {
  ///     return response.statusCode >= 200 && response.statusCode < 300,
  ///   },
  /// );
  /// ```

  HttpOption({
    this.uri,
    this.url,
    Map<String, String>? headers,
    ResponseStatusFn? responseStatusFn,
    Duration? timeout,
  })  : responseStatusFn = responseStatusFn ?? defaultResponseStatusFn,
        headers = headers ?? defaultHeaders,
        timeout = timeout ?? AddressOption._defaultTimeout,
        assert(
          (uri != null) ^ (url != null),
          "Provide either uri or url",
        ) {
    try {
      uri ??= Uri.parse(url!);
      String? scheme;
      if (url != null) {
        scheme = AddressUtils().getScheme(url!);
        if (scheme != null && scheme != uri?.scheme) {
          throw Exception("Enter a Valid URL");
        }
      }

      if (uri?.scheme == null || uri?.scheme == "") {
        uri = Uri(
          scheme: "https",
          host: uri?.host,
          path: uri?.path,
          query: uri?.query,
          fragment: uri?.fragment,
          port: uri?.port,
          userInfo: uri?.userInfo,
          pathSegments: uri?.pathSegments,
          queryParameters: uri?.queryParameters,
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  /// The default [responseStatusFn]. Success is considered if the status code
  /// is `200`.
  ///
  /// Update this in the `main` function to change the default
  /// behaviour for all [uri] checks.
  ///
  /// *Usage Example:*
  ///
  /// ```dart
  /// void main() {
  ///   HttpOption.defaultResponseStatusFn = (response) {
  ///     return response.statusCode >= 200 && response.statusCode < 300;
  ///   };
  ///   runApp(MyApp());
  /// }
  /// ```

  static ResponseStatusFn defaultResponseStatusFn = (response) {
    return response.statusCode == 200;
  };

  /// Default headers to make sure the `Uri`s have no caching enabled.
  /// Otherwise, the results may be inaccurate.
  ///
  /// Cache-Control: 'no-cache, no-store, must-revalidate' tells the client not
  /// to cache the response and to always revalidate it.
  ///
  /// Pragma: 'no-cache' is used for backward compatibility
  /// with HTTP/1.0 clients.
  ///
  /// Expires: '0' ensures that the response is considered
  /// stale and not cached.
  static Map<String, String> defaultHeaders = {
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0',
  };

  /// URI to check for connectivity. A HEAD request will be made to this URI.
  ///
  /// Make sure that the cache-control header is set to `no-cache` on the server
  /// side. Otherwise, the HEAD request will be cached and the result will be
  /// incorrect.
  ///
  /// For `web` platform, make sure that the URI is _CORS_ enabled. To check if
  /// requests are being blocked, open the **Network tab** in your browser's
  /// developer tools and see if the request is being blocked by _CORS_.

  Uri? uri;

  /// URL to check for connectivity. A HEAD request will be made to this URL.
  ///
  String? url;

  /// A map of additional headers to send with the request.
  ///
  /// Make sure that the cache-control header is set to `no-cache` on the
  /// server side. Otherwise, the HEAD request will be cached and the result
  /// will be incorrect.
  /// For `web` platform, make sure that the URI is _CORS_ enabled. To check
  /// if requests are being blocked, open the **Network tab** in your browser's
  /// developer tools and see if the request is being blocked by _CORS_.
  /// For more information, see [this](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS).
  final Map<String, String> headers;

  /// A custom callback function to decide whether the request succeeded or not.
  ///
  /// It is useful if your [uri] returns `non-200` status code.
  ///
  /// *Usage Example:*
  ///
  /// ```dart
  /// responseStatusFn: (response) {
  ///   return response.statusCode >= 200 && response.statusCode < 300;
  /// }
  /// ```
  final ResponseStatusFn responseStatusFn;

  /// Default set to 10 second
  final Duration timeout;

  @override
  String toString() {
    return 'HttpOptions(\n'
        '  uri/url: ${uri ?? url},\n'
        '  timeout: $timeout,\n'
        '  responseStatusFn: ${responseStatusFn.toString()},\n'
        '  headers: ${headers.toString()}\n'
        ')';
  }
}

/// A Callback Function to decide whether the request succeeded or not.
typedef ResponseStatusFn = bool Function(http.Response response);
