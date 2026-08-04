import 'dart:async';

import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/itunes_api.dart';

/// 곡 검색 화면 (iTunes Search API).
/// 선택한 곡 목록을 pop 결과로 돌려준다.
class SongSearchScreen extends StatefulWidget {
  const SongSearchScreen({super.key});

  @override
  State<SongSearchScreen> createState() => _SongSearchScreenState();
}

class _SongSearchScreenState extends State<SongSearchScreen> {
  final _api = ItunesApi();
  final _controller = TextEditingController();
  Timer? _debounce;

  List<Song> _results = [];
  final List<Song> _selected = [];
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted) return;
      setState(() => _searching = true);
      try {
        final results = await _api.searchSongs(query);
        if (mounted) setState(() => _results = results);
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  bool _isSelected(Song song) =>
      _selected.any((s) => s.trackId == song.trackId);

  void _toggle(Song song) {
    setState(() {
      if (_isSelected(song)) {
        _selected.removeWhere((s) => s.trackId == song.trackId);
      } else {
        _selected.add(song);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('곡 검색'),
        actions: [
          if (_selected.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(context).pop(_selected),
              child: Text('${_selected.length}곡 추가'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: '곡 제목이나 아티스트 검색',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFF1A1526),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_searching) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _controller.text.isEmpty
                          ? '듣고 싶은 곡을 검색해 보세요 🎵'
                          : (_searching ? '' : '검색 결과가 없어요'),
                      style: const TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final song = _results[i];
                      final selected = _isSelected(song);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF2A2438)
                              : const Color(0xFF1A1526),
                          borderRadius: BorderRadius.circular(14),
                          border: selected
                              ? Border.all(color: const Color(0xFF7C4DFF))
                              : null,
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: song.artworkUrl != null
                                ? Image.network(
                                    song.artworkUrl!
                                        .replaceAll('600x600', '100x100'),
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        const SizedBox(
                                            width: 44, height: 44),
                                  )
                                : const SizedBox(width: 44, height: 44),
                          ),
                          title: Text(song.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                          trailing: Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.add_circle_outline,
                            color: selected
                                ? const Color(0xFF7C4DFF)
                                : Colors.white38,
                          ),
                          onTap: () => _toggle(song),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
