import 'dart:async';

import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:flutter/material.dart';
import 'package:oaubot/screen/forgot_password.dart';
import '../services/authentication.dart';

class LoginSignUpPage extends StatefulWidget {
  LoginSignUpPage({this.auth, this.onSignedIn});

  final Auth auth;
  final VoidCallback onSignedIn;

  @override
  State<StatefulWidget> createState() => _LoginSignUpPageState();
}

enum FormMode { LOGIN, SIGNUP }

class _LoginSignUpPageState extends State<LoginSignUpPage> {
  final _formKey = GlobalKey<FormState>();

  String _email;
  String _password;
  String _errorMessage;

  // Initial form is login form
  FormMode _formMode = FormMode.LOGIN;
  bool _isIos;

  StreamSubscription<DataConnectionStatus> listener;
  bool _isLoading;

  // Check if form is valid before perform login or signup
  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  // Initially password is obscure
  bool _obscureText = true;

  // Toggles the password show status
  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  // Perform login or signup
  void _validateAndSubmit() async {
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });

    DataConnectionStatus status = await checkInternetConnection();
    if (status == DataConnectionStatus.connected) {
      if (_validateAndSave()) {
        _isLoading = false;
        String userId = "";
        try {
          if (_formMode == FormMode.LOGIN) {
            userId = await widget.auth.signIn(_email, _password);
            print('Signed in: $userId');
          } else {
            userId = await widget.auth.signUp(_email, _password);
            _showAccountCreatedDialog();

            print('Signed up user: $userId');
          }
          setState(() {
            _isLoading = false;
          });

          if (userId.length > 0 &&
              userId != null &&
              _formMode == FormMode.LOGIN) {
            widget.onSignedIn();
          }
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
    } else {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('No Internet'),
                content: Text('Check your internet connection.'),
              ));
    }
  }

  @override
  void initState() {
    _errorMessage = "";
    _isLoading = false;
    super.initState();
  }

  @override
  void dispose() {
    listener.cancel();
    super.dispose();
  }

  checkInternetConnection() async {
    // Simple check to see if we have internet
    print("The statement 'this machine is connected to the Internet' is: ");
    print(await DataConnectionChecker().hasConnection);
    // returns a bool

    // We can also get an enum value instead of a bool
    print("Current status: ${await DataConnectionChecker().connectionStatus}");
    // prints either DataConnectionStatus.connected
    // or DataConnectionStatus.disconnected

    // This returns the last results from the last call
    // to either hasConnection or connectionStatus
    print("Last results: ${DataConnectionChecker().lastTryResults}");

    // actively listen for status updates
    // this will cause DataConnectionChecker to check periodically
    // with the interval specified in DataConnectionChecker().checkInterval
    // until listener.cancel() is called
    listener = DataConnectionChecker().onStatusChange.listen((status) {
      switch (status) {
        case DataConnectionStatus.connected:
          print('Data connection is available.');
          break;
        case DataConnectionStatus.disconnected:
          print('You are disconnected from the internet.');
          break;
      }
    });

    return await DataConnectionChecker().connectionStatus;
  }

  void _changeFormToSignUp() {
    _formKey.currentState.reset();
    _errorMessage = "";
    setState(() {
      _formMode = FormMode.SIGNUP;
    });
  }

  void _changeFormToLogin() {
    _formKey.currentState.reset();
    _errorMessage = "";
    setState(() {
      _formMode = FormMode.LOGIN;
    });
  }

  @override
  Widget build(BuildContext context) {
    _isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          _showBody(),
          _showCircularProgress(),
        ],
      ),
    );
  }

  Widget _showCircularProgress() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  void _showAccountCreatedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          content: Text(
              "Your account has been created successfully. You can now login."),
          actions: <Widget>[
            FlatButton(
              child: Text("Dismiss"),
              onPressed: () {
                _changeFormToLogin();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _showBody() {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              _showLogo(),
              _showEmailInput(),
              _showPasswordInput(),
              FlatButton(
                  child: Text(
                    'Forget your password?',
                    style: new TextStyle(
                        fontSize: 18.0, fontWeight: FontWeight.w300),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ForgotPasswordPage(
                          auth: widget.auth,
                        ),
                      ),
                    );
                  }),
              _showPrimaryButton(),
              _showSecondaryButton(),
              _showErrorMessage(),
            ],
          ),
        ));
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

  Widget _showLogo() {
    return Column(
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
    );
  }

  Widget _showEmailInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 16.0, 0.0, 0.0),
      child: TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        autofocus: false,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: 'Email',
          prefixIcon: Icon(
            Icons.mail,
            color: Colors.grey,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22.0),
          ),
        ),
        validator: (value) => value.isEmpty ? "Email can't be empty" : null,
        onSaved: (value) => _email = value.trim(),
      ),
    );
  }

  Widget _showPasswordInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
      child: TextFormField(
        maxLines: 1,
        obscureText: _obscureText,
        autofocus: false,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: 'Password',
          prefixIcon: Icon(
            Icons.lock,
            color: Colors.grey,
          ),
          suffixIcon: InkWell(
            onTap: _toggle,
            child: (_obscureText)
                ? Icon(
                    Icons.visibility_off,
                    color: Colors.grey,
                  )
                : Icon(
                    Icons.visibility,
                    color: Colors.grey,
                  ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22.0),
          ),
        ),
        validator: (value) => value.isEmpty ? "Password can't be empty" : null,
        onSaved: (value) => _password = value.trim(),
      ),
    );
  }

  Widget _showSecondaryButton() {
    return FlatButton(
      child: _formMode == FormMode.LOGIN
          ? Text('Create an account',
              style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300))
          : Text('Have an account? Sign in',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
      onPressed: _formMode == FormMode.LOGIN
          ? _changeFormToSignUp
          : _changeFormToLogin,
    );
  }

  Widget _showPrimaryButton() {
    return Padding(
        padding: EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 0.0),
        child: SizedBox(
          height: 40.0,
          child: RaisedButton(
            elevation: 5.0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0)),
            color: Colors.blue,
            child: _formMode == FormMode.LOGIN
                ? Text('Login',
                    style: TextStyle(fontSize: 20.0, color: Colors.white))
                : Text('Create account',
                    style: TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: _validateAndSubmit,
          ),
        ));
  }
}
