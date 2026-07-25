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

The public `bootstrap.sh` can be reviewed before execution. A fixed installer release, fixed core version, fixed Worker path, and embedded SHA256 are safer and more reproducible than directly running changing `main` branch content.

The bootstrap downloads only the allowlisted `v0.2.0-beta.2` archive through the read-only HTTPS Worker. It verifies the installer-embedded SHA256 before listing or extracting the archive, rejects unsafe paths and links, and then verifies required files.

The R2 bucket remains private. Public bucket access and `r2.dev` are disabled. The Worker exposes only `/healthz` plus the fixed archive and checksum paths over GET/HEAD; it has no listing, arbitrary-key, write, or delete route.

The installer and Worker contain no GitHub token, Cloudflare credential, R2 access key, account identifier, or arbitrary URL override. Report a checksum mismatch or unexpected Worker response without attaching downloaded node credentials.
