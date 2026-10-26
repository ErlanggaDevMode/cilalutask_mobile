import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

export 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuthException, User, UserCredential;

/// Secure authentication service wrapping Firebase Authentication.
/// Handles login, registration, logout, and session state.
/// Ensures passwords are never logged, stored in local storage, or exposed.
class AuthService {
  static AuthService? _instance;
  factory AuthService() => _instance ??= AuthService._();
  AuthService._();

  FirebaseAuth? _auth;

  FirebaseAuth get auth {
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  /// Whether Firebase Auth instance is available and initialized.
  bool get isAvailable {
    try {
      return _auth != null || FirebaseAuth.instance.app.name.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Current authenticated Firebase user.
  User? get currentUser {
    try {
      return auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Current Firebase Auth UID. Stable identifier across devices.
  String? get currentUid => currentUser?.uid;

  /// Current authenticated email.
  String? get currentEmail => currentUser?.email;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges {
    try {
      return auth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Sign in with email and password via Firebase Auth.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    return await auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );
  }

  /// Register a new user with email and password via Firebase Auth.
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    return await auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );
  }

  /// Sign out current Firebase session completely.
  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      debugPrint('Auth sign out warning');
    }
  }

  /// Safe, human-friendly error messages that prevent leaking internal stack
  /// traces or database internals.
  static String getReadableAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
        case 'user-not-found':
        case 'wrong-password':
          return 'Email atau password tidak valid.';
        case 'email-already-in-use':
          return 'Email ini sudah terdaftar. Silakan masuk menggunakan akun Anda.';
        case 'weak-password':
          return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
        case 'invalid-email':
          return 'Format alamat email tidak valid.';
        case 'user-disabled':
          return 'Akun ini telah dinonaktifkan oleh administrator.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan gagal. Silakan coba beberapa saat lagi.';
        case 'network-request-failed':
          return 'Koneksi internet bermasalah. Periksa jaringan Anda.';
        case 'operation-not-allowed':
          return 'Metode autentikasi ini belum diaktifkan di Firebase Console.';
        default:
          return 'Gagal memproses autentikasi. Silakan periksa kredensial Anda.';
      }
    }
    return 'Terjadi kendala autentikasi. Silakan coba kembali.';
  }
}
