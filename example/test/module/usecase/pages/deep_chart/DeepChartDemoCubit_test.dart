import 'dart:io';

import 'package:example/base/api/KlineApi.dart';
import 'package:example/module/usecase/pages/deep_chart/DeepChartDemoCubit.dart';
import 'package:flutter_foundation_kit/api/RestClient.dart';
import 'package:flutter_foundation_kit/api/RestResponse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('start loads depth snapshot into state', () async {
    final api = KlineApi(
      client: _FakeRestClient({
        'ch': 'market.btcusdt.depth.step0',
        'status': 'ok',
        'ts': 100,
        'tick': {
          'ts': 90,
          'version': 8,
          'bids': [
            [100, 2],
          ],
          'asks': [
            [101, 3],
          ],
        },
      }),
    );
    final cubit = DeepChartDemoCubit(api: api);

    await cubit.start();

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.error, isNull);
    expect(cubit.state.bids.single.price, 100);
    expect(cubit.state.asks.single.size, 3);
    await cubit.close();
  });
}

class _FakeRestClient extends RestClient {
  _FakeRestClient(this.responseData);

  final Map<String, dynamic> responseData;

  @override
  Future<RestResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ContentType? contentType,
  }) async {
    return RestResponse(
      statusCode: 200,
      message: 'OK',
      data: responseData,
      headers: const {},
    );
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
