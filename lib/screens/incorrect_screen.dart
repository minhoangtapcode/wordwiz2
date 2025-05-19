import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'welcome_screen.dart';
import 'game_screen.dart';

class IncorrectScreen extends StatefulWidget {
  final String answer;

  IncorrectScreen({required this.answer});

  @override
  _IncorrectScreenState createState() => _IncorrectScreenState();
}

class _IncorrectScreenState extends State<IncorrectScreen> {
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initializeTts().then((_) {
      Future.delayed(Duration(milliseconds: 500), () {
        _speak(widget.answer);
      });
    });
  }

  Future<void> _initializeTts() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      print("TTS initialized with language: en-US, pitch: 1.0, rate: 0.5");
    } catch (e) {
      print("TTS Initialization Error: $e");
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    try {
      print("Attempting to speak: $text");
      await _flutterTts.speak(text);
      print("Spoke: $text successfully");
    } catch (e) {
      print("TTS Error in IncorrectScreen: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlue[200]!, Colors.lightBlue[100]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sentiment_dissatisfied, size: 120, color: Colors.blueGrey),
                  SizedBox(height: 20),
                  Text("TIME OUT", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red)),
                  SizedBox(height: 20),
                  Text("THE WORD WAS", style: TextStyle(fontSize: 16, color: Colors.black54)),
                  SizedBox(height: 10),
                  Text(widget.answer.toUpperCase(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  Text("Words Mastered: ${gameProvider.wordsMastered}", style: Theme.of(context).textTheme.bodyMedium),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          gameProvider.quit();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => WelcomeScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: Text("Quit", style: TextStyle(fontSize: 20, color: Colors.white)),
                      ),
                      SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await gameProvider.playAgain(gameProvider.level, gameProvider.stage);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => GameScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: Text("Try Again", style: TextStyle(fontSize: 20, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}