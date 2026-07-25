# KitTUI Mobile Installer

This is the public installation entry point for [KitTUI Mobile Lite](https://github.com/hcloudlab/kittui-mobile). It is currently Beta software. Installer version `v0.1.1` pins core version `v0.2.0-beta.2` by default and does not execute code from the core repository's `main` branch.

## One-command install

The fixed installer release is recommended for regular users:

```bash
curl -fsSL \
  https://raw.githubusercontent.com/hcloudlab/hcloudlab-kittui-mobile-installer/v0.1.1/bootstrap.sh |
  sudo bash
```

Select a client:

```bash
curl -fsSL \
  https://raw.githubusercontent.com/hcloudlab/hcloudlab-kittui-mobile-installer/v0.1.1/bootstrap.sh |
  sudo bash -s -- install --client shadowrocket
```

For development-branch testing only; not recommended for regular users:

```bash
curl -fsSL \
  https://raw.githubusercontent.com/hcloudlab/hcloudlab-kittui-mobile-installer/main/bootstrap.sh |
  sudo bash
```

Client-specific output is available for:

- Shadowrocket
- v2rayN
- v2rayNG
- Mihomo / Clash Meta
- sing-box

## What it deploys

- VLESS Reality, preferring `443/TCP`
- Hysteria2, preferring `443/UDP`
- Ubuntu 22.04 / 24.04
- Debian 11 / 12
- amd64 / arm64

TCP and UDP are checked independently, so both protocols may use numeric port 443.

## Commands after installation

```bash
sudo kittui-mobile status
sudo kittui-mobile show
sudo kittui-mobile repair
sudo kittui-mobile uninstall
```

Confirm that any provider cloud firewall, security group, or upstream ACL allows the displayed TCP and UDP ports.

Node links, subscriptions, and QR codes contain access credentials. Do not publish them, record them, or attach them to a GitHub issue. Use this project only on a VPS you are authorized to administer.

## Version override

Regular users should keep the fixed default. To test another published core tag:

```bash
sudo env KML_CORE_VERSION=0.2.0-beta.2 bash bootstrap.sh install
```

or:

```bash
sudo bash bootstrap.sh --core-version 0.2.0-beta.2 install
```

Version values accept only letters, digits, dots, underscores, and hyphens. They cannot override the repository or download URL.

`v0.1.1` changes only ShellCheck 0.10.0 CI compatibility and the default core version to `v0.2.0-beta.2`. Bootstrap security boundaries, argument forwarding, and temporary-directory cleanup behavior are unchanged.

## Project and support

- Core project: https://github.com/hcloudlab/kittui-mobile
- Installer issues: https://github.com/hcloudlab/hcloudlab-kittui-mobile-installer/issues
- Core issues: https://github.com/hcloudlab/kittui-mobile/issues
