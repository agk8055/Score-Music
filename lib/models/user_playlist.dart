class UserPlaylist {
  final String id;
  final String name;
  final List<String> songIds;
  final DateTime createdAt;
  final DateTime lastUpdated;

  UserPlaylist({
    required this.id,
    required this.name,
    List<String>? songIds,
    DateTime? createdAt,
    DateTime? lastUpdated,
  })  : songIds = songIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songIds': songIds,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory UserPlaylist.fromJson(Map<String, dynamic> json) {
    return UserPlaylist(
      id: json['id'] as String,
      name: json['name'] as String,
      songIds: List<String>.from(json['songIds'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  UserPlaylist copyWith({
    String? id,
    String? name,
    List<String>? songIds,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return UserPlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
} 