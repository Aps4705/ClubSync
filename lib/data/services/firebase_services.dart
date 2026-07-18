import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Notification Service 

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  Future<void> initialize(String uid) async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token and save to Firestore
      final token = await _messaging.getToken();
      if (token != null) await _saveToken(uid, token);

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((token) => _saveToken(uid, token));

      // Init local notifications for foreground
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _local.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );

      // Show notification when app is in foreground
      FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        if (notification != null) {
          _local.show(
            notification.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'clubsync_channel', 'ClubSync',
                channelDescription: 'ClubSync notifications',
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
          );
        }
      });
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'fcmToken': token});
  }

  // Call this when user logs out
  Future<void> clearToken(String uid) async {
    await FirebaseMessaging.instance.deleteToken();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'fcmToken': null});
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());
// Auth Service 

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Sign in with email/password. Only @kiet.edu emails allowed.
  Future<UserCredential> signIn(String email, String password) async {
    if (!email.endsWith(AppConstants.kietDomain)) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Only KIET college email (@kiet.edu) is allowed.',
      );
    }
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Register new student. Only @kiet.edu emails allowed.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String branch,
    required String year,
  }) async {
    if (!email.endsWith(AppConstants.kietDomain)) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Only KIET college email (@kiet.edu) is allowed.',
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user!.sendEmailVerification();

    final user = UserModel(
      uid: credential.user!.uid,
      name: name,
      email: email,
      branch: branch,
      year: year,
      role: AppConstants.roleStudent,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(credential.user!.uid)
        .set(user.toFirestore());

    return user;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }
}

//  Clubs Service 

class ClubsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

Stream<List<ClubModel>> getClubs({String? category}) {
  Query query = _db.collection(AppConstants.clubsCollection);

  if (category != null && category != 'All') {
    query = query.where('category', isEqualTo: category);
  }

  return query.snapshots().map((snap) {
    final clubs = snap.docs.map(ClubModel.fromFirestore).toList();
    clubs.sort((a, b) => b.followerCount.compareTo(a.followerCount));
    return clubs;
  });
}

  Stream<ClubModel?> getClub(String clubId) => _db
      .collection(AppConstants.clubsCollection)
      .doc(clubId)
      .snapshots()
      .map((doc) => doc.exists ? ClubModel.fromFirestore(doc) : null);

 
  Stream<List<ClubModel>> getClubsByIds(List<String> ids) {
    if (ids.isEmpty) return Stream.value([]);

    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
    }

    if (chunks.length == 1) {
      return _db
          .collection(AppConstants.clubsCollection)
          .where(FieldPath.documentId, whereIn: chunks.first)
          .snapshots()
          .map((s) => s.docs.map(ClubModel.fromFirestore).toList());
    }

   
    final controller = StreamController<List<ClubModel>>.broadcast();
    final latest = List<List<ClubModel>>.filled(chunks.length, const []);
    final received = List<bool>.filled(chunks.length, false);
    final subs = <StreamSubscription>[];

    for (var i = 0; i < chunks.length; i++) {
      final index = i;
      final sub = _db
          .collection(AppConstants.clubsCollection)
          .where(FieldPath.documentId, whereIn: chunks[index])
          .snapshots()
          .map((s) => s.docs.map(ClubModel.fromFirestore).toList())
          .listen((clubs) {
        latest[index] = clubs;
        received[index] = true;
        if (received.every((r) => r)) {
          controller.add(latest.expand((l) => l).toList());
        }
      });
      subs.add(sub);
    }

    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };

    return controller.stream;
  }

  Future<List<ClubModel>> searchClubs(String query) async {
    final snap = await _db
        .collection(AppConstants.clubsCollection)
        .where('isVerified', isEqualTo: true)
        .get();
    return snap.docs
        .map(ClubModel.fromFirestore)
        .where((c) =>
            c.name.toLowerCase().contains(query.toLowerCase()) ||
            c.description.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<void> followClub(String uid, String clubId) async {
    final batch = _db.batch();
    batch.update(
      _db.collection(AppConstants.usersCollection).doc(uid),
      {
        'followedClubs': FieldValue.arrayUnion([clubId])
      },
    );
    batch.update(
      _db.collection(AppConstants.clubsCollection).doc(clubId),
      {'followerCount': FieldValue.increment(1)},
    );
    await batch.commit();
  }

  Future<void> unfollowClub(String uid, String clubId) async {
    final batch = _db.batch();
    batch.update(
      _db.collection(AppConstants.usersCollection).doc(uid),
      {
        'followedClubs': FieldValue.arrayRemove([clubId])
      },
    );
    batch.update(
      _db.collection(AppConstants.clubsCollection).doc(clubId),
      {'followerCount': FieldValue.increment(-1)},
    );
    await batch.commit();
  }
}

// Events Service 

class EventsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

Stream<List<EventModel>> getEvents({String? filter}) {
  final now = DateTime.now();
  Query query = _db.collection(AppConstants.eventsCollection);

  if (filter == 'today') {
    query = query
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(
          DateTime(now.year, now.month, now.day),
        ))
        .where('date', isLessThan: Timestamp.fromDate(
          DateTime(now.year, now.month, now.day + 1),
        ));
  } else if (filter == 'week') {
    query = query
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('date', isLessThan: Timestamp.fromDate(
          now.add(const Duration(days: 7)),
        ));
  } else if (filter == 'completed') {
    query = query.where('date', isLessThan: Timestamp.fromDate(now));
  }
  

  return query.snapshots().map((snap) {
    final events = snap.docs.map(EventModel.fromFirestore).toList();
    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  });
}

  Stream<List<EventModel>> getClubEvents(String clubId) => _db
      .collection(AppConstants.eventsCollection)
      .where('clubId', isEqualTo: clubId)
      .orderBy('date', descending: false)
      .snapshots()
      .map((s) => s.docs.map(EventModel.fromFirestore).toList());

  Stream<List<EventModel>> getEventsByIds(List<String> ids) {
    if (ids.isEmpty) return Stream.value([]);

    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
    }

    if (chunks.length == 1) {
      return _db
          .collection(AppConstants.eventsCollection)
          .where(FieldPath.documentId, whereIn: chunks.first)
          .snapshots()
          .map((s) => s.docs.map(EventModel.fromFirestore).toList());
    }

   
    final controller = StreamController<List<EventModel>>.broadcast();
    final latest = List<List<EventModel>>.filled(chunks.length, const []);
    final received = List<bool>.filled(chunks.length, false);
    final subs = <StreamSubscription>[];

    for (var i = 0; i < chunks.length; i++) {
      final index = i;
      final sub = _db
          .collection(AppConstants.eventsCollection)
          .where(FieldPath.documentId, whereIn: chunks[index])
          .snapshots()
          .map((s) => s.docs.map(EventModel.fromFirestore).toList())
          .listen((events) {
        latest[index] = events;
        received[index] = true;
        if (received.every((r) => r)) {
          controller.add(latest.expand((l) => l).toList());
        }
      });
      subs.add(sub);
    }

    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };

    return controller.stream;
  }

