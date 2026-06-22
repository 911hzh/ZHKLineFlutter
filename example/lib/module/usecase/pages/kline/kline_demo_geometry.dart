// ignore_for_file: file_names

// K 线 Demo 几何工具：集中维护主图/副图裁剪和内容区域计算。
part of 'KLineDemoPage.dart';

const double kLineDemoSecondaryContentVerticalPadding = 8.0;

/// 计算副图实际参与数值映射的区域，上下预留空白避免贴边。
Rect kLineDemoSecondaryContentRect(Rect rect) {
  final inset = math.min(kLineDemoSecondaryContentVerticalPadding, rect.height / 2);
  return Rect.fromLTRB(rect.left, rect.top + inset, rect.right, rect.bottom - inset);
}

/// 将屏幕坐标系下的裁剪区域转换为滚动内容画布坐标系。
Rect kLineDemoDrawableClipRect(Rect rect, {required double scrollOffset}) {
  return rect.shift(Offset(scrollOffset, 0));
}
