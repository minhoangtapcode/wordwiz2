import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class GameProvider with ChangeNotifier {
  final ApiService apiService = ApiService();
  // Danh sách từ vựng cho mỗi level và stage (sẽ thay bằng Firestore sau này)
  final Map<int, List<String>> wordLists = {
    1: ["cat", "dog", "sun", "pen", "cup", "hat", "box", "car", "bed", "bag"],
    2: ["tree", "fish", "moon", "book", "door", "cake", "ball", "shoe", "hand", "star"],
    3: ["house", "bird", "cloud", "chair", "table", "apple", "river", "clock", "shirt", "light"],
    4: ["forest", "tiger", "ocean", "window", "banana", "mirror", "garden", "pencil", "jacket", "bridge"],
    5: ["mountain", "elephant", "desert", "computer", "bicycle", "kitchen", "painting", "umbrella", "hospital", "guitar"],
  };

  String _clue = "";
  String _answer = "";
  String _feedback = "";
  String _hint = "";
  bool _isCorrect = false;
  bool _isTimeOut = false;
  bool _isIncorrect = false;
  int _score = 0;
  int _level = 1;
  int _stage = 1;
  int _wordsMastered = 0;
  int _incorrectAttempts = 0;
  List<String?> _revealedLetters = [];
  bool _isStageUnlocked = true;

  // Getters
  String get clue => _clue;
  String get answer => _answer;
  String get feedback => _feedback;
  String get hint => _hint;
  bool get isCorrect => _isCorrect;
  bool get isTimeOut => _isTimeOut;
  bool get isIncorrect => _isIncorrect;
  int get score => _score;
  int get level => _level;
  int get stage => _stage;
  int get wordsMastered => _wordsMastered;
  int get incorrectAttempts => _incorrectAttempts;
  List<String?> get revealedLetters => _revealedLetters;
  bool get isStageUnlocked => _isStageUnlocked;

  GameProvider() {
    // Load tiến độ từ SharedPreferences
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _score = prefs.getInt('score') ?? 0;
    _level = prefs.getInt('level') ?? 1;
    _stage = prefs.getInt('stage') ?? 1;
    _wordsMastered = prefs.getInt('wordsMastered') ?? 0;
    _isStageUnlocked = prefs.getBool('isStageUnlocked') ?? true;
    await startNewGame(_level, _stage);
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('score', _score);
    await prefs.setInt('level', _level);
    await prefs.setInt('stage', _stage);
    await prefs.setInt('wordsMastered', _wordsMastered);
    await prefs.setBool('isStageUnlocked', _isStageUnlocked);
  }

  Future<void> startNewGame(int level, int stage) async {
    try {
      final words = wordLists[level] ?? wordLists[1]!;
      final word = words[stage - 1];
      final clueData = await apiService.generateClue(word, "Level $level");
      _clue = clueData['clue'];
      _answer = word;
      _feedback = "";
      _hint = "";
      _isCorrect = false;
      _isTimeOut = false;
      _isIncorrect = false;
      _level = level;
      _stage = stage;
      _incorrectAttempts = 0;
      _revealedLetters = List<String?>.filled(word.length, null)..[0] = word[0];
      await _saveProgress();
      notifyListeners();
    } catch (e) {
      _clue = "This is a common pet.";
      _answer = "cat";
      _feedback = "";
      _hint = "";
      _isCorrect = false;
      _isTimeOut = false;
      _isIncorrect = false;
      _level = level;
      _stage = stage;
      _incorrectAttempts = 0;
      _revealedLetters = List<String?>.filled("cat".length, null)..[0] = "c";
      await _saveProgress();
      notifyListeners();
    }
  }

  void submitGuess(List<String?> guessedLetters) {
    final guessedWord = guessedLetters.join().toLowerCase();
    if (guessedWord == _answer.toLowerCase()) {
      _isCorrect = true;
      _score += 10;
      _wordsMastered += 1;
      _isStageUnlocked = _stage < 10 ? true : _level < 5;
      _incorrectAttempts = 0;
    } else {
      _incorrectAttempts += 1;
      if (_incorrectAttempts >= 3) {
        _isIncorrect = true;
        _incorrectAttempts = 0;
      } else {
        _feedback = "Try again!";
      }
    }
    _saveProgress();
    notifyListeners();
  }

  Future<void> showHint() async {
    try {
      final hintData = await apiService.generateHint(_answer);
      _hint = hintData['hint'];
    } catch (e) {
      _feedback = "Error fetching hint: $e";
    }
    _saveProgress();
    notifyListeners();
  }

  Future<void> playAgain(int level, int stage) async {
    await startNewGame(level, stage);
  }

  void quit() {
    _saveProgress();
    notifyListeners();
  }
}