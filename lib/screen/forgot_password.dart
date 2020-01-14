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
  final _formKey = GlobalKey<FormState>();

  String _errorMessage = '';
  bool _isIos;

  _ForgotPasswordState() {
    _resetPasswordEmailFilter.addListener(_resetPasswordEmailListen);
  }

  @override
  void initState() {
    _errorMessage = "";
    super.initState();
  }

  void _resetPasswordEmailListen() {
    if (_resetPasswordEmailFilter.text.isEmpty) {
      _resetPasswordEmail = "";
    } else {
      _resetPasswordEmail = _resetPasswordEmailFilter.text;
    }
  }

  // bool _validateAndSave() {
  //   final form = _formKey.currentState;
  //   if (form.validate()) {
  //     form.save();
  //     return true;
  //   }
  //   return false;
  // }

  void _validateAndSubmit() async {
    setState(() {
      _errorMessage = "";
    });

    try {
      if (_resetPasswordEmail.isEmpty || _resetPasswordEmail == null) {
        _errorMessage = 'Email field is empty';
      } else {
        print("============>" + _resetPasswordEmail);
        widget.auth.sendPasswordResetMail(_resetPasswordEmail);
        _showPasswordResetDialog();
      }
      setState(() {});
    } catch (e) {
      print('Error: $e');
      setState(() {
        if (_isIos) {
          _errorMessage = e.details;
        }
        if (e.message.contains('An internal error has occurred.')) {
          _errorMessage = 'No internet connecton';
        } else
          _errorMessage = e.message;
        print(e.message);
      });
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
      body: ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Hero(
                      tag: 'hero',
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          radius: 80.0,
                          child: Image.asset('assets/images/logo1.png'),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'OAUBOT',
                        style: TextStyle(
                          fontFamily: 'Mansalva',
                          fontSize: 30.0,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30.0),
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
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextFormField(
                    // key: _formKey,
                    autofocus: false,
                    controller: _resetPasswordEmailFilter,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    maxLines: 1,
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                      hintText: "Email",
                      prefixIcon: Icon(
                        Icons.email,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22.0),
                      ),
                    ),
                    validator: (value) =>
                        value.isEmpty ? "Email can't be empty" : null,
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: MaterialButton(
                    elevation: 5.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    onPressed: _validateAndSubmit,
                    minWidth: MediaQuery.of(context).size.width,
                    padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                    color: Colors.blueAccent,
                    textColor: Colors.white,
                    child: Text(
                      "Reset Password",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                _showErrorMessage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _showErrorMessage() {
    if (_errorMessage.length > 0 && _errorMessage != null) {
      return Text(
        _errorMessage,
        style: TextStyle(
            fontSize: 13.0,
            color: Colors.red,
            height: 1.0,
            fontWeight: FontWeight.w300),
      );
    } else {
      return Container(
        height: 0.0,
      );
    }
  }
}
