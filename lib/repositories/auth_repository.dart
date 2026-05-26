import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/models.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  // ── Email / Password ──────────────────────────────────────

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email, password: password,
    );
    return _fetchOrCreateUser(credential.user!);
  }

  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email, password: password,
    );
    await credential.user!.updateDisplayName(displayName);
    return _createUser(credential.user!, displayName: displayName);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Google Sign-In ────────────────────────────────────────

  Future<AppUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    return _fetchOrCreateUser(userCredential.user!);
  }

  // ── Anonymous Sign-In ─────────────────────────────────────

  Future<AppUser> signInAnonymously() async {
    final userCredential = await _auth.signInAnonymously();
    return _fetchOrCreateUser(userCredential.user!, displayName: 'Guest');
  }

  // ── Apple Sign-In ─────────────────────────────────────────

  Future<AppUser> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);
    return _fetchOrCreateUser(
      userCredential.user!,
      displayName: [
        appleCredential.givenName,
        appleCredential.familyName,
      ].whereType<String>().join(' '),
    );
  }

  // ── Sign Out ──────────────────────────────────────────────

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // ── User Profile ──────────────────────────────────────────

  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _fetchOrCreateUser(user);
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    Address? defaultAddress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final updates = <String, dynamic>{};
    if (displayName != null) {
      updates['displayName'] = displayName;
      await user.updateDisplayName(displayName);
    }
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
    if (defaultAddress != null) updates['defaultAddress'] = defaultAddress.toMap();

    await _db.collection('users').doc(user.uid).update(updates);
  }

  // ── Helpers ───────────────────────────────────────────────

  Future<AppUser> _fetchOrCreateUser(User user, {String? displayName}) async {
    final doc = await _db.collection('users').doc(user.uid).get();
    if (doc.exists) return AppUser.fromFirestore(doc);
    return _createUser(user, displayName: displayName);
  }

  Future<AppUser> _createUser(User user, {String? displayName}) async {
    final appUser = AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: displayName ?? user.displayName ?? 'User',
      photoUrl: user.photoURL,
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(user.uid).set(appUser.toFirestore());
    return appUser;
  }
}
