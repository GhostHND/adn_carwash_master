import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MasterApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic> errors;

  const MasterApiException(
    this.message, {
    this.statusCode,
    this.errors = const {},
  });

  @override
  String toString() => message;
}

class MasterUser {
  final int id;
  final String name;
  final String email;

  const MasterUser({required this.id, required this.name, required this.email});

  factory MasterUser.fromJson(Map<String, dynamic> json) {
    return MasterUser(
      id: MasterApiClient._requiredInt(json['id'], 'id'),
      name: MasterApiClient._requiredString(json['name'], 'name'),
      email: MasterApiClient._requiredString(json['email'], 'email'),
    );
  }
}

class MasterApiClient {
  static const _configuredBaseUrl = String.fromEnvironment(
    'MASTER_API_BASE_URL',
    defaultValue: 'https://master.adnpublicidad.site/api/v1',
  );

  final http.Client _httpClient;
  final Uri _baseUri;
  String? _token;

  MasterApiClient({
    http.Client? httpClient,
    String baseUrl = _configuredBaseUrl,
  }) : _httpClient = httpClient ?? http.Client(),
       _baseUri = _parseBaseUrl(baseUrl);

  bool get isAuthenticated => _token != null;

  Future<MasterUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _send(
      'POST',
      '/auth/login',
      body: {
        'email': email.trim(),
        'password': password,
        'device_name': kIsWeb ? 'master-web' : 'master-flutter',
      },
      authenticated: false,
    );
    final data = _object(response['data'], 'data');
    final token = _requiredString(data['token'], 'data.token');
    final user = MasterUser.fromJson(_object(data['user'], 'data.user'));
    _token = token;

    return user;
  }

  Future<void> logout() async {
    try {
      await _send('POST', '/auth/logout');
    } finally {
      _token = null;
    }
  }

  Future<void> requestPasswordReset(String email) async {
    await _send(
      'POST',
      '/auth/password/forgot',
      body: {'email': email.trim()},
      authenticated: false,
    );
  }

  Future<Map<String, dynamic>> getObject(String path) async {
    return _send('GET', path);
  }

  Future<List<Map<String, dynamic>>> getCollection(String path) async {
    final collection = <Map<String, dynamic>>[];
    var page = 1;
    var lastPage = 1;
    do {
      final separator = path.contains('?') ? '&' : '?';
      final response = await _send(
        'GET',
        '$path${separator}per_page=100&page=$page',
      );
      final data = response['data'];
      if (data is! List) {
        throw const MasterApiException(
          'La respuesta del servidor no contiene una lista de datos válida.',
        );
      }

      collection.addAll(data.map((item) => _object(item, 'data[]')));
      final meta = response['meta'];
      if (meta is Map && meta['last_page'] is int) {
        lastPage = meta['last_page'] as int;
      }
      page++;
    } while (page <= lastPage);

    return List<Map<String, dynamic>>.unmodifiable(collection);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    return _send('POST', path, body: body);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    return _send('PATCH', path, body: body);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    return _send('PUT', path, body: body);
  }

  void dispose() {
    _httpClient.close();
    _token = null;
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final uri = _baseUri.resolve(path.replaceFirst(RegExp(r'^/+'), ''));
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (authenticated && _token != null) 'Authorization': 'Bearer $_token',
    };
    final request = http.Request(method, uri)
      ..headers.addAll(headers)
      ..body = body == null ? '' : jsonEncode(body);

    http.StreamedResponse streamed;
    try {
      streamed = await _httpClient
          .send(request)
          .timeout(const Duration(seconds: 20));
    } on Exception catch (error) {
      throw MasterApiException(
        'No se pudo conectar con Software Master. '
        'Verifica tu conexión e inténtalo de nuevo: $error',
      );
    }

    final responseBody = await streamed.stream.bytesToString();
    Map<String, dynamic> decoded = {};
    if (responseBody.isNotEmpty) {
      try {
        decoded = _object(jsonDecode(responseBody), 'respuesta');
      } on FormatException {
        throw MasterApiException(
          'El servidor devolvió una respuesta inválida.',
          statusCode: streamed.statusCode,
        );
      }
    }

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final errors = decoded['errors'] is Map
          ? Map<String, dynamic>.from(decoded['errors'] as Map)
          : <String, dynamic>{};
      throw MasterApiException(
        decoded['message'] is String
            ? decoded['message'] as String
            : 'La solicitud falló con código HTTP ${streamed.statusCode}.',
        statusCode: streamed.statusCode,
        errors: errors,
      );
    }

    return decoded;
  }

  static Uri _parseBaseUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw ArgumentError.value(value, 'baseUrl', 'Must be an HTTP(S) URL.');
    }

    return uri.replace(path: '${uri.path.replaceFirst(RegExp(r'/+$'), '')}/');
  }

  static Map<String, dynamic> _object(Object? value, String field) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw MasterApiException('La respuesta del servidor no contiene $field.');
  }

  static String _requiredString(Object? value, String field) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw MasterApiException('La respuesta del servidor no contiene $field.');
  }

  static int _requiredInt(Object? value, String field) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    throw MasterApiException('La respuesta del servidor no contiene $field.');
  }
}
