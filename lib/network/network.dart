import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:machine_task/main.dart' hide Article;
import 'package:machine_task/model/model.dart';

class NewsRepository {
  final http.Client httpClient;
  NewsRepository({http.Client? client}) : httpClient = client ?? http.Client();

  Future<List<Article>> fetchTopHeadlines({int page = 1, String? query}) async {
    final Map<String, String> params = {
      'apiKey': kApiKey,
      'country': kCountry,
      'pageSize': '$kPageSize',
      'page': '$page',
    };
    if (query != null && query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }

    final uri = Uri.parse(kBaseUrl).replace(queryParameters: params);
    final resp = await httpClient.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Failed to load news: ${resp.statusCode}');
    }

    final jsonBody = json.decode(resp.body) as Map<String, dynamic>;
    if (jsonBody['status'] != 'ok') {
      throw Exception('API error: ${jsonBody['message'] ?? 'unknown'}');
    }

    final articlesJson = (jsonBody['articles'] as List<dynamic>);
    return articlesJson.map((e) => Article.fromJson(e as Map<String, dynamic>)).toList();
  }
}