import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/song.dart';
import '../widgets/player_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayer _player = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  List<Song> _songs = [];
  List<Song> _filtered = [];
  int _currentIndex = -1;
  bool _loading = true;
  bool _hasPermission = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _requestPermissions();
    if (_hasPermission) {
      await _loadSongs();
    }
    setState(() => _loading = false);
  }

  Future<void> _requestPermissions() async {
    final audioStatus = await Permission.audio.request();
    final storageStatus = await Permission.storage.request();
    _hasPermission = audioStatus.isGranted || storageStatus.isGranted;
    if (!_hasPermission) {
      _hasPermission = await _audioQuery.permissionsStatus();
    }
  }

  Future<void> _loadSongs() async {
    try {
      final rawSongs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      setState(() {
        _songs = rawSongs
            .map((s) => Song(
                  id: s.id,
                  title: s.title,
                  artist: s.artist ?? 'Näbelli aýdymçy',
                  album: s.album,
                  duration: Duration(milliseconds: s.duration ?? 0),
                  uri: s.uri,
                ))
            .toList();
        _filtered = _songs;
      });
    } catch (e) {
      debugPrint('Ýüklemek säwligi: $e');
    }
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filtered = _songs;
      } else {
        _filtered = _songs.where((s) {
          return s.title.toLowerCase().contains(_searchQuery) ||
              s.artist.toLowerCase().contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _playSong(int index) async {
    if (index < 0 || index >= _filtered.length) return;
    try {
      final song = _filtered[index];
      final result = await _audioQuery.querySongById(song.id);
      if (result.isEmpty || result.first.uri == null) return;

      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(result.first.uri!)),
      );
      _player.play();
      setState(() => _currentIndex = _songs.indexOf(song));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çalyp bolmady: $e')),
        );
      }
    }
  }

  void _next() {
    if (_filtered.isEmpty) return;
    final currentFilteredIdx = _filtered.indexWhere(
      (s) => _songs.indexOf(s) == _currentIndex,
    );
    final next = (currentFilteredIdx + 1) % _filtered.length;
    _playSong(next);
  }

  void _previous() {
    if (_filtered.isEmpty) return;
    final currentFilteredIdx = _filtered.indexWhere(
      (s) => _songs.indexOf(s) == _currentIndex,
    );
    final prev = (currentFilteredIdx - 1 + _filtered.length) % _filtered.length;
    _playSong(prev);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🎵 Meniň aýdymlarym (${_songs.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Täzele',
            onPressed: () async {
              setState(() => _loading = true);
              await _loadSongs();
              setState(() => _loading = false);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_songs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                onChanged: _applySearch,
                decoration: InputDecoration(
                  hintText: 'Gözle...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: _songs.isEmpty
          ? null
          : PlayerBar(
              player: _player,
              currentTitle: _currentIndex >= 0
                  ? _songs[_currentIndex].title
                  : null,
              onNext: _next,
              onPrevious: _previous,
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Ýüklenýär...'),
          ],
        ),
      );
    }
    if (!_hasPermission) {
      return _buildPermissionDenied();
    }
    if (_songs.isEmpty) {
      return _buildEmptyState();
    }
    if (_filtered.isEmpty) {
      return const Center(child: Text('Aýdym tapylmady'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 180),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final song = _filtered[index];
        final isCurrent = _songs.indexOf(song) == _currentIndex;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                isCurrent ? Theme.of(context).colorScheme.primary : null,
            child: Icon(
              isCurrent ? Icons.music_note : Icons.audiotrack,
              color: isCurrent
                  ? Theme.of(context).colorScheme.onPrimary
                  : null,
            ),
          ),
          title: Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : null,
            ),
          ),
          subtitle: Text(
            '${song.artist} • ${song.durationText}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _playSong(index),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off,
              size: 100, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('Aýdym tapylmady',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Telefonyňyza MP3 faýl goýuň',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock,
                size: 100, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Aýdymlara giriş ýok',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Sazlamalarda audio faýllara giriş rugsatyny beriň',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async => await openAppSettings(),
              icon: const Icon(Icons.settings),
              label: const Text('Sazlamalary aç'),
            ),
          ],
        ),
      ),
    );
  }
}
