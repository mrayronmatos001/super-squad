import 'package:dio/dio.dart';

import '../../domain/agent.dart';

/// Resposta paginada do json-server (v1):
/// { "first": 1, "prev": null, "next": 2, "last": 57, "pages": 57, "items": 563, "data": [...] }
class PagedResult {
  final int items;
  final int? next;
  final List<Agent> data;

  const PagedResult({required this.items, required this.next, required this.data});

  factory PagedResult.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] is List ? json['data'] as List : const [];
    return PagedResult(
      items: (json['items'] as num?)?.toInt() ?? rawList.length,
      // "next" é null na última página, por isso é int? (nullable).
      next: (json['next'] as num?)?.toInt(),
      data: rawList
          .map((e) => Agent.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class ApiClient {
  final Dio _dio;

  ApiClient({required String baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            // O plano gratuito do Render "adormece" o servidor; a primeira
            // requisição pode levar ~50 s. Sem internet, o erro é imediato,
            // então esse tempo longo não atrasa o modo offline.
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

  /// Busca uma página de heróis: GET /heroes?_page=1&_per_page=10
  Future<PagedResult> getHeroes({required int page, required int perPage}) async {
    final response = await _dio.get(
      '/heroes',
      queryParameters: {'_page': page, '_per_page': perPage},
    );
    final data = response.data;
    // Versões antigas do json-server devolvem uma lista simples em vez do
    // objeto paginado. Tratamos os dois formatos.
    if (data is List) {
      return PagedResult(
        items: data.length,
        next: null,
        data: data.map((e) => Agent.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );
    }
    return PagedResult.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Busca todos os heróis de uma vez: GET /heroes (sem paginação).
  /// Usado para preencher o cache e permitir o uso completo offline.
  Future<List<Agent>> getAllHeroes() async {
    final response = await _dio.get('/heroes');
    final data = response.data;
    // Sem _page e _per_page, o json-server devolve uma lista simples.
    final list = data is List ? data : (data as Map)['data'] as List;
    return list.map((e) => Agent.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Busca um herói pelo id: GET /heroes/1
  Future<Agent> getHero(int id) async {
    final response = await _dio.get('/heroes/$id');
    return Agent.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}
