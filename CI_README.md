# CI/CD 配置说明

本项目已配置完整的CI/CD流程，支持自动化测试、构建和部署。

## 📁 文件结构

```
ZHKLineFlutter/
├── Makefile                          # 开发常用命令
├── ci.sh                             # CI/CD专用脚本 ⭐
├── CI_SETUP_GUIDE.md                # CI配置详细指南 ⭐
├── CI_README.md                     # 本文件
└── .github/
    └── workflows/
        ├── ci.yml                    # 完整CI流程 ⭐
        └── pr-check.yml              # PR快速检查 ⭐
```

## 🚀 快速开始

### 本地开发

```bash
# 使用开发版Makefile
make run           # 运行项目
make test          # 运行测试
make build         # 构建项目
```

### 本地测试CI流程

```bash
# 使用CI脚本
./ci.sh help        # 查看所有命令
./ci.sh ci-quick    # 快速检查（推荐提交前运行）
./ci.sh ci          # 完整CI流程
```

## 🔄 CI工作流

### 1. PR快速检查（pr-check.yml）

**触发时机**: 创建或更新Pull Request时

**执行内容**:
- ✅ 代码格式检查
- ✅ 静态代码分析
- ✅ 单元测试
- 📝 自动添加PR检查结果评论

**执行时间**: ~10-15分钟

### 2. 完整CI流程（ci.yml）

**触发时机**: 
- Push到主要分支（main/master/develop）
- Pull Request（非草稿）

**执行内容**:

#### 测试阶段（并行）
- ✅ 代码格式检查
- ✅ 静态代码分析
- ✅ 单元测试（带覆盖率）
- 📊 上传测试报告和覆盖率

#### 构建阶段（并行执行）
- 🤖 **Android**: 构建APK和AAB
- 🌐 **Web**: 构建Web版本
- 🍎 **iOS**: 仅在主分支构建（需macOS runner）

**执行时间**: ~20-45分钟

## 📦 构建产物

CI构建完成后，可以在GitHub Actions的"Artifacts"下载以下产物：

### Android
- `android-apk` - APK安装包
- `android-bundle` - AAB上架包

### iOS
- `ios-build` - iOS构建产物（仅主分支）

### Web
- `web-build` - Web静态文件

### 测试报告
- `test-reports` - 测试日志和覆盖率报告
- `pr-check-reports` - PR检查报告

## 📋 CI/CD命令参考

### 开发命令（Makefile）

```bash
make help          # 查看所有命令
make run           # 运行项目
make test          # 运行测试
make build         # 构建APK
make clean         # 清理项目
make gen           # 运行代码生成器
make analyze       # 代码分析
make format        # 格式化代码
```

### CI命令（ci.sh）

```bash
# 主要流程
./ci.sh ci              # 完整CI流程
./ci.sh ci-quick        # 快速检查（不构建）
./ci.sh ci-test         # 只运行测试
./ci.sh ci-build        # 只运行构建

# 平台构建
./ci.sh build-android   # 构建Android
./ci.sh build-ios       # 构建iOS
./ci.sh build-web       # 构建Web

# 代码质量
./ci.sh analyze         # 代码分析
./ci.sh format-check    # 格式检查
./ci.sh test-unit       # 单元测试
./ci.sh test-integration # 集成测试

# 辅助命令
./ci.sh setup           # 初始化CI环境
./ci.sh check-env       # 检查环境
./ci.sh clean           # 清理CI产物
./ci.sh report          # 生成报告
./ci.sh help            # 显示帮助信息
```

## 🔧 本地CI测试建议

### 提交代码前

```bash
# 1. 格式化代码
make format

# 2. 快速检查
./ci.sh ci-quick
```

### 创建PR前

```bash
# 完整的本地CI测试
./ci.sh ci-test
```

### 发布前

```bash
# 构建所有平台
./ci.sh ci
```

## 📊 CI状态徽章

在项目README.md中添加以下徽章：

```markdown
![Flutter CI](https://github.com/你的用户名/ZHKLineFlutter/workflows/Flutter%20CI/badge.svg)
![PR Check](https://github.com/你的用户名/ZHKLineFlutter/workflows/PR%20快速检查/badge.svg)
```

## 🎯 最佳实践

1. **提交前检查**: 运行 `make -f Makefile.ci ci-quick`
2. **小步提交**: 频繁提交小的改动，便于CI快速验证
3. **关注CI结果**: PR不要合并失败的CI
4. **查看覆盖率**: 保持测试覆盖率在合理水平
5. **及时修复**: CI失败时立即修复，不要积累问题

## 🐛 故障排查

### CI运行失败？

1. **查看日志**: 点击失败的job查看详细日志
2. **本地复现**: 使用相同的命令在本地运行
3. **环境问题**: 检查Flutter版本是否匹配
4. **依赖问题**: 尝试 `./ci.sh clean && ./ci.sh setup`

### 常见问题

#### 代码格式检查失败
```bash
# 修复方法
make format
git add .
git commit --amend --no-edit
git push -f
```

#### 代码分析失败
```bash
# 查看具体问题
flutter analyze
# 或
make analyze
```

#### 测试失败
```bash
# 本地运行测试
flutter test
# 或
make test
```

## 📚 详细文档

- **[CI_SETUP_GUIDE.md](./CI_SETUP_GUIDE.md)** - CI配置详细指南
  - 各种CI平台配置示例（GitHub Actions、GitLab CI、Jenkins、CircleCI）
  - 环境变量配置
  - 缓存优化
  - 故障排查

## 🔐 密钥配置

如需配置Android签名或其他敏感信息，请在GitHub仓库的Settings → Secrets中添加：

### Android签名
- `ANDROID_KEYSTORE_BASE64` - Keystore文件（Base64编码）
- `ANDROID_KEYSTORE_PASSWORD` - Keystore密码
- `ANDROID_KEY_ALIAS` - Key别名
- `ANDROID_KEY_PASSWORD` - Key密码

### 测试覆盖率上传
- `CODECOV_TOKEN` - Codecov token（可选）

## 📈 后续优化建议

- [ ] 添加自动发布到Google Play
- [ ] 添加自动发布到App Store
- [ ] 集成更多代码质量工具（如SonarQube）
- [ ] 添加性能测试
- [ ] 添加UI测试
- [ ] 配置依赖更新自动PR（Dependabot）

## 🤝 贡献

如有改进建议，欢迎提交Issue或Pull Request！

---

**注意**: 首次使用CI时，请确保已在GitHub仓库中启用Actions功能。

