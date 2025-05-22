import 'song.dart';
import 'album.dart';
import 'playlist.dart';

enum PlayHistoryItemType {
  song,
  album,
  playlist,
}

class PlayHistoryItem {
  final PlayHistoryItemType type;
  final String id;
  final String title;
  final String image;
  final String subtitle;
  final String url;
  final Song? song;
  final Album? album;
  final Playlist? playlist;

  PlayHistoryItem({
    required this.type,
    required this.id,
    required this.title,
    required this.image,
    required this.subtitle,
    required this.url,
    this.song,
    this.album,
    this.playlist,
  });

  factory PlayHistoryItem.fromSong(Song song) {
    return PlayHistoryItem(
      type: PlayHistoryItemType.song,
      id: song.id,
      title: song.title,
      image: song.image,
      subtitle: song.primaryArtists,
      url: song.permaUrl,
      song: song,
    );
  }

  factory PlayHistoryItem.fromAlbum(Album album) {
    return PlayHistoryItem(
      type: PlayHistoryItemType.album,
      id: album.id,
      title: album.name,
      image: album.image,
      subtitle: album.primaryArtists,
      url: album.url,
      album: album,
    );
  }

  factory PlayHistoryItem.fromPlaylist(Playlist playlist) {
    return PlayHistoryItem(
      type: PlayHistoryItemType.playlist,
      id: playlist.id,
      title: playlist.name,
      image: playlist.image,
      subtitle: playlist.subtitleDesc.isNotEmpty ? playlist.subtitleDesc[0] : '',
      url: playlist.url,
      playlist: playlist,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'type': type.toString().split('.').last,
      'id': id,
      'title': title,
      'image': image,
      'subtitle': subtitle,
      'url': url,
    };

    if (song != null) {
      data['song'] = song!.toJson();
    }
    if (album != null) {
      data['album'] = album!.toJson();
    }
    if (playlist != null) {
      data['playlist'] = playlist!.toJson();
    }

    return data;
  }

  factory PlayHistoryItem.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'song';
    final type = PlayHistoryItemType.values.firstWhere(
      (e) => e.toString().split('.').last == typeStr,
      orElse: () => PlayHistoryItemType.song,
    );

    if (type == PlayHistoryItemType.song && json['song'] != null) {
      return PlayHistoryItem.fromSong(Song.fromJson(json['song']));
    } else if (type == PlayHistoryItemType.album && json['album'] != null) {
      return PlayHistoryItem.fromAlbum(Album.fromJson(json['album']));
    } else if (type == PlayHistoryItemType.playlist && json['playlist'] != null) {
      return PlayHistoryItem.fromPlaylist(Playlist.fromJson(json['playlist']));
    }

    // Fallback to basic data if specific type data is missing
    return PlayHistoryItem(
      type: type,
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      image: json['image'] ?? '',
      subtitle: json['subtitle'] ?? '',
      url: json['url'] ?? '',
    );
  }
} 