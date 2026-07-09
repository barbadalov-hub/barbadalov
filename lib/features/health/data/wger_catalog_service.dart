import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// One exercise from the live wger.de open database.
class WgerExercise {
  final int id;
  final String name;
  final String category;
  final List<String> muscles;
  final String? imageUrl;
  final String? videoUrl;
  final String description;

  const WgerExercise({
    required this.id,
    required this.name,
    required this.category,
    required this.muscles,
    required this.description,
    this.imageUrl,
    this.videoUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'muscles': muscles,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'description': description,
      };

  factory WgerExercise.fromJson(Map<String, dynamic> json) => WgerExercise(
        id: json['id'] as int,
        name: json['name'] as String,
        category: (json['category'] as String?) ?? '',
        muscles: ((json['muscles'] as List<dynamic>?) ?? const [])
            .cast<String>(),
        imageUrl: json['imageUrl'] as String?,
        videoUrl: json['videoUrl'] as String?,
        description: (json['description'] as String?) ?? '',
      );
}

/// Client for wger's public REST API (no key, CORS `*` on the API). Exercise
/// names/descriptions come localized straight from wger — Russian is language
/// id 5, Ukrainian 15, English 2.
class WgerCatalogService {
  final http.Client _http;
  WgerCatalogService([http.Client? client]) : _http = client ?? http.Client();

  static const languageIds = {'ru': 5, 'uk': 15, 'en': 2};

  /// wger's /media/ files send no CORS headers, so on web route images through
  /// the public wsrv.nl image proxy; native platforms load directly.
  static String corsSafeImage(String url) => kIsWeb
      ? 'https://images.weserv.nl/?url=${Uri.encodeComponent(url.replaceFirst(RegExp('^https?://'), ''))}'
      : url;

  /// Parse one API page into exercises, choosing the first translation
  /// matching [langPriority] (e.g. [5, 2] = Russian, then English).
  static List<WgerExercise> parsePage(
    Map<String, dynamic> body,
    List<int> langPriority,
  ) {
    final out = <WgerExercise>[];
    for (final raw in (body['results'] as List<dynamic>? ?? const [])) {
      final r = raw as Map<String, dynamic>;
      final translations =
          (r['translations'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

      Map<String, dynamic>? picked;
      for (final lang in langPriority) {
        for (final t in translations) {
          if (t['language'] == lang && (t['name'] as String?)?.isNotEmpty == true) {
            picked = t;
            break;
          }
        }
        if (picked != null) break;
      }
      if (picked == null) continue;

      final images = (r['images'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      final mainImage = images.isEmpty
          ? null
          : (images.firstWhere(
              (i) => i['is_main'] == true,
              orElse: () => images.first,
            )['image'] as String?);

      final videos = (r['videos'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      final video = videos.isEmpty ? null : videos.first['video'] as String?;

      out.add(WgerExercise(
        id: r['id'] as int,
        name: (picked['name'] as String).trim(),
        category:
            ((r['category'] as Map<String, dynamic>?)?['name'] as String?) ??
                '',
        muscles: [
          for (final m in (r['muscles'] as List<dynamic>? ?? const []))
            ((m as Map<String, dynamic>)['name_en'] as String?)?.isNotEmpty ==
                    true
                ? m['name_en'] as String
                : (m['name'] as String? ?? ''),
        ].where((s) => s.isNotEmpty).toList(),
        description: _stripHtml((picked['description'] as String?) ?? ''),
        imageUrl: mainImage,
        videoUrl: video,
      ));
    }
    return out;
  }

  static String _stripHtml(String html) => html
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Fetch the whole catalog (~818 exercises, paginated). Tolerant: returns
  /// whatever pages loaded before an error/timeout.
  Future<List<WgerExercise>> fetchAll(List<int> langPriority) async {
    final all = <WgerExercise>[];
    var offset = 0;
    const limit = 100;
    while (true) {
      try {
        final res = await _http.get(
          Uri.parse(
            'https://wger.de/api/v2/exerciseinfo/?limit=$limit&offset=$offset',
          ),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 15));
        if (res.statusCode != 200) break;
        final body =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        all.addAll(parsePage(body, langPriority));
        if (body['next'] == null) break;
        offset += limit;
        if (offset > 2000) break; // safety valve
      } catch (_) {
        break;
      }
    }
    return all;
  }
}
