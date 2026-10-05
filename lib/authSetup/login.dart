import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaselearning/authSetup/signUp.dart';
import 'package:firebaselearning/l10n/app_localizations.dart';
import 'package:firebaselearning/main_nav_shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

const _firebaseRequestTimeout = Duration(seconds: 20);

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool isObscure = true;
  bool _isSigningIn = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController emailresetController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  CollectionReference users = FirebaseFirestore.instance.collection('Users');

  String get _platformName {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }

  Future<void> _ensureUserProfile(User user) async {
    final userDocument = users.doc(user.uid);
    final snapshot = await userDocument.get().timeout(_firebaseRequestTimeout);
    if (snapshot.exists) return;

    await userDocument
        .set({
          'UserName':
              user.displayName ?? user.email?.split('@')[0] ?? 'No Name',
          'Email': user.email ?? 'No Email',
          'platform': _platformName,
          'clientId': user.uid,
          'liked': [],
          'cart': [],
          'orders': [],
          'addresses': [],
          'phone': '',
        })
        .timeout(_firebaseRequestTimeout);
  }

  Future<void> _showError(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Login failed'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  String _authErrorMessage(FirebaseAuthException error) {
    debugPrint(
      '[login] Firebase Authentication failed: ${error.code} - ${error.message}',
    );
    return switch (error.code) {
      'invalid-email' => 'The email address is not valid.',
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' => 'The email or password is incorrect.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' =>
        'Too many login attempts. Please wait a moment and try again.',
      'network-request-failed' =>
        'Could not reach Firebase. Check your internet connection and try again.',
      'operation-not-allowed' =>
        'This login method is not enabled in Firebase Authentication.',
      'account-exists-with-different-credential' =>
        'An account already exists with this email using another login method.',
      'popup-blocked' =>
        'Your browser blocked the Google sign-in window. Allow popups and try again.',
      'popup-closed-by-user' => 'Google sign-in was cancelled.',
      'unauthorized-domain' =>
        'This website is not an authorized Firebase Authentication domain.',
      _ => error.message ?? 'Firebase could not sign you in. Please try again.',
    };
  }

  Future<void> _openApp() async {
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavShell()),
    );
  }

  Future<void> _signInWithEmail() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _isSigningIn = true);
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          )
          .timeout(_firebaseRequestTimeout);
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'missing-user',
          message: 'Firebase did not return a signed-in user.',
        );
      }

      if (!user.emailVerified) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: const Text('Email not verified'),
                content: const Text(
                  'Verify your email before logging in. You can resend the verification email below.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await user.sendEmailVerification();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Resend email'),
                  ),
                ],
              ),
        );
        return;
      }

      await _openApp();
    } on TimeoutException {
      debugPrint('[login] Email login timed out');
      await _showError(
        'Firebase did not respond. Check your internet connection and try again.',
      );
    } on FirebaseAuthException catch (error) {
      await _showError(_authErrorMessage(error));
    } catch (error, stackTrace) {
      debugPrint('[login] Unexpected email login failure: $error\n$stackTrace');
      await _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isSigningIn = true);
    try {
      final credential = await signInWithGoogle();
      if (credential == null) return;

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'missing-user',
          message: 'Firebase did not return a signed-in user.',
        );
      }

      await _ensureUserProfile(user);
      await _openApp();
    } on TimeoutException {
      debugPrint('[login] Google login timed out');
      await _showError(
        'Firebase did not respond. Check your internet connection and try again.',
      );
    } on FirebaseAuthException catch (error) {
      await _showError(_authErrorMessage(error));
    } on UnsupportedError catch (error) {
      debugPrint('[login] Google login is unsupported: $error');
      await _showError(
        'Google sign-in is not supported by Firebase on this device.',
      );
    } on FirebaseException catch (error) {
      debugPrint(
        '[login] Firebase profile setup failed: ${error.code} - ${error.message}',
      );
      await _showError(
        'Google sign-in succeeded, but the user profile could not be loaded. '
        'Check the Firestore rules for Users/${FirebaseAuth.instance.currentUser?.uid}.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[login] Unexpected Google login failure: $error\n$stackTrace',
      );
      await _showError('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    emailresetController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width > 480 ? 460.0 : size.width;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1D3557), Color(0xFF2C5364)],
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
                          l10n.login,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        Text(l10n.email),
                        TextFormField(
                          validator: (val) {
                            if (val!.isEmpty) {
                              return l10n.pleaseEnterYourEmail;
                            } else if (!RegExp(
                              r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
                            ).hasMatch(val)) {
                              return l10n.pleaseEnterValidEmail;
                            }
                            return null;
                          },
                          controller: emailController,
                          decoration: InputDecoration(
                            hintText: l10n.enterYourEmail,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.password),
                        TextFormField(
                          validator: (val) {
                            if (val!.isEmpty) {
                              return l10n.pleaseEnterYourPassword;
                            }
                            return null;
                          },
                          obscureText: isObscure,
                          obscuringCharacter: "*",
                          controller: passwordController,
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  isObscure = !isObscure;
                                });
                              },
                              icon:
                                  isObscure
                                      ? Icon(Icons.visibility)
                                      : Icon(Icons.visibility_off),
                            ),
                            hintText: l10n.enterYourPassword,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text('Password Enter Account Email'),
                                  content: TextFormField(
                                    controller: emailresetController,
                                    decoration: InputDecoration(
                                      hintText: "Enter your email",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text('Password Reset'),
                                              content: Text(
                                                'If the email is registered, a password reset link will be sent to your email.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text('OK'),
                                                ),
                                              ],
                                            );
                                          },
                                          barrierDismissible: false,
                                        );
                                        try {
                                          await FirebaseAuth.instance
                                              .sendPasswordResetEmail(
                                                email:
                                                    emailresetController.text
                                                        .trim(),
                                              );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text('Error'),
                                                content: Text(
                                                  'An error occurred while sending the password reset email. Please try again later.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                    },
                                                    child: Text('OK'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        }
                                      },
                                      child: Text('OK'),
                                    ),
                                  ],
                                );
                              },
                              barrierDismissible: false,
                            );
                          },
                          child: Container(
                            alignment: Alignment.centerRight,
                            child: Text(
                              l10n.forgotPassword,
                              style: TextStyle(
                                color: const Color.fromARGB(255, 86, 174, 247),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed:
                                      _isSigningIn ? null : _signInWithEmail,
                                  child:
                                      _isSigningIn
                                          ? const SizedBox.square(
                                            dimension: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : Text(l10n.login),
                                ),
                              ),
                              SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed:
                                      _isSigningIn ? null : _signInWithGoogle,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${l10n.loginWithGoogle} '),
                                      SizedBox(width: 10),
                                      SizedBox(
                                        height: 30,
                                        width: 30,
                                        child: Image.asset(
                                          'lib/assets/google.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              Text(l10n.dontHaveAccount),
                              SizedBox(height: 10),

                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonal(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Signup(),
                                      ),
                                    );
                                  },
                                  child: Text(l10n.signUp),
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

Future<UserCredential?> signInWithGoogle() async {
  final auth = FirebaseAuth.instance;
  final provider = GoogleAuthProvider();

  if (kIsWeb) {
    return auth.signInWithPopup(provider).timeout(_firebaseRequestTimeout);
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-token',
          message: 'Google did not provide an authentication token.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return auth
          .signInWithCredential(credential)
          .timeout(_firebaseRequestTimeout);
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return auth.signInWithProvider(provider).timeout(_firebaseRequestTimeout);
  }
}
