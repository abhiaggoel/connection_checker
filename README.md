# ConnectionChecker

**ConnectionChecker** is a simple Flutter package that allows you to check for internet connectivity or the connectivity status of any URI provided by the user. This package provides an easy way to verify if a device is online or can access a specific endpoint, making it perfect for apps that need network status validation.

[![pub package][package_svg]][package]

[![GitHub][license_svg]](LICENSE)


## Features

- Check internet connectivity.
- Verify connectivity to any specific URI.
- Lightweight and easy to integrate into Flutter projects.
- Handles different network types (Wi-Fi, mobile data, etc.).
- Use Sockets for fast and reliable connectivity checks.

## Installation

Add the package to your `pubspec.yaml` file:

```yaml
dependencies:
  connection_checker: ^0.0.3
```

Then, run the following command to get the dependencies:

```bash
flutter pub get connection_checker
```

## Usage

### Android Permissions
Android apps must declare their use of the internet in the Android manifest (AndroidManifest.xml):
```xml
<manifest xmlns:android...>
 ...
 <uses-permission android:name="android.permission.INTERNET" />
 <application ...
</manifest>
```

### IOS Permissions
For iOS, following must be put in Info-debug.plist:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### macOS Permissions
macOS apps must allow network access in the relevant *.entitlements files.
```xml
<key>com.apple.security.network.client</key>
<true/>
```

### Check Internet Connectivity

To check if the device is connected to the internet:

```dart
import 'package:connection_checker/connection_checker.dart';

void checkConnectivity() async {
  bool isConnected = await ConnectionChecker.hasConnection();
  print('Internet Connected: $isConnected');
}
```

### Check Connectivity to a Specific URI

To check if a specific URI is reachable:

```dart
import 'package:connection_checker/connection_checker.dart';

void checkConnectivity() async {
  String uri = 'https://example.com';
  bool isConnected = await ConnectionChecker.checkConnectivity(HttpOption(url:uri));
  print('Connected to $uri: $isConnected');
}
```

### Listen to Connectivity Changes

You can also subscribe to changes in the device’s connectivity status (online/offline):

```dart
import 'package:connection_checker/connection_checker.dart';

void monitorConnectivityChanges() {
  ConnectionChecker.onConnectivityChanged.listen((status) {
    if (status == ConnectivityResult.connected) {
      print('Device is online');
    } else {
      print('Device is offline');
    }
  });
}
```

## API Reference

### 1. `checkConnectivity()`

- **Description**: Checks if the device has an active internet connection.
- **Returns**: A `Future<bool>` which resolves to `true` if connected, `false` otherwise.

### 2. `checkConnectivity(String url)`

- **Description**: Checks if a specific URI is reachable over the internet.
- **Parameters**:
  - `url` (String): The URI to check.
- **Returns**: A `Future<bool>` which resolves to `true` if the URI is reachable, `false` otherwise.

### 3. `onConnectivityChanged`

- **Description**: A stream that listens for connectivity changes.
- **Returns**: A `Stream<ConnectivityResult>` which broadcasts changes in connectivity (e.g., `connected`, `disconnected`).

## Example

Here’s a complete example of how to use **ConnectionChecker** in a Flutter app:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connection_checker/connection_checker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLifecycleListener _listener;
  late final StreamSubscription<ConnectionStatus> _subscription;
  ValueNotifier<bool> res = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    var i = ConnectionChecker();

    _subscription = i.onConnectivityChanged.listen((status) {
      res.value = status == ConnectionStatus.connected;
    });

    _listener = AppLifecycleListener(
      onResume: _subscription.resume,
      onHide: _subscription.pause,
      onDetach: _subscription.cancel,
      onPause: _subscription.pause,
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ValueListenableBuilder(
            valueListenable: res,
            builder: (context, value, child) {
              return Text("$value");
            },
          ),
        ),
      ),
    );
  }
}
```

## Contributing

Contributions are welcome! Feel free to open a pull request or submit issues in the [GitHub repository](https://github.com/abhiaggoel/connection_checker).


## Current working

making it compatible with web, having issues with web connectivity
