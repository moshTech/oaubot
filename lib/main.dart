import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oaubot/screen/intro_screen.dart';
import 'package:oaubot/screen/root_page.dart';
import 'package:oaubot/services/authentication.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'oau bot',
      theme: ThemeData(
        primaryColor: Colors.blue[200],
      ),
      home: ShowIntroOnce(),
    );
  }
}

class ShowIntroOnce extends StatefulWidget {
  @override
  _ShowIntroOnceState createState() => _ShowIntroOnceState();
}

class _ShowIntroOnceState extends State<ShowIntroOnce> {
  Future checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool _seen = (prefs.getBool('seen') ?? false);

    if (_seen) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => RootPage(
            auth: Auth(),
          ),
        ),
      );
    } else {
      await prefs.setBool('seen', true);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => IntroScreen(),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    Timer(Duration(milliseconds: 200), () {
      checkFirstSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(),
    );
  }
}