Future<bool> registerForEvent(String uid, String eventId) async {
  final userRef = _db.collection(AppConstants.usersCollection).doc(uid);
  final eventRef = _db.collection(AppConstants.eventsCollection).doc(eventId);
  final registrationRef = _db.collection(AppConstants.registrationsCollection).doc('${uid}_$eventId');

 
  return _db.runTransaction<bool>((txn) async {
    final userSnap = await txn.get(userRef);
    final registeredEvents = List<String>.from(userSnap.data()?['registeredEvents'] ?? []);
    if (registeredEvents.contains(eventId)) return false; // already registered

    txn.update(userRef, {
      'registeredEvents': FieldValue.arrayUnion([eventId])
    });
    txn.update(eventRef, {'registrationCount': FieldValue.increment(1)});
    txn.set(registrationRef, {
      'uid': uid,
      'eventId': eventId,
      'registeredAt': FieldValue.serverTimestamp(),
    });
    return true;
  });
}

Future<void> unregisterFromEvent(String uid, String eventId) async {
  final batch = _db.batch();
  batch.update(
    _db.collection(AppConstants.usersCollection).doc(uid),
    {'registeredEvents': FieldValue.arrayRemove([eventId])},
  );
  batch.update(
    _db.collection(AppConstants.eventsCollection).doc(eventId),
    {'registrationCount': FieldValue.increment(-1)},
  );
  await _db
      .collection(AppConstants.registrationsCollection)
      .doc('${uid}_$eventId')
      .delete();
  await batch.commit();
}
}

//Announcements Service

class AnnouncementsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<AnnouncementModel>> getAnnouncements({List<String>? followedClubs}) {
    return _db
        .collection(AppConstants.announcementsCollection)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map(AnnouncementModel.fromFirestore)
          .where((a) {
            if (a.isCampusWide) return true;
            if (followedClubs != null && a.clubId != null) {
              return followedClubs.contains(a.clubId);
            }
            return true;
          })
          .toList();
    });
  }
}

//  Recruitments Service 

class RecruitmentsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<RecruitmentModel>> getOpenRecruitments() => _db
      .collection(AppConstants.recruitmentsCollection)
      .where('status', isEqualTo: 'open')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map(RecruitmentModel.fromFirestore)
          
          .where((r) => r.deadline.isAfter(DateTime.now()))
          .toList());
}

// Hackathons Service

class HackathonsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<HackathonModel>> getHackathons() => _db
      .collection(AppConstants.hackathonsCollection)
      .orderBy('startDate', descending: false)
      .snapshots()
      .map((s) => s.docs.map(HackathonModel.fromFirestore).toList());
}

// Team Up Service

class TeamUpService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<TeamUpPost>> getPosts() => _db
      .collection(AppConstants.teamUpPostsCollection)
      .where('isOpen', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(TeamUpPost.fromFirestore).toList());

  Future<void> createPost(TeamUpPost post) async {
    await _db
        .collection(AppConstants.teamUpPostsCollection)
        .doc(post.id)
        .set(post.toFirestore());
  }

  Future<void> updatePost(TeamUpPost post) async {
    await _db
        .collection(AppConstants.teamUpPostsCollection)
        .doc(post.id)
        .update(post.toFirestore());
  }

  Future<void> closePost(String postId) async {
    await _db
        .collection(AppConstants.teamUpPostsCollection)
        .doc(postId)
        .update({'isOpen': false});
  }
}

