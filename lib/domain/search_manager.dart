import 'package:flutter/material.dart';

class SearchManager extends ChangeNotifier {
  String _inputSearchQuery = '';
  String _outputSearchQuery = '';
  List<TextRange> _inputMatches = [];
  List<TextRange> _outputMatches = [];
  int _inputCurrentMatch = 0;
  int _outputCurrentMatch = 0;

  String get inputSearchQuery => _inputSearchQuery;

  String get outputSearchQuery => _outputSearchQuery;

  List<TextRange> get inputMatches => _inputMatches;

  List<TextRange> get outputMatches => _outputMatches;

  int get inputCurrentMatch => _inputCurrentMatch;

  int get outputCurrentMatch => _outputCurrentMatch;

  void updateInputMatches(String text, String query) {
    _inputSearchQuery = query;
    _inputMatches = _findMatches(text, query);
    _inputCurrentMatch = _inputMatches.isNotEmpty ? 0 : 0;
    notifyListeners();
  }

  void updateOutputMatches(String text, String query) {
    _outputSearchQuery = query;
    _outputMatches = _findMatches(text, query);
    _outputCurrentMatch = _outputMatches.isNotEmpty ? 0 : 0;
    notifyListeners();
  }

  List<TextRange> _findMatches(String text, String query) {
    if (query.isEmpty) return [];
    final matches = <TextRange>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int start = 0;
    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) break;
      matches.add(TextRange(start: index, end: index + query.length));
      start = index + query.length;
    }
    return matches;
  }

  void nextInputMatch() {
    if (_inputMatches.isEmpty) return;
    _inputCurrentMatch = (_inputCurrentMatch + 1) % _inputMatches.length;
    notifyListeners();
  }

  void prevInputMatch() {
    if (_inputMatches.isEmpty) return;
    _inputCurrentMatch =
        (_inputCurrentMatch - 1 + _inputMatches.length) % _inputMatches.length;
    notifyListeners();
  }

  void nextOutputMatch() {
    if (_outputMatches.isEmpty) return;
    _outputCurrentMatch = (_outputCurrentMatch + 1) % _outputMatches.length;
    notifyListeners();
  }

  void prevOutputMatch() {
    if (_outputMatches.isEmpty) return;
    _outputCurrentMatch = (_outputCurrentMatch - 1 + _outputMatches.length) %
        _outputMatches.length;
    notifyListeners();
  }

  void clear() {
    _inputSearchQuery = '';
    _outputSearchQuery = '';
    _inputMatches = [];
    _outputMatches = [];
    _inputCurrentMatch = 0;
    _outputCurrentMatch = 0;
    notifyListeners();
  }
}