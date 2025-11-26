# 完整的代码生成器实现示例

## 🚀 快速开始 - 创建你自己的代码生成器

这是一个完整的、可运行的示例，展示如何从零开始创建一个类似 injectable_generator 的代码生成器。

---

## 第一步：项目结构

```
my_codegen_project/
├── my_annotations/          # 注解包
│   ├── pubspec.yaml
│   └── lib/
│       └── my_annotations.dart
│
├── my_generator/            # 生成器包
│   ├── pubspec.yaml
│   ├── build.yaml
│   └── lib/
│       ├── builder.dart
│       └── src/
│           └── route_generator.dart
│
└── example_app/             # 示例应用
    ├── pubspec.yaml
    ├── build.yaml
    └── lib/
        ├── main.dart
        └── pages/
            ├── home_page.dart
            └── profile_page.dart
```

---

## 第二步：创建注解包

### my_annotations/pubspec.yaml

```yaml
name: my_annotations
description: Custom annotations for code generation
version: 1.0.0
publish_to: none

environment:
  sdk: ^3.0.0
```

### my_annotations/lib/my_annotations.dart

```dart
/// 标记一个类为可路由的页面
class RoutePage {
  /// 路由路径，例如 '/home'
  final String path;

  /// 路由名称，用于命名路由
  final String? name;

  const RoutePage({
    required this.path,
    this.name,
  });
}

/// 标记需要自动生成单例的类
class AutoSingleton {
  const AutoSingleton();
}

/// 标记需要自动生成 JSON 序列化的类
class JsonModel {
  const JsonModel();
}
```

---

## 第三步：创建生成器包

### my_generator/pubspec.yaml

```yaml
name: my_generator
description: Code generator for custom annotations
version: 1.0.0
publish_to: none

environment:
  sdk: ^3.0.0

dependencies:
  build: ^2.4.0
  source_gen: ^1.5.0
  analyzer: ^6.4.0
  dart_style: ^2.3.0
  code_builder: ^4.10.0
  my_annotations:
    path: ../my_annotations

dev_dependencies:
  build_runner: ^2.4.0
  build_test: ^2.2.0
```

### my_generator/lib/src/route_generator.dart

```dart
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:my_annotations/my_annotations.dart';

/// 路由生成器 - 扫描所有带 @RoutePage 注解的类
class RouteGenerator extends GeneratorForAnnotation<RoutePage> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // 验证元素类型
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@RoutePage 只能用于类',
        element: element,
      );
    }

    // 获取注解参数
    final className = element.name;
    final path = annotation.read('path').stringValue;
    final name = annotation.peek('name')?.stringValue ?? className;

    // 生成扩展方法
    return '''
// Generated route for $className
extension ${className}RouteExtension on $className {
  static const String routePath = '$path';
  static const String routeName = '$name';

  static Route<dynamic> route() {
    return MaterialPageRoute(
      builder: (context) => $className(),
      settings: RouteSettings(name: routeName),
    );
  }
}
''';
  }
}
```

### my_generator/lib/src/singleton_generator.dart

```dart
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:my_annotations/my_annotations.dart';

/// 单例生成器 - 为类生成单例模式代码
class SingletonGenerator extends GeneratorForAnnotation<AutoSingleton> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@AutoSingleton 只能用于类',
        element: element,
      );
    }

    final className = element.name;

    // 检查是否有私有构造函数
    final hasPrivateConstructor = element.constructors.any(
      (c) => c.name.startsWith('_'),
    );

    return '''
// Generated singleton for $className
extension ${className}SingletonExtension on $className {
  static final ${className} _instance = ${className}${hasPrivateConstructor ? '._internal' : ''}();

  static ${className} get instance => _instance;
}
''';
  }
}
```

### my_generator/lib/src/aggregated_generator.dart

