<div align="center">
  <img src="docs/assets/logo.svg" width="110" alt="VPS Doctor 标志">
  <h1>VPS Doctor</h1>
  <p><strong>一条命令诊断常见 VPS 故障，然后安全地修复。</strong></p>
  <p><a href="README.md">English</a> · <a href="docs/rules.md">检查规则</a> · <a href="docs/repairs.md">修复安全</a> · <a href="docs/release-verification.md">Release 校验</a> · <a href="ROADMAP.md">路线图</a></p>
</div>

![VPS Doctor 终端演示](docs/assets/terminal-demo.svg)

VPS Doctor 是一个“默认只读”的 Linux 服务器诊断工具，适合小型 VPS、家庭实验室和自托管服务。它把分散的系统信息整理成健康分数、可执行建议和经过脱敏的诊断报告。

## 它解决什么问题

服务器变慢、磁盘爆满或网站打不开时，新手通常需要到处搜索并执行许多命令。VPS Doctor 一次检查完整故障链：

`磁盘 → 内存 → 服务 → 网络 → SSH → 防火墙 → Docker → 网站/TLS`

扫描过程中不会安装常驻程序、开放端口、上传遥测数据或修改系统。

## 快速开始

在克隆后的项目目录中运行：

```bash
sudo bash ./install.sh
sudo vps-doctor scan
```

临时测试环境也可以直接获取安装脚本：

```bash
curl -fsSL https://raw.githubusercontent.com/wcnmd666/vps-doctor/main/install.sh | sudo bash
```

正式服务器建议下载带版本号的 Release 与同一 Release 中的 `SHA256SUMS`，核对校验值和 GitHub 构建来源证明，阅读安装脚本后再从已验证的本地副本安装。详见 [Release 校验说明](docs/release-verification.md)。不建议在生产环境盲目信任任何通过网络直接传给 root 的可变脚本。

## 主要能力

- 检查 CPU、内存、Swap、磁盘空间和 inode；
- 检查 OOM、失败的 systemd 服务和待重启状态；
- 检查默认路由、DNS 和监听端口；
- 检查防火墙、SSH 策略、暴力登录记录和自动安全更新；
- 检查 Docker 服务、异常容器和过大的容器日志；
- 检查 Nginx、Apache、Caddy，以及可选的域名和 TLS 证书；
- 输出终端、JSON、Markdown 和独立离线 HTML 报告；
- 支持可验证阈值配置与带原因的规则排除；
- 每项问题都有固定规则编号、证据、严重程度和建议。

## 常用命令

```bash
sudo vps-doctor scan
sudo vps-doctor scan --quick
sudo vps-doctor scan --format json --output report.json
sudo vps-doctor scan --format markdown --output report.md
sudo vps-doctor scan --format html --output report.html
sudo vps-doctor scan --fail-under 75
```

HTML 报告完全离线，系统来源文本会先转义，并使用严格的 Content Security Policy，不加载第三方脚本、字体、跟踪器或其他远程资源。

## 安全修复

扫描永远只读。修复命令与扫描分开，必须使用 root、明确显示操作内容并经过确认：

```bash
sudo vps-doctor fixes
sudo vps-doctor fix vacuum-journal --dry-run
sudo vps-doctor fix vacuum-journal
sudo vps-doctor fix create-swap --size 2G
```

工具会拒绝危险猜测：不会自动合并已有的 Docker JSON 配置，不会贸然启用可能导致 SSH 失联的防火墙，也不会自动修改 SSH 登录策略。详见 [修复安全说明](docs/repairs.md)。

## 隐私

项目没有遥测。终端、JSON、Markdown 与 HTML 报告会尽力隐藏当前用户名、主机名、IPv4、部分常见 IPv6 形式、常见密钥赋值以及常见 Authorization/Bearer 凭证。自动脱敏属于纵深防御，不可能覆盖所有情况，公开报告前仍需人工检查。详见 [隐私说明](docs/privacy.md)。

## 支持范围

重点支持 Ubuntu 20.04/22.04/24.04 和 Debian 11/12/13；其他使用 systemd 的 Linux 会以尽力而为方式运行。需要 Bash 4.4 或更高版本。

## 项目状态

`v0.2.0` 重点增强“可复现诊断证据”和维护安全性：加入离线 HTML 报告、配置校验与可审计规则排除、Ubuntu/Debian 确定性测试场景、强化后的 CI/Release 流程、可验证的 Release 构建来源以及更严格的报告隐私保护。诊断结果仍然不是安全认证，请先在临时服务器验证修复功能。
