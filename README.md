# KitTUI Mobile Installer

这是 [KitTUI Mobile Lite](https://github.com/hcloudlab/kittui-mobile) 的公开安装入口。当前版本为 Beta，installer 版本为 `v0.1.3`，默认固定下载核心版本 `v0.2.0-beta.3`，不会运行核心仓库的 `main` 分支代码。

核心源码归档由只读 Cloudflare Worker 从私有 R2 bucket 提供。installer 内嵌固定 Worker 下载地址、核心版本和发布归档 SHA256；只有完整性校验通过后才会读取并解压归档。安装流程不需要 Git、GitHub Token、R2 密钥或任意下载 URL。

## 一键安装

普通用户推荐使用固定 installer 版本：

```bash
curl -fsSL \
  https://raw.githubusercontent.com/hcloudlab/hcloudlab-kittui-mobile-installer/v0.1.3/bootstrap.sh |
  sudo bash -s -- install
```

指定客户端：

```bash
curl -fsSL \
  https://raw.githubusercontent.com/hcloudlab/hcloudlab-kittui-mobile-installer/v0.1.3/bootstrap.sh |
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

## 固定版本与完整性

`v0.1.3` 只允许下载受支持列表中的核心版本。目前唯一允许的核心版本为 `v0.2.0-beta.3`。以下两种写法用于显式确认该版本：

```bash
sudo env KML_CORE_VERSION=0.2.0-beta.3 bash bootstrap.sh install
```

或：

```bash
sudo bash bootstrap.sh --core-version 0.2.0-beta.3 install
```

版本值除字符校验外还必须命中 installer 的固定允许列表，不能覆盖 Worker、bucket、对象 key、SHA256 或任意下载 URL。

下载链路为：

```text
公开 installer v0.1.3
  -> 固定 HTTPS Worker 路径
  -> 私有 R2 bucket binding
  -> 固定 v0.2.0-beta.3 归档
  -> installer 内嵌 SHA256 校验
  -> 安全检查并执行 install.sh
```

R2 bucket 不开启 `r2.dev` 或公开 bucket 域名。Worker 只允许 GET/HEAD 访问固定归档和校验文件，不提供目录列表、任意 key、上传或删除接口。

## 项目与反馈

- 核心项目：https://github.com/hcloudlab/kittui-mobile
- 安装入口问题：https://github.com/hcloudlab/hcloudlab-kittui-mobile-installer/issues
- 核心功能问题：https://github.com/hcloudlab/kittui-mobile/issues
