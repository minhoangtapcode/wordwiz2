import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';
import 'game_screen.dart';
import 'multiplayer_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final List<String> categories = ["Food", "Animals", "Travel"];
  String selectedCategory = "Food";

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
        child: Center(
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
              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.active) {
                    User? user = snapshot.data;
                    if (user != null) {
                      return Column(
                        children: [
                          Text(
                            "Welcome, ${user.displayName ?? user.email}",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          SizedBox(height: 10),
                          TextButton(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WelcomeScreen(),
                                ),
                              );
                            },
                            child: Text(
                              "Logout",
                              style: TextStyle(fontSize: 16, color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    }
                  }
                  return Text(
                    "Your Username",
                    style: Theme.of(context).textTheme.bodyLarge,
                  );
                },
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Category: ",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  DropdownButton<String>(
                    value: selectedCategory,
                    onChanged: (String? newValue) {
                      selectedCategory = newValue!;
                    },
                    items:
                        categories.map<DropdownMenuItem<String>>((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (FirebaseAuth.instance.currentUser != null) {
                    context.read<GameBloc>().add(
                      StartGameEvent(selectedCategory),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GameScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please log in first!")),
                    );
                  }
                },
                child: Text(
                  "Play Solo",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (FirebaseAuth.instance.currentUser != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MultiplayerScreen(),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please log in first!")),
                    );
                  }
                },
                child: Text(
                  "Play Multiplayer",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.active) {
                    User? user = snapshot.data;
                    if (user == null) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(),
                                ),
                              );
                            },
                            child: Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterScreen(),
                                ),
                              );
                            },
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  }
                  return SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
