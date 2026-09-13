class Song {
  final int id;
  final String title;
  final String artist;
  final String? album;
  final Duration duration;
  final String? data;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.duration,
    this.data,
  });

  factory Song.fromQuery(Map<String, dynamic> data) {
    return Song(
      id: data['id'] as int,
      title: data['title'] as String? ?? 'Ady ýok',
      artist: data['artist'] as String? ?? 'Näbelli aýdymçy',
      album: data['album'] as String?,
      duration: Duration(milliseconds: data['duration'] as int? ?? 0),
      data: data['data'] as String?,
    );
  }

  String get durationText {
    final m = duration.inMinutes;
    final s = duration.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
