library connection_checker;

import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

part 'src/utils/address_utils.dart';
part 'src/utils/connectivity_status.dart';
part 'src/connectivity_result.dart';
part 'src/connectivity_address_options.dart';
part 'src/connectivity_impl.dart';