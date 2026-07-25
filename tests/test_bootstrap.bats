#!/usr/bin/env bats

setup() {
  export PROJECT_ROOT="$BATS_TEST_DIRNAME/.."
  export KML_INSTALLER_TEST_TMPDIR="${BATS_TEST_TMPDIR:-}"
  export KML_INSTALLER_TEST_TMPDIR_CREATED=false
  if [[ -z "$KML_INSTALLER_TEST_TMPDIR" ]]; then
    KML_INSTALLER_TEST_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/kittui-mobile-installer-bats.XXXXXX")"
    export KML_INSTALLER_TEST_TMPDIR
    KML_INSTALLER_TEST_TMPDIR_CREATED=true
  fi
  export MOCK_BIN="$KML_INSTALLER_TEST_TMPDIR/bin"
  export MOCK_RECORD_DIR="$KML_INSTALLER_TEST_TMPDIR/record"
  export MOCK_ARCHIVE="$KML_INSTALLER_TEST_TMPDIR/core.tar.gz"
  export TMPDIR="$KML_INSTALLER_TEST_TMPDIR/temp"
  export ORIGINAL_PATH="$PATH"
  mkdir -p "$MOCK_BIN" "$MOCK_RECORD_DIR" "$TMPDIR"

  cat > "$MOCK_BIN/id" <<'EOF'
#!/usr/bin/env bash
if [[ "${MOCK_NON_ROOT:-false}" == "true" ]]; then
  printf '1000\n'
else
  printf '0\n'
fi
EOF

  cat > "$MOCK_BIN/curl" <<'EOF'
#!/usr/bin/env bash
output_file=""
source_url=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -o)
      output_file="$2"
      shift 2
      ;;
    --proto|--retry|--connect-timeout)
      shift 2
      ;;
    -*)
      shift
      ;;
    *)
      source_url="$1"
      shift
      ;;
  esac
done
printf '%s\n' "$source_url" > "$MOCK_RECORD_DIR/url"
[[ "${MOCK_DOWNLOAD_FAIL:-false}" != "true" ]] || exit 22
cp "$MOCK_ARCHIVE" "$output_file"
EOF

  chmod +x "$MOCK_BIN/id" "$MOCK_BIN/curl"
  export PATH="$MOCK_BIN:$ORIGINAL_PATH"
  unset KML_CORE_VERSION MOCK_NON_ROOT MOCK_DOWNLOAD_FAIL MOCK_INSTALL_EXIT
}

teardown() {
  if [[ "${KML_INSTALLER_TEST_TMPDIR_CREATED:-false}" == "true" &&
    -n "${KML_INSTALLER_TEST_TMPDIR:-}" && -d "$KML_INSTALLER_TEST_TMPDIR" ]]; then
    rm -rf -- "$KML_INSTALLER_TEST_TMPDIR"
  fi
}

create_mock_archive() {
  local mode="${1:-complete}"
  local source_root="$KML_INSTALLER_TEST_TMPDIR/archive/kittui-mobile-v0.2.0-beta.2"

  mkdir -p "$source_root/lib"
  cat > "$source_root/install.sh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$MOCK_RECORD_DIR/args"
pwd > "$MOCK_RECORD_DIR/pwd"
exit "${MOCK_INSTALL_EXIT:-0}"
EOF
  printf '%s\n' '# fake main' > "$source_root/lib/main.sh"
  if [[ "$mode" != "missing-client-output" ]]; then
    printf '%s\n' '# fake client output' > "$source_root/lib/client_output.sh"
  fi
  printf '%s\n' '# fake permissions' > "$source_root/lib/permissions.sh"
  tar -czf "$MOCK_ARCHIVE" -C "$KML_INSTALLER_TEST_TMPDIR/archive" .
}

assert_temp_clean() {
  local leftovers
  leftovers="$(find "$TMPDIR" -maxdepth 1 -name 'kittui-mobile-installer.*' -print)"
  [ -z "$leftovers" ]
}

@test "default version URL is fixed to the released core tag" {
  create_mock_archive

  run bash "$PROJECT_ROOT/bootstrap.sh" --help
  [ "$status" -eq 0 ]
  [ "$(cat "$MOCK_RECORD_DIR/url")" = \
    "https://github.com/hcloudlab/kittui-mobile/archive/refs/tags/v0.2.0-beta.2.tar.gz" ]
}

@test "VERSION identifies the installer release" {
  local version
  version="$(tr -d '[:space:]' < "$PROJECT_ROOT/VERSION")"

  [ "$version" = "0.1.1" ]
}

