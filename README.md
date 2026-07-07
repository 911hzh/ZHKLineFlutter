# ZHKLine Flutter

[![Flutter](https://img.shields.io/badge/Flutter-3.7.0+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.7.0+-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A Flutter candlestick chart and financial chart library for K-line charts,
technical indicators, trading chart interactions, OHLCV data, and cumulative
depth charts. It uses `CustomPainter` and delegate-based rendering, so you can
start with the default UI and replace drawing, layout, overlays, or data
adapters only where your app needs custom behavior.

Chinese documentation is available in [`README_CHINESE.md`](README_CHINESE.md).
For custom UI, depth chart integration, external controls, realtime data, and
complete examples, see [`example/use_docs.md`](example/use_docs.md).

## Preview

### Dynamic Indicators and Labels

<img
  src="https://raw.githubusercontent.com/911hzh/ZHKLineFlutter/develop-0.3.0/lib/assets/show/flutter_custom_indicator_text.png"
  alt="Dynamic indicator labels"
  width="360"
/>

[Watch the dynamic indicator demo](https://raw.githubusercontent.com/911hzh/ZHKLineFlutter/develop-0.3.0/lib/assets/show/flutter_dynamic_indicator_draw.webm)

### Scroll and Zoom

<img
  src="https://raw.githubusercontent.com/911hzh/ZHKLineFlutter/develop-0.3.0/lib/assets/show/flutter_scrolling.gif"
  alt="Scroll and zoom demo"
  width="360"
/>

### Long-press Details

<img
  src="https://raw.githubusercontent.com/911hzh/ZHKLineFlutter/develop-0.3.0/lib/assets/show/flutter_tap_longpress_dataDetail.gif"
  alt="Long press crosshair demo"
  width="360"
/>

### Custom Background

<img
  src="https://raw.githubusercontent.com/911hzh/ZHKLineFlutter/develop-0.3.0/lib/assets/show/flutter_custom_background.png"
  alt="Custom chart background"
  width="360"
/>

### Custom Overlay

<img
  src="https://raw.githubusercontent.com/911hzh/ZHKLineFlutter/develop-0.3.0/lib/assets/show/flutter_custom_overlay_ui.png"
  alt="Custom overlay UI"
  width="360"
/>

### Custom Detail Panel

<img
  src="https://raw.githubusercontent.com/911hzh/ZHKLineFlutter/develop-0.3.0/lib/assets/show/flutter_custom_detail_ui.png"
  alt="Custom detail panel"
  width="360"
/>

### Custom Main Chart Drawing

<img
  src="https://raw.githubusercontent.com/911hzh/ZHKLineFlutter/develop-0.3.0/lib/assets/show/flutter_custom_main_draw.png"
  alt="Custom main chart drawing"
  width="360"
/>

### Realtime Data Append

[Watch the realtime append demo](https://raw.githubusercontent.com/911hzh/ZHKLineFlutter/develop-0.3.0/lib/assets/show/flutter_custom_real_time_data_insert_append_end.webm)

## Why Use It

- **Fast setup**: pass a `List<T>` and a `KLineDataAdapter<T>` to render a
  ready-to-use Flutter candlestick chart with indicators, sub charts,
  long-press details, and loading states.
- **Clear extension points**: customize background, grid, indicator labels,
  main chart drawing, selected overlays, or depth charts through
  `KLineChartDelegate<T>` and `DeepChartDelegate<T>`.
- **Extensible technical indicators**: define main-chart and sub-chart
  indicators with `KLineIndicatorSpec<T>` and `KLineIndicatorSeries<T>` instead
  of editing enums or switch statements.
- **Reusable defaults**: extend `KLineDefaultDelegateImpl<T>` and call `super`
  to keep the default candles, indicators, grids, overlays, and selected
  details while adding only your business-specific drawing.
- **Optimized for market data**: candlesticks, indicators, and sub charts are
  painted with `CustomPainter`, reducing widget rebuild pressure for large OHLCV
  datasets.
- **Native-feeling gestures**: horizontal scrolling uses Flutter scroll physics
  and only calls pagination callbacks for user-driven drag gestures.
- **Adapter-first data model**: backend models, cached models, and calculated
  indicator models can be used directly through adapters.
- **Complete chart features**: built-in MA, EMA, BOLL, MACD, KDJ, RSI, WR, VOL,
  zoom, scroll, selected state control, and cumulative order-book depth charts.

## Quick Start

Add the package to your Flutter project:

```bash
flutter pub add kline_flutter
```

Or add it manually:

```yaml
dependencies:
  kline_flutter: ^0.4.0
```

Then import it:

```dart
import 'package:kline_flutter/kline_flutter.dart';
```

To run the example app:

```bash
git clone https://github.com/911hzh/ZHKLineFlutter.git
cd ZHKLineFlutter
cd example
flutter pub get
flutter run -d macos
```

## Minimal Integration

You usually only need two pieces:

- `MyCandle`: your business candlestick model from an API, database, or local
  calculation.
- `MyCandleAdapter`: an adapter that exposes open, high, low, close, volume,
  and time labels to the chart.

```dart
import 'package:kline_flutter/kline_flutter.dart';

class MyCandle {
  const MyCandle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.timeLabel,
  });

  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final String timeLabel;
}

class MyCandleAdapter extends KLineDataAdapter<MyCandle> {
  const MyCandleAdapter();

  @override
  double open(MyCandle item) => item.open;

  @override
  double high(MyCandle item) => item.high;

  @override
  double low(MyCandle item) => item.low;

  @override
  double close(MyCandle item) => item.close;

  @override
  double volume(MyCandle item) => item.volume;

  @override
  String dateLabel(MyCandle item) => item.timeLabel;
}
```

In your UI, pass the data and adapter to `KLineWidget`:

```dart
class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return KLineWidget<MyCandle>(
      dataSource: candles,
      adapter: const MyCandleAdapter(),
      initialIndicators: const [KLineDefaultIndicators.volumeId],
    );
  }
}
```

## More Usage

This README keeps the setup short. For dynamic indicators, realtime data,
external controls, custom drawing, custom UI, Loading / Empty / Error states,
and depth chart integration, see [`example/use_docs.md`](example/use_docs.md).

## Core APIs

### K-line Chart

- `KLineWidget<T>`: default K-line UI for fast integration.
- `KLineChart<T>`: core chart component for fully custom drawing.
- `KLineChartDelegate<T>`: rendering protocol for layout nodes, grids, main
  charts, sub charts, overlays, and selected-state UI.
- `KLineDataAdapter<T>`: business model adapter.
- `KLineController`: zoom, scroll, selected item, visible range, and indicator
  state control.
- `KLineIndicatorSpec<T>`: dynamic indicator definition for main charts, sub
  charts, and custom renderers.

### Depth Chart

- `DeepChart<T>`: default depth chart component.
- `DeepChartDataAdapter<T>`: order-book data adapter.
- `DeepChartDelegate<T>`: depth chart rendering protocol.
- `DeepChartLayoutConfig`: layout config for the chart area and bottom price
  row.

## Project Structure

```text
lib/
├── kline_flutter.dart
└── src/
    ├── kline/
    └── deepchart/

example/
├── lib/base/api/
├── lib/base/store/
└── lib/module/usecase/pages/
    ├── kline/
    ├── deep_chart/
    └── custom_page/
```

## Architecture

The architecture diagram lives in a separate document for easier viewing:

[View the architecture document](doc/architecture.md)

## Use Cases

- Exchange, futures, stock, fund, and crypto market pages.
- Flutter apps that need a default candlestick chart or K-line chart UI quickly.
- Financial chart screens that need custom rendering protocols.
- Apps that maintain K-line charts, technical indicators, order-book depth, and
  trading chart interactions in one package.

## Contributing

This package is still evolving. Contributions are welcome:

- Open issues for bugs, performance problems, or API design suggestions.
- Send pull requests for chart features, examples, tests, or documentation.
- Share real-world delegate, theme, and interaction examples.

If this project helps you, a GitHub star and a pub.dev like are appreciated.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
