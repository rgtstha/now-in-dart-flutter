import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:now_in_dart_flutter/features/core/data/data.dart';

typedef _RemoteMarkdown = Future<RemoteResponse<String>>;

abstract class DetailRemoteService {
  DetailRemoteService({
    required Dio dio,
    required HeaderCache headerCache,
  })  : _dio = dio,
        _headerCache = headerCache;

  final Dio _dio;
  final HeaderCache _headerCache;

  @protected
  _RemoteMarkdown getDetail(String fullPathToMarkdownFile) async {
    final requestUri = Uri.https(_dio.options.baseUrl, fullPathToMarkdownFile);

    final cachedHeader = await _headerCache.getHeader(fullPathToMarkdownFile);

    try {
      final response = await _dio.getUri<Map<String, dynamic>>(
        requestUri,
        options: Options(
          headers: <String, String>{
            'If-None-Match': cachedHeader?.eTag ?? '',
          },
        ),
      );

      switch (response.statusCode) {
        case 200:
          final header = GithubHeader.parse(response, fullPathToMarkdownFile);
          await _headerCache.saveHeader(header);
          final html = response.data as String;
          return RemoteResponse.withNewData(html);

        case 304:
          return const RemoteResponse.notModified();

        default:
          throw RestApiException(response.statusCode);
      }
    } on DioError catch (e) {
      if (e.isNoConnectionError) {
        return const RemoteResponse.noConnection();
      } else if (e.response != null) {
        throw RestApiException(e.response?.statusCode);
      } else {
        rethrow;
      }
    }
  }
}