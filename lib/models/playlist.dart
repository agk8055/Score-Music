class Playlist {
  final String id;
  final String name;
  final String image;
  final String url;
  final String fanCount;
  final String followerCount;
  final List<String> contentList;
  final String type;
  final String username;
  final String firstname;
  final String lastname;
  final bool isFollowed;
  final String lastUpdated;
  final List<String> subtitleDesc;

  Playlist({
    required this.id,
    required this.name,
    required this.image,
    required this.url,
    required this.fanCount,
    required this.followerCount,
    required this.contentList,
    required this.type,
    required this.username,
    required this.firstname,
    required this.lastname,
    required this.isFollowed,
    required this.lastUpdated,
    required this.subtitleDesc,
  });

  static String _toString(dynamic value) => value?.toString() ?? '';
  static bool _toBool(dynamic value) => value?.toString().toLowerCase() == 'true';
  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: _toString(json['listid']),
      name: _toString(json['listname']),
      image: _toString(json['image']),
      url: _toString(json['perma_url']),
      fanCount: _toString(json['fan_count']),
      followerCount: _toString(json['follower_count']),
      contentList: _toStringList(json['content_list']),
      type: _toString(json['type']),
      username: _toString(json['username']),
      firstname: _toString(json['firstname']),
      lastname: _toString(json['lastname']),
      isFollowed: json['is_followed'] == true,
      lastUpdated: _toString(json['last_updated']),
      subtitleDesc: _toStringList(json['subtitle_desc']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'listid': id,
      'listname': name,
      'image': image,
      'perma_url': url,
      'fan_count': fanCount,
      'follower_count': followerCount,
      'content_list': contentList,
      'type': type,
      'username': username,
      'firstname': firstname,
      'lastname': lastname,
      'is_followed': isFollowed,
      'last_updated': lastUpdated,
      'subtitle_desc': subtitleDesc,
    };
  }
} 