@test "bootstrap default core version is the repaired immutable release" {
  grep -Fq 'KML_DEFAULT_CORE_VERSION="0.2.0-beta.2"' "$PROJECT_ROOT/bootstrap.sh"
}

@test "install arguments pass through unchanged" {
  create_mock_archive

  run bash "$PROJECT_ROOT/bootstrap.sh" install --client shadowrocket --no-firewall
  [ "$status" -eq 0 ]
  [ "$(sed -n '1p' "$MOCK_RECORD_DIR/args")" = "install" ]
  [ "$(sed -n '2p' "$MOCK_RECORD_DIR/args")" = "--client" ]
  [ "$(sed -n '3p' "$MOCK_RECORD_DIR/args")" = "shadowrocket" ]
  [ "$(sed -n '4p' "$MOCK_RECORD_DIR/args")" = "--no-firewall" ]
}

@test "core version supports controlled environment and parameter overrides" {
  create_mock_archive

  KML_CORE_VERSION="0.2.0-beta.3" run bash "$PROJECT_ROOT/bootstrap.sh" --help
  [ "$status" -eq 0 ]
  [[ "$(cat "$MOCK_RECORD_DIR/url")" == *"/v0.2.0-beta.3.tar.gz" ]]

  run bash "$PROJECT_ROOT/bootstrap.sh" --core-version=v0.2.0-beta.4 --help
  [ "$status" -eq 0 ]
  [[ "$(cat "$MOCK_RECORD_DIR/url")" == *"/v0.2.0-beta.4.tar.gz" ]]
}

@test "unsafe core versions are rejected before download" {
  local version
  create_mock_archive

  for version in "" "../main" "https://example.com/a" "v1;id" "bad value"; do
    run bash "$PROJECT_ROOT/bootstrap.sh" --core-version "$version" --help
    [ "$status" -ne 0 ]
  done
}

@test "installer exit code is preserved and temporary source is removed" {
  create_mock_archive
  export MOCK_INSTALL_EXIT=37

  run bash "$PROJECT_ROOT/bootstrap.sh" install
  [ "$status" -eq 37 ]
  assert_temp_clean
}

@test "successful execution removes temporary source" {
  create_mock_archive

  run bash "$PROJECT_ROOT/bootstrap.sh" --help
  [ "$status" -eq 0 ]
  assert_temp_clean
}

@test "download failure is nonzero and cleans temporary source" {
  create_mock_archive
  export MOCK_DOWNLOAD_FAIL=true

  run bash "$PROJECT_ROOT/bootstrap.sh" --help
  [ "$status" -ne 0 ]
  [[ "$output" == *"核心源码下载失败"* ]]
  assert_temp_clean
}

@test "archive missing a required file is rejected" {
  create_mock_archive missing-client-output

  run bash "$PROJECT_ROOT/bootstrap.sh" --help
  [ "$status" -ne 0 ]
  [[ "$output" == *"lib/client_output.sh"* ]]
  assert_temp_clean
}

@test "non-root execution stops before download" {
  create_mock_archive
  export MOCK_NON_ROOT=true

  run bash "$PROJECT_ROOT/bootstrap.sh" --help
  [ "$status" -ne 0 ]
  [[ "$output" == *"root 权限"* ]]
  [ ! -e "$MOCK_RECORD_DIR/url" ]
}

@test "bootstrap runs from stdin without BASH_SOURCE" {
  create_mock_archive

  run bash -c 'cat "$PROJECT_ROOT/bootstrap.sh" | bash -s -- install --client skip'
  [ "$status" -eq 0 ]
  [ "$(sed -n '1p' "$MOCK_RECORD_DIR/args")" = "install" ]
  [ "$(sed -n '2p' "$MOCK_RECORD_DIR/args")" = "--client" ]
  [ "$(sed -n '3p' "$MOCK_RECORD_DIR/args")" = "skip" ]
}

@test "bootstrap contains no token unsafe curl eval or BASH_SOURCE dependency" {
  if grep -Eq 'gh''p_[A-Za-z0-9]+|github_''pat_|gh''o_[A-Za-z0-9]+' "$PROJECT_ROOT/bootstrap.sh"; then
    false
  fi
  if grep -Eq 'curl[[:space:]].*-k|curl[[:space:]].*--insecure' "$PROJECT_ROOT/bootstrap.sh"; then
    false
  fi
  if grep -Eq '(^|[[:space:]])eval([[:space:]]|$)|BASH_SOURCE' "$PROJECT_ROOT/bootstrap.sh"; then
    false
  fi
}

@test "bootstrap shell syntax is valid" {
  run bash -n "$PROJECT_ROOT/bootstrap.sh"
  [ "$status" -eq 0 ]
}
