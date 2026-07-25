# Security Policy

## Reporting issues

Do not include complete node links, subscriptions, or QR codes in a public issue.

Never submit:

- VLESS UUIDs;
- Hysteria2 passwords;
- Reality private keys;
- a usable Reality public-key and Short-ID credential set;
- VPS root passwords;
- SSH private keys;
- GitHub, R2, or other API credentials.

Redact server IP addresses and all node credentials before sharing logs or screenshots. Describe the failure stage and provide sanitized command output only.

Security-sensitive reports can be opened with minimal public detail at:

https://github.com/hcloudlab/hcloudlab-kittui-mobile-installer/issues

## Installation safety

The public `bootstrap.sh` can be reviewed before execution. A fixed installer release and fixed core version are safer and more reproducible than directly running changing `main` branch content.

The bootstrap downloads only a validated, fixed Tag archive from the public `hcloudlab/kittui-mobile` repository. It does not contain a GitHub token and does not access a private repository.
