# Flutter 项目常用命令脚本
# 使用方法: make <command>

# 包含CI专用配置（Makefile.ci中的命令可以直接使用）
-include Makefile.ci

FLUTTER ?= $(shell if command -v fvm >/dev/null 2>&1 && [ -f .fvmrc ]; then echo "fvm flutter"; else echo "flutter"; fi)

.PHONY: help gen clean build run test get upgrade analyze format format-check watch deep-clean build-ios build-web check-version

# 默认显示帮助信息
help:
	@echo "可用的命令:"
	@echo ""
	@echo "开发命令:"
	@echo "  make gen            - 运行代码生成器（build_runner）"
	@echo "  make clean          - 清理项目缓存和构建文件"
	@echo "  make build          - 构建项目（默认Android APK）"
	@echo "  make run            - 运行项目"
	@echo "  make test           - 运行测试"
	@echo "  make get            - 获取依赖包"
	@echo "  make upgrade        - 升级依赖包"
	@echo "  make watch          - 监听文件变化并自动生成代码"
	@echo ""
	@echo "CI构建命令:"
	@echo "  make ci-build         - CI构建所有平台（Android + Web）"
	@echo "  make ci-build-android - CI构建Android（APK + AAB）"
	@echo "  make ci-build-ios     - CI构建iOS"
	@echo "  make ci-build-web     - CI构建Web"
	@echo ""
	@echo "辅助命令:"
	@echo "  make check-version    - 检查Flutter版本和环境"
	@echo ""
	@echo "代码质量命令:"
	@echo "  make analyze        - 分析代码"
	@echo "  make format         - 格式化代码"
	@echo "  make format-check   - 检查代码格式（不修改）"

# 运行代码生成器
gen:
	@echo "🚀 运行代码生成器..."
	$(FLUTTER) pub run build_runner build --delete-conflicting-outputs --build-filter="lib/**"

# 监听文件变化并自动生成代码
watch:
	@echo "👀 监听文件变化中..."
	$(FLUTTER) pub run build_runner watch --delete-conflicting-outputs --build-filter="lib/**"

# 清理项目
clean:
	@echo "🧹 清理项目..."
	flutter clean
	flutter pub get

# 深度清理（包括 build_runner 缓存）
deep-clean:
	@echo "🧹 深度清理项目..."
	flutter clean
	rm -rf .dart_tool/
	rm -rf build/
	flutter pub get

# 获取依赖包
get:
	@echo "📦 获取依赖包..."
	flutter pub get

# 升级依赖包
upgrade:
	@echo "⬆️  升级依赖包..."
	flutter pub upgrade

# 运行项目
run:
	@echo "▶️  运行项目..."
	flutter run

# 运行测试
test:
	@echo "🧪 运行测试..."
	flutter test

# 构建项目（默认 Android）
build:
	@echo "🔨 构建项目..."
	flutter build apk

# 构建 iOS
build-ios:
	@echo "🔨 构建 iOS..."
	flutter build ios

# 构建 Web
build-web:
	@echo "🔨 构建 Web..."
	flutter build web

# 分析代码
analyze:
	@echo "🔍 分析代码..."
	flutter analyze

# 格式化代码
format:
	@echo "✨ 格式化代码..."
	dart format lib/ test/

# 检查代码格式（不修改）
format-check:
	@echo "🔍 检查代码格式..."
	dart format --output=none --set-exit-if-changed lib/ test/

# 检查Flutter版本
check-version:
	@echo "📋 检查Flutter版本..."
	flutter --version
	flutter doctor -v
