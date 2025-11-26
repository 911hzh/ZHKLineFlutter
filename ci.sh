#!/bin/bash
# Flutter CI/CD 自动化脚本
# 使用方法: ./ci.sh [command]
# 或在CI中直接调用: bash ci.sh ci

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_header() {
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo -e "${BLUE}$1${NC}"
    echo "════════════════════════════════════════════════════════════"
    echo ""
}

print_step() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

# CI环境变量
CI_BUILD_DIR="build/ci"
CI_REPORTS_DIR="${CI_BUILD_DIR}/reports"
CI_ARTIFACTS_DIR="${CI_BUILD_DIR}/artifacts"

# ============================================
# 辅助函数
# ============================================

# 检查Flutter环境
check_env() {
    print_header "🔍 检查Flutter环境"
    
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter未安装或未添加到PATH"
        exit 1
    fi
    
    print_step "Flutter版本信息:"
    flutter --version
    echo ""
    
    print_step "Flutter Doctor:"
    flutter doctor -v
    echo ""
}

# 初始化CI环境
setup() {
    print_header "📦 初始化CI环境"
    
    # 创建CI目录
    mkdir -p "${CI_BUILD_DIR}"
    mkdir -p "${CI_REPORTS_DIR}"
    mkdir -p "${CI_ARTIFACTS_DIR}/android"
    mkdir -p "${CI_ARTIFACTS_DIR}/ios"
    mkdir -p "${CI_ARTIFACTS_DIR}/web"
    mkdir -p "coverage"
    
    print_step "CI目录创建完成"
    
    # 获取依赖
    print_step "获取依赖包..."
    flutter pub get
    
    # 运行代码生成器
    print_step "运行代码生成器..."
    flutter pub run build_runner build --delete-conflicting-outputs || true
    
    print_step "CI环境初始化完成"
}

# ============================================
# 代码质量检查
# ============================================

# 检查代码格式
format_check() {
    print_header "📝 检查代码格式"
    
    if dart format --output=none --set-exit-if-changed lib/ test/; then
        print_step "代码格式检查通过"
    else
        print_error "代码格式不符合规范"
        echo ""
        echo "请运行以下命令修复:"
        echo "  dart format lib/ test/"
        echo "  或"
        echo "  make format"
        exit 1
    fi
}

# 代码静态分析
analyze() {
    print_header "🔍 代码静态分析"
    
    if flutter analyze --fatal-infos --fatal-warnings > "${CI_REPORTS_DIR}/analyze.log" 2>&1; then
        print_step "代码分析通过"
    else
        print_error "代码分析失败"
        cat "${CI_REPORTS_DIR}/analyze.log"
        exit 1
    fi
}

# 运行单元测试
test_unit() {
    print_header "🧪 运行单元测试"
    
    if flutter test --coverage --reporter=expanded | tee "${CI_REPORTS_DIR}/test.log"; then
        print_step "单元测试通过"
        if [ -f "coverage/lcov.info" ]; then
            print_step "测试覆盖率报告: coverage/lcov.info"
        fi
    else
        print_error "单元测试失败"
        exit 1
    fi
}

# 运行集成测试
test_integration() {
    if [ -d "integration_test" ]; then
        print_header "🔗 运行集成测试"
        
        if flutter test integration_test | tee "${CI_REPORTS_DIR}/integration_test.log"; then
            print_step "集成测试通过"
        else
            print_error "集成测试失败"
            exit 1
        fi
    else
        print_warning "未找到集成测试目录，跳过"
    fi
}

# ============================================
# 构建函数
# ============================================

