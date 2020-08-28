import 'package:chat_app/widgets/image_pick.dart';
import 'package:/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: Center(
          child: FormScreen(),
        ));
  }
}

class FormScreen extends StatefulWidget {
  @override
  _FormScreenState createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  File _image;

  bool _loading = false;
  final _auth = FirebaseAuth.instance;

  void _saveForm() async {
    AuthResult _authResult;
    final _isValid = _key.currentState.validate();
    FocusScope.of(context).unfocus();

    if (_image == null && !_isLogin) {
      Scaffold.of(context)
          .showSnackBar(SnackBar(content: Text('Please select an image')));
      return;
    }

    try {
      if (_isValid) {
        setState(() {
          _loading = true;
        });
        _key.currentState.save();

        if (_isLogin) {
          {
            _authResult = await _auth.signInWithEmailAndPassword(
                email: _info['email'], password: _info['password']);
          }
        } else {
          _authResult = await _auth.createUserWithEmailAndPassword(
              email: _info['email'], password: _info['password']);
          final ref = FirebaseStorage.instance
              .ref()
              .child('/user_images')
              .child(
                  _authResult.user.uid + Timestamp.now().toString() + '.jpg');

          await ref.putFile(_image).onComplete;
          final _url = await ref.getDownloadURL();

          await Firestore.instance
              .collection('users')
              .document(_authResult.user.uid)
              .setData({
            'username': _info['username'],
            'email': _info['email'],
            'image': _url
          });
        }
      }
    } on PlatformException catch (err) {
      print(err.message);
      var message = "An error occured, please check your creds";
      if (err.message != null) {
        message = err.message;
      }
      setState(() {
        _loading = false;
      });
      Scaffold.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _selectimg(File img) {
    _image = img;
  }

  final _controller = TextEditingController();
  final _key = GlobalKey<FormState>();
  Map<String, String> _info = {'email': '', 'password': '', 'username': ''};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  var _isLogin = true;
  @override
  Widget build(BuildContext context) {
    return _loading
        ? Center(
            child: CircularProgressIndicator(),
          )
        : Card(
            margin: EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: AnimatedContainer(
                constraints: BoxConstraints(
                    minHeight: _isLogin
                        ? MediaQuery.of(context).size.height * 0.40
                        : MediaQuery.of(context).size.height * 0.46),
                duration: Duration(milliseconds: 259),
                curve: Curves.easeInBack,
                height: _isLogin
                    ? MediaQuery.of(context).size.height * 0.40
                    : MediaQuery.of(context).size.height * 0.60,
                padding: EdgeInsets.all(16),
                child: AnimatedContainer(
                  constraints: BoxConstraints(
                    minHeight: _isLogin
                        ? MediaQuery.of(context).size.height * 0.33
                        : MediaQuery.of(context).size.height * 0.60,
                  ),
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInBack,
                  child: SingleChildScrollView(
                    child: Form(
                      key: _key,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (!_isLogin) PickImage(_selectimg),
                          TextFormField(
                            onSaved: (val) {
                              _info['email'] = val.trim();
                            },
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val.isEmpty || !val.contains('@')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                            ),
                          ),
                          if (!_isLogin)
                            Container(
                              child: TextFormField(
                                onSaved: (val) {
                                  _info['username'] = val.trim();
                                },
                                validator: (val) {
                                  if (val.length < 4) {
                                    return 'Please enter atleast 4 characters';
                                  }
                                  return null;
                                },
                                decoration:
                                    InputDecoration(labelText: 'User Name'),
                              ),
                            ),
                          TextFormField(
                            controller: _controller,
                            onSaved: (val) {
                              _info['password'] = val.trim();
                            },
                            validator: (val) {
                              if (val.length < 7) {
                                return 'Password must be atleast 7 characters long';
                              }
                              return null;
                            },
                            obscureText: true,
                            decoration: InputDecoration(labelText: 'Password'),
                          ),
                          if (!_isLogin)
                            Container(
                              child: TextFormField(
                                autovalidate: true,
                                validator: (val) {
                                  if (val != _controller.text) {
                                    return 'Password doesn\'t match';
                                  }
                                  return null;
                                },
                                obscureText: true,
                                decoration: InputDecoration(
                                    labelText: 'Confirm password'),
                              ),
                            ),
                          SizedBox(
                            height: 10,
                          ),
                          RaisedButton(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            onPressed: _saveForm,
                            child: Text(_isLogin ? 'Login' : 'Signup'),
                          ),
                          FlatButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                            child: Text(
                                !_isLogin ? 'Login' : 'Create a new account'),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}
