import 'dart:ui';

import 'package:flutter/foundation.dart';

@immutable
class KLineVisibleRange {
  const KLineVisibleRange({required this.start, required this.end});

  final int start;
  final int end;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KLineVisibleRange &&
            runtimeType == other.runtimeType &&
            start == other.start &&
            end == other.end;
  }

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'KLineVisibleRange(start: $start, end: $end)';
}

/// Public controller for reading and driving chart interaction state.
class KLineController extends ChangeNotifier {
  KLineController({
    double initialScale = 1,
    double initialScrollOffset = 0,
    Iterable<String> initialIndicators = const [],
  }) : _scale = initialScale,
       _scrollOffset = initialScrollOffset,
       _activeIndicatorIds = List<String>.unmodifiable(initialIndicators);

  double _scale;
  double _scrollOffset;
  int? _selectedIndex;
  Offset? _selectionLocalPosition;
  Offset? _selectionContentPosition;
  KLineVisibleRange? _visibleRange;
  List<String> _activeIndicatorIds;

  double get scale => _scale;
  double get scrollOffset => _scrollOffset;
  int? get selectedIndex => _selectedIndex;
  Offset? get selectionLocalPosition => _selectionLocalPosition;
  Offset? get selectionContentPosition => _selectionContentPosition;
  KLineVisibleRange? get visibleRange => _visibleRange;
  List<String> get activeIndicatorIds => _activeIndicatorIds;

  void setScale(double value) {
    if (_scale == value) return;
    _scale = value;
    notifyListeners();
  }

  void setScaleAroundFocalPoint({
    required double scale,
    required double baseScale,
    required double localFocalX,
    required double contentFocalX,
  }) {
    if (baseScale == 0) return;
    final scaleRatio = scale / baseScale;
    final nextScrollOffset = contentFocalX * scaleRatio - localFocalX;
    final scaleChanged = _scale != scale;
    final scrollChanged = _scrollOffset != nextScrollOffset;
    if (!scaleChanged && !scrollChanged) return;
    _scale = scale;
    _scrollOffset = nextScrollOffset;
    notifyListeners();
  }

  void setScrollOffset(double value) {
    if (_scrollOffset == value) return;
    _scrollOffset = value;
    notifyListeners();
  }

  void selectIndex(
    int? index, {
    Offset? localPosition,
    Offset? contentPosition,
  }) {
    final nextLocalPosition = index == null ? null : localPosition;
    final nextContentPosition = index == null ? null : contentPosition;
    if (_selectedIndex == index &&
        _selectionLocalPosition == nextLocalPosition &&
        _selectionContentPosition == nextContentPosition) {
      return;
    }
    _selectedIndex = index;
    _selectionLocalPosition = nextLocalPosition;
    _selectionContentPosition = nextContentPosition;
    notifyListeners();
  }

  void clearSelection() => selectIndex(null);

  void setVisibleRange(KLineVisibleRange? range) {
    if (_visibleRange == range) return;
    _visibleRange = range;
    notifyListeners();
  }

  void setActiveIndicators(Iterable<String> indicatorIds) {
    final next = List<String>.unmodifiable(indicatorIds);
    if (listEquals(_activeIndicatorIds, next)) return;
    _activeIndicatorIds = next;
    notifyListeners();
  }

  void toggleIndicator(String indicatorId) {
    final next = [..._activeIndicatorIds];
    if (next.contains(indicatorId)) {
      next.remove(indicatorId);
    } else {
      next.add(indicatorId);
    }
    setActiveIndicators(next);
  }
}
