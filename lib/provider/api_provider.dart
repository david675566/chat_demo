import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

class ApiProvider {
  static const String baseUrl = "localhost:8080";
  // Cache
  static final CacheOptions cacheOptions = CacheOptions(
    // A default store is required for interceptor.
    store: MemCacheStore(),

    // All subsequent fields are optional.

    // Default.
    policy: CachePolicy.request,
    // Returns a cached response on error but for statuses 401 & 403.
    // Also allows to return a cached response on network errors (e.g. offline usage).
    // Defaults to [null].
    hitCacheOnErrorExcept: const [401, 403],
    // Overrides any HTTP directive to delete entry past this duration.
    // Useful only when origin server has no cache config or custom behaviour is desired.
    // Defaults to [null].
    maxStale: const Duration(minutes: 5),
    // Default. Allows 3 cache sets and ease cleanup.
    priority: CachePriority.normal,
    // Default. Body and headers encryption with your own algorithm.
    cipher: null,
    // Default. Key builder to retrieve requests.
    keyBuilder: CacheOptions.defaultCacheKeyBuilder,
    // Default. Allows to cache POST requests.
    // Overriding [keyBuilder] is strongly recommended when [true].
    allowPostMethod: false,
  );
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
  static final Dio _dio = Dio()..interceptors.addAll([dioLogger, DioCacheInterceptor(options: cacheOptions)]);

  Future<List> fetchConversations() {
    final uri = Uri.http(baseUrl, '/local-mock/conversations');
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
    final uri = Uri.http(baseUrl, '/local-mock/messages', {'conversationId': conversationId.toString()});
    debugPrint("Fetching from ${uri.toString()}");

    return _dio
        .getUri(uri, options: (refresh) ? cacheOptions.copyWith(policy: CachePolicy.refresh).toOptions() : null)
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
    final uri = Uri.http(baseUrl, '/local-mock/conversations/$conversationId/messages/create');
    debugPrint("Fetching from ${uri.toString()}");

    return _dio
        .postUri(uri, data: jsonEncode(messageJson))
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
    final uri = Uri.http(baseUrl, '/local-mock/conversations/$conversationId/messages/reaction');
    debugPrint("Fetching from ${uri.toString()}");

    return _dio
        .postUri(uri, data: jsonEncode(body))
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
