# Flutter 仓库规则

## 适用范围
- 本仓库包含两个不同层次：
  - 根包 `lib/`：可复用的图表库代码
  - `example/`：示例应用与集成演示
- 不要混淆根包与示例应用的职责边界。
- 除非明确要求，否则不要调整现有目录结构。

## 仓库结构
- 根包代码位于 `lib/src/` 下，按现有领域继续组织：
  - `deepchart/`
  - `kline/`
- 在这些领域内部，如无明确理由，继续沿用当前职责划分：
  - `adapter/`
  - `controller/`
  - `delegate/`
  - `model/`
  - `theme/`
  - `u_default_impl/`
  - `widgets/`
- `lib/kline_flutter.dart` 是包的公开导出入口。新增公共能力时，优先通过这里暴露，而不是随意暴露内部路径。

## 示例应用结构
- `example/lib/` 下继续遵循现有组织方式，不强行引入新的分层架构：
  - `base/`：放 API、store、util 及应用级基础能力
  - `module/getIt/`：放依赖注入相关代码
  - `module/route/`：放路由相关代码
  - `module/usecase/pages/`：放示例页面
  - `infra/`、`domain/`、`e_uikit/`：仅在符合当前既有用法时继续使用
- 不要强行把示例应用改造成 MVVM、Clean Architecture 或 Riverpod 模板。

## 工作方式
- 修改前先阅读目标文件以及相邻相关文件。
- 优先做符合当前设计的最小改动。
- 新增实现前，优先复用已有的 delegate、adapter、controller、store、theme 和 widget。
- 如果发现结构性改进空间，可以先提出建议；未经明确要求，不直接改结构。

## 命名规范
- 以你正在修改目录中的既有命名风格为准。
- 不要为了统一风格而批量重命名现有文件。
- 新文件命名优先与同级文件保持一致，而不是机械套用通用规范。
- 变量、方法命名应具备明确语义，例如 `isLoading`、`hasError`、`visibleCount`、`selectedRange`。

## Dart 与 Import
- 优先使用静态类型；在不影响可读性的前提下使用类型推断。
- import 顺序保持为：
  - `dart:`
  - `package:`
  - 项目内导入
- 尽量避免无意义地调整 import。

## Flutter 实践
- 能使用 `const` 时尽量使用，以减少不必要的 rebuild。
- 保持 widget 和辅助逻辑小而专注。
- 避免在 `build` 中执行本可提前计算的昂贵逻辑。
- 注释用于说明不明显的意图、约束和权衡，不写噪音注释。

## 根包层规则
- 根包 `lib/` 中的代码应保持为面向包的、可复用的、与示例应用解耦的实现。
- 不要把 `example/` 中的业务或演示逻辑引入根包。
- 公共 API 应保持稳定、清晰；实现细节尽量留在 `lib/src/` 下。

## 示例应用层规则
- 示例应用可以更偏业务演示，但仍需遵守现有模块边界。
- 继续沿用 `example/lib/` 中已有的依赖注入和 store 模式。
- 未经明确要求，不要把现有 store 或 DI 体系替换为 Riverpod、BLoC 或其他框架。

## UI 与主题
- 根包内继续遵循现有图表渲染、delegate 和 theme 扩展模式。
- 示例应用继续遵循现有页面、路由与 UI 组织方式。
- 除非明确要求，不做大规模 UI 风格调整。

## 安全与验证
- 不修改无关文件。
- 不覆盖用户已有改动。
- 修改完成后，执行最小必要验证。
- 如果未执行验证，需要明确说明。
