import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhoneVerificationDialog extends StatefulWidget {
  const PhoneVerificationDialog({super.key});

  @override
  State<PhoneVerificationDialog> createState() =>
      _PhoneVerificationDialogState();
}

class _PhoneVerificationDialogState extends State<PhoneVerificationDialog> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _verificationId = '';
  bool _isLoading = false;
  bool _otpSent = false;
  String _errorMessage = '';

  Future<void> _sendOTP() async {
    if (_phoneController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter a phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String phoneNumber = _phoneController.text.trim();

      // Ensure phone number has country code
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+1$phoneNumber'; // Default to US, adjust as needed
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (mounted) {
            await _verifyAndSavePhoneNumber(credential);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Verification failed: ${e.message}';
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _otpSent = true;
              _verificationId = verificationId;
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) {
            setState(() => _verificationId = verificationId);
          }
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error sending OTP: $e';
        });
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );

      await _verifyAndSavePhoneNumber(credential);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid OTP: $e';
        });
      }
    }
  }

  Future<void> _verifyAndSavePhoneNumber(PhoneAuthCredential credential) async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No user logged in';
          });
        }
        return;
      }

      // For demo purposes, we'll save directly to Firestore without full verification
      // In production, you might want to use the Cloud Function approach mentioned earlier
      await _savePhoneNumberToFirestore(user.uid, _phoneController.text.trim());

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  Future<void> _savePhoneNumberToFirestore(
    String userId,
    String phoneNumber,
  ) async {
    await _firestore.collection('Users').doc(userId).update({
      'phone': phoneNumber,
    });
  }

  void _resetDialog() {
    if (mounted) {
      setState(() {
        _otpSent = false;
        _phoneController.clear();
        _otpController.clear();
        _errorMessage = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF14181E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _otpSent ? 'Verify OTP' : 'Add Phone Number',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_otpSent)
              TextField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: _darkInput(hint: 'Phone Number', icon: Icons.phone),
              ),

            if (_otpSent) ...[
              const SizedBox(height: 6),
              const Text(
                'Enter the 6-digit code sent to your phone',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: _darkInput(
                  hint: 'OTP Code',
                  icon: Icons.sms,
                  counterText: '',
                ),
              ),
            ],

            if (_errorMessage.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1A1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      actions: [
        if (_otpSent)
          TextButton(
            onPressed: _resetDialog,
            child: const Text(
              'Change Number',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _isLoading ? null : (_otpSent ? _verifyOTP : _sendOTP),
          child:
              _isLoading
                  ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : Text(
                    _otpSent ? 'Verify' : 'Send OTP',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}

InputDecoration _darkInput({
  required String hint,
  required IconData icon,
  String? counterText,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white38),
    prefixIcon: Icon(icon, color: Colors.white54),
    counterText: counterText,
    filled: true,
    fillColor: const Color(0xFF0F1115),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white30),
    ),
  );
}