# 构建Android
build_android() {
    print_header "🤖 构建Android"
    
    print_step "构建APK..."
    flutter build apk --release
    
    print_step "构建App Bundle..."
    flutter build appbundle --release
    
    # 复制构建产物
    if [ -d "build/app/outputs/flutter-apk" ]; then
        cp build/app/outputs/flutter-apk/*.apk "${CI_ARTIFACTS_DIR}/android/" 2>/dev/null || true
    fi
    
    if [ -d "build/app/outputs/bundle/release" ]; then
        cp build/app/outputs/bundle/release/*.aab "${CI_ARTIFACTS_DIR}/android/" 2>/dev/null || true
    fi
    
    print_step "Android构建完成"
    
    # 显示构建产物
    if [ -n "$(ls -A ${CI_ARTIFACTS_DIR}/android/ 2>/dev/null)" ]; then
        echo ""
        echo "构建产物:"
        ls -lh "${CI_ARTIFACTS_DIR}/android/"
    fi
}

# 构建iOS
build_ios() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_header "🍎 构建iOS"
        
        flutter build ios --release --no-codesign
        
        # 复制构建产物
        if [ -d "build/ios/iphoneos" ]; then
            cp -r build/ios/iphoneos/*.app "${CI_ARTIFACTS_DIR}/ios/" 2>/dev/null || true
        fi
        
        print_step "iOS构建完成"
    else
        print_warning "iOS构建需要macOS环境，当前系统: $OSTYPE"
        print_warning "跳过iOS构建"
    fi
}

# 构建Web
build_web() {
    print_header "🌐 构建Web"
    
    flutter build web --release
    
    # 复制构建产物
    if [ -d "build/web" ]; then
        cp -r build/web/* "${CI_ARTIFACTS_DIR}/web/"
    fi
    
    print_step "Web构建完成"
    
    # 显示构建大小
    if [ -d "${CI_ARTIFACTS_DIR}/web" ]; then
        echo ""
        echo "构建大小:"
        du -sh "${CI_ARTIFACTS_DIR}/web"
    fi
}

# ============================================
# CI流程
# ============================================

# CI测试阶段
ci_test() {
    print_header "🧪 CI测试阶段"
    
    setup
    format_check
    analyze
    test_unit
    test_integration
    
    print_header "✅ CI测试阶段完成"
}

# CI构建阶段
ci_build() {
    print_header "🔨 CI构建阶段"
    
    build_android
    build_web
    build_ios
    
    print_header "✅ CI构建阶段完成"
    
    # 显示所有构建产物
    echo ""
    echo "所有构建产物:"
    du -sh "${CI_ARTIFACTS_DIR}"/*
}

# 完整CI流程
ci_full() {
    print_header "🚀 开始完整CI流程"
    
    check_env
    ci_test
    ci_build
    
    print_header "🎉 完整CI流程完成！"
    
    # 生成报告
    generate_report
}

# 快速CI检查（不构建）
ci_quick() {
    print_header "⚡ 快速CI检查"
    
    check_env
    setup
    format_check
    analyze
    test_unit
    
    print_header "✅ 快速CI检查完成"
}

# 生成CI报告
generate_report() {
    print_header "📊 CI报告"
    
    echo "报告文件目录: ${CI_REPORTS_DIR}"
    if [ -d "${CI_REPORTS_DIR}" ]; then
        ls -lh "${CI_REPORTS_DIR}/" 2>/dev/null || echo "  未生成报告"
    fi
    
    echo ""
    echo "构建产物目录: ${CI_ARTIFACTS_DIR}"
    if [ -d "${CI_ARTIFACTS_DIR}" ]; then
        du -sh "${CI_ARTIFACTS_DIR}"/* 2>/dev/null || echo "  未生成构建产物"
    fi
    
    echo ""
    echo "测试覆盖率:"
    if [ -f "coverage/lcov.info" ]; then
        echo "  ✓ 覆盖率文件: coverage/lcov.info"
        echo "  生成HTML报告命令: genhtml coverage/lcov.info -o coverage/html"
    else
        echo "  未生成覆盖率报告"
    fi
}

# 清理CI产物
clean_ci() {
    print_header "🧹 清理CI产物"
    
    rm -rf "${CI_BUILD_DIR}"
    rm -rf "coverage"
    rm -rf "build"
    
    print_step "CI清理完成"
}

# ============================================
# 帮助信息
# ============================================

show_help() {
    cat << EOF
════════════════════════════════════════════════════════════
  Flutter CI/CD 自动化脚本
════════════════════════════════════════════════════════════

使用方法: ./ci.sh [command]

📋 主要CI流程:
  ci              完整CI流程（检查环境 → 测试 → 构建）
  ci-quick        快速CI检查（只做代码检查和测试，不构建）
  ci-test         CI测试阶段（格式检查 + 代码分析 + 单元测试）
  ci-build        CI构建阶段（构建所有平台）

🔨 平台构建:
  build-android   构建Android（APK + Bundle）
  build-ios       构建iOS（需要macOS）
  build-web       构建Web版本

🔍 代码质量:
  format-check    检查代码格式
  analyze         运行代码静态分析
  test-unit       运行单元测试（带覆盖率）
  test-integration 运行集成测试

🛠️  辅助命令:
  setup           初始化CI环境
  check-env       检查Flutter环境
  clean           清理CI构建产物
  report          生成CI报告
  help            显示此帮助信息

示例:
  ./ci.sh ci              # 运行完整CI流程
  ./ci.sh ci-quick        # 快速检查（提交前推荐）
  ./ci.sh build-android   # 只构建Android

════════════════════════════════════════════════════════════
EOF
}

# ============================================
# 主函数
# ============================================

main() {
    local command="${1:-help}"
    
    case "$command" in
        ci|ci-full)
            ci_full
            ;;
        ci-quick)
            ci_quick
            ;;
        ci-test)
            ci_test
            ;;
        ci-build)
            ci_build
            ;;
        build-android)
            setup
            build_android
            ;;
        build-ios)
            setup
            build_ios
            ;;
        build-web)
            setup
            build_web
            ;;
        format-check)
            format_check
            ;;
        analyze)
            setup
            analyze
            ;;
        test-unit|test)
            setup
            test_unit
            ;;
        test-integration)
            setup
            test_integration
            ;;
        setup)
            check_env
            setup
            ;;
        check-env|check)
            check_env
            ;;
        clean)
            clean_ci
            ;;
        report)
            generate_report
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"

