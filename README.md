# KitTUI Mobile Installer

这是 [KitTUI Mobile Lite](https://github.com/hcloudlab/kittui-mobile) 的公开安装入口。当前版本为 Beta，installer 版本为 `v0.1.1`，默认固定下载核心版本 `v0.2.0-beta.2`，不会默认运行核心仓库的 `main` 分支代码。

## 一键安装

普通用户推荐使用固定 installer 版本：

```bash
curl -fsSL \
  https://raw.githubusercontent.com/hcloudlab/hcloudlab-kittui-mobile-installer/v0.1.1/bootstrap.sh |
  sudo bash
```

指定客户端：

```bash
curl -fsSL \
  https://raw.githubusercontent.com/hcloudlab/hcloudlab-kittui-mobile-installer/v0.1.1/bootstrap.sh |
  sudo bash -s -- install --client shadowrocket
```

仅用于测试开发分支，不建议普通用户使用：

```bash
curl -fsSL \
  https://raw.githubusercontent.com/hcloudlab/hcloudlab-kittui-mobile-installer/main/bootstrap.sh |
  sudo bash
```

支持的客户端展示包括：

- Shadowrocket
- v2rayN
- v2rayNG
- Mihomo / Clash Meta
- sing-box

## 部署内容

- VLESS Reality，默认优先使用 `443/TCP`
- Hysteria2，默认优先使用 `443/UDP`
- Ubuntu 22.04 / 24.04
- Debian 11 / 12
- amd64 / arm64

TCP 和 UDP 会独立检测，因此 Reality 和 Hysteria2 可以同时使用数字端口 443。

## 安装后命令

```bash
sudo kittui-mobile status
sudo kittui-mobile show
sudo kittui-mobile repair
sudo kittui-mobile uninstall
```

请在 VPS 服务商控制台确认云防火墙、安全组或前置 ACL 已放行安装结果中显示的 TCP 和 UDP 端口。

节点链接、订阅和二维码包含访问凭据，请勿公开分享、录屏或提交到 GitHub Issue。仅在你拥有管理权限的 VPS 上使用本项目。

## 版本覆盖

普通用户应使用默认固定版本。测试其他已发布核心 Tag 时，可使用：

```bash
sudo env KML_CORE_VERSION=0.2.0-beta.2 bash bootstrap.sh install
```

或：

```bash
sudo bash bootstrap.sh --core-version 0.2.0-beta.2 install
```

版本值只允许字母、数字、点、下划线和连字符，不能覆盖仓库或下载 URL。

`v0.1.1` 仅修复 ShellCheck 0.10.0 的 CI 兼容性，并将默认核心更新到 `v0.2.0-beta.2`；bootstrap 的安全边界、参数透传和临时目录清理行为不变。

## 项目与反馈

- 核心项目：https://github.com/hcloudlab/kittui-mobile
- 安装入口问题：https://github.com/hcloudlab/hcloudlab-kittui-mobile-installer/issues
- 核心功能问题：https://github.com/hcloudlab/kittui-mobile/issues
