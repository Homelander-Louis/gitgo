[CmdletBinding()]
param(
    [ValidateRange(1, 65535)]
    [int]$Port,
    [switch]$ConfigureGit
)

$ErrorActionPreference = 'Stop'
$commonPorts = @(7890, 7891, 7892, 7893, 7897, 1080, 10808, 10809, 8080, 8118)
$proxyProcessPattern = 'clash|verge|mihomo|v2ray|xray|sing-box|nekoray|shadowsocks'
$candidates = [System.Collections.Generic.List[object]]::new()

function Add-Candidate {
    param([int]$CandidatePort, [string]$Source, [string]$ProcessName = '')
    if ($CandidatePort -lt 1 -or $CandidatePort -gt 65535) { return }
    if ($candidates.Port -contains $CandidatePort) { return }
    $candidates.Add([pscustomobject]@{
        Port = $CandidatePort
        Source = $Source
        ProcessName = $ProcessName
    })
}

if ($PSBoundParameters.ContainsKey('Port')) {
    Add-Candidate -CandidatePort $Port -Source '用户指定'
} else {
    # 优先检查 Git 当前配置，便于快速确认原端口是否仍然有效。
    foreach ($key in @('http.proxy', 'https.proxy')) {
        $value = & git config --global --get $key 2>$null
        if ($value -match '127\.0\.0\.1:(\d+)') {
            Add-Candidate -CandidatePort ([int]$Matches[1]) -Source "Git 配置 $key"
        }
    }

    foreach ($candidatePort in $commonPorts) {
        Add-Candidate -CandidatePort $candidatePort -Source '常见端口'
    }

    # 动态枚举代理进程的监听端口，覆盖 Clash Verge 自定义端口等情况。
    $listeners = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue
    foreach ($listener in $listeners) {
        $process = Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue
        if ($process -and $process.ProcessName -match $proxyProcessPattern) {
            Add-Candidate -CandidatePort $listener.LocalPort -Source '代理进程' -ProcessName $process.ProcessName
        }
    }
}

$selected = $null
foreach ($candidate in $candidates) {
    $listener = Get-NetTCPConnection -State Listen -LocalPort $candidate.Port -ErrorAction SilentlyContinue |
        Where-Object { $_.LocalAddress -in @('127.0.0.1', '0.0.0.0', '::', '::1') } |
        Select-Object -First 1
    if (-not $listener) { continue }

    if (-not $candidate.ProcessName) {
        $candidate.ProcessName = (Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue).ProcessName
    }

    Write-Host "发现监听端口 127.0.0.1:$($candidate.Port) [$($candidate.ProcessName)]，正在验证代理..."
    try {
        $requestParameters = @{
            Method = 'Head'
            Uri = 'https://github.com/'
            Proxy = "http://127.0.0.1:$($candidate.Port)"
            TimeoutSec = 8
            UseBasicParsing = $true
        }
        $response = Invoke-WebRequest @requestParameters
        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
            $selected = $candidate
            break
        }
    } catch {
        Write-Verbose "端口 $($candidate.Port) 代理验证失败：$($_.Exception.Message)"
    }
}

if (-not $selected) {
    throw '未发现能够访问 GitHub 的本机 HTTP 代理。请确认代理软件已启动，或使用 -Port 指定端口。'
}

Write-Host "可用代理：127.0.0.1:$($selected.Port)；进程：$($selected.ProcessName)；来源：$($selected.Source)"

if ($ConfigureGit) {
    $proxyUrl = "http://127.0.0.1:$($selected.Port)"
    & git config --global http.proxy $proxyUrl
    & git config --global https.proxy $proxyUrl

    $existingRewrites = @(& git config --global --get-all 'url.https://github.com/.insteadOf' 2>$null)
    foreach ($rewrite in @('git@github.com:', 'ssh://git@github.com/')) {
        if ($existingRewrites -notcontains $rewrite) {
            & git config --global --add 'url.https://github.com/.insteadOf' $rewrite
        }
    }

    & git ls-remote 'https://github.com/octocat/Hello-World.git' HEAD | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Git 配置已更新，但 GitHub 验证失败。' }
    Write-Host "Git 代理已更新为 $proxyUrl，GitHub 连接正常。"
}

[pscustomobject]@{
    Port = $selected.Port
    ProcessName = $selected.ProcessName
    Source = $selected.Source
    GitConfigured = [bool]$ConfigureGit
}
