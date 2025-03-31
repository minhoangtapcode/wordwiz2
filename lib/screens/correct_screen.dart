import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Thêm import flutter_bloc
import '../bloc/game_bloc.dart'; // Import GameBloc
import 'welcome_screen.dart';
import 'game_screen.dart';

class CorrectScreen extends StatefulWidget {
  final String answer;

  CorrectScreen({required this.answer});

  @override
  _CorrectScreenState createState() => _CorrectScreenState();
}

class _CorrectScreenState extends State<CorrectScreen> {
  late ConfettiController _confettiController;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: Duration(seconds: 2));
    _confettiController.play();
    _initializeTts().then((_) {
      Future.delayed(Duration(milliseconds: 500), () {
        _speak(widget.answer);
      });
    });
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    try {
      print("Attempting to speak: $text");
      await _flutterTts.speak(text);
      print("Spoke: $text successfully");
    } catch (e) {
      print("TTS Error in CorrectScreen: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                  Icon(Icons.sentiment_satisfied_alt, size: 120, color: Colors.blue),
                  SizedBox(height: 20),
                  Text("YOU WON!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                  SizedBox(height: 20),
                  Text("CORRECT ANSWER", style: TextStyle(fontSize: 16, color: Colors.black54)),
                  SizedBox(height: 10),
                  Text(widget.answer.toUpperCase(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  Text("Score: 10", style: Theme.of(context).textTheme.bodyMedium),
                  SizedBox(height: 10),
                  Text("Words Mastered: 1", style: Theme.of(context).textTheme.bodyMedium),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
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
                        onPressed: () {
                          // Gọi PlayAgainEvent với category hiện tại
                          BlocProvider.of<GameBloc>(context).add(PlayAgainEvent(BlocProvider.of<GameBloc>(context).state.category));
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => GameScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: Text("Play", style: TextStyle(fontSize: 20, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }
}