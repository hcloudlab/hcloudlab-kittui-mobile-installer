#!/usr/bin/env bash
set -euo pipefail

readonly KML_CORE_REPOSITORY="hcloudlab/kittui-mobile"
readonly KML_DEFAULT_CORE_VERSION="0.2.0-beta.2"

kml_error() {
  printf '错误：%s\n' "$*" >&2
}

kml_die() {
  kml_error "$*"
  exit 1
}

kml_validate_core_version() {
  local version="$1"

  [[ -n "$version" ]] || kml_die "核心版本不能为空。"
  [[ "$version" != *[!A-Za-z0-9._-]* ]] ||
    kml_die "核心版本包含不允许的字符：$version"
  [[ "$version" == [A-Za-z0-9]* ]] ||
    kml_die "核心版本必须以字母或数字开头：$version"
}

kml_require_commands() {
  local command_name

  for command_name in id curl tar mktemp; do
    command -v "$command_name" >/dev/null 2>&1 ||
      kml_die "缺少必需命令：$command_name"
  done
}

kml_parse_args() {
  KML_SELECTED_CORE_VERSION="${KML_CORE_VERSION:-$KML_DEFAULT_CORE_VERSION}"
  KML_INSTALL_ARGS=()
  local version_option_seen="false"

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --core-version)
        [[ "$version_option_seen" == "false" ]] ||
          kml_die "--core-version 不得重复指定。"
        shift
        [[ -n "${1:-}" ]] || kml_die "--core-version 需要版本参数。"
        KML_SELECTED_CORE_VERSION="$1"
        version_option_seen="true"
        ;;
      --core-version=*)
        [[ "$version_option_seen" == "false" ]] ||
          kml_die "--core-version 不得重复指定。"
        [[ -n "${1#*=}" ]] || kml_die "--core-version 需要版本参数。"
        KML_SELECTED_CORE_VERSION="${1#*=}"
        version_option_seen="true"
        ;;
      --)
        shift
        KML_INSTALL_ARGS+=("$@")
        break
        ;;
      *)
        KML_INSTALL_ARGS+=("$1")
        ;;
    esac
    shift || true
  done

  kml_validate_core_version "$KML_SELECTED_CORE_VERSION"
}

kml_core_tag() {
  if [[ "$KML_SELECTED_CORE_VERSION" == v* ]]; then
    printf '%s\n' "$KML_SELECTED_CORE_VERSION"
  else
    printf 'v%s\n' "$KML_SELECTED_CORE_VERSION"
  fi
}

# shellcheck disable=SC2317,SC2329
kml_cleanup() {
  local exit_code="$?"

  if [[ -n "${KML_TEMP_DIR:-}" && -d "$KML_TEMP_DIR" ]]; then
    rm -rf -- "$KML_TEMP_DIR"
  fi
  exit "$exit_code"
}

kml_validate_archive_paths() {
  local archive_list="$1" entry

  while IFS= read -r entry; do
    case "$entry" in
      /*|../*|*/../*|*/..)
        kml_die "源码压缩包包含不安全路径，已停止。"
        ;;
    esac
  done < "$archive_list"
}

kml_find_source_root() {
  local extract_dir="$1"
  local entries=()

  shopt -s nullglob dotglob
  entries=("$extract_dir"/*)
  shopt -u nullglob dotglob
  [[ "${#entries[@]}" -eq 1 && -d "${entries[0]}" && ! -L "${entries[0]}" ]] ||
    kml_die "源码压缩包目录结构无效。"
  printf '%s\n' "${entries[0]}"
}

kml_verify_source_tree() {
  local source_root="$1" required_file
  local required_files=(
    install.sh
    lib/main.sh
    lib/client_output.sh
    lib/permissions.sh
  )

  for required_file in "${required_files[@]}"; do
    [[ -f "$source_root/$required_file" && ! -L "$source_root/$required_file" ]] ||
      kml_die "源码归档缺少必需文件：$required_file"
  done
}

kml_main() {
  local temp_base archive_file archive_list extract_dir source_root core_tag source_url install_status

  kml_parse_args "$@"
  kml_require_commands
  [[ "$(id -u)" == "0" ]] || kml_die "请使用 root 权限运行，例如：curl ... | sudo bash"

  temp_base="${TMPDIR:-/tmp}"
  [[ "$temp_base" == "/" ]] || temp_base="${temp_base%/}"
  KML_TEMP_DIR="$(mktemp -d "$temp_base/kittui-mobile-installer.XXXXXX")" ||
    kml_die "无法创建安全临时目录。"
  trap kml_cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM

  archive_file="$KML_TEMP_DIR/source.tar.gz"
  archive_list="$KML_TEMP_DIR/archive.list"
  extract_dir="$KML_TEMP_DIR/source"
  mkdir -p "$extract_dir"

  core_tag="$(kml_core_tag)"
  source_url="https://github.com/$KML_CORE_REPOSITORY/archive/refs/tags/$core_tag.tar.gz"
  if ! curl -fL --proto '=https' --tlsv1.2 --retry 3 --connect-timeout 15 \
    -o "$archive_file" "$source_url"; then
    kml_die "核心源码下载失败：$core_tag"
  fi

  if ! tar -tzf "$archive_file" > "$archive_list"; then
    kml_die "核心源码压缩包无法读取。"
  fi
  kml_validate_archive_paths "$archive_list"
  if ! tar -xzf "$archive_file" -C "$extract_dir"; then
    kml_die "核心源码压缩包解压失败。"
  fi

  source_root="$(kml_find_source_root "$extract_dir")"
  kml_verify_source_tree "$source_root"

  set +e
  (
    cd "$source_root"
    bash install.sh "${KML_INSTALL_ARGS[@]}"
  )
  install_status="$?"
  set -e
  exit "$install_status"
}

kml_main "$@"
