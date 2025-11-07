import 'package:dio/dio.dart';

/// 网络请求错误类型
class NetworkError implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  NetworkError(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => message;
}

/// 网络请求基类
class ApiClient {
  final String baseUrl;
  final Dio _dio;

  /// 初始化网络请求客户端
  ApiClient({required this.baseUrl, Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {'Accept': 'application/json'};
  }

  /// GET请求
  Future<Response> get(String path) async {
    try {
      final response = await _dio.get(path);

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw NetworkError(
          '服务器错误: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      return response;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkError('网络超时', originalError: e);
      } else if (e.type == DioExceptionType.badResponse) {
        throw NetworkError(
          '服务器错误: ${e.response?.statusCode}',
          statusCode: e.response?.statusCode,
          originalError: e,
        );
      } else {
        throw NetworkError('网络错误: ${e.message}', originalError: e);
      }
    } catch (e) {
      throw NetworkError('未知错误', originalError: e);
    }
  }

  /// 泛型GET请求，自动解析JSON
  Future<T> getJson<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await get(path);

      if (response.data == null) {
        throw NetworkError('没有数据');
      }

      return fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (e is NetworkError) {
        rethrow;
      }
      throw NetworkError('数据解析错误', originalError: e);
    }
  }
}
