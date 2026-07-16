// Reusable Dio transport for iTop multipart REST/JSON operations.

import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/config/itop_configuration.dart';
import '../models/itop_response.dart';

/// Transport error that preserves an iTop response message when available.
class ItopClientException implements Exception {
  const ItopClientException(this.message, {this.isTimeout = false});

  final String message;
  final bool isTimeout;

  @override
  String toString() => message;
}

/// Posts documented iTop JSON instructions as multipart form data.
class ItopApiClient {
  const ItopApiClient({required Dio dio, required ItopConfiguration config})
    : _dio = dio,
      _config = config;

  final Dio _dio;
  final ItopConfiguration _config;

  /// Executes one iTop instruction and returns its common response envelope.
  Future<ItopResponse> execute(Map<String, dynamic> instruction) async {
    try {
      final response = await _dio.post<Object?>(
        ItopConfiguration.restPath,
        data: FormData.fromMap({
          'auth_user': _config.username,
          'auth_pwd': _config.password,
          'json_data': jsonEncode(instruction),
        }),
      );
      if (response.data is! Map) {
        throw const ItopClientException('Invalid iTop response.');
      }
      return ItopResponse.fromJson(
        Map<String, dynamic>.from(response.data! as Map),
      );
    } on DioException catch (error) {
      final apiMessage = _responseMessage(error.response?.data);
      final isTimeout =
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout;
      throw ItopClientException(
        apiMessage ?? error.message ?? 'iTop request failed.',
        isTimeout: isTimeout,
      );
    }
  }
}

/// Extracts the exact server message from a failed Dio response when present.
String? _responseMessage(Object? data) {
  if (data is Map) {
    final message = data['message']?.toString();
    if (message != null && message.isNotEmpty) {
      return message;
    }
  }
  return null;
}
