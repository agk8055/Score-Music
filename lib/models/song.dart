class Song {
  final String id;
  final String title;
  final String album;
  final String albumUrl;
  final String image;
  final String mediaUrl;
  final String mediaPreviewUrl;
  final String duration;
  final String language;
  final Map<String, String> artistMap;
  final String primaryArtists;
  final String singers;
  final String music;
  final String year;
  final String playCount;
  final bool isDrm;
  final bool hasLyrics;
  final String permaUrl;
  final String releaseDate;
  final String label;
  final String copyrightText;
  final bool is320kbps;
  final String disabledText;
  final bool isDisabled;

  String get coverUrl => image;
  String get artist => primaryArtists;

  Song({
    required this.id,
    required this.title,
    required this.album,
    required this.albumUrl,
    required this.image,
    required this.mediaUrl,
    required this.mediaPreviewUrl,
    required this.duration,
    required this.language,
    required this.artistMap,
    required this.primaryArtists,
    required this.singers,
    required this.music,
    required this.year,
    required this.playCount,
    required this.isDrm,
    required this.hasLyrics,
    required this.permaUrl,
    required this.releaseDate,
    required this.label,
    required this.copyrightText,
    required this.is320kbps,
    required this.disabledText,
    required this.isDisabled,
  });

  static String _toString(dynamic value) => value?.toString() ?? '';
  static bool _toBool(dynamic value) => value?.toString().toLowerCase() == 'true';

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: _toString(json['id']),
      title: _toString(json['song']),
      album: _toString(json['album']),
      albumUrl: _toString(json['album_url']),
      image: _toString(json['image']),
      mediaUrl: _toString(json['media_url']),
      mediaPreviewUrl: _toString(json['media_preview_url']),
      duration: _toString(json['duration']),
      language: _toString(json['language']),
      artistMap: Map<String, String>.from(json['artistMap'] ?? {}),
      primaryArtists: _toString(json['primary_artists']),
      singers: _toString(json['singers']),
      music: _toString(json['music']),
      year: _toString(json['year']),
      playCount: _toString(json['play_count']),
      isDrm: json['is_drm'] == 1,
      hasLyrics: _toBool(json['has_lyrics']),
      permaUrl: _toString(json['perma_url']),
      releaseDate: _toString(json['release_date']),
      label: _toString(json['label']),
      copyrightText: _toString(json['copyright_text']),
      is320kbps: _toBool(json['320kbps']),
      disabledText: _toString(json['disabled_text']),
      isDisabled: _toBool(json['disabled']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'song': title,
      'album': album,
      'album_url': albumUrl,
      'image': image,
      'media_url': mediaUrl,
      'media_preview_url': mediaPreviewUrl,
      'duration': duration,
      'language': language,
      'artistMap': artistMap,
      'primary_artists': primaryArtists,
      'singers': singers,
      'music': music,
      'year': year,
      'play_count': playCount,
      'is_drm': isDrm ? 1 : 0,
      'has_lyrics': hasLyrics,
      'perma_url': permaUrl,
      'release_date': releaseDate,
      'label': label,
      'copyright_text': copyrightText,
      '320kbps': is320kbps,
      'disabled_text': disabledText,
      'disabled': isDisabled,
    };
  }
} 