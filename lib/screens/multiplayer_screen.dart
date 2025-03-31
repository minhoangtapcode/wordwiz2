import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MultiplayerScreen extends StatefulWidget {
  @override
  _MultiplayerScreenState createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends State<MultiplayerScreen> {
  final TextEditingController _wordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _roomId;
  String? _currentWord;
  List<String> _usedWords = [];
  String? _currentTurn;
  List<Map<String, dynamic>> _players = [];
  int _userLevel = 1;

  @override
  void initState() {
    super.initState();
    _initializeUserLevel();
    _joinRoom();
  }

  Future<void> _initializeUserLevel() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      int score = userDoc.exists ? (userDoc['score'] ?? 0) : 0;
      setState(() {
        if (score <= 20)
          _userLevel = 1;
        else if (score <= 50)
          _userLevel = 2;
        else if (score <= 100)
          _userLevel = 3;
        else if (score <= 200)
          _userLevel = 4;
        else
          _userLevel = 5;
      });
    }
  }

  Future<void> _joinRoom() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Kiểm tra xem người dùng đã ở trong phòng nào chưa
    QuerySnapshot rooms =
        await _firestore
            .collection('rooms')
            .where('level', isEqualTo: _userLevel)
            .where('players', arrayContains: user.uid)
            .limit(1)
            .get();

    if (rooms.docs.isEmpty) {
      // Tìm phòng trống (dưới 4 người) ở cùng mức
      rooms =
          await _firestore
              .collection('rooms')
              .where('level', isEqualTo: _userLevel)
              .where('players', arrayContains: null) // Phòng chưa đầy
              .limit(1)
              .get();

      if (rooms.docs.isNotEmpty) {
        _roomId = rooms.docs.first.id;
        await _firestore.collection('rooms').doc(_roomId).update({
          'players': FieldValue.arrayUnion([user.uid]),
        });
      } else {
        // Tạo phòng mới nếu không tìm thấy phòng trống
        DocumentReference newRoom = await _firestore.collection('rooms').add({
          'level': _userLevel,
          'players': [user.uid],
          'currentWord': '',
          'usedWords': [],
          'turn': user.uid,
        });
        _roomId = newRoom.id;
      }
    } else {
      _roomId = rooms.docs.first.id;
    }

    // Lưu thông tin người dùng vào Firestore nếu chưa có
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'score': 0,
      'level': _userLevel,
    }, SetOptions(merge: true));
  }

  Future<bool> _isValidWord(String word) async {
    if (_currentWord != null && _currentWord!.isNotEmpty) {
      if (word[0].toLowerCase() !=
          _currentWord![_currentWord!.length - 1].toLowerCase()) {
        return false;
      }
    }
    if (_usedWords.contains(word.toLowerCase())) {
      return false;
    }
    DocumentSnapshot wordDoc =
        await _firestore.collection('words').doc(word.toLowerCase()).get();
    return wordDoc.exists;
  }

  Future<void> _submitWord() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || _roomId == null || _currentTurn != user.uid) return;

    String word = _wordController.text.trim().toLowerCase();
    if (await _isValidWord(word)) {
      await _firestore.collection('rooms').doc(_roomId).update({
        'currentWord': word,
        'usedWords': FieldValue.arrayUnion([word]),
        'turn':
            _players[(_players.indexWhere((p) => p['uid'] == user.uid) + 1) %
                _players.length]['uid'],
      });
      await _firestore.collection('users').doc(user.uid).update({
        'score': FieldValue.increment(10),
      });
      _wordController.clear();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Invalid word!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_roomId == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('rooms').doc(_roomId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        var roomData = snapshot.data!.data() as Map<String, dynamic>;
        _currentWord = roomData['currentWord'] ?? '';
        _usedWords = List<String>.from(roomData['usedWords'] ?? []);
        _currentTurn = roomData['turn'] ?? '';
        _players = [];
        for (String uid in roomData['players']) {
          _players.add({'uid': uid, 'score': 0});
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
                // Bảng xếp hạng
                Container(
                  padding: EdgeInsets.all(10),
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        _firestore
                            .collection('users')
                            .where('uid', whereIn: roomData['players'])
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return CircularProgressIndicator();
                      _players =
                          snapshot.data!.docs.map((doc) {
                            return {'uid': doc.id, 'score': doc['score'] ?? 0};
                          }).toList();
                      _players.sort((a, b) => b['score'].compareTo(a['score']));
                      return Column(
                        children: [
                          Text(
                            "Leaderboard",
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          ..._players.map(
                            (player) => ListTile(
                              title: Text(
                                "Player ${player['uid'].substring(0, 5)}",
                              ),
                              trailing: Text("Score: ${player['score']}"),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Từ hiện tại
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "Current Word: ${_currentWord != null && _currentWord!.isNotEmpty ? _currentWord : 'Start!'}",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                // Lượt chơi
                Text(
                  _currentTurn == FirebaseAuth.instance.currentUser?.uid
                      ? "Your Turn!"
                      : "Waiting for other player...",
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
                SizedBox(height: 20),
                // Nhập từ
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
                  onPressed:
                      _currentTurn == FirebaseAuth.instance.currentUser?.uid
                          ? _submitWord
                          : null,
                  child: Text("Submit", style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
