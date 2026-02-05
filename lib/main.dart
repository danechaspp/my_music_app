import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const CupertinoApp(
  theme: CupertinoThemeData(brightness: Brightness.dark, primaryColor: CupertinoColors.activeOrange),
  debugShowCheckedModeBanner: false,
  home: MusicApp(),
));

class MusicApp extends StatefulWidget {
  const MusicApp({super.key});
  @override
  State<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> {
  final String scClientId = "s9ToR3wrMiSkqOZ2kbnwPU0vIXYOtYQS";
  final AudioPlayer audioPlayer = AudioPlayer();
  List<dynamic> tracks = [];
  bool isLoading = true;
  dynamic currentTrack;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    loadTopCharts(); // Загружаем ТОП при входе
  }

  // Загрузка чартов (Топ музыки)
  Future<void> loadTopCharts() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse("https://api-v2.soundcloud.com/charts?kind=top&genre=soundcloud%3Agenres%3Aall-music&client_id=$scClientId&limit=20");
      final response = await http.get(url, headers: {"User-Agent": "Mozilla/5.0"});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          tracks = data['collection'].map((item) => item['track']).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Поиск
  Future<void> searchMusic(String query) async {
    if (query.isEmpty) { loadTopCharts(); return; }
    setState(() => isLoading = true);
    try {
      final url = Uri.parse("https://api-v2.soundcloud.com/search/tracks?q=${Uri.encodeComponent(query)}&client_id=$scClientId&limit=20");
      final response = await http.get(url, headers: {"User-Agent": "Mozilla/5.0"});
      if (response.statusCode == 200) {
        setState(() {
          tracks = json.decode(response.body)['collection'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Воспроизведение
  Future<void> playMusic(dynamic track) async {
    try {
      final transcodings = track['media']['transcodings'] as List;
      // Ищем поток, который Edge/Chrome проиграют без проблем
      var streamInfo = transcodings.firstWhere(
            (t) => t['format']['protocol'] == 'progressive',
        orElse: () => transcodings.first,
      );

      final streamRes = await http.get(Uri.parse("${streamInfo['url']}?client_id=$scClientId"));
      final mp3Url = json.decode(streamRes.body)['url'];

      await audioPlayer.play(UrlSource(mp3Url));
      setState(() {
        currentTrack = track;
        isPlaying = true;
      });
    } catch (e) {
      print("Ошибка: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const Text('Genius Music'),
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.person_crop_circle_fill, size: 32),
                  onPressed: () => Navigator.push(context, CupertinoPageRoute(builder: (c) => const ProfilePage())),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CupertinoSearchTextField(
                    placeholder: 'Треки, артисты...',
                    onSubmitted: searchMusic,
                  ),
                ),
              ),
              if (isLoading)
                const SliverFillRemaining(child: Center(child: CupertinoActivityIndicator()))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final track = tracks[index];
                      return MusicTile(
                        track: track,
                        onTap: () => playMusic(track),
                        onArtistTap: () => Navigator.push(context, CupertinoPageRoute(builder: (c) => ArtistPage(artist: track['user']))),
                      );
                    },
                    childCount: tracks.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          // ПЛЕЕР ВНИЗУ
          if (currentTrack != null)
            Positioned(
              bottom: 30, left: 15, right: 15,
              child: MiniPlayer(
                track: currentTrack,
                isPlaying: isPlaying,
                onToggle: () {
                  if (isPlaying) audioPlayer.pause(); else audioPlayer.resume();
                  setState(() => isPlaying = !isPlaying);
                },
              ),
            ),
        ],
      ),
    );
  }
}

// --- ВИДЖЕТЫ СТРАНИЦ ---

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text("Мой Профиль")),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Center(child: Icon(CupertinoIcons.person_circle_fill, size: 100, color: CupertinoColors.activeOrange)),
            const Text("Admin", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const Text("Premium Developer", style: TextStyle(color: CupertinoColors.systemGrey)),
            const SizedBox(height: 30),
            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(title: const Text("Моя медиатека"), trailing: const Icon(CupertinoIcons.right_chevron), onTap: () {}),
                CupertinoListTile(title: const Text("Настройки"), trailing: const Icon(CupertinoIcons.right_chevron), onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ArtistPage extends StatelessWidget {
  final dynamic artist;
  const ArtistPage({super.key, this.artist});
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(artist['username'] ?? 'Артист')),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            ClipOval(child: Image.network(artist['avatar_url'] ?? '', width: 120, height: 120, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(CupertinoIcons.person, size: 120))),
            const SizedBox(height: 10),
            Text(artist['username'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text("Исполнитель SoundCloud", style: TextStyle(color: CupertinoColors.systemGrey)),
          ],
        ),
      ),
    );
  }
}

class MiniPlayer extends StatelessWidget {
  final dynamic track;
  final bool isPlaying;
  final VoidCallback onToggle;
  const MiniPlayer({super.key, required this.track, required this.isPlaying, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: CupertinoColors.black.withOpacity(0.5), blurRadius: 15)],
      ),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(track['artwork_url'] ?? '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(CupertinoIcons.music_note))),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(track['title'] ?? '', maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(track['user']['username'] ?? '', maxLines: 1, style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 12)),
          ])),
          CupertinoButton(padding: EdgeInsets.zero, onPressed: onToggle, child: Icon(isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill, size: 35, color: CupertinoColors.activeOrange)),
        ],
      ),
    );
  }
}

class MusicTile extends StatelessWidget {
  final dynamic track;
  final VoidCallback onTap;
  final VoidCallback onArtistTap;
  const MusicTile({super.key, required this.track, required this.onTap, required this.onArtistTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5))),
        child: Row(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(track['artwork_url'] ?? '', width: 55, height: 55, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(CupertinoIcons.music_note))),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(track['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1),
              GestureDetector(onTap: onArtistTap, child: Text(track['user']['username'] ?? '', style: const TextStyle(color: CupertinoColors.activeOrange, fontSize: 13))),
            ])),
            const Icon(CupertinoIcons.play_circle, color: CupertinoColors.systemGrey),
          ],
        ),
      ),
    );
  }
}