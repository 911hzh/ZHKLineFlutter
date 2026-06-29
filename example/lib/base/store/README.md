# store 目录说明

`store` 用于放置状态存储、持久化和示例数据管理代码。这里的代码通常封装 `flutter_foundation_kit` 提供的 Repository、KeyChain、Preference 等基础能力，供模块层直接使用。

## 当前内容

- `auth/`：认证相关 Store 示例，例如 token 或登录状态的保存。
- `user/`：用户信息 Store 示例。
- `settings/`：设置项模型、配置读取和环境配置示例。

## 使用约定

Store 负责数据读写和状态维护，页面与 Cubit 可以调用 Store，但持久化细节应尽量留在 Store 内部，避免散落到模块页面中。
