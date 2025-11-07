import 'dart:ui';

/// Color扩展，支持十六进制颜色字符串
extension ColorExtension on Color {
  /// 通过十六进制字符串创建Color
  /// 支持格式：#RRGGBB, #RRGGBBAA, RRGGBB, RRGGBBAA
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));

    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      // 如果解析失败，返回透明色
      return const Color(0x00000000);
    }
  }

  /// 通过十六进制整数值创建Color
  static Color fromHexInt(int hex, {double opacity = 1.0}) {
    final alpha = (opacity * 255).round();
    return Color.fromARGB(alpha, (hex & 0xFF0000) >> 16, (hex & 0x00FF00) >> 8, hex & 0x0000FF);
  }

  /// 将Color转换为十六进制字符串
  String toHexString({bool includeAlpha = false}) {
    if (includeAlpha) {
      return '#${a.round().toRadixString(16).padLeft(2, '0')}'
              '${r.round().toRadixString(16).padLeft(2, '0')}'
              '${g.round().toRadixString(16).padLeft(2, '0')}'
              '${b.round().toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();
    } else {
      return '#${r.round().toRadixString(16).padLeft(2, '0')}'
              '${g.round().toRadixString(16).padLeft(2, '0')}'
              '${b.round().toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();
    }
  }
}
