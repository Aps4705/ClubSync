class AppConstants {
  // App info
  static const String appName = 'ClubSync';
  static const String appTagline = 'Your Campus, One Place';
  static const String kietDomain = '@kiet.edu';

  // Firebase collections
  static const String usersCollection = 'users';
  static const String clubsCollection = 'clubs';
  static const String eventsCollection = 'events';
  static const String announcementsCollection = 'announcements';
  static const String recruitmentsCollection = 'recruitments';
  static const String hackathonsCollection = 'hackathons';
  static const String teamUpPostsCollection = 'team_up_posts';
  static const String registrationsCollection = 'registrations';
  static const String notificationsCollection = 'notifications';

  // Storage paths
  static const String clubLogosPath = 'club_logos';
  static const String eventImagesPath = 'event_images';
  static const String userAvatarsPath = 'user_avatars';

  // User roles
  static const String roleStudent = 'student';
  static const String roleClubAdmin = 'club_admin';
  static const String roleSuperAdmin = 'super_admin';

  // Club categories
  static const List<String> clubCategories = [
    'Technical',
    'Cultural',
    'Sports',
    'Finance',
    'Literary',
  ];

  // Branches
  static const List<String> branches = [
    'CSE',
    'CSE (AI/ML)',
    'CSE (IoT)',
    'ECE',
    'EEE',
    'ME',
    'IT',
    'CSIT',
    'CS',
    'CS-DS',
  ];

  // Years
  static const List<String> years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

  // Skill tags for Team Up
  static const List<String> skillTags = [
    'Flutter',
    'React Native',
    'Android',
    'iOS',
    'React.js',
    'Node.js',
    'Django',
    'FastAPI',
    'Python',
    'Java',
    'C++',
    'Machine Learning',
    'Deep Learning',
    'Data Science',
    'UI/UX Design',
    'Figma',
    'DevOps',
    'Cloud',
    'Blockchain',
    'IoT',
    'Embedded Systems',
    'Robotics',
    'Cybersecurity',
    'Game Development',
  ];


  static const int pageSize = 20; // number of pages loaded per req

  // Cache duration
  static const Duration cacheDuration = Duration(minutes: 15); //good to do this not necessary but good practice
  
}