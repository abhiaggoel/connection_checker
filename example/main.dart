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
