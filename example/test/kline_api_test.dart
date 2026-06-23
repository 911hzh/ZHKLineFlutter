import 'dart:io';

import 'package:example/base/api/KlineApi.dart';
import 'package:flutter_foundation_kit/api/RestClient.dart';
import 'package:flutter_foundation_kit/api/RestResponse.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/base/api/model/kline/KLinePeriod.dart';

void main() {
  test('fetchKLineData requests Huobi kline history through RestClient', () async {
    final client = _FakeRestClient({
      'ch': 'market.btcusdt.kline.15min',
      'status': 'ok',
      'ts': 100,
      'data': [
        {'id': 2, 'open': 10, 'close': 12, 'low': 9, 'high': 13, 'amount': 1000, 'vol': 100, 'count': 10},
      ],
    });
    final api = KlineApi(client: client);

    final data = await api.fetchKLineData(symbol: 'btcusdt', period: KLinePeriod.min15, size: 2000);

    expect(client.lastPath, '/market/history/kline');
    expect(client.lastQueryParameters, {'period': '15min', 'size': 2000, 'symbol': 'btcusdt'});
    expect(data.single.id, 2);
  });
}

class _FakeRestClient extends RestClient {
  _FakeRestClient(this.responseData);

  final Map<String, dynamic> responseData;
  String? lastPath;
  Map<String, dynamic>? lastQueryParameters;

  @override
  Future<RestResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ContentType? contentType,
  }) async {
    lastPath = path;
    lastQueryParameters = queryParameters;
    return RestResponse(statusCode: 200, message: 'OK', data: responseData, headers: const {});
  }

  @override
  Future<RestResponse> request(
    String path,
    String method, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ContentType? contentType,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<RestResponse> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ContentType? contentType,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<RestResponse> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ContentType? contentType,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<RestResponse> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ContentType? contentType,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<RestResponse> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ContentType? contentType,
  }) {
    throw UnimplementedError();
  }
}
