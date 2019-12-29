import 'package:flutter/material.dart';
import 'package:intro_views_flutter/Models/page_view_model.dart';
import 'package:intro_views_flutter/intro_views_flutter.dart';
import 'package:oaubot/screen/root_page.dart';
import 'package:oaubot/services/authentication.dart';

class IntroScreen extends StatelessWidget {
  final pages = [
    PageViewModel(
      pageColor: Colors.lightBlue,
      // bubble: Icon(Icons.thumb_up),
      // bubbleBackgroundColor: Colors.grey,
      iconImageAssetPath: "assets/images/logo1.png",
      body: Text(
          'Welcome to OAUBOT, the best journey adviser you can ever get on campus.'),
      title: Text('Welcome'),
      textStyle: TextStyle(
        color: Colors.white,
        fontFamily: 'Mansalva',
      ),
      mainImage: Image.asset(
        'assets/images/logo1.png',
        color: Colors.pink[100],
      ),
    ),
    PageViewModel(
      pageColor: Colors.blue,
      bubble: Icon(
        Icons.directions_bike,
      ),
      body: Text(
          'With OAUBOT, you can easily get to wherever you are going within campus.'),
      title: Text('Almost there'),
      textStyle: TextStyle(
        color: Colors.white,
        fontFamily: 'Mansalva',
      ),
      mainImage: Icon(
        Icons.directions_bike,
        color: Colors.pink[100],
        size: 170.0,
      ),
    ),
    PageViewModel(
      pageColor: const Color(0xFF03A9F4),
      bubble: Icon(Icons.mood),
      body: Text("Now, let's get started."),
      title: Text('Get Started'),
      textStyle: TextStyle(
        color: Colors.white,
        fontFamily: 'Mansalva',
      ),
      mainImage: Icon(
        Icons.mood,
        color: Colors.pink[100],
        size: 170.0,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => IntroViewsFlutter(
          pages,
          onTapDoneButton: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RootPage(
                auth: Auth(),
              ),
            ),
          ),
          // showNextButton: true,
          // showBackButton: true,
          pageButtonTextStyles: TextStyle(
            color: Colors.white,
            fontSize: 18.0,
          ),
        ),
      ),
    );
  }
}
