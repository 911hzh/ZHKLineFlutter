# Makefile 使用说明

仓库现在有两个实际入口：

- 根目录 `Makefile`：只负责 package 自身的依赖、测试、分析、格式化
- `example/Makefile`：只负责 example 的代码生成和编译

## 根目录命令

```bash
make get            # 获取根 package 依赖
make test           # 运行根 package 测试
make analyze        # 分析根 package
make format         # 格式化 lib/ 和 test/
make format-check   # 检查格式
make clean          # 清理并重新拉依赖
make deep-clean     # 深度清理
make watch          # 监听根目录代码生成
make check-version  # 检查 Flutter 环境
```

## example 命令

```bash
cd example
make gen            # 运行 example 代码生成
make watch          # 监听 example 代码生成
make build-web      # 构建 example Web
```

## CI 对应关系

GitHub Actions 当前拆成两个 job：

- package check：根目录执行 `make get`、`make analyze`、`make test`
- example build web：`cd example` 后执行 `make gen`、`make build-web`

## 推荐用法

提交前先在根目录执行：

```bash
make analyze
make test
```

如果改了 `example/` 的注入或页面代码，再补一遍：

```bash
cd example
make gen
make build-web
```