```dart
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:my_annotations/my_annotations.dart';

/// 聚合生成器 - 生成所有路由的统一配置
class RouteConfigGenerator extends Generator {
  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final routes = <RouteInfo>[];

    // 扫描当前库中的所有类
    for (final element in library.allElements) {
      if (element is ClassElement) {
        // 检查是否有 @RoutePage 注解
        final annotation = _getRouteAnnotation(element);
        if (annotation != null) {
          final path = annotation.read('path').stringValue;
          final name = annotation.peek('name')?.stringValue ?? element.name;

          routes.add(RouteInfo(
            className: element.name,
            path: path,
            name: name,
            import: buildStep.inputId.uri.toString(),
          ));
        }
      }
    }

    if (routes.isEmpty) {
      return '';
    }

    return _generateRouteConfig(routes);
  }

  ConstantReader? _getRouteAnnotation(ClassElement element) {
    const typeChecker = TypeChecker.fromRuntime(RoutePage);
    final annotation = typeChecker.firstAnnotationOf(element);
    return annotation != null ? ConstantReader(annotation) : null;
  }

  String _generateRouteConfig(List<RouteInfo> routes) {
    final buffer = StringBuffer();

    buffer.writeln('// GENERATED ROUTE CONFIGURATION');
    buffer.writeln('// DO NOT MODIFY BY HAND');
    buffer.writeln();

    // 生成导入
    for (final route in routes) {
      buffer.writeln("import '${route.import}';");
    }
    buffer.writeln();

    // 生成路由映射
    buffer.writeln('class AppRoutes {');
    buffer.writeln('  static const Map<String, String> routes = {');
    for (final route in routes) {
      buffer.writeln("    '${route.name}': '${route.path}',");
    }
    buffer.writeln('  };');
    buffer.writeln();

    // 生成路由工厂
    buffer.writeln('  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {');
    buffer.writeln('    switch (settings.name) {');
    for (final route in routes) {
      buffer.writeln("      case '${route.path}':");
      buffer.writeln('        return MaterialPageRoute(');
      buffer.writeln('          builder: (context) => ${route.className}(),');
      buffer.writeln('          settings: settings,');
      buffer.writeln('        );');
    }
    buffer.writeln('      default:');
    buffer.writeln('        return null;');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln('}');

    return buffer.toString();
  }
}

class RouteInfo {
  final String className;
  final String path;
  final String name;
  final String import;

  RouteInfo({
    required this.className,
    required this.path,
    required this.name,
    required this.import,
  });
}
```

### my_generator/lib/builder.dart

```dart
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/route_generator.dart';
import 'src/singleton_generator.dart';

/// 配置部分生成器（Part Builder）
Builder myPartBuilder(BuilderOptions options) {
  return SharedPartBuilder(
    [
      RouteGenerator(),
      SingletonGenerator(),
    ],
    'my_generator',
  );
}

/// 配置库生成器（Library Builder）- 用于生成独立文件
Builder myLibraryBuilder(BuilderOptions options) {
  return LibraryBuilder(
    RouteConfigGenerator(),
    generatedExtension: '.routes.dart',
  );
}
```

### my_generator/build.yaml

```yaml
builders:
  # Part 生成器 - 生成 .g.dart 文件
  my_part_builder:
    import: "package:my_generator/builder.dart"
    builder_factories: ["myPartBuilder"]
    build_extensions: { ".dart": [".g.dart"] }
    auto_apply: dependents
    build_to: cache
    applies_builders: ["source_gen|combining_builder"]

  # Library 生成器 - 生成独立的 .routes.dart 文件
  my_library_builder:
    import: "package:my_generator/builder.dart"
    builder_factories: ["myLibraryBuilder"]
    build_extensions: { ".dart": [".routes.dart"] }
    auto_apply: dependents
    build_to: source
```

---

## 第四步：在应用中使用

### example_app/pubspec.yaml

```yaml
name: example_app
description: Example app using custom code generator
version: 1.0.0
publish_to: none

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  my_annotations:
    path: ../my_annotations

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  my_generator:
    path: ../my_generator
```

### example_app/lib/pages/home_page.dart

```dart
import 'package:flutter/material.dart';
import 'package:my_annotations/my_annotations.dart';

part 'home_page.g.dart';

@RoutePage(path: '/home', name: 'home')
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('This page route: ${HomePageRouteExtension.routePath}'),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: const Text('Go to Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### example_app/lib/services/app_service.dart

```dart
import 'package:my_annotations/my_annotations.dart';

part 'app_service.g.dart';

@AutoSingleton()
class AppService {
  AppService._internal();

  int counter = 0;

  void incrementCounter() {
    counter++;
    print('Counter: $counter');
  }
}

// 使用生成的单例
void useService() {
  final service = AppServiceSingletonExtension.instance;
  service.incrementCounter();
}
```

### example_app/lib/main.dart

```dart
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Code Gen Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: HomePageRouteExtension.routePath,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
```

---

## 第五步：运行代码生成

在 `example_app` 目录下运行：

```bash
# 安装依赖
flutter pub get

# 运行代码生成
flutter pub run build_runner build --delete-conflicting-outputs

# 或者监听文件变化自动生成
flutter pub run build_runner watch --delete-conflicting-outputs

# 清理生成的文件
flutter pub run build_runner clean
```

---

## 生成的代码示例

### home_page.g.dart (自动生成)

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_page.dart';

// Generated route for HomePage
extension HomePageRouteExtension on HomePage {
  static const String routePath = '/home';
  static const String routeName = 'home';

  static Route<dynamic> route() {
    return MaterialPageRoute(
      builder: (context) => HomePage(),
      settings: RouteSettings(name: routeName),
    );
  }
}
```

### app_service.g.dart (自动生成)

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_service.dart';

// Generated singleton for AppService
extension AppServiceSingletonExtension on AppService {
  static final AppService _instance = AppService._internal();

  static AppService get instance => _instance;
}
```

---

## 🔧 高级功能

### 1. 添加自定义配置

**build.yaml (在项目根目录):**

```yaml
targets:
  $default:
    builders:
      my_generator|my_part_builder:
        options:
          # 自定义选项
          generate_comments: true
          output_prefix: "Auto"
