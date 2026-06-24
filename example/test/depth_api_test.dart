import 'dart:io';

import 'package:example/base/api/KlineApi.dart';
import 'package:flutter_foundation_kit/api/RestClient.dart';
import 'package:flutter_foundation_kit/api/RestResponse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'fetchMarketDepth requests Huobi depth snapshot and parses levels',
    () async {
      final client = _FakeRestClient({
        'ch': 'market.btcusdt.depth.step0',
        'status': 'ok',
        'ts': 1629790438801,
        'tick': {
          'ts': 1629790438215,
          'version': 136107114472,
          'bids': [
            [49790.87, 0.779876],
            [49785.9, 1.82E-4],
          ],
          'asks': [
            [49790.88, 2.980472],
            [49790.89, 0.006613],
          ],
        },
      });
      final api = KlineApi(client: client);

      final data = await api.fetchMarketDepth(
        symbol: 'btcusdt',
        depth: 20,
        type: 'step0',
      );

      expect(client.lastPath, '/market/depth');
      expect(client.lastQueryParameters, {
        'symbol': 'btcusdt',
        'depth': 20,
        'type': 'step0',
      });
      expect(data.channel, 'market.btcusdt.depth.step0');
      expect(data.tick.version, 136107114472);
      expect(data.tick.bids.first.price, 49790.87);
      expect(data.tick.bids.first.size, 0.779876);
      expect(data.tick.asks.last.price, 49790.89);
      expect(data.tick.asks.last.size, 0.006613);
    },
  );
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
