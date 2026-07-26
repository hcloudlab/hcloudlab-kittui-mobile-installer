# Changelog

## [0.1.3] - 2026-07-25

### Changed

- 固定核心版本更新为 `v0.2.0-beta.3`，并内嵌实际发布归档 SHA256。
- Worker allowlist 新增 beta.3 归档与校验文件，同时保留 beta.2 只读访问。

### Security

- 新增硬链接归档拒绝测试；继续拒绝路径穿越、符号链接、损坏归档、缺少必需文件和 SHA256 不匹配。
- Worker 继续仅允许 GET/HEAD 访问硬编码对象，不开放目录列表、任意 key、上传或删除接口。

## [0.1.2] - 2026-07-25

### Changed

- 将核心分发从 GitHub Tag archive 迁移到只读 Cloudflare Worker 和私有 R2 bucket。
- 固定核心 `v0.2.0-beta.2` 的 Worker 路径和 SHA256，不再接受未列入允许列表的核心版本。
- 在读取、列出或解压源码前强制校验 installer 内嵌 SHA256。
- 保留 TLS、重试、参数透传、真实退出码和成功/失败临时目录清理。

### Added

- 新增 `worker/` TypeScript Worker、私有 R2 binding、固定路径 allowlist 和离线单元测试。
- 新增 checksum mismatch、损坏归档、路径穿越、链接归档、未知版本和 Worker 方法/路径回归测试。
- CI 新增 ShellCheck 0.10/0.11、Bats 1.10/1.13 和 Worker npm/typecheck/dry-run 门禁。

### Security

- R2 bucket 保持私有，未启用 `r2.dev` 或公开 bucket 域名。
- Worker 仅允许 GET/HEAD 访问固定对象，不支持列目录、任意 key、PUT、POST、PATCH 或 DELETE。
- installer 不包含 GitHub/Cloudflare 凭据、账户标识或任意下载 URL 覆盖。

## [0.1.1] - 2026-07-25

### Fixed

- 为 trap 间接调用的 cleanup 函数增加精确的 ShellCheck 0.10.0 `SC2317` 豁免，保留原有清理逻辑。
- 将 GitHub Actions 固定为 Ubuntu 24.04、ShellCheck 0.10.0 和 Bats 1.10.0。
- 测试夹具保存稳定临时目录变量，并只清理测试自行创建的目录，以兼容旧版 Bats。
- 将默认核心版本更新为不可变的 `v0.2.0-beta.2`。
- 更新中英文固定版安装命令与版本覆盖示例。
- 本修订不改变 bootstrap 安全边界、参数透传或临时目录清理行为。

## [0.1.0] - 2026-07-25

### Added

- 首个独立公开 installer 版本。
- 从固定核心 Tag 下载完整源码归档，不依赖 Git。
- 校验归档路径和核心必需文件后，从真实解压目录执行 `install.sh`。
- 完整透传核心安装参数并保留真实退出码。
- 成功或失败均清理临时源码。
