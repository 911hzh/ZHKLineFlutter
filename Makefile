# Flutter 项目常用命令脚本
# 使用方法: make <command>

.PHONY: help gen clean build run test get upgrade

# 默认显示帮助信息
help:
	@echo "可用的命令:"
	@echo "  make gen       - 运行代码生成器（build_runner）"
	@echo "  make clean     - 清理项目缓存和构建文件"
	@echo "  make build     - 构建项目"
	@echo "  make run       - 运行项目"
	@echo "  make test      - 运行测试"
	@echo "  make get       - 获取依赖包"
	@echo "  make upgrade   - 升级依赖包"
	@echo "  make watch     - 监听文件变化并自动生成代码"

# 运行代码生成器
gen:
	@echo "🚀 运行代码生成器..."
	flutter pub run build_runner build --delete-conflicting-outputs

# 监听文件变化并自动生成代码
watch:
	@echo "👀 监听文件变化中..."
	flutter pub run build_runner watch --delete-conflicting-outputs

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

