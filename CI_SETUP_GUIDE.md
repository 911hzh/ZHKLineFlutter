# Flutter CI/CD 配置指南

本项目包含一个专门的CI Makefile (`Makefile.ci`)，用于在各种CI平台上自动化构建、测试和发布流程。

## 📋 目录

- [快速开始](#快速开始)
- [Makefile.ci 命令](#makefileci-命令)
- [CI平台配置](#ci平台配置)
  - [GitHub Actions](#github-actions)
  - [GitLab CI](#gitlab-ci)
  - [Jenkins](#jenkins)
  - [CircleCI](#circleci)
- [构建产物](#构建产物)
- [最佳实践](#最佳实践)

## 🚀 快速开始

### 本地测试CI流程

```bash
# 查看所有可用命令
make -f Makefile.ci help

# 运行完整CI流程
make -f Makefile.ci ci

# 快速检查（不构建）
make -f Makefile.ci ci-quick

# 只运行测试
make -f Makefile.ci ci-test

# 只运行构建
make -f Makefile.ci ci-build
```

## 📚 Makefile.ci 命令

### 主要CI流程

| 命令 | 说明 | 用途 |
|------|------|------|
| `make -f Makefile.ci ci` | 完整CI流程 | 检查环境 → 测试 → 构建 |
| `make -f Makefile.ci ci-quick` | 快速CI检查 | 只做代码检查和测试，不构建 |
| `make -f Makefile.ci ci-test` | CI测试阶段 | 格式检查 + 代码分析 + 单元测试 |
| `make -f Makefile.ci ci-build` | CI构建阶段 | 构建所有平台 |
| `make -f Makefile.ci ci-release` | CI发布版本 | 构建完整的release版本 |

### 平台构建

| 命令 | 说明 |
|------|------|
| `make -f Makefile.ci ci-build-android` | 构建Android（APK + Bundle） |
| `make -f Makefile.ci ci-build-ios` | 构建iOS（需要macOS） |
| `make -f Makefile.ci ci-build-web` | 构建Web版本 |

### 代码质量

| 命令 | 说明 |
|------|------|
| `make -f Makefile.ci analyze` | 运行代码静态分析 |
| `make -f Makefile.ci format-check` | 检查代码格式 |
| `make -f Makefile.ci test-unit` | 运行单元测试（带覆盖率） |
| `make -f Makefile.ci test-integration` | 运行集成测试 |

### 辅助命令

| 命令 | 说明 |
|------|------|
| `make -f Makefile.ci setup` | 初始化CI环境 |
| `make -f Makefile.ci check-env` | 检查Flutter环境 |
| `make -f Makefile.ci clean-ci` | 清理CI构建产物 |
| `make -f Makefile.ci report` | 生成CI报告 |

## 🔧 CI平台配置

### GitHub Actions

创建文件：`.github/workflows/ci.yml`

```yaml
name: Flutter CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    name: 测试
    runs-on: ubuntu-latest
    timeout-minutes: 30
    
    steps:
      - name: 检出代码
        uses: actions/checkout@v4
      
      - name: 设置Flutter环境
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'
      
      - name: 运行CI测试
        run: make -f Makefile.ci ci-test
      
      - name: 上传测试覆盖率
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/lcov.info
          fail_ci_if_error: false
      
      - name: 上传测试报告
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-reports
          path: build/ci/reports/

  build-android:
    name: 构建Android
    runs-on: ubuntu-latest
    needs: test
    timeout-minutes: 30
    
    steps:
      - name: 检出代码
        uses: actions/checkout@v4
      
      - name: 设置Java环境
        uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '17'
      
      - name: 设置Flutter环境
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'
      
      - name: 构建Android
        run: make -f Makefile.ci ci-build-android
      
      - name: 上传APK
        uses: actions/upload-artifact@v3
        with:
          name: android-apk
          path: build/app/outputs/flutter-apk/*.apk
      
      - name: 上传AAB
        uses: actions/upload-artifact@v3
        with:
          name: android-bundle
          path: build/app/outputs/bundle/release/*.aab

  build-ios:
    name: 构建iOS
    runs-on: macos-latest
    needs: test
    timeout-minutes: 45
    
    steps:
      - name: 检出代码
        uses: actions/checkout@v4
      
      - name: 设置Flutter环境
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'
      
      - name: 构建iOS
        run: make -f Makefile.ci ci-build-ios
      
      - name: 上传iOS构建产物
        uses: actions/upload-artifact@v3
        with:
          name: ios-build
          path: build/ci/artifacts/ios/

  build-web:
    name: 构建Web
    runs-on: ubuntu-latest
    needs: test
    timeout-minutes: 20
    
    steps:
      - name: 检出代码
        uses: actions/checkout@v4
      
      - name: 设置Flutter环境
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'
      
      - name: 构建Web
        run: make -f Makefile.ci ci-build-web
      
      - name: 上传Web构建产物
        uses: actions/upload-artifact@v3
        with:
          name: web-build
          path: build/web/
```

### GitLab CI

创建文件：`.gitlab-ci.yml`

```yaml
stages:
  - test
  - build
  - deploy

variables:
  FLUTTER_VERSION: "3.x"

before_script:
  - apt-get update -qq
  - apt-get install -y curl git unzip xz-utils zip libglu1-mesa
  - git clone https://github.com/flutter/flutter.git -b stable --depth 1
  - export PATH="$PATH:`pwd`/flutter/bin"
  - flutter doctor -v

test:
  stage: test
  script:
    - make -f Makefile.ci ci-test
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/lcov.info
    paths:
      - build/ci/reports/
      - coverage/
    expire_in: 1 week
  coverage: '/lines\.*: \d+\.\d+\%/'

build:android:
  stage: build
  dependencies:
    - test
  script:
    - make -f Makefile.ci ci-build-android
  artifacts:
    paths:
      - build/app/outputs/flutter-apk/*.apk
      - build/app/outputs/bundle/release/*.aab
    expire_in: 1 month
  only:
    - main
    - develop
    - tags

build:web:
  stage: build
  dependencies:
    - test
  script:
    - make -f Makefile.ci ci-build-web
  artifacts:
    paths:
      - build/web/
    expire_in: 1 month
  only:
    - main
    - develop
    - tags

deploy:web:
  stage: deploy
  dependencies:
    - build:web
  script:
    - echo "部署Web应用到服务器..."
    # 添加您的部署脚本
  only:
    - main
```

### Jenkins

创建文件：`Jenkinsfile`

```groovy
pipeline {
    agent any
    
    environment {
        FLUTTER_HOME = '/opt/flutter'
        PATH = "$FLUTTER_HOME/bin:$PATH"
    }
    
    stages {
        stage('环境检查') {
            steps {
                sh 'make -f Makefile.ci check-env'
            }
        }
        
        stage('测试') {
            steps {
                sh 'make -f Makefile.ci ci-test'
            }
            post {
                always {
                    junit 'build/ci/reports/**/*.xml'
                    publishHTML([
                        reportDir: 'coverage/html',
                        reportFiles: 'index.html',
                        reportName: 'Coverage Report'
                    ])
                }
            }
        }
        
        stage('构建') {
            parallel {
                stage('构建Android') {
                    steps {
                        sh 'make -f Makefile.ci ci-build-android'
                    }
                }
                stage('构建Web') {
                    steps {
                        sh 'make -f Makefile.ci ci-build-web'
                    }
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: 'build/ci/artifacts/**/*'
                }
            }
        }
        
        stage('报告') {
            steps {
                sh 'make -f Makefile.ci report'
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
```

### CircleCI

创建文件：`.circleci/config.yml`

```yaml
version: 2.1

orbs:
  flutter: circleci/flutter@1.1.0

jobs:
  test:
    executor: flutter/default
    steps:
      - checkout
      - flutter/install_sdk_and_pub:
          flutter_version: 3.x
      - run:
          name: 运行测试
          command: make -f Makefile.ci ci-test
      - store_test_results:
          path: build/ci/reports
      - store_artifacts:
          path: coverage

  build-android:
    executor: flutter/default
    steps:
      - checkout
      - flutter/install_sdk_and_pub:
          flutter_version: 3.x
      - run:
          name: 构建Android
          command: make -f Makefile.ci ci-build-android
      - store_artifacts:
          path: build/app/outputs

  build-web:
    executor: flutter/default
    steps:
      - checkout
      - flutter/install_sdk_and_pub:
          flutter_version: 3.x
      - run:
          name: 构建Web
          command: make -f Makefile.ci ci-build-web
      - store_artifacts:
          path: build/web

workflows:
  version: 2
  test-and-build:
    jobs:
      - test
      - build-android:
          requires:
            - test
      - build-web:
          requires:
            - test
```

## 📦 构建产物

CI流程会生成以下产物：

### 目录结构

```
build/
├── ci/
│   ├── artifacts/          # 构建产物
│   │   ├── android/
│   │   │   ├── *.apk
│   │   │   └── *.aab
│   │   ├── ios/
│   │   │   └── *.app
│   │   └── web/
│   │       └── ...
│   └── reports/           # CI报告
│       ├── analyze.log
│       ├── test.log
│       └── integration_test.log
├── app/
│   └── outputs/          # Flutter原始构建输出
└── web/                  # Web构建输出

coverage/                 # 测试覆盖率
├── lcov.info
└── html/                 # HTML覆盖率报告
```

### Android产物

- **APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **AAB**: `build/app/outputs/bundle/release/app-release.aab`

### iOS产物

- **App**: `build/ios/iphoneos/Runner.app`

### Web产物

- **静态文件**: `build/web/`

## 🎯 最佳实践

### 1. 提交前本地检查

```bash
# 提交代码前运行快速检查
make -f Makefile.ci ci-quick
```

### 2. Pull Request时运行完整测试

```bash
# PR时运行完整测试（不构建）
make -f Makefile.ci ci-test
```

### 3. 合并到主分支时构建所有平台

```bash
# 主分支合并时运行完整CI
make -f Makefile.ci ci
```

### 4. 发布版本时

```bash
# 发布时构建release版本
make -f Makefile.ci ci-release
```

### 5. 环境变量配置

在CI环境中设置以下环境变量：

```bash
# Flutter版本
FLUTTER_VERSION=3.x

# Android签名配置
ANDROID_KEYSTORE_PATH=/path/to/keystore
ANDROID_KEYSTORE_PASSWORD=***
ANDROID_KEY_ALIAS=***
ANDROID_KEY_PASSWORD=***

# iOS签名配置（macOS）
IOS_CERTIFICATE_PATH=/path/to/cert
IOS_PROVISIONING_PROFILE=/path/to/profile
```

### 6. 缓存优化

在CI配置中缓存以下目录以加速构建：

```yaml
cache:
  paths:
    - $HOME/.pub-cache
    - $HOME/.gradle/caches
    - $HOME/.gradle/wrapper
    - build/
```

### 7. 超时设置

建议设置以下超时时间：

- 测试阶段：15-30分钟
- Android构建：20-30分钟
- iOS构建：30-45分钟
- Web构建：10-20分钟

## 🔍 故障排查

### 常见问题

1. **Flutter版本不匹配**
   ```bash
   make -f Makefile.ci check-env
   ```

2. **依赖安装失败**
   ```bash
   make -f Makefile.ci setup
   ```

3. **构建失败**
   ```bash
   # 查看详细日志
   cat build/ci/reports/analyze.log
   ```

4. **清理后重试**
   ```bash
   make -f Makefile.ci clean-ci
   make -f Makefile.ci ci
   ```

## 📚 相关资源

- [Flutter CI最佳实践](https://docs.flutter.dev/deployment/cd)
- [GitHub Actions Flutter](https://github.com/marketplace/actions/flutter-action)
- [GitLab CI Flutter](https://docs.gitlab.com/ee/ci/examples/flutter.html)

## 🤝 贡献

如有问题或建议，请提交Issue或Pull Request。

