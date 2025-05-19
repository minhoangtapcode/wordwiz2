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

  // Solo mode state
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

  // Multiplayer mode state
  List<Map<String, dynamic>> _players = [
    {'uid': 'player1', 'score': 0},
    {'uid': 'player2', 'score': 0},
    {'uid': 'player3', 'score': 0},
    {'uid': 'player4', 'score': 0},
  ];
  String _currentWord = '';
  List<String> _usedWords = [];
  String _currentTurn = 'player1';
  bool _isGameOver = false;
  String _multiplayerFeedback = '';

  // Getters for solo mode
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

  // Getters for multiplayer mode
  List<Map<String, dynamic>> get players => _players;
  String get currentWord => _currentWord;
  List<String> get usedWords => _usedWords;
  String get currentTurn => _currentTurn;
  bool get isGameOver => _isGameOver;
  String get multiplayerFeedback => _multiplayerFeedback;

  GameProvider() {
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

  // Solo mode methods
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

  // Multiplayer mode methods
  Future<void> submitMultiplayerWord(String word) async {
    try {
      final validationResult = await apiService.validateWord(word, _currentWord.isEmpty ? word : _currentWord, _usedWords);
      bool isValid = validationResult['is_valid'] == true || validationResult['is_valid'] == "true";
      String message = validationResult['message']?.toString() ?? 'Invalid word!';

      if (isValid) {
        _currentWord = word;
        _usedWords.add(word);
        final playerIndex = _players.indexWhere((p) => p['uid'] == _currentTurn);
        _players[playerIndex]['score'] += 10;
        _currentTurn = _players[(playerIndex + 1) % _players.length]['uid'];
        _multiplayerFeedback = '';
      } else {
        _multiplayerFeedback = message;
      }
    } catch (e) {
      _multiplayerFeedback = 'Error validating word: $e';
    }
    notifyListeners();
  }

  void skipTurn() {
    _isGameOver = true;
    _multiplayerFeedback = 'Game over! $_currentTurn skipped their turn.';
    notifyListeners();
  }

  void resetMultiplayerGame() {
    _players = [
      {'uid': 'player1', 'score': 0},
      {'uid': 'player2', 'score': 0},
      {'uid': 'player3', 'score': 0},
      {'uid': 'player4', 'score': 0},
    ];
    _currentWord = '';
    _usedWords = [];
    _currentTurn = 'player1';
    _isGameOver = false;
    _multiplayerFeedback = '';
    notifyListeners();
  }
}