```

**在 Generator 中使用配置:**

```dart
class RouteGenerator extends GeneratorForAnnotation<RoutePage> {
  final BuilderOptions? options;

  RouteGenerator(this.options);

  @override
  String generateForAnnotatedElement(...) {
    final generateComments = options?.config['generate_comments'] ?? false;

    if (generateComments) {
      // 生成额外的注释
    }
    // ...
  }
}
```

### 2. 处理依赖关系

```dart
class DependencyAnalyzer {
  List<ClassElement> analyzeDependencies(ClassElement element) {
    final dependencies = <ClassElement>[];

    // 分析构造函数参数
    final constructor = element.unnamedConstructor;
    if (constructor != null) {
      for (final param in constructor.parameters) {
        if (param.type is InterfaceType) {
          final paramType = param.type as InterfaceType;
          dependencies.add(paramType.element as ClassElement);
        }
      }
    }

    return dependencies;
  }

  List<ClassElement> topologicalSort(List<ClassElement> classes) {
    // 实现拓扑排序以确定正确的初始化顺序
    final sorted = <ClassElement>[];
    final visited = <ClassElement>{};

    void visit(ClassElement cls) {
      if (visited.contains(cls)) return;
      visited.add(cls);

      for (final dep in analyzeDependencies(cls)) {
        visit(dep);
      }

      sorted.add(cls);
    }

    for (final cls in classes) {
      visit(cls);
    }

    return sorted;
  }
}
```

### 3. 生成更复杂的代码

```dart
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

String generateComplexCode() {
  // 创建类
  final generatedClass = Class((b) => b
    ..name = 'AppConfig'
    ..fields.addAll([
      Field((f) => f
        ..name = '_routes'
        ..type = refer('Map<String, RouteFactory>')
        ..modifier = FieldModifier.final$
        ..assignment = Code('{}')
      ),
    ])
    ..constructors.add(Constructor((c) => c
      ..name = '_internal'
      ..constant = false
    ))
    ..methods.addAll([
      Method((m) => m
        ..name = 'registerRoute'
        ..returns = refer('void')
        ..requiredParameters.addAll([
          Parameter((p) => p..name = 'name'..type = refer('String')),
          Parameter((p) => p..name = 'factory'..type = refer('RouteFactory')),
        ])
        ..body = Code('_routes[name] = factory;')
      ),
      Method((m) => m
        ..name = 'getRoute'
        ..returns = refer('RouteFactory?')
        ..requiredParameters.add(
          Parameter((p) => p..name = 'name'..type = refer('String'))
        )
        ..body = Code('return _routes[name];')
      ),
    ])
  );

  // 生成并格式化代码
  final emitter = DartEmitter(allocator: Allocator());
  final generatedCode = '${generatedClass.accept(emitter)}';

  final formatter = DartFormatter();
  return formatter.format(generatedCode);
}
```

---

## 📊 injectable_generator 的核心实现对比

### Injectable Generator 的实际工作流程:

```dart
// 1. 定义注解
class Injectable {
  final List<Type> as;
  final String? env;
  const Injectable({this.as = const [], this.env});
}

// 2. Generator 扫描
class InjectableGenerator extends GeneratorForAnnotation<InjectableInit> {
  Future<String> generateForAnnotatedElement(...) async {
    // 扫描所有库
    final libraries = await buildStep.resolver.libraries.toList();

    // 收集依赖
    final dependencies = <DependencyConfig>[];
    for (final lib in libraries) {
      dependencies.addAll(await _getDependencies(lib));
    }

    // 排序依赖（拓扑排序）
    final sorted = _sortDependencies(dependencies);

    // 生成代码
    return _generateCode(sorted);
  }

  String _generateCode(List<DependencyConfig> deps) {
    return '''
extension GetItInjectableX on GetIt {
  GetIt init({...}) {
    final gh = GetItHelper(this, environment, environmentFilter);
    ${deps.map((d) => _generateRegistration(d)).join('\n')}
    return this;
  }
}
''';
  }
}
```

---

## 🎯 总结

### 实现代码生成器的关键步骤：

1. **定义注解** → 创建 annotation 包
2. **创建 Generator** → 继承 `GeneratorForAnnotation` 或 `Generator`
3. **分析代码** → 使用 `analyzer` 包解析 AST
4. **生成代码** → 使用字符串拼接或 `code_builder`
5. **配置 Builder** → 编写 `build.yaml`
6. **运行生成** → 使用 `build_runner`

### 核心技术：

- ✅ **source_gen**: 代码生成框架
- ✅ **analyzer**: AST 分析
- ✅ **code_builder**: 代码构建
- ✅ **build_runner**: 执行引擎

### Injectable 的特殊之处：

- 跨库扫描所有注解
- 自动解析依赖关系
- 拓扑排序确定注册顺序
- 支持环境配置
- 处理泛型和复杂类型

现在你已经掌握了创建自己的代码生成器的完整知识！🎉
