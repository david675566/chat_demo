import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

// local
import 'package:chat_demo/secret.dart';

class ApiProvider {
  static const String baseUrl = secretBaseUrl;
  // Logger
  static PrettyDioLogger dioLogger = PrettyDioLogger(
    requestHeader: true,
    requestBody: true,
    responseBody: true,
    responseHeader: false,
    error: true,
    compact: true,
    maxWidth: 90,
  );
  static final Dio _dio = Dio()..interceptors.addAll([dioLogger]);

  Future<List> fetchConversations() {
    final uri = Uri.http(baseUrl, '/conversations');
    debugPrint("Fetching from ${uri.toString()}");

    return _dio
        .getUri(uri)
        .then(
          (value) {
            return value.data;
          },
          onError: (value) {
            debugPrint(value);
            return false;
          },
        );
  }

  Future<List> fetchMessages(int conversationId, {bool refresh = false}) {
    final uri = Uri.http(baseUrl, '/messages', {'conversationId': conversationId.toString()});
    debugPrint("Fetching from ${uri.toString()}");

    return _dio
        .getUri(uri)
        .then(
          (value) {
            return value.data;
          },
          onError: (value) {
            debugPrint(value);
            return false;
          },
        );
  }

  Future<Response> postMessage(int conversationId, Map messageJson) {
    final uri = Uri.http(baseUrl, '/conversations/$conversationId/messages/create');
    debugPrint("Fetching from ${uri.toString()}");

    return _dio
        .postUri(uri, data: messageJson)
        .then(
          (value) {
            return value;
          },
          onError: (value) {
            debugPrint(value);
            return Future.error(value);
          },
        );
  }

  Future<Response> reactMessage(int conversationId, Map body) {
    final uri = Uri.http(baseUrl, '/conversations/$conversationId/messages/reaction');
    debugPrint("Fetching from ${uri.toString()}");

    return _dio
        .patchUri(uri, data: body)
        .then(
          (value) {
            return value;
          },
          onError: (value) {
            debugPrint(value);
            return Future.error(value);
          },
        );
  }
}
