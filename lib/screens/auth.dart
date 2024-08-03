import 'dart:io';
import 'package:chat_app/themes/theme.dart';
import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firebase = FirebaseAuth.instance;
//final _storage = FirebaseStorage.instance;

final _cloudstore = FirebaseFirestore.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  var _enteredUsername = '';
  var _isAuthenticating = false;
  File? _selectedImage;

  var _emailAddress = '';
  var _password = "";

  var _islogin = true;
  var _visibility = false;

  void _submit() async {
    final isvalid = _form.currentState!.validate();
    if (!isvalid || (!_islogin && _selectedImage == null)) {
      //show error message
      return;
    }

    _form.currentState!.save();
    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_islogin) {
        final UserCredentials = await _firebase.signInWithEmailAndPassword(
            email: _emailAddress, password: _password);
        print(UserCredentials);
      } else {
        final UserCredentials = await _firebase.createUserWithEmailAndPassword(
            email: _emailAddress, password: _password);
        // print(UserCredentials);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${UserCredentials.user!.uid}.jpg');

        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();
        print(imageUrl);
        await _cloudstore
            .collection('users')
            .doc('${UserCredentials.user!.uid}')
            .set({
          'username': _enteredUsername,
          'email': _emailAddress,
          'image_url': imageUrl,
        });
      }
    } on FirebaseAuthException catch (error) {
      // if (error.code == 'email-already-in-use:') {
      //   //show error code
      // }
      // on general
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? "Authentication failed"),
        ),
      );
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text("Barbie Chat App"),),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                width: 200,
                child: Opacity(
                    opacity: 0.3, child: Image.asset("assets/chat.png")),
              ),
              Card(
                margin: EdgeInsets.all(20),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min, //chaiyeko jait matrai space
                        children: [
                          if (!_islogin)
                            UserImagePicker(onPickImage: (pickedImage) {
                              _selectedImage = pickedImage;
                            }),
                          TextFormField(
                            style: TextStyle(fontSize: 20),
                            decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: TextStyle(fontSize: labelFont)),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains("@")) {
                                return "enter valid email";
                              }
                              return null;
                            },
                            onSaved: (value) => {
                              _emailAddress = value!,
                            },
                          ),
                          if(!_islogin)
                          TextFormField(
                            decoration: const InputDecoration(
                              hintText: 'Enter Username',
                            ),
                            enableSuggestions: false,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value.trim().length <= 4) {
                                return 'enter valid username';
                              } else {
                                return null;
                              }
                            },
                            onSaved: (value) {
                              _enteredUsername = value!;
                            },
                          ),
                          TextFormField(
                            style: TextStyle(fontSize: 20),

                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(fontSize: labelFont),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _visibility = !_visibility;
                                  });
                                },
                                icon: Icon(_visibility
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                              ),
                            ),
                            //  keyboardType: TextInputType.multiline,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            obscureText: _visibility ? false : true,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  value.trim().length < 6) {
                                return "enter valid password";
                              }
                              return null;
                            },
                            onSaved: (newValue) => {
                              _password = newValue!,
                            },
                          ),
                          SizedBox(
                            height: 12,
                          ),
                          if (_isAuthenticating) CircularProgressIndicator(),
                          if (!_isAuthenticating)
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer),
                              child: Text(
                                _islogin ? "Log in " : "Sign Up",
                                style:
                                    TextStyle().copyWith(color: Colors.black87),
                              ),
                            ),
                          SizedBox(
                            height: 12,
                          ),
                          if (_isAuthenticating) CircularProgressIndicator(),
                          if (!_isAuthenticating)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _islogin = !_islogin;
                                  // _isLogin = islogin? false:true
                                });
                              },
                              child: Text(
                                _islogin
                                    ? "Create a new account"
                                    : 'I already have an account',
                                style:
                                    TextStyle().copyWith(color: Colors.black87),
                              ),
                            )
                        ],
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
