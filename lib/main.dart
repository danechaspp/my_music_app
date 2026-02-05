import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.systemPink,
      ),
      home: MusicPlayerScreen(),
    );
  }
}

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List _tracks = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentTrackUrl;

  Future<void> _searchMusic(String query) async {
    final url = Uri.parse('https://api-v2.soundcloud.com/search/tracks?q=$query&client_id=YOUR_CLIENT_ID_IF_NEEDED');
    // Внимание: SoundCloud API может требовать Client ID. 
    // Для теста мы используем упрощенную логику.
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _tracks = json.decode(response.body)['collection'];
        });
      }
    } catch (e) {
      print("Ошибка поиска: $e");
    }
  }

  void _playMusic(String url) async {
    if (_currentTrackUrl == url && _isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play(UrlSource(url));
      setState(() {
        _currentTrackUrl = url;
        _isPlaying = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Genius Music'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoSearchTextField(
                controller: _searchController,
                onSubmitted: _searchMusic,
              ),
            ),
            Expanded(
              child: _tracks.isEmpty
                  ? const Center(child: Text('Поиск музыки...'))
                  : ListView.builder(
                      itemCount: _tracks.length,
                      itemBuilder: (context, index) {
                        final track = _tracks[index];
                        return CupertinoListTile(
                          title: Text(track['title'] ?? 'Без названия'),
                          subtitle: Text(track['user']['username'] ?? 'Неизвестен'),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: track['artwork_url'] != null 
                                ? Image.network(track['artwork_url']) 
                                : const Icon(CupertinoIcons.music_note),
                          ),
                          trailing: CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: Icon(
                              _currentTrackUrl == track['stream_url'] && _isPlaying
                                  ? CupertinoIcons.pause_fill
                                  : CupertinoIcons.play_fill,
                            ),
                            onPressed: () => _playMusic(track['stream_url']),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Простой аналог ListTile для стиля Cupertino
class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final Widget leading;
  final Widget trailing;

  const CupertinoListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                subtitle,
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
