---
name: gitgo
description: 自动发现本机 Clash、Clash Verge、Mihomo、V2Ray 等代理进程的监听端口，配置 Git 代理并验证 GitHub 连接。用户提到 gitgo、Git 通、GitHub 无法连接、Git 代理失效、换梯子或配置代理时使用。
---

# gitgo（Git 通）

按以下顺序检测代理端口，禁止只扫描固定端口后就判定代理未运行：

1. 检查当前 Git `http.proxy` 和 `https.proxy` 中的本机端口是否仍在监听。
2. 检查常见端口：`7890`、`7891`、`7892`、`7893`、`7897`、`1080`、`10808`、`10809`、`8080`、`8118`。
3. 动态枚举本机 TCP 监听端口，并优先选取进程名包含 `clash`、`verge`、`mihomo`、`v2ray`、`xray`、`sing-box`、`nekoray` 或 `shadowsocks` 的端口。
4. Windows 优先运行 `scripts/detect-proxy.ps1`。其他环境运行 `gitgo`。
5. 若发现多个候选端口，逐个验证其是否能作为 HTTP 代理访问 `https://github.com/`，使用首个验证成功的端口。
6. 只有动态发现和连通测试都失败时，才询问用户实际代理端口。

发现可用端口后执行：

```bash
git config --global http.proxy http://127.0.0.1:PORT
git config --global https.proxy http://127.0.0.1:PORT
git config --global --add url."https://github.com/".insteadOf "git@github.com:"
git config --global --add url."https://github.com/".insteadOf "ssh://git@github.com/"
```

不要重复添加已有的 `insteadOf` 值。当前进程需要代理环境变量时，再设置 `HTTP_PROXY`、`HTTPS_PROXY`、`http_proxy` 和 `https_proxy`；不要声称临时环境变量会永久保存。

最后验证：

```bash
git ls-remote https://github.com/octocat/Hello-World.git HEAD
```

向用户报告检测到的进程、端口、Git 配置结果和 GitHub 验证结果。若失败，保留诊断输出并提示检查代理软件或节点。
