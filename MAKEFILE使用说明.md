# Makefile 使用说明

本项目包含两个 Makefile 文件：

- **Makefile** - 主文件，包含所有开发命令
- **Makefile.ci** - CI 构建专用配置（自动包含）

## ✨ 重要说明

**所有命令都可以直接使用 `make xxx`，无需 `-f` 参数！**

主 `Makefile` 通过 `include Makefile.ci` 自动包含了 CI 配置。

## 📋 常用命令

### 开发命令

```bash
make run            # 运行项目
make test           # 运行测试
make build          # 构建APK
make build-ios      # 构建iOS
make build-web      # 构建Web
make clean          # 清理项目
make gen            # 运行代码生成器
make watch          # 监听文件变化并自动生成代码
make format         # 格式化代码
make analyze        # 代码分析
make get            # 获取依赖包
make upgrade        # 升级依赖包
```

### CI 构建命令（直接使用）⭐

```bash
make ci-build           # 构建所有平台（Android + Web）
make ci-build-android   # 构建Android（APK + AAB）
make ci-build-ios       # 构建iOS
make ci-build-web       # 构建Web
```

### 辅助命令

```bash
make help           # 查看所有命令
make check-version  # 检查Flutter版本和环境
make format-check   # 检查代码格式（不修改文件）
make deep-clean     # 深度清理（包括.dart_tool等）
```

## 🎯 推荐工作流

### 1. 日常开发

```bash
# 运行项目
make run

# 运行测试
make test

# 代码格式化
make format
```

### 2. 提交代码前

```bash
# 格式化代码
make format

# 检查代码质量
make analyze

# 运行测试
make test
```

### 3. CI 构建

```bash
# 构建Android
make ci-build-android

# 构建所有平台
make ci-build
```

## 📂 文件说明

### Makefile（115 行）

包含所有基础开发命令：

- 代码生成（gen, watch）
- 项目管理（clean, get, upgrade）
- 运行和测试（run, test）
- 本地构建（build, build-ios, build-web）
- 代码质量（analyze, format, format-check）
- 自动 include Makefile.ci

### Makefile.ci（40 行）⭐

只包含 CI 构建命令：

- `ci-build` - 构建所有平台
- `ci-build-android` - Android 构建（APK + AAB）
- `ci-build-ios` - iOS 构建
- `ci-build-web` - Web 构建

**特点：简洁、专注、易维护**

## 🔍 查看所有命令

```bash
make help
```

输出示例：

```
可用的命令:

开发命令:
  make gen            - 运行代码生成器（build_runner）
  make clean          - 清理项目缓存和构建文件
  make build          - 构建项目（默认Android APK）
  make run            - 运行项目
  make test           - 运行测试
  ...

CI构建命令:
  make ci-build         - CI构建所有平台（Android + Web）
  make ci-build-android - CI构建Android（APK + AAB）
  make ci-build-ios     - CI构建iOS
  make ci-build-web     - CI构建Web

代码质量命令:
  make analyze        - 分析代码
  make format         - 格式化代码
  make format-check   - 检查代码格式（不修改）
```

## 💡 技术实现

主 `Makefile` 第 5 行使用了 `include` 指令：

```makefile
# 包含CI专用配置（Makefile.ci中的命令可以直接使用）
-include Makefile.ci
```

这样实现了：

- ✅ `Makefile.ci` 保持独立，专注 CI 构建
- ✅ 所有命令可以直接 `make xxx` 使用
- ✅ 代码简洁，易于维护

## 📊 构建产物位置

### Android

- **APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **AAB**: `build/app/outputs/bundle/release/app-release.aab`

### iOS

- **App**: `build/ios/iphoneos/Runner.app`

### Web

- **静态文件**: `build/web/`

## 🚀 CI/CD 集成

在 CI 配置文件中直接使用：

**GitHub Actions:**

```yaml
- name: 构建Android
  run: make ci-build-android

- name: 构建所有平台
  run: make ci-build
```

**GitLab CI:**

```yaml
build:
  script:
    - make ci-build
```

## 🎉 总结

**简洁就是力量！**

现在的 Makefile.ci 只有 40 行，只做一件事：**构建**。

```bash
# 以下命令都可以直接使用：
make ci-build           ✅
make ci-build-android   ✅
make ci-build-ios       ✅
make ci-build-web       ✅
```

Happy Coding! 🚀
