# 代理链配置指南

## 场景说明

实现代理链路：**手机 → Proxyman → VPN → 外网**

## 配置步骤

### 1. Proxyman 配置上游代理

#### 方法 A：通过 Proxyman 设置界面

1. 打开 **Proxyman**
2. 菜单栏 → **Proxyman** → **Preferences** (或按 `⌘,`)
3. 选择 **Network** 标签
4. 找到 **Upstream Proxy Settings** 部分
5. 配置如下：
   ```
   ☑️ Enable Upstream Proxy
   Proxy Type: HTTP/HTTPS
   Host: 127.0.0.1
   Port: 7897
   ```
6. 点击 **Apply** 或 **OK**

#### 方法 B：通过 Proxyman Rules（更灵活）

1. 打开 **Proxyman**
2. 菜单栏 → **Tools** → **Breakpoint** → **Rules**
3. 创建新规则：**Add Rule** → **Custom Response**
4. 设置条件：**All requests**
5. 在 **Actions** 中选择 **Upstream Proxy**
6. 配置：
   ```
   Proxy: 127.0.0.1:7897
   ```

### 2. 验证配置

#### 检查 VPN 是否运行

```bash
# 在终端运行，查看7897端口是否被监听
lsof -i :7897
# 或
netstat -an | grep 7897
```

#### 检查 Proxyman 端口

```bash
# 查看Proxyman监听的端口（通常是9090或其他）
lsof -i :9090
```

#### 查看电脑 IP 地址

```bash
# 查看局域网IP
ifconfig | grep "inet " | grep -v 127.0.0.1
# 或
ipconfig getifaddr en0
```

### 3. 手机配置

1. 打开 **设置** → **Wi-Fi**
2. 点击已连接的 WiFi 旁的 **ⓘ** 图标
3. 滚动到底部，找到 **HTTP 代理**
4. 选择 **手动**
5. 配置：
   ```
   服务器: 192.168.x.x  (你的电脑IP)
   端口: 9090          (Proxyman的端口)
   ```
6. 保存

### 4. 测试流量链路

在 Proxyman 中应该能看到：

```
手机请求 → Proxyman拦截 → 转发到127.0.0.1:7897(VPN) → 外网
```

## 常见问题

### Q1: Proxyman 没有上游代理选项？

**解决方案：** 升级到最新版本的 Proxyman，或使用 **External Proxy Tool** 功能。

### Q2: 流量没有走 VPN

**排查步骤：**

1. 确认 VPN 正在运行（端口 7897 监听中）
2. 确认 Proxyman 的上游代理配置正确
3. 在 Proxyman 中查看请求的 **Upstream Proxy** 信息
4. 测试直接访问外网地址，看是否被墙

### Q3: 需要针对特定域名走 VPN

**解决方案：** 在 Proxyman Rules 中配置：

```
If URL matches: *.google.com
Then: Use Upstream Proxy 127.0.0.1:7897

If URL matches: *.local.com
Then: Direct Connection
```

### Q4: 如何在代码中强制走 VPN？

修改 `lib/main.dart`：

```dart
const String proxyHost = '127.0.0.1';
const int proxyPort = 7897;
const bool enableProxy = true;  // 启用
```

**注意：** 真机调试时，WiFi 代理会覆盖代码中的配置，建议优先使用 Proxyman 配置。

## 代理链路图

```
┌─────────┐
│  手机   │
│  App    │
└────┬────┘
     │ WiFi代理: 电脑IP:9090
     ↓
┌─────────────┐
│  Proxyman   │ (电脑)
│  端口: 9090 │
└──────┬──────┘
       │ 上游代理: 127.0.0.1:7897
       ↓
┌─────────────┐
│  VPN 代理   │ (电脑)
│  端口: 7897 │
└──────┬──────┘
       │
       ↓
   ┌───────┐
   │ 外网  │
   └───────┘
```

## 备选方案：使用命令行代理链

如果不想用 Proxyman 的上游代理功能，可以使用 **privoxy** 或 **tinyproxy** 等工具实现代理链。

### 安装 privoxy

```bash
brew install privoxy
```

### 配置 privoxy

编辑 `/usr/local/etc/privoxy/config`：

```
forward / 127.0.0.1:7897
listen-address 0.0.0.0:8118
```

### 启动 privoxy

```bash
brew services start privoxy
```

然后手机 WiFi 代理指向：`电脑IP:8118`

---

## 总结

**推荐方案：** 在 Proxyman 中配置上游代理到 VPN，这是最简单直接的方式。

代码中的 `enableProxy = false` 保持关闭状态，因为 WiFi 代理已经生效。

