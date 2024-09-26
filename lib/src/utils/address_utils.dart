part of '../../connection_checker.dart';

class AddressUtils {
  /// Captures the String before the port colon
  /// which could be of length between 1 and 5
  /// if match is found empty returns the input
  ///
  /// may misfunction if user information is used
  ///
  static String trimPort(String input) {
    Match? schemeMatch = AddressRegexUtils.schemeRegex.firstMatch(input);
    String withoutScheme = trimScheme(input);
    String pathQueryFragment =
        withoutScheme.substring(trimAnyPathQueryFragment(withoutScheme).length);
    Match? hostPortmatch = AddressRegexUtils.groupHostPortRegex
        .firstMatch(trimAnyPathQueryFragment(withoutScheme));
    if (hostPortmatch != null && hostPortmatch.groupCount >= 2) {
      String withoutSchemePort = hostPortmatch.group(1)! + pathQueryFragment;
      return schemeMatch == null
          ? withoutSchemePort
          : schemeMatch.group(0)! + withoutSchemePort;
    } else {
      return input;
    }
    // return input.replaceFirst(RegExp(r':\d{1,5}'), '');
  }

  /// Removes the Scheme from the input
  ///
  /// if no scheme is present returns the input
  static String trimScheme(String input) {
    return input.replaceFirst(AddressRegexUtils.schemeRegex, '');
  }

  /// Captures the String before the path or
  /// query or fragment
  static String trimAnyPathQueryFragment(String input) {
    Match? schemeMatch = AddressRegexUtils.schemeRegex.firstMatch(input);
    String schemeHostPort = AddressRegexUtils.removePathQueryFragmentRegex
        .firstMatch(trimScheme(input))!
        .group(0)!;
    if (schemeMatch == null) {
      return schemeHostPort;
    }
    return schemeMatch.group(0)! + schemeHostPort;
  }

  String validHostAddress(String url) {
    try {
      Uri parseUri = Uri.parse(url);
      if (AddressRegexUtils.schemeRegex.hasMatch(url)) {
        if (parseUri.host == "") {
          throw Exception("Invalid or Empty Host Name");
        }
        // if (parseUri.scheme == "https" ||
        //     parseUri.scheme == "http" ||
        //     parseUri.scheme == "ws" ||
        //     parseUri.scheme == "wss") {
        return parseUri.host;
        // } else {
        //   return "false";
        // }
      } else {
        Match? groupHostPortMatch =
            AddressRegexUtils.removePathQueryFragmentRegex.firstMatch(url);
        if (groupHostPortMatch != null) {
          if (AddressRegexUtils.groupHostPortRegex
                  .firstMatch(groupHostPortMatch.group(0)!) ==
              null) {
            return parseUri.path;
          } else {
            return parseUri.scheme;
          }
        } else {
          throw Exception("Invalid or Empty Host Name");
        }
      }
    } on FormatException catch (e) {
      if (e.message == "Scheme not starting with alphabetic character") {
        Match? hostandportmatch =
            AddressRegexUtils.removePathQueryFragmentRegex.firstMatch(url);
        String? ipv4withport = hostandportmatch?.group(0);
        if (ipv4withport != null) {
          Match? hostmatch =
              AddressRegexUtils.groupHostPortRegex.firstMatch(ipv4withport);
          if (hostmatch != null &&
              hostmatch.groupCount >= 2 &&
              AddressRegexUtils.ipv4Regex.hasMatch(hostmatch.group(1)!) &&
              AddressRegexUtils.containsNumbersOnlyRegex
                  .hasMatch(hostmatch.group(2)!) &&
              hostmatch.group(2)!.length <= 5) {
            return hostmatch.group(1)!;
          }
        }
      } else if (e.message == "Invalid empty scheme") {
        throw Exception(e.message);
      }
      throw Exception("Invalid Host Name");
    } on Exception catch (exception) {
      throw Exception(exception.toString());
    }
  }

  /// Returns the Scheme from the input
  ///
  /// if no scheme is present returns null
  /// eg: input = "https://example.com/path?query#fragment;"
  /// returns "https"
  String? getScheme(String input) {
    String? match = AddressRegexUtils.schemeRegex.firstMatch(input)?.group(0);
    if (match != null) return RegExp(r'^[a-zA-Z]+').firstMatch(match)?.group(0);
    return null;
  }
}

class AddressRegexUtils {
  /// Captures the String before the path or
  /// query or fragment
  ///
  /// Gives match null if only path or query
  /// or fragment is Provided
  /// Example:
  /// ```dart
  /// String a = example.com/path?query#fragment;
  /// String b = https://example.com/path?query#fragment;
  /// String c = /path?query=1#fragment;
  /// String res1 = pathQueryFragmentRegex.firstMatch(a).group(0);
  /// String res2 = pathQueryFragmentRegex.firstMatch(b).group(0);
  /// String res3 = pathQueryFragmentRegex.firstMatch(c).group(0);
  /// ```
  /// `Output:`
  /// res1 = example.com , res2 = https: , res3 is null
  ///
  static RegExp removePathQueryFragmentRegex =
      RegExp(r'(?:^[^:]+:\/\/|^)([^/?#]+)');

  /// Captures the Scheme of Uri before any authority or path
  ///
  /// Example:
  /// ```dart
  /// String a = https://example.com/path;
  /// String res1 = schemeRegex.firstMatch(a).group(0);
  /// String b = file:///C:/users/user/example.txt;
  /// String res2 = schemeRegex.firstMatch(b).group(0);
  /// ```
  /// `Output:`
  /// res1 = https:// , res2 = file://
  static RegExp schemeRegex = RegExp(r'^[a-zA-Z]+:\/\/');

  /// Captures the String before the port colon
  /// which could be of length between 1 and 5
  ///
  /// may misfunction if user information is present in URI
  ///
  /// if port is not present or is of length 6 or above
  /// will match null
  ///
  /// use it after clearing the path,query and fragment
  /// By default it clears the path,query and fragment
  ///
  /// Example:
  /// ```dart
  /// String a = https://example.com:80/path;
  /// String res1 = removePortRegex.firstMatch(a).group(0);
  /// String b = https://example.com/path;
  /// String res2 = removePortRegex.firstMatch(b).group(0);
  /// ```
  /// `Output:`
  /// res1 = https://example.com , res2 = null
  ///
  static RegExp removePortRegex = RegExp(r'^.*?(?=:\d{1,5}(?!\d))');

  /// Captures the String before the port colon on group 1
  /// and after the port colon on group 2
  /// if no colon is present will match null
  /// group 0 gives the complete capture
  /// Use this after clearing the path,query and fragment

  static RegExp groupHostPortRegex = RegExp(r'^(.*):(.*)$');

  /// Checks if the String contains only numbers
  static RegExp containsNumbersOnlyRegex = RegExp(r'^\d+$');

  /// Checks if the String is a Valid Ipv4 Address
  /// match null if contains any other character
  /// or is not a valid ipv4 address
  /// Example:
  /// ```dart
  /// List<String> ipv4List = ['255.255.255.255', '127.0.0.1.1', '256.256.256.256', '0.0.0.0'];
  /// List<bool> ipv4ListRes = ipv4List.map((e) => ipv4Regex.hasMatch(e)).toList();
  /// ```
  ///
  /// `Output:`
  /// ipv4ListRes = [true, false, false, true]
  static RegExp ipv4Regex = RegExp(
      r'^(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])){3}$');
}
