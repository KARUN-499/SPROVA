class AppConfig {
  // App Info
  static const String appName = 'Sprova';
  static const String appTagline = 'Build a Startup in 30 Days';

  // Cohort Info
  static const String cohortName = 'Cohort 1';
  static const String cohortStartDate = 'August 1, 2026';
  static const int totalSeats = 15;

  // Pricing
  static const int priceRupees = 2999;
  static const int pricePaise = 299900;
  static const String currencyCode = 'INR';

  // Payment
  static const String paymentDisplayName = 'Sprova Cohort 1';
  static const int paymentTimeoutSeconds = 600;

  // Target Audience
  static const int minAge = 17;
  static const int maxAge = 22;
  static const String targetCountry = 'India';

  // Format strings
  static String get seatsLeftText => '$seatsRemaining seats left';
  static int get seatsRemaining => totalSeats - seatsTaken;
  static const int seatsTaken = 4;

  // Track descriptions
  static const Map<String, String> trackDescriptions = {
    'Digital Product':
        'App, SaaS, tool, or digital service. Ship and sell online.',
    'Physical Product':
        'Make something real. Sell it before you manufacture at scale.',
    'Local Business':
        'Serve your city. Get your first paying local customer in 30 days.',
    'No-Code': 'Build with Webflow, Glide, or Notion. No coding required.',
  };

  // Weekly curriculum
  static const Map<String, String> weeklyCurriculum = {
    'Week 1': 'Kill your bad assumptions',
    'Week 2': 'Build the right thing',
    'Week 3': 'Get your first rupee',
    'Week 4': 'Prove it\'s a business',
  };

  // Policies
  static const String refundPolicy =
      'No refunds. No extensions. No exceptions.\nIf you\'re not ready to commit, this isn\'t for you.';
}
