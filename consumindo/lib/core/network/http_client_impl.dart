import 'dart:async' as async;
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../error/exceptions.dart';
import 'http_client.dart';

/// Implementação de [IHttpClient] sobre o package `http`.
///
/// Concentra timeout, decodificação e a tradução de erros de transporte em
/// [AppException] — os datasources ficam livres desse ruído. Não importa
/// `dart:io`, portanto compila também para web.
final class HttpClientImpl implements IHttpClient {
  HttpClientImpl({http.Client? client, Duration? timeout})
      : _client = client ?? http.Client(),
        _timeout = timeout ?? ApiConstants.requestTimeout;

  final http.Client _client;
  final Duration _timeout;

  static const Map<String, String> _defaultHeaders = <String, String>{
    'Accept': 'application/json',
    // A Open Library pede identificação do consumidor nas boas práticas de uso.
    'User-Agent': 'Libria/1.0 (Flutter; contato@libria.app)',
  };

  @override
  Future<dynamic> getJson(Uri url, {Map<String, String>? headers}) async {
    try {
      final http.Response response = await _client
          .get(url, headers: <String, String>{..._defaultHeaders, ...?headers})
          .timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _decode(response);
      }

      throw ServerException(
        _messageForStatus(response.statusCode),
        statusCode: response.statusCode,
      );
    } on AppException {
      rethrow;
    } on async.TimeoutException {
      throw const TimeoutException();
    } on http.ClientException {
      throw const NetworkException('Não foi possível falar com a Open Library.');
    } on FormatException {
      throw const ParseException();
    } catch (_) {
      // Erros de socket/DNS variam entre plataformas: tratados como rede.
      throw const NetworkException();
    }
  }

  dynamic _decode(http.Response response) {
    try {
      // `bodyBytes` + utf8 preserva acentuação quando o header charset vem ausente.
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const ParseException();
    }
  }

  String _messageForStatus(int status) {
    return switch (status) {
      400 => 'Busca inválida. Revise os termos e tente de novo.',
      404 => 'Não encontramos esse registro na Open Library.',
      429 => 'Muitas buscas em sequência. Aguarde alguns segundos.',
      >= 500 => 'A Open Library está indisponível no momento.',
      _ => 'Não foi possível concluir a requisição (HTTP $status).',
    };
  }

  @override
  void dispose() => _client.close();
}
