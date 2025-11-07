import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

class RestResponse<T> {
  RestResponse(this.statusCode, this.statusMessage, this.headers, this.data);

  final int statusCode;
  final String statusMessage;
  final Map<String, String> headers;
  final T data;

  bool isOk() {
    return statusCode >= 200 && statusCode < 300;
  }
}

@Singleton()
class ApiClient<T> {
  final String baseUrl;
  final Dio dio = Dio();

  ApiClient() : baseUrl = 'https://api.example.com';
  Future<RestResponse> get({required String url, Map<String, dynamic>? params}) async {
    final response = await dio.get(baseUrl + url, queryParameters: params);
    return _handleResponse(response);
  }
}

RestResponse _handleResponse(Response response) {
  var headers = <String, String>{};
  response.headers.forEach((name, values) {
    headers.putIfAbsent(name, () => values.first);
  });
  return RestResponse(response.statusCode ?? 500, response.statusMessage ?? 'Unknown error', headers, response.data);
}

extension FutureRestResponseExtension on Future<RestResponse> {
  Future<RestResponse<T>> toModel<T>(T Function(Map<String, dynamic>) parser) {
    return then((value) {
      dynamic data = value.data;
      if (data is String) {
        data = jsonDecode(data);
      }
      var model = parser(data);
      return Future.value(RestResponse<T>(value.statusCode, value.statusMessage, value.headers, model));
    });
  }
}
