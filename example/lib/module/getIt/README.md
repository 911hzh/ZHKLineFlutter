# getIt 目录说明

`getIt` 用于维护依赖注入配置，集中注册 example 工程运行时需要的对象。当前工程结合 `get_it` 和 `injectable` 使用，既包含自动生成的注册代码，也包含手写的 module 注册。

## 当前内容

- `Injection.dart`：GetIt 实例和依赖初始化入口。
- `Injection.config.dart`：`injectable` 生成的依赖注册代码。
- `RegisterModule.dart`：手写依赖注册，例如 `RestClient`、Repository、网络代理和证书配置。
- `GetItInstanceName.dart`：命名实例的名称定义。

## 使用约定

新增 Port 实现、Store、SDK 适配器或基础服务时，应在这里完成注册，让模块层通过依赖注入获取对象。生成文件由构建工具维护，手写注册逻辑放在 `RegisterModule.dart` 或同职责文件中。
