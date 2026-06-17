import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around [FirebaseAuth] so the rest of the app never imports
/// the Firebase package directly. Makes mocking in tests trivial.
class AuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;

  /// Emits the current Firebase user, or `null` when signed out.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(displayName);
    return cred;
  }

  Future<void> signOut() => _auth.signOut();

  /// Begins phone verification. The verification id is returned via
  /// [onCodeSent] (used to confirm the OTP) and again as part of the
  /// auto-retrieval timeout. On Android, [verificationCompleted] may fire
  /// instantly when the SMS is auto-detected — when that happens we just
  /// sign in directly.
  Future<void> sendPhoneOtp({
    required String phoneE164,
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException error) onFailed,
    void Function(UserCredential cred)? onAutoSignIn,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final cred = await _auth.signInWithCredential(credential);
          onAutoSignIn?.call(cred);
        } on FirebaseAuthException catch (e) {
          onFailed(e);
        }
      },
      verificationFailed: onFailed,
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserCredential> confirmPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
}
