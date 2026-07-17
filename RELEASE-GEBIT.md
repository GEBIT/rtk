# RELEASE-GEBIT

This guide describes how to build and package a GEBIT release of RTK with telemetry routed to the on-premise telemetry server.

## Scope

Use this document when you need to create release artifacts (local or CI) for GEBIT distribution.

## 1. Prerequisites

- Rust toolchain installed (`rustup`, `cargo`)
- Git working tree on the release commit/tag
- Access to on-prem telemetry endpoint URL
- Release token for telemetry header (`X-RTK-Token`)

Optional packaging tools:
- `cargo-deb` for `.deb`
- `cargo-generate-rpm` for `.rpm`
- `7z` for Windows ZIP packaging

## 2. Set Release Inputs

Define these build-time environment variables before compiling:

- `RTK_TELEMETRY_URL`
- `RTK_TELEMETRY_TOKEN`

PowerShell example:

```powershell
$env:RTK_TELEMETRY_URL = "https://telemetry.gebit.intra/rtk-telemetry"
$env:RTK_TELEMETRY_TOKEN = "<shared-secret>"
```

These values are compiled into the binary via `option_env!()`.

## 3. Build Release Binary (Current Platform)

```powershell
cargo build --release
```

Output:
- Windows: `target/release/rtk.exe`
- Linux/macOS: `target/release/rtk`

## 4. Verify Build

Run smoke checks against the built binary:

```powershell
./target/release/rtk.exe --version
./target/release/rtk.exe telemetry status
```

Expected telemetry status behavior:
- Shows telemetry enabled by default
- Shows endpoint configured at build time

## 5. Build Multi-Platform Artifacts (CI Matrix)

The repository release workflow builds these targets:

- `x86_64-apple-darwin`
- `aarch64-apple-darwin`
- `x86_64-unknown-linux-musl`
- `aarch64-unknown-linux-gnu`
- `x86_64-pc-windows-msvc`

Equivalent command pattern:

```bash
cargo build --release --target <target-triple>
```

Packaging in CI:
- Unix targets: `.tar.gz`
- Windows target: `.zip`
- Linux packages: `.deb` and `.rpm`

## 6. Build Debian Package

```bash
cargo install cargo-deb
cargo deb
```

Output location:
- `target/debian/*.deb`

## 7. Build RPM Package

```bash
cargo install cargo-generate-rpm
cargo build --release
cargo generate-rpm
```

Output location:
- `target/generate-rpm/*.rpm`

## 8. Create Checksums

Generate SHA-256 checksums for published artifacts:

```bash
sha256sum * > checksums.txt
```

Store checksums next to release artifacts.

## 9. Suggested Release Validation Checklist

- Binary starts and prints expected version
- `telemetry status` shows default-enabled + on-prem endpoint
- Core quality checks pass on release commit:
  - `cargo fmt --all --check`
  - `cargo clippy --all-targets`
  - `cargo test --all`
- Artifacts are created for required targets
- Checksums generated and archived

## 10. CI Release Workflow Notes

The existing GitHub workflow already injects telemetry variables into build jobs and packages all target artifacts.

Relevant workflow file:
- `.github/workflows/release.yml`

Recommended usage:
- Trigger release with a version tag (for example `v0.42.4-gebit`)
- Ensure repository variables/secrets are populated:
  - `vars.RTK_TELEMETRY_URL`
  - `secrets.RTK_TELEMETRY_TOKEN`

## 11. Troubleshooting

### Telemetry endpoint not shown in status

Cause:
- `RTK_TELEMETRY_URL` was not set at build time.

Fix:
- Rebuild with `RTK_TELEMETRY_URL` and `RTK_TELEMETRY_TOKEN` set.

### `rtk telemetry status` shows blocked

Cause:
- `RTK_TELEMETRY_DISABLED=1` is set in runtime environment.

Fix:
- Unset the variable in the runtime environment or service shell.

### Package build fails

Cause:
- Missing packager tool (`cargo-deb` or `cargo-generate-rpm`) or platform dependencies.

Fix:
- Install required tools and rerun packaging commands.
