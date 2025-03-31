import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/game_bloc.dart';
import 'correct_screen.dart';
import 'incorrect_screen.dart';

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TextEditingController _controller = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  Timer? _timer;
  int maxSeconds = 15;
  int seconds = 15;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    startTimer(); // Bắt đầu Timer ngay khi màn hình được tạo
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flutterTts.stop();
    _controller.dispose();
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
        // Tự động chuyển sang IncorrectScreen khi hết thời gian
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => IncorrectScreen(answer: context.read<GameBloc>().state.answer),
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
    return BlocListener<GameBloc, GameState>(
      listener: (context, state) {
        if (state.isCorrect) {
          stopTimer(); // Dừng Timer khi trả lời đúng
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => CorrectScreen(answer: state.answer)),
          );
        } else if (state.isIncorrect) {
          stopTimer(); // Dừng Timer khi nhập sai 3 lần
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => IncorrectScreen(answer: state.answer)),
          );
        }
      },
      child: Scaffold(
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
              // Box cố định ở trên cùng
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
                      Text("Score: ${context.watch<GameBloc>().state.score}",
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white)),
                      Row(
                        children: List.generate(3, (index) {
                          return Icon(
                            Icons.favorite,
                            color: index < (3 - context.watch<GameBloc>().state.incorrectAttempts)
                                ? Colors.red
                                : Colors.grey,
                            size: 20,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              // Timer progress bar
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
                      Text("Category: ${context.watch<GameBloc>().state.category}",
                          style: Theme.of(context).textTheme.bodyMedium),
                      SizedBox(height: 20),
                      Text(context.watch<GameBloc>().state.clue,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center),
                      SizedBox(height: 30),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.blueGrey, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                            ),
                            hintText: "Type your guess",
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.95),
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                          ),
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              context.read<GameBloc>().add(SubmitGuessEvent(_controller.text));
                              _controller.clear();
                            },
                            child: Text("Submit", style: TextStyle(fontSize: 18)),
                          ),
                          SizedBox(width: 20),
                          IconButton(
                            onPressed: () {
                              context.read<GameBloc>().add(ShowHintEvent());
                            },
                            icon: Icon(Icons.lightbulb, color: Colors.yellow[700], size: 30),
                            tooltip: "Hint",
                          ),
                          SizedBox(width: 20),
                          IconButton(
                            onPressed: () {
                              _speak(context.read<GameBloc>().state.clue);
                            },
                            icon: Icon(Icons.volume_up, color: Colors.blue, size: 30),
                            tooltip: "Speak Clue",
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text(context.watch<GameBloc>().state.feedback,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center),
                      SizedBox(height: 10),
                      if (context.watch<GameBloc>().state.hint != '')
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
                            context.watch<GameBloc>().state.hint,
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
      ),
    );
  }
}