# Proxmark Studio

A modern Flutter desktop GUI for Proxmark3 RFID/NFC tooling. Proxmark Studio provides a cleaner, safer, and better-documented interface for common Proxmark3 workflows on macOS, Linux, and Windows.

## Status

- **Release**: v1.0.0
- **Validated on**: macOS arm64 with Flutter 3.38.9 / Dart 3.10.8
- **License**: GNU General Public License v3.0 only (see `LICENSE`)
- **Support**: [Buy me a coffee](https://buymeacoffee.com/einnovoeg)

## Features

### Core Management
- Import a local `pm3` or `proxmark3` client build
- Download stable or experimental cores from an official release feed (when configured)
- Reject broken or untrusted binaries before launch with validation

### Device Workflow
- Serial-port discovery with Iceman-style port preference
- Connect/disconnect controls
- HF, LF, EMV scan modes (single and continuous)
- Live console output with command entry and chaining

### Card Workflow
- Save reads into a local card library
- Import saved-card metadata from files
- Assign cards to eight slots
- Build and persist PM3 write plans per saved card

### UI/UX
- Responsive desktop layout
- Hover tooltips for all interactive controls
- Theme mode support (light/dark/system)
- Accent color customization

## Known Issues And Limitations

**Please read before using:**

1. **No bundled PM3 binary**: This source release does not ship a compiled Proxmark3 client. You must:
   - Import a working local PM3 client (`pm3` or `proxmark3`)
   - Or use a system-installed PM3 package
   - Or configure an official release feed for auto-download

2. **Hardware required**: Full functionality requires actual Proxmark3 hardware. The app will show "No device connected" without hardware.

3. **Serial port permissions**: On macOS and Linux, you may need to grant USB/serial access permissions to access the Proxmark3 device.

4. **Online updates require configuration**: Automatic core download from GitHub is only available in builds configured with official release-feed metadata (via `--dart-define` flags).

5. **Some advanced PM3 commands**: Certain advanced PM3 operations may require manual command entry through the live console rather than UI buttons.

6. **Continuous scan stability**: Continuous scan mode works best with a stable USB connection. If connection drops, restart the scan.

## Installation And Run

### Prerequisites

- **Flutter** 3.38.9 or newer on the stable channel
- **Dart** 3.10.8 or newer
- **Xcode command line tools** (macOS)
- **Proxmark3 hardware** and **working client build** (for live hardware access)

### Development Build

```bash
# Clone or navigate to the project directory
cd proxmark-studio

# Get dependencies
flutter pub get

# Run in debug mode
flutter run -d macos
```

### macOS Build

```bash
# Build debug version
flutter build macos --debug

# Build release version
flutter build macos --release
```

### Linux Build

```bash
flutter build linux --release
```

### Windows Build

```bash
flutter build windows --release
```

## Core Setup

The Proxmark3 client binary is **not included**. You must set it up manually:

### Option 1: Import Local Core

1. Build or install a working Proxmark3 client (e.g., from [RfidResearchGroup/proxmark3](https://github.com/RfidResearchGroup/proxmark3))
2. In Proxmark Studio: `Settings` → `Import core binary`
3. Select your `pm3` or `proxmark3` executable
4. The app validates the client with `pm3 --helpclient` before trusting it

### Option 2: System Core

Place a working `pm3` binary in one of the trusted system locations:
- macOS: `/opt/homebrew/opt/proxmark3/bin/pm3` or `/usr/local/opt/proxmark3/bin/pm3`
- Linux: `/usr/bin/pm3` or `/usr/local/bin/pm3`
- Windows: `C:\Program Files\Proxmark3\pm3.exe`

### Option 3: Official Release Feed (When Configured)

If you have an official build with configured release feed:
- `Settings` → `Download stable` or `Download experimental`
- The app will download and validate the core automatically

**Note**: If you prepare a redistributable embedded core for a private build, use `tools/bundle_core.sh` and record the exact upstream source tag or commit in `assets/bundled/README.txt` before distributing.

## Documentation

- [USER_GUIDE.md](USER_GUIDE.md) — User workflow and troubleshooting
- [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) — Third-party notices and compliance
- [DEPENDENCIES.md](DEPENDENCIES.md) — Build and runtime dependencies
- [CHANGELOG.md](CHANGELOG.md) — Release history
- [CONTRIBUTORS.md](CONTRIBUTORS.md) — Upstream credits
- [tools/README.md](tools/README.md) — Embedded-core bundling notes

## Contributing And Issues

We welcome contributions and bug reports! If you encounter issues:

1. Check the [known issues](#known-issues-and-limitations) above
2. Review open issues on GitHub
3. Submit a pull request or issue with details

**Please help fix any issues you come across by reporting them or submitting fixes.**

## Security

This project takes security seriously:

- All GitHub download URLs are validated against a trusted host allowlist
- Archive extraction prevents path traversal attacks
- Downloaded binaries are checksum-verified before use
- Executable path resolution uses a trusted-path whitelist
- External links are restricted to safe HTTPS URLs

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for full license compliance details.

## License

Proxmark Studio is licensed under the **GNU General Public License v3.0 only**.

See `LICENSE` for the full license text and `THIRD_PARTY_NOTICES.md` for dependency and upstream attribution details.

**Upstream Licenses**:
- RfidResearchGroup/proxmark3: GPL-3.0
- iceman1001/proxmark3: GPL-2.0
- Flutter SDK: BSD-style
- All Flutter dependencies: Various open-source licenses (see DEPENDENCIES.md)

## Support

- [Buy me a coffee](https://buymeacoffee.com/einnovoeg)
- [GitHub Issues](https://github.com/Einnovoeg/proxmark-studio/issues)

---

**We encourage users to help fix issues they come across and submit pull requests to improve the project.**