class LeetCodeStats {
  final String username;
  final String? name; // Added name field
  final String? profilePicture; // Added profile picture URL
  final int totalSolved;
  final int easySolved;
  final int mediumSolved;
  final int hardSolved;
  final int ranking;
  final int weeklyScore;
  final DateTime lastUpdated;

  LeetCodeStats({
    required this.username,
    this.name, 
    this.profilePicture,
    required this.totalSolved,
    required this.easySolved,
    required this.mediumSolved,
    required this.hardSolved,
    required this.ranking,
    this.weeklyScore = 0,
    required this.lastUpdated,
  });

  factory LeetCodeStats.fromMap(Map<String, dynamic> map) {
    return LeetCodeStats(
      username: map['username'] ?? '',
      name: map['name'], // Map name from DB join or passed value
      profilePicture: map['profile_picture'], // Map profile picture from DB
      totalSolved: map['total_solved'] ?? 0,
      easySolved: map['easy_solved'] ?? 0,
      mediumSolved: map['medium_solved'] ?? 0,
      hardSolved: map['hard_solved'] ?? 0,
      ranking: map['ranking'] ?? 0,
      weeklyScore: map['weekly_score'] ?? 0,
      lastUpdated: map['last_updated'] != null ? DateTime.parse(map['last_updated']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      // 'name': name, // Name is usually not stored in stats table, but joined
      'profile_picture': profilePicture, // Store profile picture URL
      'total_solved': totalSolved,
      'easy_solved': easySolved,
      'medium_solved': mediumSolved,
      'hard_solved': hardSolved,
      'ranking': ranking,
      'weekly_score': weeklyScore,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
  
  // Empty state
  factory LeetCodeStats.empty(String username) {
    return LeetCodeStats(
      username: username, 
      totalSolved: 0, 
      easySolved: 0, 
      mediumSolved: 0, 
      hardSolved: 0, 
      ranking: 0, 
      lastUpdated: DateTime.now()
    );
  }
  
  LeetCodeStats copyWith({String? name, String? profilePicture}) {
    return LeetCodeStats(
      username: username,
      name: name ?? this.name,
      profilePicture: profilePicture ?? this.profilePicture,
      totalSolved: totalSolved,
      easySolved: easySolved,
      mediumSolved: mediumSolved,
      hardSolved: hardSolved,
      ranking: ranking,
      weeklyScore: weeklyScore,
      lastUpdated: lastUpdated,
    );
  }
}
