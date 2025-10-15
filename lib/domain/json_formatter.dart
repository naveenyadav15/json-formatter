import 'dart:convert';
import 'package:flutter/material.dart';

class JsonFormatter extends ChangeNotifier {
  String _input = '';
  String _output = '';
  String _error = '';

  String get input => _input;

  String get output => _output;

  String get error => _error;

  void formatJson(String rawInput) {
    _input = rawInput;
    if (rawInput.trim().isEmpty) {
      _output = '';
      _error = '';
    } else {
      try {
        // final decoded = json.decode(rawInput) as Map<String, dynamic>;
        // final message = decoded['message'];
        // if (message is String) {
        //   try {
        //     decoded['message'] = json.decode(message);
        //   } catch (_) {}
        // }
        final decoded = fullyDecodeJson(rawInput);
        _output = const JsonEncoder.withIndent('  ').convert(decoded);
        _error = '';
      } on FormatException catch (e) {
        _output = '';
        _error = 'Error: [${e.message}]\nAt offset: ${e.offset}';
      } catch (e) {
        _output = '';
        _error = 'Unexpected error: $e';
      }
    }
    notifyListeners();
  }

  dynamic fullyDecodeJson(String jsonString) {
    dynamic decodeNested(dynamic data) {
      if (data is String) {
        // Try decoding string if it looks like JSON
        try {
          final decoded = jsonDecode(data);
          return decodeNested(decoded); // Recursively decode again
        } catch (_) {
          return data; // Not JSON, return as is
        }
      } else if (data is Map<String, dynamic>) {
        return data.map((key, value) => MapEntry(key, decodeNested(value)));
      } else if (data is List) {
        return data.map(decodeNested).toList();
      }
      return data;
    }

    final firstDecode = jsonDecode(jsonString);
    return decodeNested(firstDecode);
  }

  void clear() {
    _input = '';
    _output = '';
    _error = '';
    notifyListeners();
  }
}
