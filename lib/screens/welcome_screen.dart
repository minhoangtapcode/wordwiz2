import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';
import 'multiplayer_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int selectedLevel = 1; // Default level

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
        child: SingleChildScrollView( // Wrap entire content in SingleChildScrollView
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0), // Add padding to avoid edge overflow
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.yellow[200],
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "Word Wiz",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "GUESS THE WORD",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  SizedBox(height: 30),
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.yellow[200],
                    child: Icon(Icons.face, size: 80, color: Colors.blue),
                  ),
                  SizedBox(height: 20),
                  Column(
                    children: [
                      Text(
                        "Welcome, Guest",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          // Placeholder for logout
                        },
                        child: Text(
                          "Logout",
                          style: TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Level selection dropdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Level: ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      DropdownButton<int>(
                        value: selectedLevel,
                        onChanged: (int? newValue) {
                          setState(() {
                            selectedLevel = newValue!;
                          });
                        },
                        items: List.generate(5, (index) {
                          return DropdownMenuItem<int>(
                            value: index + 1,
                            child: Text("Level ${index + 1}"),
                          );
                        }),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Display stages for the selected level
                  Consumer<GameProvider>(
                    builder: (context, gameProvider, child) {
                      return Column(
                        children: [
                          Text(
                            "Stages in Level $selectedLevel",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          SizedBox(height: 10),
                          GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 5,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            physics: NeverScrollableScrollPhysics(),
                            children: List.generate(10, (stageIndex) {
                              final stage = stageIndex + 1;
                              final isUnlocked = (selectedLevel == 1 && stage == 1) ||
                                  (gameProvider.isStageUnlocked &&
                                      (selectedLevel < gameProvider.level ||
                                          (selectedLevel == gameProvider.level && stage <= gameProvider.stage)));
                              return GestureDetector(
                                onTap: isUnlocked
                                    ? () async {
                                        await gameProvider.startNewGame(selectedLevel, stage);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => GameScreen()),
                                        );
                                      }
                                    : null,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isUnlocked ? Colors.green[100] : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      "$stage",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isUnlocked ? Colors.black87 : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MultiplayerScreen()),
                      );
                    },
                    child: Text(
                      "Play Multiplayer",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                          );
                        },
                        child: Text(
                          "Login",
                          style: TextStyle(fontSize: 16, color: Colors.blue),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RegisterScreen()),
                          );
                        },
                        child: Text(
                          "Sign Up",
                          style: TextStyle(fontSize: 16, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}