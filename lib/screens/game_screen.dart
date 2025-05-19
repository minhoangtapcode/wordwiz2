import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/game_provider.dart';
import 'correct_screen.dart';
import 'incorrect_screen.dart';

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  Timer? _timer;
  int maxSeconds = 15;
  int seconds = 15;
  List<TextEditingController> controllers = [];
  List<FocusNode> focusNodes = [];

  @override
  void initState() {
    super.initState();
    _initializeTts();
    startTimer();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flutterTts.stop();
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void startTimer({bool reset = true}) {
    _timer?.cancel();
    if (reset) {
      setState(() {
        seconds = maxSeconds;
      });
    }

    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (seconds > 0) {
        setState(() => seconds--);
      } else {
        stopTimer();
        Provider.of<GameProvider>(context, listen: false).submitGuess(
          Provider.of<GameProvider>(context, listen: false).revealedLetters,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => IncorrectScreen(answer: Provider.of<GameProvider>(context, listen: false).answer),
          ),
        );
      }
    });
  }

  void stopTimer({bool reset = true}) {
    if (reset) {
      setState(() => seconds = maxSeconds);
    }
    _timer?.cancel();
  }

  Future<void> _speak(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print("TTS Error: $e");
    }
  }

  Color getProgressColor(int seconds, int maxSeconds) {
    double progress = seconds / maxSeconds;
    if (progress > 0.5) return Colors.green;
    if (progress > 0.25) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        if (gameProvider.clue.isEmpty && gameProvider.answer.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }

        if (controllers.isEmpty) {
          controllers = List.generate(
            gameProvider.answer.length,
            (index) => TextEditingController(text: gameProvider.revealedLetters[index] ?? ''),
          );
          focusNodes = List.generate(gameProvider.answer.length, (index) => FocusNode());
        }

        if (gameProvider.isCorrect) {
          stopTimer();
          return CorrectScreen(answer: gameProvider.answer);
        } else if (gameProvider.isIncorrect) {
          stopTimer();
          return IncorrectScreen(answer: gameProvider.answer);
        }

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlue[200]!, Colors.lightBlue[100]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.lightBlue[300]!, Colors.lightBlue[200]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border(bottom: BorderSide(color: Colors.white, width: 2)),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2))],
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Score: ${gameProvider.score}",
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white)),
                        Row(
                          children: List.generate(3, (index) {
                            return Icon(
                              Icons.favorite,
                              color: index < (3 - gameProvider.incorrectAttempts) ? Colors.red : Colors.grey,
                              size: 20,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 10,
                  child: Stack(
                    children: [
                      LinearProgressIndicator(
                        value: seconds / maxSeconds,
                        minHeight: 10,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(getProgressColor(seconds, maxSeconds)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Level ${gameProvider.level} - Stage ${gameProvider.stage}",
                            style: Theme.of(context).textTheme.bodyMedium),
                        SizedBox(height: 20),
                        Text(gameProvider.clue,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center),
                        SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(gameProvider.answer.length, (index) {
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (gameProvider.revealedLetters[index] == null)
                                      Positioned(
                                        bottom: 0,
                                        child: Text(
                                          "_",
                                          style: TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    TextField(
                                      controller: controllers[index],
                                      focusNode: focusNodes[index],
                                      textAlign: TextAlign.center,
                                      maxLength: 1,
                                      readOnly: index == 0,
                                      keyboardType: TextInputType.text,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                                      ],
                                      decoration: InputDecoration(
                                        counterText: '',
                                        border: InputBorder.none,
                                        filled: false,
                                      ),
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      onChanged: index == 0
                                          ? null
                                          : (value) {
                                              if (value.isEmpty) {
                                                setState(() {
                                                  gameProvider.revealedLetters[index] = null;
                                                  controllers[index].clear();
                                                });
                                                if (index > 0) {
                                                  focusNodes[index - 1].requestFocus();
                                                }
                                              } else if (value.length == 1 && RegExp(r'[a-zA-Z]').hasMatch(value)) {
                                                setState(() {
                                                  gameProvider.revealedLetters[index] = value.toLowerCase();
                                                  controllers[index].text = value.toLowerCase();
                                                });
                                                if (index < gameProvider.answer.length - 1) {
                                                  focusNodes[index + 1].requestFocus();
                                                }
                                              }
                                            },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                gameProvider.submitGuess(gameProvider.revealedLetters);
                                if (gameProvider.feedback.isNotEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(gameProvider.feedback)),
                                  );
                                }
                              },
                              child: Text("Check", style: TextStyle(fontSize: 18)),
                            ),
                            SizedBox(width: 20),
                            IconButton(
                              onPressed: () async {
                                await gameProvider.showHint();
                                if (gameProvider.feedback.contains("Error")) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(gameProvider.feedback)),
                                  );
                                }
                              },
                              icon: Icon(Icons.lightbulb, color: Colors.yellow[700], size: 30),
                              tooltip: "Hint",
                            ),
                            SizedBox(width: 20),
                            IconButton(
                              onPressed: () {
                                _speak(gameProvider.clue);
                              },
                              icon: Icon(Icons.volume_up, color: Colors.blue, size: 30),
                              tooltip: "Speak Clue",
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        if (gameProvider.hint.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Text(
                              gameProvider.hint,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}