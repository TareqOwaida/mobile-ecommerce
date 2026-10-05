import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaselearning/authSetup/login.dart';
import 'package:flutter/material.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  bool? isObscure;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController confirmpasswordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  CollectionReference users = FirebaseFirestore.instance.collection('Users');
  Future<void> addUser() {
    String docId =
        FirebaseAuth.instance.currentUser?.uid ??
        "custom_id_${DateTime.now().millisecondsSinceEpoch}";
    return users.doc(docId).set({
      'UserName': usernameController.text,
      'Email': emailController.text,
      'platform': Platform.isIOS ? "iOS" : "Android",
      'clientId': FirebaseAuth.instance.currentUser?.uid,
      'liked': [],
      'cart': [],
      'orders': [],
      'addresses': [],
      'phone': '',
    });
  }

  @override
  void initState() {
    isObscure = true;
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    confirmpasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width > 520 ? 500.0 : size.width;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed:
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Login()),
              ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  "SignUp",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Text("Username"),
                TextFormField(
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Please enter your username";
                    } else if (val.length < 5) {
                      return "Username must be at least 5 characters long";
                    }
                    return null;
                  },
                  controller: usernameController,
                  decoration: InputDecoration(hintText: "Enter your username"),
                ),
                const SizedBox(height: 16),
                Text("Email"),
                TextFormField(
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Please enter your email";
                    } else if (!RegExp(
                      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
                    ).hasMatch(val)) {
                      return "Please enter a valid email";
                    }
                    return null;
                  },
                  controller: emailController,
                  decoration: InputDecoration(hintText: "Enter your email"),
                ),
                const SizedBox(height: 16),
                Text("Password"),
                TextFormField(
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Please enter your password";
                    } else if (val.length < 6) {
                      return "Password must be at least 6 characters long";
                    } else if (!RegExp(
                      r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{6,}$",
                    ).hasMatch(val)) {
                      return "Password must contain at least one uppercase letter, one lowercase letter, and one number";
                    }
                    return null;
                  },
                  obscureText: isObscure!,
                  obscuringCharacter: "*",
                  controller: passwordController,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          isObscure = !isObscure!;
                        });
                      },
                      icon:
                          isObscure!
                              ? Icon(Icons.visibility)
                              : Icon(Icons.visibility_off),
                    ),
                    hintText: "Enter your password",
                  ),
                ),
                const SizedBox(height: 16),
                Text("Confirm Password"),
                TextFormField(
                  obscureText: true,
                  obscuringCharacter: "*",
                  controller: confirmpasswordController,
                  decoration: InputDecoration(hintText: "Confirm Password"),
                ),

                SizedBox(height: 30),
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            if (passwordController.text ==
                                confirmpasswordController.text) {
                              try {
                                // ignore: unused_local_variable
                                final credential = await FirebaseAuth.instance
                                    .createUserWithEmailAndPassword(
                                      email: emailController.text.trim(),
                                      password: passwordController.text.trim(),
                                    );
                                await addUser();
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text('Please verify your email'),
                                      content: Text(
                                        'An email has been sent to the email given to verify your account.please verify your email before logging in.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () async {
                                            await FirebaseAuth
                                                .instance
                                                .currentUser!
                                                .sendEmailVerification();
                                            await FirebaseAuth
                                                .instance
                                                .currentUser
                                                ?.reload();
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => Login(),
                                              ),
                                            );
                                          },
                                          child: Text('OK'),
                                        ),
                                      ],
                                    );
                                  },
                                  barrierDismissible: false,
                                );
                              } on FirebaseAuthException catch (e) {
                                if (e.code == 'weak-password') {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('Faild to create account'),
                                        content: Text(
                                          'The password provided is too weak',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () =>
                                                    Navigator.of(context).pop(),
                                            child: Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                    barrierDismissible: false,
                                  );
                                } else if (e.code == 'email-already-in-use') {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('Erorr'),
                                        content: Text(
                                          'There has be an error making the account. Please try again later',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () =>
                                                    Navigator.of(context).pop(),
                                            child: Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                    barrierDismissible: false,
                                  );
                                }
                              } catch (e) {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text('Erorr'),
                                      content: Text(
                                        'There has be an error making the account. Please try again later',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: Text('OK'),
                                        ),
                                      ],
                                    );
                                  },
                                  barrierDismissible: false,
                                );
                              }
                            } else {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('Password Mismatch'),
                                    content: Text(
                                      'please make sure both passwords are same',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(context).pop(),
                                        child: Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                                barrierDismissible: false,
                              );
                            }
                          },
                          child: const Text('Sign Up'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
