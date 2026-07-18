import 'package:cloud_firestore/cloud_firestore.dart';

// User Model 

class UserModel {
  final String? managedClubId; // for club_admin ..... which club they manage
  final String uid;
  final String name;
  final String email;
  final String branch;
  final String year;
  final String role; // student , club admin , super admin
  final String? avatarUrl;
  final List<String> followedClubs;
  final List<String> registeredEvents;
  final bool notificationsEnabled;
  final Map<String, bool> notificationPrefs;
  final DateTime createdAt;
  final bool isApproved; // for club admin

  const UserModel({
    this.managedClubId,
    required this.uid,
    required this.name,
    required this.email,
    required this.branch,
    required this.year,
    required this.role,
    this.avatarUrl,
    this.followedClubs = const [],
    this.registeredEvents = const [],
    this.notificationsEnabled = true,
    this.notificationPrefs = const {},
    required this.createdAt,
    this.isApproved = true,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      managedClubId: data['managedClubId'],
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      branch: data['branch'] ?? '',
      year: data['year'] ?? '',
      role: data['role'] ?? 'student',
      avatarUrl: data['avatarUrl'],
      followedClubs: List<String>.from(data['followedClubs'] ?? []),
      registeredEvents: List<String>.from(data['registeredEvents'] ?? []),
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      notificationPrefs: Map<String, bool>.from(data['notificationPrefs'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isApproved: data['isApproved'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'managedClubId': managedClubId,
        'name': name,
        'email': email,
        'branch': branch,
        'year': year,
        'role': role,
        'avatarUrl': avatarUrl,
        'followedClubs': followedClubs,
        'registeredEvents': registeredEvents,
        'notificationsEnabled': notificationsEnabled,
        'notificationPrefs': notificationPrefs,
        'createdAt': Timestamp.fromDate(createdAt),
        'isApproved': isApproved,
      };

  UserModel copyWith({
  String? managedClubId,
  String? name,
  String? branch,
  String? year,
  String? avatarUrl,
  List<String>? followedClubs,
  List<String>? registeredEvents,
  bool? notificationsEnabled,
  Map<String, bool>? notificationPrefs,
}) =>
    UserModel(
      managedClubId: managedClubId ?? this.managedClubId, 
      uid: uid,
      name: name ?? this.name,
      email: email,
      branch: branch ?? this.branch,
      year: year ?? this.year,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      followedClubs: followedClubs ?? this.followedClubs,
      registeredEvents: registeredEvents ?? this.registeredEvents,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
      createdAt: createdAt,
      isApproved: isApproved,
    );
}

//Club Model

class ClubModel {
  final String id;
  final String name;
  final String category; // Technical , Cultural ,Sports ,Finance ,Literary
  final String description;
  final String? logoUrl;
  final String? bannerUrl;
  final List<String> domains;
  final CoreTeam coreTeam;
  final String recruitmentStatus; // open or closed
  final List<SocialLink> socialLinks;
  final List<String> achievements;
  final int followerCount;
  final String adminUid;
  final bool isVerified;
  final DateTime createdAt;

  const ClubModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    this.logoUrl,
    this.bannerUrl,
    this.domains = const [],
    required this.coreTeam,
    this.recruitmentStatus = 'closed',
    this.socialLinks = const [],
    this.achievements = const [],
    this.followerCount = 0,
    required this.adminUid,
    this.isVerified = false,
    required this.createdAt,
  });

  factory ClubModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClubModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'Technical',
      description: data['description'] ?? '',
      logoUrl: data['logoUrl'],
      
      bannerUrl: data['bannerUrl'],
      domains: List<String>.from(data['domains'] ?? []),
      coreTeam: CoreTeam.fromMap(data['coreTeam'] ?? {}),
      recruitmentStatus: data['recruitmentStatus'] ?? 'closed',
      socialLinks: (data['socialLinks'] as List<dynamic>? ?? [])
          .map((e) => SocialLink.fromMap(e))
          .toList(),
      achievements: List<String>.from(data['achievements'] ?? []),
      followerCount: data['followerCount'] ?? 0,
      adminUid: data['adminUid'] ?? '',
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'category': category,
        'description': description,
        'logoUrl': logoUrl,
        'bannerUrl': bannerUrl,
        'domains': domains,
        'coreTeam': coreTeam.toMap(),
        'recruitmentStatus': recruitmentStatus,
        'socialLinks': socialLinks.map((e) => e.toMap()).toList(),
        'achievements': achievements,
        'followerCount': followerCount,
        'adminUid': adminUid,
        'isVerified': isVerified,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class CoreTeam {
  final String headName;
  final String headAvatarUrl;
  final String headEmail;
  final List<CoreMember> members;

  const CoreTeam({
    required this.headName,
    required this.headAvatarUrl,
    this.headEmail = '',
    this.members = const [],
  });

  factory CoreTeam.fromMap(Map<String, dynamic> map) => CoreTeam(
        headName: map['headName'] ?? '',
        headAvatarUrl: map['headAvatarUrl'] ?? '',
        headEmail: map['headEmail'] ?? '',
        members: (map['members'] as List<dynamic>? ?? [])
            .map((e) => CoreMember.fromMap(e))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'headName': headName,
        'headAvatarUrl': headAvatarUrl,
        'headEmail': headEmail,
        'members': members.map((e) => e.toMap()).toList(),
      };
}

class CoreMember {
  final String name;
  final String role;
  final String? avatarUrl;

  const CoreMember({required this.name, required this.role, this.avatarUrl});

  factory CoreMember.fromMap(Map<String, dynamic> map) => CoreMember(
        name: map['name'] ?? '',
        role: map['role'] ?? '',
        avatarUrl: map['avatarUrl'],
      );

  Map<String, dynamic> toMap() => {'name': name, 'role': role, 'avatarUrl': avatarUrl};
}

class SocialLink {
  final String platform; // instagram , linkedin ,github , website
  final String url;

  const SocialLink({required this.platform, required this.url});

  factory SocialLink.fromMap(Map<String, dynamic> map) =>
      SocialLink(platform: map['platform'] ?? '', url: map['url'] ?? '');

  Map<String, dynamic> toMap() => {'platform': platform, 'url': url};
}

// Event Model

class EventModel {
  final String id;
  final String title;
  final String clubId;
  final String clubName;
  final String? clubLogoUrl;
  final String description;
  final DateTime date;
  final String venue;
  final String? imageUrl;
  final String? registrationLink;
  final int registrationCount;
  final String status; // upcoming , ongoing ,completed
  final String type; // workshop , hackathon , seminar ,cultural , sports
  final DateTime createdAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.clubId,
    required this.clubName,
    this.clubLogoUrl,
    required this.description,
    required this.date,
    required this.venue,
    this.imageUrl,
    this.registrationLink,
    this.registrationCount = 0,
    this.status = 'upcoming',
    this.type = 'workshop',
    required this.createdAt,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      clubId: data['clubId'] ?? '',
      clubName: data['clubName'] ?? '',
      clubLogoUrl: data['clubLogoUrl'],
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      venue: data['venue'] ?? '',
      imageUrl: data['imageUrl'],
      registrationLink: data['registrationLink'],
      registrationCount: data['registrationCount'] ?? 0,
      status: data['status'] ?? 'upcoming',
      type: data['type'] ?? 'workshop',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'clubId': clubId,
        'clubName': clubName,
        'clubLogoUrl': clubLogoUrl,
        'description': description,
        'date': Timestamp.fromDate(date),
        'venue': venue,
        'imageUrl': imageUrl,
        'registrationLink': registrationLink,
        'registrationCount': registrationCount,
        'status': status,
        'type': type,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  bool get isUpcoming => date.isAfter(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  bool get isThisWeek => date.difference(DateTime.now()).inDays <= 7 && date.isAfter(DateTime.now());
}

// Announcement Model 

class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String? clubId;
  final String? clubName;
  final String? clubLogoUrl;
  final bool isCampusWide;
  final String priority; // normal ,high ,urgent
  final DateTime createdAt;
  final DateTime? expiresAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    this.clubId,
    this.clubName,
    this.clubLogoUrl,
    this.isCampusWide = false,
    this.priority = 'normal',
    required this.createdAt,
    this.expiresAt,
  });

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      clubId: data['clubId'],
      clubName: data['clubName'],
      clubLogoUrl: data['clubLogoUrl'],
      isCampusWide: data['isCampusWide'] ?? false,
      priority: data['priority'] ?? 'normal',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null ? (data['expiresAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'body': body,
        'clubId': clubId,
        'clubName': clubName,
        'clubLogoUrl': clubLogoUrl,
        'isCampusWide': isCampusWide,
        'priority': priority,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      };
}

// Recruitment Model 

class RecruitmentModel {
  final String id;
  final String clubId;
  final String clubName;
  final String? clubLogoUrl;
  final String title;
  final String description;
  final List<String> rolesAvailable;
  final String? applyLink;
  final DateTime deadline;
  final String status; // open or closed
  final DateTime createdAt;

  const RecruitmentModel({
    required this.id,
    required this.clubId,
    required this.clubName,
    this.clubLogoUrl,
    required this.title,
    required this.description,
    this.rolesAvailable = const [],
    this.applyLink,
    required this.deadline,
    this.status = 'open',
    required this.createdAt,
  });

  factory RecruitmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecruitmentModel(
      id: doc.id,
      clubId: data['clubId'] ?? '',
      clubName: data['clubName'] ?? '',
      clubLogoUrl: data['clubLogoUrl'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      rolesAvailable: List<String>.from(data['rolesAvailable'] ?? []),
      applyLink: data['applyLink'],
      deadline: (data['deadline'] as Timestamp).toDate(),
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'clubId': clubId,
        'clubName': clubName,
        'clubLogoUrl': clubLogoUrl,
        'title': title,
        'description': description,
        'rolesAvailable': rolesAvailable,
        'applyLink': applyLink,
        'deadline': Timestamp.fromDate(deadline),
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  bool get isOpen => status == 'open' && deadline.isAfter(DateTime.now());
}

// Hackathon Model

class HackathonModel {
  final String id;
  final String title;
  final String organizer;
  final String description;
  final String? imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime registrationDeadline;
  final String? registrationLink;
  final String mode; // online , offline , hybrid
  final String? prizePool;
  final List<String> themes;
  final int teamSize;
  final String status; // upcoming,ongoing ,completed
  final DateTime createdAt;

  const HackathonModel({
    required this.id,
    required this.title,
    required this.organizer,
    required this.description,
    this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.registrationDeadline,
    this.registrationLink,
    this.mode = 'offline',
    this.prizePool,
    this.themes = const [],
    this.teamSize = 4,
    this.status = 'upcoming',
    required this.createdAt,
  });

  factory HackathonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HackathonModel(
      id: doc.id,
      title: data['title'] ?? '',
      organizer: data['organizer'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      registrationDeadline: (data['registrationDeadline'] as Timestamp).toDate(),
      registrationLink: data['registrationLink'],
      mode: data['mode'] ?? 'offline',
      prizePool: data['prizePool'],
      themes: List<String>.from(data['themes'] ?? []),
      teamSize: data['teamSize'] ?? 4,
      status: data['status'] ?? 'upcoming',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'organizer': organizer,
        'description': description,
        'imageUrl': imageUrl,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'registrationDeadline': Timestamp.fromDate(registrationDeadline),
        'registrationLink': registrationLink,
        'mode': mode,
        'prizePool': prizePool,
        'themes': themes,
        'teamSize': teamSize,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  bool get registrationOpen => registrationDeadline.isAfter(DateTime.now());
}

//  Team Up Post Model 

class TeamUpPost {
  final String id;
  final String authorUid;
  final String authorName;
  final String? authorAvatarUrl;
  final String authorBranch;
  final String authorYear;
  final String title;
  final String description;
  final List<String> skillsNeeded;
  final String contactInfo;
  final String? linkedHackathon;
  final bool isOpen;
  final DateTime createdAt;

  const TeamUpPost({
    required this.id,
    required this.authorUid,
    required this.authorName,
    this.authorAvatarUrl,
    required this.authorBranch,
    required this.authorYear,
    required this.title,
    required this.description,
    this.skillsNeeded = const [],
    required this.contactInfo,
    this.linkedHackathon,
    this.isOpen = true,
    required this.createdAt,
  });

  factory TeamUpPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamUpPost(
      id: doc.id,
      authorUid: data['authorUid'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatarUrl: data['authorAvatarUrl'],
      authorBranch: data['authorBranch'] ?? '',
      authorYear: data['authorYear'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      skillsNeeded: List<String>.from(data['skillsNeeded'] ?? []),
      contactInfo: data['contactInfo'] ?? '',
      linkedHackathon: data['linkedHackathon'],
      isOpen: data['isOpen'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'authorUid': authorUid,
        'authorName': authorName,
        'authorAvatarUrl': authorAvatarUrl,
        'authorBranch': authorBranch,
        'authorYear': authorYear,
        'title': title,
        'description': description,
        'skillsNeeded': skillsNeeded,
        'contactInfo': contactInfo,
        'linkedHackathon': linkedHackathon,
        'isOpen': isOpen,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
