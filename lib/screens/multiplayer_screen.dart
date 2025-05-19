import 'package:flutter/material.dart';

class MultiplayerScreen extends StatefulWidget {
  @override
  _MultiplayerScreenState createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends State<MultiplayerScreen> {
  final TextEditingController _wordController = TextEditingController();
  String _currentWord = '';
  List<String> _usedWords = [];
  String _currentTurn = 'player1';
  List<Map<String, dynamic>> _players = [
    {'uid': 'player1', 'score': 30},
    {'uid': 'player2', 'score': 20},
    {'uid': 'player3', 'score': 10},
  ];

  void _submitWord() {
    String word = _wordController.text.trim().toLowerCase();
    if (word.isNotEmpty && !_usedWords.contains(word)) {
      setState(() {
        _currentWord = word;
        _usedWords.add(word);
        _players[0]['score'] += 10; // Mock score update for player1
        _currentTurn = _players[(_players.indexWhere((p) => p['uid'] == _currentTurn) + 1) % _players.length]['uid'];
      });
      _wordController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid or used word!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  ..._players.map(
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
                "Current Word: ${_currentWord.isNotEmpty ? _currentWord : 'Start!'}",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            // Turn indicator
            Text(
              _currentTurn == 'player1' ? "Your Turn!" : "Waiting for other player...",
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
            ElevatedButton(
              onPressed: _currentTurn == 'player1' ? _submitWord : null,
              child: Text("Submit", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}