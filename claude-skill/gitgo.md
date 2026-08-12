---
name: gitgo（Git 通）
description: 自动发现本机 Clash、Clash Verge、Mihomo、V2Ray 等代理进程的监听端口，配置 Git 代理并验证 GitHub 连接
metadata:
  type: utility
---

# gitgo（Git 通）— 代理配置工具

当用户说“连不上 GitHub”“Git 代理有问题”“换梯子了”“配置代理”“gitgo”或“Git 通”时，使用此 skill。

## 操作步骤

1. 检查当前 Git `http.proxy` 和 `https.proxy` 中的本机端口是否仍在监听。
2. 扫描常见端口：`7890`、`7891`、`7892`、`7893`、`7897`、`1080`、`10808`、`10809`、`8080`、`8118`。
3. 动态枚举 TCP 监听端口，优先识别进程名包含 `clash`、`verge`、`mihomo`、`v2ray`、`xray`、`sing-box`、`nekoray` 或 `shadowsocks` 的端口。
4. Windows 优先运行仓库中的 `scripts/detect-proxy.ps1`；其他环境运行 `gitgo`。
5. 对候选端口逐个执行 HTTP 代理连通测试，使用首个能访问 `https://github.com/` 的端口。
6. 只有动态发现和测试均失败时，才询问用户实际端口。

## Git 配置

```bash
git config --global http.proxy http://127.0.0.1:PORT
git config --global https.proxy http://127.0.0.1:PORT
```

检查 `url.insteadOf` 后补齐缺失值，不要覆盖或重复添加：

```bash
git config --global --add url."https://github.com/".insteadOf "git@github.com:"
git config --global --add url."https://github.com/".insteadOf "ssh://git@github.com/"
```

当前进程需要时再设置 `HTTP_PROXY`、`HTTPS_PROXY`、`http_proxy` 和 `https_proxy`。不要声称临时环境变量会永久保存。

## 验证

```bash
git ls-remote https://github.com/octocat/Hello-World.git HEAD
```

向用户报告检测到的代理进程、端口、配置结果和 GitHub 验证结果。失败时提示检查代理软件或更换节点。
