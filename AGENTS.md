# Repository Guidelines

## Project Structure & Module Organization
这是一个 Flutter package 仓库。核心导出入口在 `lib/kline_flutter.dart`，实现代码集中在 `lib/src/kline/` 和 `lib/src/deepchart/`，分别对应 K 线与深度图能力。根目录 `test/` 放 package 级测试。`example/` 是完整示例应用，业务分层主要在 `example/lib/base/`、`example/lib/module/`，示例测试在 `example/test/`。演示图片资源位于 `lib/assets/show/`。

## Build, Test, and Development Commands
- `flutter pub get`：安装根 package 依赖。
- `flutter analyze`：按 `analysis_options.yaml` 执行静态检查。
- `flutter test`：运行根目录测试，如 `test/deep_chart_delegate_test.dart`。
- `cd example && flutter pub get`：安装示例应用依赖。
- `cd example && flutter run -d macos`：本地启动示例应用，其他平台可替换设备参数。
- `cd example && flutter test`：运行示例应用测试。
- `cd example && make gen`：执行 `build_runner` 代码生成。

## Coding Style & Naming Conventions
遵循 Flutter 默认风格和 `flutter_lints`。Dart 使用 2 空格缩进，类型名使用 `PascalCase`，成员与方法使用 `camelCase`。包内源码文件优先使用 `snake_case.dart`；`example/` 中已有部分 `PascalCase.dart` 文件，修改时先保持所在目录既有风格，不要顺手大改命名。优先复用现有 delegate、adapter、theme 和 controller 结构，避免新增无实际复用价值的抽象层。

## Testing Guidelines
测试框架使用 `flutter_test`。新增逻辑优先补最小可运行测试，覆盖公共 API、delegate 计算、数据适配和关键交互。测试文件命名采用 `*_test.dart`，与被测模块靠近，例如 `test/package_api/k_line_package_api_test.dart`。提交前至少运行受影响范围的 `flutter test`；若改动 example 里的状态管理或注入逻辑，也运行 `cd example && flutter test`。

## Commit & Pull Request Guidelines
现有提交历史以简短说明为主，常见形式如 `新增 K 线深度图组件`、`demo 修复...`、版本号提交如 `0.0.1`。建议继续使用简洁、聚焦单一变更的提交信息，首句直接说明结果。PR 应包含：变更目的、影响范围、测试结果；若改动图表绘制或交互，请附截图或 GIF，并关联对应 issue 或使用场景。

## Security & Configuration Tips
不要把真实密钥、生产地址或账号信息提交到 `example/lib/base/store/settings/`。新增配置优先走现有 `development.json` / `release.json` 分层，避免把环境差异硬编码到 widget 或 delegate 中。
