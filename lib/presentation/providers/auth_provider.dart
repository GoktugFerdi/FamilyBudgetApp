import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isGuest;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String activePlan; // 'personal' or 'family'
  final String? familyId;
  final bool isPremium;

  AuthState({
    this.isGuest = true,
    this.userId,
    this.userName,
    this.userEmail,
    this.activePlan = 'personal',
    this.familyId,
    this.isPremium = false,
  });

  AuthState copyWith({
    bool? isGuest,
    String? userId,
    String? userName,
    String? userEmail,
    String? activePlan,
    String? familyId,
    bool? isPremium,
  }) {
    return AuthState(
      isGuest: isGuest ?? this.isGuest,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      activePlan: activePlan ?? this.activePlan,
      familyId: familyId ?? this.familyId,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<DocumentSnapshot>? _familySubscription;

  AuthNotifier() : super(AuthState()) {
    _loadAuthStatus();

    // Auth durum değişikliklerini dinle
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _fetchUserData(user);
        _listenToUserData(user);
      } else {
        await logout();
      }
    });
  }

  void _listenToUserData(User user) {
    _userSubscription?.cancel();
    _familySubscription?.cancel();

    _userSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (doc) {
            if (doc.exists) {
              final data = doc.data()!;
              final familyId = data['familyId'] as String?;
              final activePlan = data['activePlan'] ?? state.activePlan;
              bool isPremium = data['isPremium'] ?? false;

              // Eğer aileye bağlıysa, aileyi de dinlemeye başla
              if (familyId != null) {
                _familySubscription?.cancel();
                _familySubscription = _firestore
                    .collection('families')
                    .doc(familyId)
                    .snapshots()
                    .listen((familyDoc) {
                      if (familyDoc.exists) {
                        final familyPremium =
                            familyDoc.data()?['isPremium'] ?? false;
                        state = state.copyWith(
                          isPremium: isPremium || familyPremium,
                        );
                      }
                    });
              }

              state = state.copyWith(
                isGuest: false,
                userId: user.uid,
                userName: data['name'] ?? user.displayName ?? user.email?.split('@').first,
                userEmail: user.email,
                activePlan: activePlan,
                familyId: familyId,
                isPremium: isPremium,
              );
            }
          },
          onError: (e) {
            debugPrint('User data listen error: $e');
          },
        );
  }

  Future<void> _loadAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final activePlan = prefs.getString('active_plan') ?? 'personal';
    final user = _auth.currentUser;

    if (user != null) {
      state = state.copyWith(
        isGuest: false,
        userId: user.uid,
        userName: user.displayName ?? user.email?.split('@').first,
        userEmail: user.email,
        activePlan: activePlan,
      );
      await _fetchUserData(user);
      _listenToUserData(user);
    } else {
      state = AuthState(isGuest: true, activePlan: activePlan);
    }
  }

  Future<void> _fetchUserData(User user) async {
    try {
      var doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        final initialData = {
          'name': user.displayName ?? user.email?.split('@').first ?? 'Kullanıcı',
          'email': user.email,
          'activePlan': 'personal',
          'isPremium': false,
          'familyId': null,
        };
        await _firestore.collection('users').doc(user.uid).set(initialData);
        doc = await _firestore.collection('users').doc(user.uid).get();
      }

      final data = doc.data() ?? {};
      final familyId = data['familyId'] as String?;
      final activePlan = data['activePlan'] ?? 'personal';
      final isPremium = data['isPremium'] ?? false;

      if (familyId != null) {
        _familySubscription?.cancel();
        _familySubscription = _firestore
            .collection('families')
            .doc(familyId)
            .snapshots()
            .listen((familyDoc) {
              if (familyDoc.exists) {
                final familyPremium = familyDoc.data()?['isPremium'] ?? false;
                state = state.copyWith(isPremium: isPremium || familyPremium);
              }
            });
      }

      state = state.copyWith(
        isGuest: false,
        userId: user.uid,
        userName:
            data['name'] ?? user.displayName ?? user.email?.split('@').first,
        userEmail: user.email,
        activePlan: activePlan,
        familyId: familyId,
        isPremium: isPremium,
      );
    } catch (e) {
      debugPrint('User data fetch error: $e');
    }
  }

  Future<void> switchPlan(String planName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_plan', planName);

    if (_auth.currentUser != null) {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'activePlan': planName,
      });
    }

    state = state.copyWith(activePlan: planName);
  }

  Future<void> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = cred.user;
      if (user != null) {
        await _fetchUserData(user);
        _listenToUserData(user);
      }
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user!;

      // Yeni kullanıcı verisini Firestore'a kaydet
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'activePlan': 'personal',
        'isPremium': false,
        'familyId': null,
      });

      state = state.copyWith(
        isGuest: false,
        userId: user.uid,
        userName: name,
        userEmail: email,
        activePlan: 'personal',
        familyId: null,
        isPremium: false,
      );

      _listenToUserData(user);
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    }
  }

  String _generateShortCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = math.Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<String> createFamily() async {
    if (state.userId == null) {
      throw Exception('Giriş yapmanız gerekiyor.');
    }

    String newCode = '';
    bool success = false;

    final familyDoc = _firestore.collection('families').doc();

    while (!success) {
      newCode = _generateShortCode();
      final codeRef = _firestore.collection('family_codes').doc(newCode);

      try {
        await _firestore.runTransaction((transaction) async {
          final codeSnapshot = await transaction.get(codeRef);
          if (codeSnapshot.exists) {
            throw Exception('Code exists');
          }

          transaction.set(codeRef, {
            'familyId': familyDoc.id,
            'createdAt': FieldValue.serverTimestamp(),
          });

          transaction.set(familyDoc, {
            'createdBy': state.userId,
            'code': newCode,
            'members': [state.userId],
            'isPremium': false,
          });

          transaction.update(_firestore.collection('users').doc(state.userId), {
            'familyId': familyDoc.id,
          });
        });
        success = true;
      } catch (e) {
        if (e.toString().contains('Code exists')) {
          continue;
        } else {
          rethrow;
        }
      }
    }
    return newCode;
  }

  Future<void> joinFamily(String code) async {
    if (state.userId == null) {
      throw Exception('Giriş yapmanız gerekiyor.');
    }
    final codeStr = code.trim().toUpperCase();

    await _firestore.runTransaction((transaction) async {
      final codeRef = _firestore.collection('family_codes').doc(codeStr);
      final codeSnapshot = await transaction.get(codeRef);
      if (!codeSnapshot.exists) throw Exception('Geçersiz davet kodu.');

      final familyId = codeSnapshot.data()!['familyId'] as String;
      final familyRef = _firestore.collection('families').doc(familyId);
      final familySnapshot = await transaction.get(familyRef);
      if (!familySnapshot.exists) throw Exception('Aile bulunamadı.');

      final currentMembers = List<String>.from(
        familySnapshot.data()?['members'] ?? [],
      );
      if (!currentMembers.contains(state.userId)) {
        currentMembers.add(state.userId!);
        transaction.update(familyRef, {'members': currentMembers});
      }

      transaction.update(_firestore.collection('users').doc(state.userId), {
        'familyId': familyId,
      });
    });
  }

  Future<void> leaveFamily() async {
    if (state.userId == null || state.familyId == null) return;

    await _firestore.collection('users').doc(state.userId).update({
      'familyId': null,
      'activePlan': 'personal',
    });

    final familyRef = _firestore.collection('families').doc(state.familyId);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(familyRef);
      if (doc.exists) {
        final members = List<String>.from(doc.data()?['members'] ?? []);
        members.remove(state.userId);
        transaction.update(familyRef, {'members': members});
      }
    });

    await switchPlan('personal');
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() async {
    _userSubscription?.cancel();
    _familySubscription?.cancel();
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_plan');

    state = AuthState(isGuest: true, activePlan: 'personal');
  }
}
