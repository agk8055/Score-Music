class Album {
  final String id;
  final String name;
  final String url;
  final String image;
  final String year;
  final String language;
  final String primaryArtists;
  final String title;
  final String releaseDate;
  final String primaryArtistsId;

  Album({
    required this.id,
    required this.name,
    required this.url,
    required this.image,
    required this.year,
    required this.language,
    required this.primaryArtists,
    required this.title,
    required this.releaseDate,
    required this.primaryArtistsId,
  });

  static String _toString(dynamic value) => value?.toString() ?? '';

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: _toString(json['albumid']),
      name: _toString(json['name']),
      url: _toString(json['perma_url']),
      image: _toString(json['image']),
      year: _toString(json['year']),
      language: _toString(json['language'] ?? ''),
      primaryArtists: _toString(json['primary_artists']),
      title: _toString(json['title']),
      releaseDate: _toString(json['release_date']),
      primaryArtistsId: _toString(json['primary_artists_id']),
    );
  }
} 