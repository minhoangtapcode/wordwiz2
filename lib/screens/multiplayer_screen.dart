import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class MultiplayerScreen extends StatefulWidget {
  @override
  _MultiplayerScreenState createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends State<MultiplayerScreen> {
  final TextEditingController _wordController = TextEditingController();
  Timer? _timer;
  int _seconds = 15;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wordController.dispose();
    super.dispose();
  }

  void startTimer({bool reset = true}) {
    _timer?.cancel();
    if (reset) {
      setState(() {
        _seconds = 15;
      });
    }

    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        Provider.of<GameProvider>(context, listen: false).skipTurn();
        _timer?.cancel();
      }
    });
  }

  void resetTimer() {
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        if (gameProvider.isGameOver) {
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
                    Text(
                      "Game Over!",
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    SizedBox(height: 20),
                    Text(
                      gameProvider.multiplayerFeedback,
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Leaderboard",
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    ...gameProvider.players
                        .asMap()
                        .entries
                        .map(
                          (entry) => ListTile(
                            title: Text("Player ${entry.value['uid']}"),
                            trailing: Text("Score: ${entry.value['score']}"),
                          ),
                        )
                        .toList(),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        gameProvider.resetMultiplayerGame();
                        resetTimer();
                      },
                      child: Text("Play Again", style: TextStyle(fontSize: 18)),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text("Quit", style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          );
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
                // Leaderboard
                Container(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Text(
                        "Leaderboard",
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      ...gameProvider.players.map(
                        (player) => ListTile(
                          title: Text("Player ${player['uid']}"),
                          trailing: Text("Score: ${player['score']}"),
                        ),
                      ),
                    ],
                  ),
                ),
                // Current word
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "Current Word: ${gameProvider.currentWord.isNotEmpty ? gameProvider.currentWord : 'Start!'}",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                // Turn indicator
                Text(
                  gameProvider.currentTurn == 'player1' ? "Your Turn! ($_seconds s)" : "Waiting for ${gameProvider.currentTurn}... ($_seconds s)",
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
                SizedBox(height: 20),
                // Word input
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _wordController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: Colors.blueGrey,
                          width: 2,
                        ),
                      ),
                      hintText: "Enter your word",
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: gameProvider.currentTurn == 'player1'
                          ? () async {
                              final word = _wordController.text.trim();
                              if (word.isNotEmpty) {
                                await gameProvider.submitMultiplayerWord(word);
                                if (gameProvider.multiplayerFeedback.isNotEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(gameProvider.multiplayerFeedback)),
                                  );
                                }
                                _wordController.clear();
                                resetTimer();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Please enter a word!")),
                                );
                              }
                            }
                          : null,
                      child: Text("Submit", style: TextStyle(fontSize: 18)),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: gameProvider.currentTurn == 'player1'
                          ? () {
                              gameProvider.skipTurn();
                              _wordController.clear();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      child: Text("Skip", style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}