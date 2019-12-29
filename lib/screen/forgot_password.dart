import 'package:flutter/material.dart';
import '../services/authentication.dart';

class ForgotPasswordPage extends StatefulWidget {
  final Auth auth;
  final String userId;

  const ForgotPasswordPage({Key key, this.auth, this.userId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPasswordPage> {
  final TextEditingController _resetPasswordEmailFilter =
      TextEditingController();

  String _resetPasswordEmail = "";

  _ForgotPasswordState() {
    _resetPasswordEmailFilter.addListener(_resetPasswordEmailListen);
  }
  void _resetPasswordEmailListen() {
    if (_resetPasswordEmailFilter.text.isEmpty) {
      _resetPasswordEmail = "";
    } else {
      _resetPasswordEmail = _resetPasswordEmailFilter.text;
    }
  }

  void _sendResetPasswordMail() {
    if (_resetPasswordEmail != null && _resetPasswordEmail.isNotEmpty) {
      print("============>" + _resetPasswordEmail);
      widget.auth.sendPasswordResetMail(_resetPasswordEmail);
    } else {
      print("password feild empty");
    }
  }

  void _showPasswordResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          content: Text("A password reset link has been sent to your email."),
          actions: <Widget>[
            FlatButton(
              child: Text("Dismiss"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Forgot Password"),
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            Container(
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 20.0,
                  ),
                  Container(
                    child: SizedBox(
                      height: 120.0,
                      child: Image.asset(
                        "assets/images/logo1.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 80.0,
                  ),
                  Center(
                    child: Text(
                      "please enter your email to reset the password",
                      style: TextStyle(color: Colors.blue, fontSize: 18.0),
                    ),
                  ),
                  SizedBox(
                    height: 30.0,
                  ),
                  Container(
                    child: TextFormField(
                      controller: _resetPasswordEmailFilter,
                      decoration: InputDecoration(
                        contentPadding:
                            EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                        hintText: "Email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22.0),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 30.0,
                  ),
                  Container(
                    child: MaterialButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      onPressed: () {
                        _sendResetPasswordMail();
                        _showPasswordResetDialog();
                      },
                      minWidth: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                      color: Colors.blueAccent,
                      textColor: Colors.white,
                      child: Text(
                        "Reset Password",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
