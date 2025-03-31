import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/welcome_screen.dart';
import 'bloc/game_bloc.dart';
import 'firebase/firebase__options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GameBloc(),
      child: MaterialApp(
        theme: ThemeData(
          primaryColor: Colors.lightBlue[100],
          scaffoldBackgroundColor: Colors.transparent,
          textTheme: GoogleFonts.quicksandTextTheme(
            Theme.of(context).textTheme.copyWith(
              headlineLarge: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              bodyLarge: TextStyle(fontSize: 24, color: Colors.black87),
              bodyMedium: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              textStyle: GoogleFonts.quicksand(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
        home: WelcomeScreen(),
      ),
    );
  }
}
