FLUTTER ?= $(shell if command -v fvm >/dev/null 2>&1; then echo "fvm flutter"; else echo "flutter"; fi)

.PHONY: gen watch build-web

gen:
	@echo "🚀 运行 example 代码生成器..."
	$(FLUTTER) pub run build_runner build --delete-conflicting-outputs --build-filter="lib/**"

watch:
	@echo "👀 监听 example 文件变化中..."
	$(FLUTTER) pub run build_runner watch --delete-conflicting-outputs --build-filter="lib/**"

build-web:
	@echo "🌐 构建 example Web..."
	$(FLUTTER) build web
