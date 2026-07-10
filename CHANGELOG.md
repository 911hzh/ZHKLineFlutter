# Changelog

## 0.5.0

- Reorganized package and example tests to mirror the source directory
  structure.
- Pruned low-value and duplicate tests while keeping focused regression
  coverage for core chart behavior.
- Added regression coverage for controller-driven K-line scroll requests and
  default delegate secondary pane height fallback.
- Added Chinese testing documentation that clarifies unit, widget, and
  integration test boundaries.

## 0.4.0

- Switched the default README to English for pub.dev and GitHub discovery.
- Moved the original Chinese README to `README_CHINESE.md`.
- Updated package metadata with an English description focused on Flutter
  candlestick charts, K-line charts, financial charts, technical indicators,
  OHLCV trading charts, and depth charts.
- Translated the changelog to English to improve pub.dev package scoring.

## 0.3.1

- Updated package documentation.

## 0.3.0

- Breaking change: replaced the default indicator enum API with dynamic
  indicator definitions based on `KLineIndicatorSpec<T>` and
  `KLineIndicatorSeries<T>`.
- Added `KLineWidget.mainIndicators` and `secondaryIndicators`; the indicator
  selector now uses the provided lists as the single source of truth. Omitted
  lists use defaults, and empty lists hide the corresponding indicators.
- Changed `KLineDataAdapter.indicatorValue` to accept `String valueId`, so apps
  can support arbitrary custom indicator values.
- Added `KLineDefaultIndicators` constants and factories for built-in MA, EMA,
  BOLL, VOL, MACD, KDJ, RSI, and WR indicators.
- Added custom sub-chart indicator support. Simple series indicators are drawn
  automatically, while complex indicators can provide a custom renderer through
  `KLineIndicatorSpec.renderer`.
- Improved default placeholder height and viewport height calculation by using
  delegate-provided heights consistently.
- Fixed occasional blank space or flicker on the right side when old scroll
  offsets exceeded the new content width after zooming out, and extracted
  `ScaleGestureHandler` for scale gesture logic.
- Updated the example custom indicator page to demonstrate default VOL, CCI
  line indicators, and a custom bar renderer together.

## 0.2.0

- Added realtime controls to `KLineController`: follow latest, scroll to latest,
  scroll to index, and reveal the selected item.
- Added a realtime update example page showing how business code updates data
  first and then calls the controller to scroll to the target position.
- Improved K-line scroll boundary synchronization and fixed edge cases where
  loading more data did not trigger near the end or caused viewport drift.
- Fixed the example K-line cache window so refreshing 50 rows is not polluted by
  previously loaded-more in-memory data.
- Adjusted the realtime demo timer so simulated pushes only run when follow
  latest is enabled.
- Replaced the hard-coded default indicator switcher height with layout config.
- Added realtime data integration docs clarifying that the package does not
  decide where incoming data should be inserted.
- Updated publish ignore rules so `build/` artifacts are not included in the pub
  package.

## 0.1.2

- Changed `.fvmrc` to the current FVM-compatible JSON format, fixing
  `fvm flutter` and `make gen` under `example`.
- Synced the local path dependency version in `example/pubspec.lock` to
  `0.1.1`.

## 0.1.1

- Renamed the package to `kline_flutter` and updated the public entrypoint and
  example imports.
- Completed publish configuration with `LICENSE`, `.pubignore`, and required
  publish validation files.
- Improved the first README screen, quick-start instructions, and core value
  proposition copy.
- Switched README preview images to GitHub raw URLs to keep image assets out of
  the pub package.
- Reduced custom UI image display width in the README for better readability.

## 0.1.0

- Initial release of the Flutter K-line chart component.
- Added quick integration through `KLineWidget` and deep custom drawing through
  `KLineChartDelegate`.
- Added default MA, EMA, BOLL, MACD, KDJ, RSI, WR, and VOL indicators.
- Added `DeepChart` for cumulative bid and ask depth charts.
- Added examples, detailed usage docs, and custom UI samples.
