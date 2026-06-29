/// 火币市场深度响应模型。
class DepthResponse {
  const DepthResponse({
    required this.channel,
    required this.status,
    required this.timestamp,
    required this.tick,
  });

  final String channel;
  final String status;
  final int timestamp;
  final DepthTick tick;

  factory DepthResponse.fromJson(Map<String, dynamic> json) {
    return DepthResponse(
      channel: json['ch'] as String,
      status: json['status'] as String,
      timestamp: json['ts'] as int,
      tick: DepthTick.fromJson(json['tick'] as Map<String, dynamic>),
    );
  }
}

class DepthTick {
  const DepthTick({
    required this.timestamp,
    required this.version,
    required this.bids,
    required this.asks,
  });

  final int timestamp;
  final int version;
  final List<DepthLevel> bids;
  final List<DepthLevel> asks;

  factory DepthTick.fromJson(Map<String, dynamic> json) {
    return DepthTick(
      timestamp: json['ts'] as int,
      version: json['version'] as int,
      bids: _levelsFromJson(json['bids']),
      asks: _levelsFromJson(json['asks']),
    );
  }

  static List<DepthLevel> _levelsFromJson(Object? value) {
    final levels = value is List ? value : const [];
    return [
      for (final level in levels)
        if (level is List && level.length >= 2)
          DepthLevel(
            price: (level[0] as num).toDouble(),
            size: (level[1] as num).toDouble(),
          ),
    ];
  }
}

class DepthLevel {
  const DepthLevel({required this.price, required this.size});

  final double price;
  final double size;
}
