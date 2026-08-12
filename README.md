# gitgo（Git 通）

自动发现本机代理端口，配置 Git 代理，并验证 GitHub 连接。

支持 Clash、Clash Verge、Mihomo、v2rayN、Xray、Shadowsocks、Nekoray、sing-box 等代理程序。除常见端口扫描外，还会根据代理进程动态发现自定义监听端口，例如 Clash Verge 的 `7897`。

## 功能

- 检查 Git 当前配置的代理端口是否仍然有效
- 扫描常见代理端口
- 根据代理进程动态发现监听端口
- 验证候选端口是否能作为 HTTP 代理访问 GitHub
- 配置 Git `http.proxy` 和 `https.proxy`
- 将 GitHub SSH 地址自动改写为 HTTPS
- Bash 版本同步配置 npm 代理
- 使用 `git ls-remote` 验证最终连接

## 安装

### Codex Skill

在 Codex 中提供本仓库地址并要求安装：

```text
请安装这个 skill：https://github.com/Homelander-Louis/gitgo
```

仓库根目录的 `SKILL.md` 是 Codex 标准技能入口。

### Claude Code Skill

将以下地址交给 Claude Code 安装：

```text
https://raw.githubusercontent.com/Homelander-Louis/gitgo/master/claude-skill/gitgo.md
```

### 独立脚本

macOS / Linux：

```bash
sudo curl -o /usr/local/bin/gitgo https://raw.githubusercontent.com/Homelander-Louis/gitgo/master/gitgo
sudo chmod +x /usr/local/bin/gitgo
```

Windows Git Bash：

```bash
mkdir -p ~/bin
curl -o ~/bin/gitgo https://raw.githubusercontent.com/Homelander-Louis/gitgo/master/gitgo
chmod +x ~/bin/gitgo
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
```

Windows PowerShell 可直接下载并运行检测器：

```powershell
Invoke-WebRequest `
  -Uri 'https://raw.githubusercontent.com/Homelander-Louis/gitgo/master/scripts/detect-proxy.ps1' `
  -OutFile "$env:TEMP\detect-proxy.ps1"
& "$env:TEMP\detect-proxy.ps1" -ConfigureGit
```

## 使用

Bash：

```bash
gitgo           # 自动发现并配置
gitgo 7897      # 指定端口并验证
```

PowerShell：

```powershell
.\scripts\detect-proxy.ps1                 # 只检测，不修改 Git
.\scripts\detect-proxy.ps1 -ConfigureGit   # 检测、配置并验证
.\scripts\detect-proxy.ps1 -Port 7897 -ConfigureGit
```

## 常见端口

| 软件 | 常见 HTTP/混合代理端口 |
|---|---:|
| Clash / Clash Verge / Mihomo | 7890、7892、7897 |
| v2rayN / Xray | 10808、10809 |
| Shadowsocks / SSR | 1080 |
| Privoxy | 8118 |

端口不在表中也可以被动态发现；若代理进程名称无法识别，可显式指定端口。
