# KitTUI Mobile Installer

This is the public installation entry point for [KitTUI Mobile Lite](https://github.com/hcloudlab/kittui-mobile). It is currently Beta software. Installer version `v0.1.2` pins core version `v0.2.0-beta.2` and does not execute code from the core repository's `main` branch.

The core source archive is served by a read-only Cloudflare Worker backed by a private R2 bucket. The installer embeds the fixed Worker URL, core version, and release archive SHA256. It reads and extracts the archive only after the integrity check succeeds. Installation requires no Git, GitHub token, R2 credential, or arbitrary download URL.

## One-command install

The fixed installer release is recommended for regular users:

```bash
curl -fsSL \
  https://raw.githubusercontent.com/hcloudlab/hcloudlab-kittui-mobile-installer/v0.1.2/bootstrap.sh |
  sudo bash
```

Select a client:

```bash
curl -fsSL \
  https://raw.githubusercontent.com/hcloudlab/hcloudlab-kittui-mobile-installer/v0.1.2/bootstrap.sh |
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

## Fixed version and integrity

Installer `v0.1.2` accepts only allowlisted core releases. The only currently supported core release is `v0.2.0-beta.2`. Either form below explicitly selects it:

```bash
sudo env KML_CORE_VERSION=0.2.0-beta.2 bash bootstrap.sh install
```

or:

```bash
sudo bash bootstrap.sh --core-version 0.2.0-beta.2 install
```

In addition to character validation, a version must match the installer's fixed allowlist. It cannot override the Worker, bucket, object key, SHA256, or any download URL.

The download chain is:

```text
public installer v0.1.2
  -> fixed HTTPS Worker path
  -> private R2 bucket binding
  -> fixed v0.2.0-beta.2 archive
  -> installer-embedded SHA256 verification
  -> safety checks and install.sh
```

The R2 bucket exposes neither `r2.dev` nor a public bucket domain. The Worker permits GET/HEAD only for the fixed archive and checksum objects. It exposes no listing, arbitrary-key, upload, or delete endpoint.

## Project and support

- Core project: https://github.com/hcloudlab/kittui-mobile
- Installer issues: https://github.com/hcloudlab/hcloudlab-kittui-mobile-installer/issues
- Core issues: https://github.com/hcloudlab/kittui-mobile/issues