// User Service 

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<UserModel?> watchUser(String uid) => _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);

  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _db.collection(AppConstants.usersCollection).doc(uid).update(data);

  Future<void> updateNotificationSettings(
      String uid, bool enabled, Map<String, bool> prefs) =>
      _db.collection(AppConstants.usersCollection).doc(uid).update({
        'notificationsEnabled': enabled,
        'notificationPrefs': prefs,
      });
}

// Storage Service 

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadAvatar(String uid, File file) async {
    final ref = _storage.ref().child('${AppConstants.userAvatarsPath}/$uid.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

// Admin Service 

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;


  Future<void> deleteEvent(String eventId) =>
    _db.collection(AppConstants.eventsCollection).doc(eventId).delete();

Future<void> deleteRecruitment(String recruitmentId) =>
    _db.collection(AppConstants.recruitmentsCollection).doc(recruitmentId).delete();

Future<void> deleteAnnouncement(String announcementId) =>
    _db.collection(AppConstants.announcementsCollection).doc(announcementId).delete();

  Future<void> createEvent(EventModel event) => _db
      .collection(AppConstants.eventsCollection)
      .doc(event.id)
      .set(event.toFirestore());

  Future<void> createAnnouncement(AnnouncementModel ann) => _db
      .collection(AppConstants.announcementsCollection)
      .doc(ann.id)
      .set(ann.toFirestore());

  Future<void> createRecruitment(RecruitmentModel r) => _db
      .collection(AppConstants.recruitmentsCollection)
      .doc(r.id)
      .set(r.toFirestore());

  // Get all users (super_admin only)
Stream<List<UserModel>> getAllUsers() => _db
    .collection(AppConstants.usersCollection)
    .snapshots()
    .map((s) => s.docs.map(UserModel.fromFirestore).toList());

// Assign club admin role
Future<void> assignClubAdmin(String uid, String clubId) async {
  final batch = _db.batch();
  batch.update(_db.collection(AppConstants.usersCollection).doc(uid), {
    'role': 'club_admin',
    'managedClubId': clubId,
    'isApproved': true,
  });
  batch.update(_db.collection(AppConstants.clubsCollection).doc(clubId), {
    'adminUid': uid,
  });
  await batch.commit();
}

// Remove club admin role
Future<void> removeClubAdmin(String uid) async {
  await _db.collection(AppConstants.usersCollection).doc(uid).update({
    'role': 'student',
    'managedClubId': null,
  });
}

// Update club logo/banner URLs
Future<void> updateClubMedia(String clubId, {String? logoUrl, String? bannerUrl}) async {
  final data = <String, dynamic>{};
  if (logoUrl != null) data['logoUrl'] = logoUrl;
  if (bannerUrl != null) data['bannerUrl'] = bannerUrl;
  await _db.collection(AppConstants.clubsCollection).doc(clubId).update(data);
}

// Update club info
Future<void> updateClubInfo(String clubId, Map<String, dynamic> data) =>
    _db.collection(AppConstants.clubsCollection).doc(clubId).update(data);

    Stream<Map<String, dynamic>> getRealClubAnalytics(String clubId) {
  return _db.collection(AppConstants.clubsCollection).doc(clubId).snapshots().map((doc) {
    final data = doc.data() ?? {};
    return {
      'followers': data['followerCount'] ?? 0,
      'recruitmentStatus': data['recruitmentStatus'] ?? 'closed',
      'domains': (data['domains'] as List?)?.length ?? 0,
      'achievements': (data['achievements'] as List?)?.length ?? 0,
    };
  });
}

Future<int> getEventRegistrationCount(String clubId) async {
  final snap = await _db.collection(AppConstants.eventsCollection)
      .where('clubId', isEqualTo: clubId).get();
  int total = 0;
  for (final doc in snap.docs) {
    total += (doc.data()['registrationCount'] as int? ?? 0);
  }
  return total;
}

Future<int> getClubEventCount(String clubId) async {
  final snap = await _db.collection(AppConstants.eventsCollection)
      .where('clubId', isEqualTo: clubId).get();
  return snap.docs.length;
}
}

// Providers

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final clubsServiceProvider = Provider<ClubsService>((ref) => ClubsService());
final eventsServiceProvider = Provider<EventsService>((ref) => EventsService());
final announcementsServiceProvider =
    Provider<AnnouncementsService>((ref) => AnnouncementsService());
final recruitmentsServiceProvider =
    Provider<RecruitmentsService>((ref) => RecruitmentsService());
final hackathonsServiceProvider =
    Provider<HackathonsService>((ref) => HackathonsService());
final teamUpServiceProvider = Provider<TeamUpService>((ref) => TeamUpService());
final userServiceProvider = Provider<UserService>((ref) => UserService());
final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(userServiceProvider).watchUser(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});